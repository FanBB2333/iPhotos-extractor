from dataclasses import dataclass, field, fields
from ipe.utils import ignore_unused_fields

@ignore_unused_fields
@dataclass
class Album:
    Z_PK: int
    Z_ENT: int
    Z_OPT: int
    ZPARENTFOLDER: int
    ZTITLE: str
    ZIMPORTEDBYBUNDLEIDENTIFIER: str
    ZUUID: str
    PhotoIds: list[int] = field(default_factory=list)
    
    def __str__(self):
        return f"{self.Z_PK}: {self.ZTITLE}"