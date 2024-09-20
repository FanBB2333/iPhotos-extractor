from dataclasses import dataclass, fields

def ignore_unused_fields(cls):
    """
    init method will only accept keyword arguments that match the field names
    """
    field_names = {f.name for f in fields(cls)}
    
    original_init = cls.__init__
    def __init__(self, *args, **kwargs):
        filtered_kwargs = {k: v for k, v in kwargs.items() if k in field_names}
        original_init(self, *args, **filtered_kwargs)
    
    cls.__init__ = __init__
    return cls


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
    
    def __str__(self):
        return f"{self.Z_PK}: {self.ZTITLE}"