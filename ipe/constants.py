# imports
import os

# file paths
MACOS_PHOTOS_LIBRARY: str = os.path.expanduser(r"~/Pictures/Photos Library.photoslibrary")
MACOS_PHOTOS_DB: str = os.path.join(MACOS_PHOTOS_LIBRARY, "database/Photos.sqlite")
IDEVICES_PHOTOS_DB: str = "/PhotoData/Photos.sqlite"

# default settings
DEVICE_ID: int = 0