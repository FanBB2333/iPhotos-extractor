import dataclasses
import traceback
from abc import ABC, abstractmethod
from tempfile import TemporaryDirectory
import logging
import json
from pathlib import Path


import sqlite3
import pandas as pd
from pymobiledevice3 import usbmux
from pymobiledevice3.lockdown import create_using_usbmux, LockdownClient
from pymobiledevice3.services.diagnostics import DiagnosticsService
from pymobiledevice3.services.afc import AfcService, AfcShell

from ipe.constants import *
from ipe.classes.album import Album
from ipe.classes.photo import Photo

class PhotosDB(ABC):
    '''
    Abstract class for Photos database, parsing and extracting data
    '''
    def __init__(self, path: str) -> None:
        print(f"Connecting to {path}")
        self.path = path
        self.conn, self.curs = None, None
        try:
            self.init_db(path)
            print(f"Connected to {path}")
        except sqlite3.OperationalError as e:
            print(f"OperationalError: {e}")
            exit(1)
        except sqlite3.DatabaseError as e:
            print(f"DatabaseError: {e}")
            exit(1)
            
        
    def __del__(self):
        if self.conn:
            self.conn.close()
    
    def init_db(self, path):
        self.conn = sqlite3.connect(path)
        self.curs = self.conn.cursor()
        self.photos = self.get_photos()
        self.albums = self.get_albums()
    
    def get_photos(self):
        # parse the main ZASSET table and read in photos info
        self.curs.execute("SELECT * FROM ZASSET")
        column_names = [description[0] for description in self.curs.description]
        assets = self.curs.fetchall()
        assets_with_columns = [dict(zip(column_names, asset)) for asset in assets]
        # convert to Photo objects
        photos = [Photo(**a) for a in assets_with_columns]
        photos = {photo.Z_PK: photo for photo in photos}
        print(f"There are {len(photos)} photos in the database.")
        return photos
    
    def get_albums(self):
        # select the user-created albums
        self.curs.execute("SELECT * FROM ZGENERICALBUM where ZKIND = 2")
        column_names = [description[0] for description in self.curs.description]
        albums = self.curs.fetchall()
        albums_with_columns = [dict(zip(column_names, album)) for album in albums]
        # convert to Album objects
        albums = [Album(**a) for a in albums_with_columns]
        
        # get info from Z_30ASSETS table
        self.curs.execute("SELECT * FROM Z_30ASSETS")
        column_names = [description[0] for description in self.curs.description]
        assets = self.curs.fetchall()
        assets_with_columns = [dict(zip(column_names, asset)) for asset in assets]
        for album in albums:
            album.PhotoIds = [asset["Z_3ASSETS"] for asset in assets_with_columns if asset["Z_30ALBUMS"] == album.Z_PK]
        
        return albums
    
    def parse_albums(self):
        for album in self.albums:
            print(album)
    


class macOSDB(PhotosDB):
    '''
    used for macOS to get the database file from local file system
    '''
    def __init__(self, path: str = MACOS_PHOTOS_DB) -> None:
        super().__init__(path=path)
    
    def test(self):
        print("test")
    
class iosDB(PhotosDB):
    '''
    used for iDevices to get the database file from the device
    '''
    def __init__(self, device_id: int = DEVICE_ID) -> None:
        self.init_device(device_id)
        self.tmp_dir = TemporaryDirectory()
        print(f"Temporary directory: {self.tmp_dir.name}")
        self.local_file = self.get_db_from_device()
        super().__init__(path=self.local_file)

    def init_device(self, device_id: int = DEVICE_ID):
        available_devices = usbmux.list_devices()
        # check the device_id is valid
        if device_id >= len(available_devices):
            if device_id == 0:
                print("No device connected.")
            else:
                print(f"Invalid device id {device_id}.")
            return None
        self.device = available_devices[device_id]
        # use afc to get the file
        self.ldc = create_using_usbmux(self.device.serial) # lockdown client
        self.afc = AfcService(lockdown=self.ldc)
        
    
    def get_db_from_device(self, remote_file: str = IDEVICES_PHOTOS_DB):
        local_file = Path(self.tmp_dir.name) / "Photos.sqlite"
        print(f"Pulling file from {self.ldc.all_values['DeviceName']} to {local_file}")
        # pull file from device
        self.afc.pull(remote_file, local_file)
        return local_file
    
    def __del__(self):
        self.tmp_dir.cleanup()
        super().__del__()
        
        
if __name__ == "__main__":
    # db = macOSDB()
    # db.parse_albums()
    db = iosDB()
    db.parse_albums()
