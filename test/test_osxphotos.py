#!/usr/bin/env python3
"""
Test script for osxphotos library integration.
This script demonstrates basic read operations using osxphotos.
"""

import osxphotos
import os
from datetime import datetime


def test_list_photos(photosdb: osxphotos.PhotosDB, limit: int = 10):
    """List photos from the library with basic info."""
    print("\n" + "=" * 60)
    print("Testing: List Photos")
    print("=" * 60)
    
    photos = photosdb.photos()
    print(f"Total photos in library: {len(photos)}")
    
    for i, photo in enumerate(photos[:limit]):
        print(f"\n[Photo {i + 1}]")
        print(f"  UUID: {photo.uuid}")
        print(f"  Filename: {photo.filename}")
        print(f"  Original filename: {photo.original_filename}")
        print(f"  Date: {photo.date}")
        print(f"  Path: {photo.path}")
        print(f"  Favorite: {photo.favorite}")
        print(f"  Hidden: {photo.hidden}")
        print(f"  In Trash: {photo.intrash}")
    
    return photos


def test_list_albums(photosdb: osxphotos.PhotosDB):
    """List all albums from the library."""
    print("\n" + "=" * 60)
    print("Testing: List Albums")
    print("=" * 60)
    
    albums = photosdb.album_info
    print(f"Total albums: {len(albums)}")
    
    for album in albums:
        photo_count = len(album.photos)
        print(f"\n[Album]")
        print(f"  Title: {album.title}")
        print(f"  UUID: {album.uuid}")
        print(f"  Photo count: {photo_count}")
        print(f"  Creation date: {album.creation_date}")
    
    return albums


def test_list_folders(photosdb: osxphotos.PhotosDB):
    """List all folders from the library."""
    print("\n" + "=" * 60)
    print("Testing: List Folders")
    print("=" * 60)
    
    folders = photosdb.folder_info
    print(f"Total folders: {len(folders)}")
    
    for folder in folders:
        print(f"\n[Folder]")
        print(f"  Title: {folder.title}")
        print(f"  UUID: {folder.uuid}")
        # List subalbums if any
        if folder.subfolders:
            print(f"  Subfolders: {[sf.title for sf in folder.subfolders]}")
        if folder.album_info:
            print(f"  Albums: {[a.title for a in folder.album_info]}")
    
    return folders


def test_query_photos(photosdb: osxphotos.PhotosDB):
    """Query photos with various filters."""
    print("\n" + "=" * 60)
    print("Testing: Query Photos")
    print("=" * 60)
    
    # Get all photos first
    all_photos = photosdb.photos()
    
    # Filter favorite photos by attribute
    favorites = [p for p in all_photos if p.favorite]
    print(f"Favorite photos: {len(favorites)}")
    
    # Filter hidden photos by attribute
    hidden = [p for p in all_photos if p.hidden]
    print(f"Hidden photos: {len(hidden)}")
    
    # Filter screenshots by attribute
    screenshots = [p for p in all_photos if p.screenshot]
    print(f"Screenshots: {len(screenshots)}")
    
    # Query photos from specific time range (last 30 days)
    from datetime import timedelta, timezone
    # Use timezone-aware datetime for comparison
    thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)
    recent = [p for p in all_photos if p.date and p.date >= thirty_days_ago]
    print(f"Photos from last 30 days: {len(recent)}")
    
    return {
        "favorites": favorites,
        "hidden": hidden,
        "screenshots": screenshots,
        "recent": recent
    }


def test_photo_metadata(photosdb: osxphotos.PhotosDB):
    """Get detailed metadata for a sample photo."""
    print("\n" + "=" * 60)
    print("Testing: Photo Metadata")
    print("=" * 60)
    
    photos = photosdb.photos()
    if not photos:
        print("No photos found in library.")
        return None
    
    # Get first non-trashed photo
    sample = None
    for p in photos:
        if not p.intrash:
            sample = p
            break
    
    if not sample:
        print("No valid photo found for metadata test.")
        return None
    
    print(f"\nDetailed metadata for: {sample.filename}")
    print(f"  UUID: {sample.uuid}")
    print(f"  Date: {sample.date}")
    print(f"  Date modified: {sample.date_modified}")
    print(f"  Description: {sample.description}")
    print(f"  Title: {sample.title}")
    print(f"  Keywords: {sample.keywords}")
    print(f"  Persons: {sample.persons}")
    print(f"  Labels: {sample.labels}")
    print(f"  Width: {sample.width}")
    print(f"  Height: {sample.height}")
    print(f"  Orientation: {sample.orientation}")
    print(f"  Is HDR: {sample.hdr}")
    print(f"  Is Live Photo: {sample.live_photo}")
    print(f"  Is Portrait: {sample.portrait}")
    print(f"  Is Selfie: {sample.selfie}")
    print(f"  Is Slow Mo: {sample.slow_mo}")
    print(f"  Is Time Lapse: {sample.time_lapse}")
    print(f"  Is Panorama: {sample.panorama}")
    
    # Location info
    loc = sample.location
    if loc and loc != (None, None):
        print(f"  Location: {loc}")
    
    # EXIF data
    exif = sample.exif_info
    if exif:
        print(f"  Camera make: {exif.camera_make}")
        print(f"  Camera model: {exif.camera_model}")
        print(f"  Lens model: {exif.lens_model}")
    
    return sample


def test_library_info(photosdb: osxphotos.PhotosDB):
    """Get library-level information."""
    print("\n" + "=" * 60)
    print("Testing: Library Info")
    print("=" * 60)
    
    print(f"Library path: {photosdb.library_path}")
    print(f"Photos database path: {photosdb.db_path}")
    print(f"Photos database version: {photosdb.db_version}")
    print(f"Photos library version: {photosdb.photos_version}")
    
    # Count statistics
    all_photos = photosdb.photos()
    print(f"\nStatistics:")
    print(f"  Total photos: {len(all_photos)}")
    print(f"  Total albums: {len(photosdb.album_info)}")
    print(f"  Total folders: {len(photosdb.folder_info)}")
    print(f"  Keywords: {photosdb.keywords}")
    print(f"  Persons: {photosdb.persons}")
    print(f"  Labels: {photosdb.labels}")


def main():
    """Main test function."""
    print("=" * 60)
    print("osxphotos Integration Test")
    print("=" * 60)
    
    # Try to open the default Photos library
    # osxphotos will use the system Photos library by default
    try:
        print("\nInitializing osxphotos with default library...")
        photosdb = osxphotos.PhotosDB()
        print("Successfully connected to Photos library!")
    except Exception as e:
        print(f"Error connecting to default library: {e}")
        print("\nTrying to use a custom library path...")
        
        # Try test library
        test_lib_path = os.path.expanduser(
            "~/Pictures/Photos Library.photoslibrary"
        )
        if os.path.exists(test_lib_path):
            photosdb = osxphotos.PhotosDB(dbfile=test_lib_path)
        else:
            print(f"Library not found at: {test_lib_path}")
            print("Please specify a valid Photos library path.")
            return
    
    # Run tests
    test_library_info(photosdb)
    test_list_albums(photosdb)
    test_list_folders(photosdb)
    test_list_photos(photosdb, limit=5)
    test_query_photos(photosdb)
    test_photo_metadata(photosdb)
    
    print("\n" + "=" * 60)
    print("All tests completed!")
    print("=" * 60)


if __name__ == "__main__":
    main()
