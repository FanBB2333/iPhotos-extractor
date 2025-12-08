import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/python_bridge.dart';
import 'providers/photos_provider.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create the Python bridge
  final bridge = PythonBridge();
  
  runApp(PhotosApp(bridge: bridge));
}

class PhotosApp extends StatelessWidget {
  final PythonBridge bridge;

  const PhotosApp({super.key, required this.bridge});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PhotosProvider(bridge)..initialize(),
      child: MaterialApp(
        title: 'Photos Viewer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const AppWrapper(),
      ),
    );
  }
}

/// Wrapper to handle initial loading state.
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotosProvider>();
    
    // Show loading screen while initializing
    if (!provider.isInitialized && provider.error == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 24),
              Text(
                'Connecting to Photos Library...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please allow access if prompted',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return const HomePage();
  }
}
