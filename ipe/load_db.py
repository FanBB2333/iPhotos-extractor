import dataclasses
from abc import ABC, abstractmethod
import sqlite3
from tempfile import TemporaryDirectory

from pymobiledevice3 import usbmux
from pymobiledevice3.lockdown import create_using_usbmux, LockdownClient
from pymobiledevice3.services.diagnostics import DiagnosticsService
from pymobiledevice3.services.afc import AfcService, AfcShell

from pathlib import Path
import traceback


class PhotosDB:
    def __init__(self, path: str) -> None:
        self.path = path
        
    def __del__(self):
        self.conn.close()
    
    def connect_db(self):
        self.conn = sqlite3.connect(self.path)
        self.cursor = self.conn.cursor()
    


class macOSDB(PhotosDB):
    '''
    used for macOS to get the database file from local file system
    '''
    def __init__(self, path: str) -> None:
        super().__init__(path)
    
class iosDB(PhotosDB):
    '''
    used for iDevices to get the database file from the device
    '''
    def __init__(self, path: str) -> None:
        super().__init__(path)

    def get_db_from_device(self, device_id: int = 0):
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
        remote_file = "/PhotoData/Photos.sqlite"
        with TemporaryDirectory() as tmp_dir:
            local_file = Path(tmp_dir) / "Photos.sqlite"
            print(f"Pulling file from {device.serial} to {local_file}")
            # pull file from device
            afc.pull(remote_file, local_file)
            return local_file
        
        
if __name__ == "__main__":
    pass