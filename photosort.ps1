Param 
(
  [String]$SourceFolder = "D:\Stuff\picsource",
  [Switch]$RecurseSource = $False,
  [String]$TargetFolder = "d:\stuff\dropbox\pictures\ByDate",
  [Switch]$RecreateFolders = $False,
  [Switch]$WhatIf = $False
)

function Get-DateByExif($filePath) {    
  Try {
    $image = New-Object System.Drawing.Bitmap -ArgumentList $filePath
    $takenData = $image.GetPropertyItem(36867).Value 
    $takenValue = [System.Text.Encoding]::Default.GetString($takenData, 0, $takenData.Length - 1)
    $taken = [DateTime]::ParseExact($takenValue, 'yyyy:MM:dd HH:mm:ss', $null)
    write-host "Matched by EXIF: $taken"
    return $taken
  }
  catch {
    return $null
  }
  finally {
    if($image) {
      $image.Dispose()
    }
  }
}

function Get-DateByFilename($fileName) {
  if ($fileName -match '^(\d\d\d\d)-(\d\d)-(\d\d).*$') {
    $filenameDate = Get-Date -Year $matches[1] -Month $matches[2] -Day $matches[3]
    write-host "Matched by filename: $filenameDate "
    return $filenameDate
  } elseif ($fileName -imatch '^IMG-(\d\d\d\d)(\d\d)(\d\d).*$') {
    $filenameDate = Get-Date -Year $matches[1] -Month $matches[2] -Day $matches[3]
    write-host "Matched by filename: $filenameDate "
    return $filenameDate
  } else {
    return $null
  }
}

function Get-DateByFileAttribute([System.IO.FileInfo]$file) {
  write-host "Matched by Last Write atribute:" + $file.LastWriteTime
  return $file.LastWriteTime
}

[Reflection.Assembly]::LoadFile('C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Drawing.dll') | Out-Null

# Get the files which should be moved.
if ($RecurseSource) {
  $files = Get-ChildItem $SourceFolder -Recurse | Where-Object { !$_.PsIsContainer -and !$_.IsReadOnly }
}
else {
  $files = Get-ChildItem $SourceFolder | Where-Object { !$_.PsIsContainer -and !$_.IsReadOnly }
}

# List Files which will be moved
"" + $files.Length + " files to move"
 $filesMoved = 0
foreach ($file in $files) {
  $filesMoved += 1
  Write-Host  –NoNewline "`rMoving file $filesMoved / $($files.Length) "
  $dateTaken = Get-DateByExif($file.FullName)
  if (-not $dateTaken) {
    $dateTaken = Get-DateByFilename($file.Name)
  }
  if (-not $dateTaken) {
    $dateTaken = Get-DateByFileAttribute($file)
  }

#  "$file" + " Date: " + $dateTaken + " (" + (($fromExif) ? "from photo data" : "from file date") + ")"

  # Get year and Month of the file
  $year = $dateTaken.Year.ToString()
  $month = $dateTaken.Month.ToString()
  $relativeFolder = ""
  if ($RecreateFolders) {
    $relativeFolder = $file.Directory.FullName.Replace($SourceFolder, "");
  }
  $outputFolder = [System.IO.Path]::Combine($TargetFolder, $relativeFolder, $year , $month)

 # "Output folder: " + $outputFolder
  
  # Create directory if it doesn't exsist
  if (!(Test-Path $outputFolder)) {
    Write-Output  "Creating directory $outputFolder"		
    if (!($WhatIf)) {
      New-Item $outputFolder -type directory | Out-Null
		  }
  }
  # Move File to new location
  $targetFile = [System.IO.Path]::Combine($outputFolder, $file.Name)
  if (Test-Path $targetFile)
  {
    if ($(Get-FileHash -path $file.FullName).Hash = $(Get-FileHash -Path $targetFile).Hash)
    {
      "Identical file found in folder. Not copying"
      Remove-Item $file
      Continue
    }
    $newFilename = $file.BaseName + " (duplicate)" + $file.Extension
    $targetFile = [System.IO.Path]::Combine($outputFolder,  $newFilename)
    "File exists in destination. Renaming."
  }
 # Write-Output "Moving $file to $targetFile"
  
  if (!($WhatIf)) {
  	Move-Item -Path $file -Destination $targetFile
  }  
}
Write-Host ""


