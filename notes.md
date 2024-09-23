# notes
## Inspect sqlite database
### The `every-photo` tables
- `ZASSET` table: One photo or video corresponds to one row in this table
- `ZEXTENDEDATTRIBUTES` table
- `ZCHARACTERRECOGNITIONATTRIBUTES` table (larger rows)
- `ZCLOUDMASTER` table (smaller rows)
- `ZCLOUDMASTERMEDIAMETADATA` table (larger rows)
- `ZCOMPUTEDASSETATTRIBUTES` table (larger rows)
- `ZCOMPUTESYNCATTRIBUTES` table (larger rows)
- `ZMEDIAANALYSISASSETATTRIBUTES` table (larger rows)
- `ZPHOTOANALYSISASSETATTRIBUTES` table (larger rows)
- `ZSCENEPRINT` table (larger rows)
- `ZVISUALSEARCHATTRIBUTES` table (larger rows)


`ZGENERICALBUM`: get the title of albums which `ZKIND` == 2:
`ZGENERICALBUM.Z_PK` == `Z_29ALBUMLISTS.Z_29ALBUMS`'s `Z_29ALBUMLISTS.Z_FOK_29ALBUMS` column

- WHAT IS THE DIFFERENCE BETWEEN `Z_29KEYASSETS` AND `Z_30ASSETS`?
  - Seems that `Z_30ASSETS` table contains whole assets in the album, while `Z_29KEYASSETS` table contains only key assets in the album.

- `CPLAssets`: Cloud Photo Library
- There is a useful tutorial for indexing the file structure of ios photos: https://theforensicscooter.com/2022/12/05/do-you-have-a-full-sized-assetor-just-a-thumbnail-did-optimized-iphone-storage-process-occur/