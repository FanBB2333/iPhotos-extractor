# [WIP] IPE(iPhotos-Extractor)
## Intro

**!!! This project is still under development. !!!**

This is a simple tool for extracting photos from `Photos` app on macOS/iOS devices by parsing the database file stored on devices.

We aim to deal with the possible problems among the existing tools.


## Possible drawbacks of existing tools

- Cannot backup live photos.
- Cannot tell the difference between original photos and edited photos if edited in `Photos.app`.
- Cannot keep the original file structure/album structure.
- Cannot extract the metadata of the photos.


## Future Plan

- [ ] Extract photos info from the database file.
- [ ] Extract live photos.
- [ ] Extract the original photos and edited photos separately.
- [ ] Extract the metadata of the photos.
- [ ] Extract album info and avoid duplicates.
- [ ] Insert photos/create albums by manipulating the database file.
- [ ] Full-database backup and restore.
- [x] Wireless connection support.(thanks to `pymobiledevice3`!)



## Acknowledgement

- [pymobiledevice3](https://github.com/doronz88/pymobiledevice3/)
- [PhotosExporter](https://github.com/abentele/PhotosExporter)