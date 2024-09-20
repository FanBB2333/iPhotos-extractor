from dataclasses import dataclass

@dataclass
class Album:
    Z_PK: int
    Z_ENT: int
    Z_OPT: int
    ZPARENTFOLDER: int
    ZTITLE: str
    ZIMPORTEDBYBUNDLEIDENTIFIER: str
    ZUUID: str
    
    def __str__(self):
        return f"{self.Z_PK}: {self.ZTITLE}"