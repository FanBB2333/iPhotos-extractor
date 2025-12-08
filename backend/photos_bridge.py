#!/usr/bin/env python3
"""
JSON-RPC Bridge for osxphotos library.
Communicates with Flutter frontend via stdin/stdout.
"""

import sys
import json
import osxphotos
from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any, List


class PhotosBridge:
    """Bridge between Flutter frontend and osxphotos library."""
    
    def __init__(self):
        self.photosdb: Optional[osxphotos.PhotosDB] = None
    
    def initialize(self) -> Dict[str, Any]:
        """Initialize connection to Photos library."""
        try:
            self.photosdb = osxphotos.PhotosDB()
            return {
                "status": "ok",
                "version": self.photosdb.photos_version,
                "library_path": self.photosdb.library_path
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}
    
    def get_library_info(self) -> Dict[str, Any]:
        """Get library-level information."""
        if not self.photosdb:
            return {"error": "Not initialized"}
        
        all_photos = self.photosdb.photos()
        
        return {
            "library_path": self.photosdb.library_path,
            "db_path": self.photosdb.db_path,
            "db_version": self.photosdb.db_version,
            "photos_version": self.photosdb.photos_version,
            "total_photos": len(all_photos),
            "total_albums": len(self.photosdb.album_info),
            "total_folders": len(self.photosdb.folder_info),
            "keywords": self.photosdb.keywords,
            "persons": self.photosdb.persons,
            "labels": self.photosdb.labels
        }
    
    def get_albums(self) -> List[Dict[str, Any]]:
        """Get all albums from the library."""
        if not self.photosdb:
            return []
        
        albums = []
        for album in self.photosdb.album_info:
            photos = album.photos
            cover_path = None
            if photos:
                # Use first photo as cover
                for p in photos:
                    if p.path:
                        cover_path = p.path
                        break
            
            albums.append({
                "uuid": album.uuid,
                "title": album.title or "Untitled",
                "count": len(photos),
                "creation_date": str(album.creation_date) if album.creation_date else None,
                "cover_path": cover_path
            })
        
        return albums
    
    def get_folders(self) -> List[Dict[str, Any]]:
        """Get all folders from the library."""
        if not self.photosdb:
            return []
        
        folders = []
        for folder in self.photosdb.folder_info:
            folders.append({
                "uuid": folder.uuid,
                "title": folder.title or "Untitled",
                "subfolders": [sf.title for sf in folder.subfolders] if folder.subfolders else [],
                "albums": [a.title for a in folder.album_info] if folder.album_info else []
            })
        
        return folders
    
    def get_photos(self, album_uuid: Optional[str] = None, 
                   favorites_only: bool = False,
                   recent_days: Optional[int] = None,
                   limit: int = 100,
                   offset: int = 0) -> List[Dict[str, Any]]:
        """Get photos with optional filters."""
        if not self.photosdb:
            return []
        
        # Get base photo list
        if album_uuid:
            album = next((a for a in self.photosdb.album_info if a.uuid == album_uuid), None)
            if not album:
                return []
            photos = album.photos
        else:
            photos = self.photosdb.photos()
        
        # Apply filters
        if favorites_only:
            photos = [p for p in photos if p.favorite]
        
        if recent_days:
            cutoff = datetime.now(timezone.utc) - timedelta(days=recent_days)
            photos = [p for p in photos if p.date and p.date >= cutoff]
        
        # Filter out trashed photos
        photos = [p for p in photos if not p.intrash]
        
        # Sort by date (newest first)
        photos = sorted(photos, key=lambda x: x.date or datetime.min.replace(tzinfo=timezone.utc), reverse=True)
        
        # Apply pagination
        photos = photos[offset:offset + limit]
        
        result = []
        for photo in photos:
            result.append({
                "uuid": photo.uuid,
                "filename": photo.filename,
                "original_filename": photo.original_filename,
                "path": photo.path,
                "date": str(photo.date) if photo.date else None,
                "width": photo.width,
                "height": photo.height,
                "favorite": photo.favorite,
                "hidden": photo.hidden,
                "is_live_photo": photo.live_photo,
                "is_video": photo.ismovie,
                "is_screenshot": photo.screenshot
            })
        
        return result
    
    def get_photo_metadata(self, uuid: str) -> Optional[Dict[str, Any]]:
        """Get detailed metadata for a specific photo."""
        if not self.photosdb:
            return None
        
        photos = self.photosdb.photos()
        photo = next((p for p in photos if p.uuid == uuid), None)
        
        if not photo:
            return None
        
        # Get EXIF data
        exif = photo.exif_info
        exif_data = None
        if exif:
            exif_data = {
                "camera_make": exif.camera_make,
                "camera_model": exif.camera_model,
                "lens_model": exif.lens_model,
                "iso": exif.iso,
                "exposure_time": exif.exposure_time,
                "focal_length": exif.focal_length,
                "aperture": exif.aperture
            }
        
        # Get location
        location = photo.location
        location_data = None
        if location and location != (None, None):
            location_data = {
                "latitude": location[0],
                "longitude": location[1]
            }
        
        return {
            "uuid": photo.uuid,
            "filename": photo.filename,
            "original_filename": photo.original_filename,
            "path": photo.path,
            "date": str(photo.date) if photo.date else None,
            "date_modified": str(photo.date_modified) if photo.date_modified else None,
            "description": photo.description,
            "title": photo.title,
            "keywords": photo.keywords,
            "persons": photo.persons,
            "labels": photo.labels,
            "width": photo.width,
            "height": photo.height,
            "orientation": photo.orientation,
            "favorite": photo.favorite,
            "hidden": photo.hidden,
            "is_hdr": photo.hdr,
            "is_live_photo": photo.live_photo,
            "is_portrait": photo.portrait,
            "is_selfie": photo.selfie,
            "is_slow_mo": photo.slow_mo,
            "is_time_lapse": photo.time_lapse,
            "is_panorama": photo.panorama,
            "is_video": photo.ismovie,
            "is_screenshot": photo.screenshot,
            "exif": exif_data,
            "location": location_data
        }
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get photo library statistics."""
        if not self.photosdb:
            return {}
        
        all_photos = self.photosdb.photos()
        
        favorites = len([p for p in all_photos if p.favorite])
        hidden = len([p for p in all_photos if p.hidden])
        screenshots = len([p for p in all_photos if p.screenshot])
        videos = len([p for p in all_photos if p.ismovie])
        live_photos = len([p for p in all_photos if p.live_photo])
        
        # Recent (last 30 days)
        cutoff = datetime.now(timezone.utc) - timedelta(days=30)
        recent = len([p for p in all_photos if p.date and p.date >= cutoff])
        
        return {
            "total": len(all_photos),
            "favorites": favorites,
            "hidden": hidden,
            "screenshots": screenshots,
            "videos": videos,
            "live_photos": live_photos,
            "recent_30_days": recent,
            "albums": len(self.photosdb.album_info),
            "folders": len(self.photosdb.folder_info)
        }
    
    def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle incoming JSON-RPC request."""
        method = request.get("method")
        params = request.get("params", {})
        request_id = request.get("id")
        
        handlers = {
            "initialize": lambda: self.initialize(),
            "get_library_info": lambda: self.get_library_info(),
            "get_albums": lambda: self.get_albums(),
            "get_folders": lambda: self.get_folders(),
            "get_photos": lambda: self.get_photos(**params),
            "get_photo_metadata": lambda: self.get_photo_metadata(**params),
            "get_statistics": lambda: self.get_statistics(),
        }
        
        if method in handlers:
            try:
                result = handlers[method]()
                return {"id": request_id, "result": result}
            except Exception as e:
                return {"id": request_id, "error": str(e)}
        
        return {"id": request_id, "error": f"Unknown method: {method}"}


def main():
    """Main entry point for JSON-RPC bridge."""
    bridge = PhotosBridge()
    
    # Read from stdin line by line
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        
        try:
            request = json.loads(line)
            response = bridge.handle_request(request)
            print(json.dumps(response), flush=True)
        except json.JSONDecodeError as e:
            print(json.dumps({"error": f"Invalid JSON: {e}"}), flush=True)
        except Exception as e:
            print(json.dumps({"error": str(e)}), flush=True)


if __name__ == "__main__":
    main()
