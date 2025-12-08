# Photo Album Display Software - Technology Stack Analysis

## Overview

本文档针对 **macOS 桌面应用** 场景，分析 Flutter + Python (osxphotos) 的最佳集成方案。

---

## Flutter + Python 集成方案对比

| 方案                      | 通信方式     | 性能      | 复杂度 | 推荐场景 |
| ------------------------- | ------------ | --------- | ------ | -------- |
| **Subprocess + JSON**     | stdin/stdout | Good      | Low    | 简单查询 |
| **Unix Socket**           | IPC          | Excellent | Medium | 高频通信 |
| **Embedded Python (FFI)** | Direct call  | Best      | High   | 极致性能 |
| **HTTP API (localhost)**  | REST         | Good      | Medium | 标准方案 |

---

## Recommended: Subprocess + JSON-RPC

这是 macOS 桌面应用最平衡的方案：Flutter 启动 Python 子进程，通过 stdin/stdout 以 JSON 格式通信。

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Flutter macOS App                       │
│  ┌────────────────────┐    ┌─────────────────────────┐ │
│  │   Flutter UI       │    │   Python Process        │ │
│  │   (Dart)           │◄──►│   (osxphotos)           │ │
│  │                    │    │                         │ │
│  │   - Album View     │    │   - Read Photos DB      │ │
│  │   - Photo Grid     │    │   - Generate Thumbnails │ │
│  │   - Image Preview  │    │   - Export Photos       │ │
│  └────────────────────┘    └─────────────────────────┘ │
│           │                          │                  │
│           │      stdin/stdout        │                  │
│           └──────── JSON-RPC ────────┘                  │
└─────────────────────────────────────────────────────────┘
```

### Python Backend (JSON-RPC Server)

```python
# backend/photos_bridge.py
import sys
import json
import osxphotos
from pathlib import Path

class PhotosBridge:
    def __init__(self):
        self.photosdb = None
    
    def initialize(self):
        self.photosdb = osxphotos.PhotosDB()
        return {"status": "ok", "version": self.photosdb.photos_version}
    
    def get_albums(self):
        return [{
            "uuid": a.uuid,
            "title": a.title,
            "count": len(a.photos)
        } for a in self.photosdb.album_info]
    
    def get_photos(self, album_uuid: str = None, limit: int = 100):
        if album_uuid:
            album = next((a for a in self.photosdb.album_info 
                         if a.uuid == album_uuid), None)
            photos = album.photos if album else []
        else:
            photos = self.photosdb.photos()[:limit]
        
        return [{
            "uuid": p.uuid,
            "filename": p.filename,
            "path": p.path,
            "date": str(p.date),
            "width": p.width,
            "height": p.height
        } for p in photos]
    
    def handle_request(self, request: dict):
        method = request.get("method")
        params = request.get("params", {})
        
        handlers = {
            "initialize": self.initialize,
            "get_albums": self.get_albums,
            "get_photos": lambda: self.get_photos(**params),
        }
        
        if method in handlers:
            return {"id": request.get("id"), "result": handlers[method]()}
        return {"id": request.get("id"), "error": f"Unknown method: {method}"}

def main():
    bridge = PhotosBridge()
    for line in sys.stdin:
        try:
            request = json.loads(line.strip())
            response = bridge.handle_request(request)
            print(json.dumps(response), flush=True)
        except Exception as e:
            print(json.dumps({"error": str(e)}), flush=True)

if __name__ == "__main__":
    main()
```

### Flutter Frontend (Dart)

```dart
// lib/services/python_bridge.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async'; // Import for Completer

class PythonBridge {
  Process? _process;
  int _requestId = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};

  Future<void> start() async {
    _process = await Process.start(
      'python3',
      ['backend/photos_bridge.py'],
      workingDirectory: Directory.current.path,
    );
    
    _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleResponse);
    
    _process!.stderr
        .transform(utf8.decoder)
        .listen((data) => print('Python stderr: $data')); // Log stderr for debugging
  }

  void _handleResponse(String line) {
    try {
      final response = jsonDecode(line) as Map<String, dynamic>;
      final id = response['id'] as int?;
      if (id != null && _pending.containsKey(id)) {
        _pending[id]!.complete(response);
        _pending.remove(id);
      } else {
        print('Received unexpected Python response: $line');
      }
    } catch (e) {
      print('Error parsing Python response: $e, line: $line');
    }
  }

  Future<Map<String, dynamic>> call(String method, [Map<String, dynamic>? params]) async {
    final id = _requestId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    
    final request = jsonEncode({
      'id': id,
      'method': method,
      'params': params ?? {},
    });
    
    _process!.stdin.writeln(request);
    return completer.future;
  }

  // Dummy Album and Photo classes for example to compile
  // In a real app, these would be defined in models/
  class Album {
    final String uuid;
    final String title;
    final int count;
    Album({required this.uuid, required this.title, required this.count});
    factory Album.fromJson(Map<String, dynamic> json) => Album(
      uuid: json['uuid'], title: json['title'], count: json['count']);
  }

  class Photo {
    final String uuid;
    final String filename;
    final String path;
    final String date;
    final int width;
    final int height;
    Photo({required this.uuid, required this.filename, required this.path,
           required this.date, required this.width, required this.height});
    factory Photo.fromJson(Map<String, dynamic> json) => Photo(
      uuid: json['uuid'], filename: json['filename'], path: json['path'],
      date: json['date'], width: json['width'], height: json['height']);
  }

  Future<List<Album>> getAlbums() async {
    final response = await call('get_albums');
    if (response.containsKey('result') && response['result'] is List) {
      return (response['result'] as List)
          .map((e) => Album.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to get albums: ${response['error']}');
  }

  Future<List<Photo>> getPhotos({String? albumUuid, int limit = 100}) async {
    final response = await call('get_photos', {
      'album_uuid': albumUuid,
      'limit': limit,
    });
    if (response.containsKey('result') && response['result'] is List) {
      return (response['result'] as List)
          .map((e) => Photo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to get photos: ${response['error']}');
  }

  void dispose() {
    _process?.kill();
  }
}
```

### Flutter App Entry

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'services/python_bridge.dart'; // Ensure this path is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final bridge = PythonBridge();
  await bridge.start();
  final initResponse = await bridge.call('initialize');
  print('Python bridge initialized: $initResponse');
  
  runApp(PhotosApp(bridge: bridge));
}

class PhotosApp extends StatelessWidget {
  final PythonBridge bridge;

  const PhotosApp({Key? key, required this.bridge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photos Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(bridge: bridge),
    );
  }
}

class HomePage extends StatefulWidget {
  final PythonBridge bridge;
  const HomePage({Key? key, required this.bridge}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<PythonBridge.Album> _albums = [];
  List<PythonBridge.Photo> _photos = [];
  bool _isLoading = true;
  String? _selectedAlbumUuid;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final albums = await widget.bridge.getAlbums();
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
      if (albums.isNotEmpty) {
        _selectedAlbumUuid = albums.first.uuid;
        _loadPhotos(_selectedAlbumUuid);
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadPhotos(String? albumUuid) async {
    setState(() { _isLoading = true; });
    try {
      final photos = await widget.bridge.getPhotos(albumUuid: albumUuid);
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading photos: $e');
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photos Album Viewer'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    value: _selectedAlbumUuid,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedAlbumUuid = newValue;
                      });
                      _loadPhotos(newValue);
                    },
                    items: _albums.map<DropdownMenuItem<String>>((album) {
                      return DropdownMenuItem<String>(
                        value: album.uuid,
                        child: Text('${album.title} (${album.count})'),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      final photo = _photos[index];
                      return Image.file(
                        File(photo.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
```

---

## Alternative: Unix Socket (Higher Performance)

如果需要传输大量图片数据或高频通信，使用 Unix Socket 更高效：

```python
# backend/socket_server.py
import socket
import os
import json
import osxphotos # Assuming osxphotos is used here too

SOCKET_PATH = "/tmp/photos_bridge.sock"

class PhotosSocketBridge:
    def __init__(self):
        self.photosdb = None
    
    def initialize(self):
        self.photosdb = osxphotos.PhotosDB()
        return {"status": "ok", "version": self.photosdb.photos_version}
    
    def get_albums(self):
        return [{
            "uuid": a.uuid,
            "title": a.title,
            "count": len(a.photos)
        } for a in self.photosdb.album_info]
    
    def get_photos(self, album_uuid: str = None, limit: int = 100):
        if album_uuid:
            album = next((a for a in self.photosdb.album_info 
                         if a.uuid == album_uuid), None)
            photos = album.photos if album else []
        else:
            photos = self.photosdb.photos()[:limit]
        
        return [{
            "uuid": p.uuid,
            "filename": p.filename,
            "path": p.path,
            "date": str(p.date),
            "width": p.width,
            "height": p.height
        } for p in photos]
    
    def handle_request(self, request: dict):
        method = request.get("method")
        params = request.get("params", {})
        
        handlers = {
            "initialize": self.initialize,
            "get_albums": self.get_albums,
            "get_photos": lambda: self.get_photos(**params),
        }
        
        if method in handlers:
            return {"id": request.get("id"), "result": handlers[method]()}
        return {"id": request.get("id"), "error": f"Unknown method: {method}"}

def start_server():
    if os.path.exists(SOCKET_PATH):
        os.remove(SOCKET_PATH)
    
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    server.listen(1)
    print(f"Listening on {SOCKET_PATH}")

    bridge = PhotosSocketBridge()
    
    while True:
        conn, _ = server.accept()
        print("Client connected")
        with conn:
            while True:
                data = conn.recv(4096)
                if not data:
                    break
                try:
                    request = json.loads(data.decode('utf-8'))
                    response = bridge.handle_request(request)
                    conn.sendall(json.dumps(response).encode('utf-8') + b'\n')
                except json.JSONDecodeError:
                    conn.sendall(json.dumps({"error": "Invalid JSON"}).encode('utf-8') + b'\n')
                except Exception as e:
                    conn.sendall(json.dumps({"error": str(e)}).encode('utf-8') + b'\n')
        print("Client disconnected")

if __name__ == "__main__":
    start_server()
```

```dart
// Dart Unix Socket client
import 'dart:io';
import 'dart:convert';
import 'dart:async';

class PythonUnixSocketBridge {
  Socket? _socket;
  int _requestId = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final String socketPath;

  PythonUnixSocketBridge(this.socketPath);

  Future<void> connect() async {
    _socket = await Socket.connect(
      InternetAddress(socketPath, type: InternetAddressType.unix),
      0,
    );
    _socket!.transform(utf8.decoder).transform(const LineSplitter()).listen(_handleResponse);
    print('Connected to Unix socket: $socketPath');
  }

  void _handleResponse(String line) {
    try {
      final response = jsonDecode(line) as Map<String, dynamic>;
      final id = response['id'] as int?;
      if (id != null && _pending.containsKey(id)) {
        _pending[id]!.complete(response);
        _pending.remove(id);
      } else {
        print('Received unexpected Python socket response: $line');
      }
    } catch (e) {
      print('Error parsing Python socket response: $e, line: $line');
    }
  }

  Future<Map<String, dynamic>> call(String method, [Map<String, dynamic>? params]) async {
    if (_socket == null) {
      throw Exception('Socket not connected. Call connect() first.');
    }
    final id = _requestId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    
    final request = jsonEncode({
      'id': id,
      'method': method,
      'params': params ?? {},
    });
    
    _socket!.writeln(request);
    return completer.future;
  }

  void dispose() {
    _socket?.destroy();
  }
}
```

---

## Project Structure

```
iPhotos-extractor/
├── backend/
│   ├── photos_bridge.py      # JSON-RPC bridge (subprocess)
│   ├── socket_server.py      # Unix Socket server (alternative)
│   ├── photos_service.py     # osxphotos wrapper (optional, for larger backend)
│   └── requirements.txt      # Python dependencies
├── lib/                      # Flutter app
│   ├── main.dart
│   ├── models/
│   │   ├── album.dart
│   │   └── photo.dart
│   ├── services/
│   │   └── python_bridge.dart # Subprocess bridge implementation
│   │   └── python_socket_bridge.dart # Unix socket bridge implementation (alternative)
│   ├── providers/
│   │   └── photos_provider.dart
│   └── pages/
│       ├── albums_page.dart
│       └── photos_page.dart
├── macos/                    # macOS specific
├── pubspec.yaml
└── README.md
```

---

## Key Benefits of Subprocess Approach

| Benefit                | Description                                                 |
| ---------------------- | ----------------------------------------------------------- |
| **Single App**         | Python process bundled with Flutter app, no separate server |
| **Auto Lifecycle**     | Python process starts/stops with app                        |
| **No Port Conflicts**  | No HTTP port needed                                         |
| **Simpler Deployment** | Bundle Python script with app                               |
| **Direct File Access** | Photo paths work directly in Flutter                        |

---

## Image Display Strategy

由于 Flutter 可以直接读取本地文件，图片显示无需通过 Python 传输：

```dart
// Flutter 直接读取图片文件
import 'dart:io'; // Required for File
// ...
Image.file(File(photo.path))

// 或使用缓存库，例如 cached_network_image，但需要将本地路径转换为 URI
// import 'package:cached_network_image/cached_network_image.dart';
// ...
// CachedNetworkImage(
//   imageUrl: 'file://${photo.path}', // Note the 'file://' scheme
//   fit: BoxFit.cover,
//   placeholder: (context, url) => CircularProgressIndicator(),
//   errorWidget: (context, url, error) => Icon(Icons.error),
// )
```

Python 只需返回图片路径，Flutter 直接加载，这样性能最优。

---

## Quick Start

```bash
# 1. Install Python dependencies
pip install osxphotos

# 2. Create Flutter project (if new)
flutter create --platforms=macos photos_viewer
cd photos_viewer

# 3. Add backend script
mkdir backend
# Copy photos_bridge.py to backend/

# 4. Run
flutter run -d macos
```
