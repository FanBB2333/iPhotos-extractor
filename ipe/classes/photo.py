from dataclasses import dataclass, fields
from ipe.utils import ignore_unused_fields

@ignore_unused_fields
@dataclass
class Photo:
    Z_PK: int
    Z_ENT: int
    Z_OPT: int
    ZDIRECTORY: str
    ZFILENAME: str
    ZMEDIAGROUPUUID: str
    ZUUID: str
    
    def __str__(self):
        return f"{self.Z_PK}: {self.ZFILENAME}"