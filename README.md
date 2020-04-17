# Photosorter
Sort your photos automatically into subfolders by YEAR/MONTH

## photosort.ps1
The main PhotoSorter script, written in PowerShell Core 7.0.

### Arguments:
  - SourceFolder - [String] The path where the images to sort are stored. (Local filesystem path)
  - RecurseSource - [Switch] Whether the source folder should be recursively scanned, or only the top-level files sorted.
  - TargetFolder - [String] The path to sort the folders into. Images will be copied to folders named [YYYY]\[MM] under that folder.
  - RecreateFolders - [Switch] If true, subfolders under SourceFolder (if RecurseSource is true) will be copied and recreated under the TargetFolder.
  - WhatIf - [Switch] If true, the source files will be evaluated and the expected output printed, but no files will actually be moved.
 
### Notes: 
  - An image's date will be calculated thus:
    - If the image contains an embedded EXIF DateTaken field, the EXIF date will be used.
    - Otherwise, if the filename contains a pattern matching [YYYY][MM][DD] or [YYYY]-[MM]-[DD], the file name date will be used.
    - Otherwise, the filesystem's LastWrite time will be used.
  - If a file with an identical name already exists in the sorted target folder, the two files will be compared by SHA256 hash of their contents.
    - If the hashes are identical, the source file will be deleted and a message logged ("identical file exists").
    - If the hashes aren't identical, the source file will be copied, with the string " (duplicate)" appended to the base file name.


## PhotoSorter.App
A simple WPF wrapper around the photosort.ps1 script
Features:
- Specify the SourceFolder and TargetFolder parameter using an file chooser dialog.
- See the script results in a dialog window.
- Nice green button.

TODO:
 - Specify the RecurseSource and RecreateFolders switches.

Screenshot:
![Screenshot of the PhotoSorter.App](https://raw.githubusercontent.com/lisardggY/Photosorter/master/assets/photosorter.app.png)
