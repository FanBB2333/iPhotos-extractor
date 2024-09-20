import dataclasses
import traceback
from abc import ABC, abstractmethod
from tempfile import TemporaryDirectory
import logging
import json
from pathlib import Path

import sqlite3
from pymobiledevice3 import usbmux
from pymobiledevice3.lockdown import create_using_usbmux, LockdownClient
from pymobiledevice3.services.diagnostics import DiagnosticsService
from pymobiledevice3.services.afc import AfcService, AfcShell

from ipe.constants import *
from ipe.classes.album import Album

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
        self.albums = self.get_albums()
    
    def get_albums(self):
        # select the user-created albums
        self.curs.execute("SELECT * FROM ZGENERICALBUM where ZKIND = 2")
        column_names = [description[0] for description in self.curs.description]

        albums = self.curs.fetchall()

        albums_with_columns = [dict(zip(column_names, album)) for album in albums]

        # convert to Album objects
        print(albums_with_columns[0])
        albums = [Album(**a) for a in albums_with_columns]
        return albums
    
    def parse_albums(self):
        for album in self.albums:
            print(album)
    


class macOSDB(PhotosDB):
    '''
    used for macOS to get the database file from local file system
    '''
    def __init__(self, path: str = MACOS_PHOTOS_DB) -> None:
        super().__init__(path)
    
    def test(self):
        print("test")
    
class iosDB(PhotosDB):
    '''
    used for iDevices to get the database file from the device
    '''
    def __init__(self, path: str) -> None:
        super().__init__(path)

    def get_db_from_device(self, device_id: int = DEVICE_ID, remote_file: str = IDEVICES_PHOTOS_DB):
        available_devices = usbmux.list_devices()
        # check the device_id is valid
        if device_id >= len(available_devices):
            if device_id == 0:
                print("No device connected.")
            else:
                print(f"Invalid device id {device_id}.")
            return None
        device = available_devices[device_id]
        # use afc to get the file
        conn = create_using_usbmux(device.serial)
        afc = AfcService(lockdown=conn)
        with TemporaryDirectory() as tmp_dir:
            local_file = Path(tmp_dir) / "Photos.sqlite"
            print(f"Pulling file from {device.serial} to {local_file}")
            # pull file from device
            afc.pull(remote_file, local_file)
            return local_file
        
        
if __name__ == "__main__":
    db = macOSDB()
    db.parse_albums()
