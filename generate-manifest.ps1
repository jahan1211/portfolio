# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (!$scriptDir) { $scriptDir = Get-Location }

$uiuxDir = Join-Path $scriptDir "uiux"
$mockupsDir = Join-Path $scriptDir "Mockups"
$postersDir = Join-Path $scriptDir "Posters & Creatives"
$videosDir = Join-Path $scriptDir "Vedio Animation"

$manifestJsonPath = Join-Path $scriptDir "manifest.json"
$manifestJsPath = Join-Path $scriptDir "manifest.js"

# Helper to format name
function Format-Name ($fileName) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    # Remove leading numbers/ordering
    $name = $name -replace '^\d+[\s_-]*', ''
    # Replace underscores/hyphens with spaces
    $name = $name -replace '[\s_-]+', ' '
    # Capitalize words
    $name = (Get-Culture).TextInfo.ToTitleCase($name.ToLower())
    return $name
}

# Process categories
$uiux = @()
$mockups = @()
$posters = @()
$videos = @()

# 1. UI/UX Folders
if (Test-Path $uiuxDir) {
    $folders = Get-ChildItem -Path $uiuxDir -Directory
    foreach ($folder in $folders) {
        $folderPath = $folder.FullName
        $imageFiles = Get-ChildItem -Path $folderPath -File | Where-Object { $_.Extension -match '\.(png|jpg|jpeg|webp|gif|tiff)$' } | Sort-Object Name
        
        $metadata = @{
            title = "$($folder.Name) UX Case Study"
            tag = "UI/UX Design"
            desc = "A premium user interface and experience design concept showcasing user-centered workflows."
            figmaUrl = ""
            behanceUrl = ""
        }

        # Check for project.json
        $metaPath = Join-Path $folderPath "project.json"
        if (Test-Path $metaPath) {
            try {
                $metaDataRaw = Get-Content -Raw -Encoding UTF8 -Path $metaPath | ConvertFrom-Json
                foreach ($prop in $metaDataRaw.psobject.properties) {
                    $metadata[$prop.Name] = $prop.Value
                }
            } catch {
                Write-Host "Error parsing project.json in $($folder.Name)"
            }
        }

        $projId = $folder.Name.ToLower() -replace '[^a-z0-9]+', '-'

        # Auto-detect mockup
        $mockupPath = ""
        # 1. Search parent UIUX folder first
        $cleanId = $projId -replace '[\s_-]+', '[\s_-]?'
        $parentMockups = Get-ChildItem -Path $uiuxDir -File | Where-Object { $_.Name.ToLower() -match "^$cleanId[\s_-]?mockup\.(png|jpg|jpeg|webp)$" } | Select-Object -First 1
        if ($parentMockups) {
            $mockupPath = "uiux/$($parentMockups.Name)"
        } else {
            # 2. Search inside local folder
            $localMockup = $imageFiles | Where-Object { $_.Name.ToLower() -match '(mockup|cover|hero)' } | Select-Object -First 1
            if ($localMockup) {
                $mockupPath = "uiux/$($folder.Name)/$($localMockup.Name)"
            } elseif ($imageFiles.Count -gt 0) {
                # 3. Fallback to first image
                $mockupPath = "uiux/$($folder.Name)/$($imageFiles[0].Name)"
            }
        }

        $modules = @()
        foreach ($file in $imageFiles) {
            $modules += @{
                name = Format-Name $file.Name
                desc = "Interface representation of $(Format-Name $file.Name)."
                type = "image"
                url = "uiux/$($folder.Name)/$($file.Name)"
            }
        }

        $directory = @()
        foreach ($file in $imageFiles) {
            $directory += @{
                name = Format-Name $file.Name
                type = "image"
                url = "uiux/$($folder.Name)/$($file.Name)"
            }
        }

        $uiux += @{
            id = $projId
            folderName = $folder.Name
            title = $metadata.title
            tag = $metadata.tag
            desc = $metadata.desc
            figmaUrl = $metadata.figmaUrl
            behanceUrl = $metadata.behanceUrl
            mockup = $mockupPath
            techStack = $metadata.techStack
            modules = $modules
            directory = $directory
        }
    }
}

# 2. Mockups
if (Test-Path $mockupsDir) {
    Get-ChildItem -Path $mockupsDir -File | Where-Object { $_.Extension -match '\.(png|jpg|jpeg|webp)$' } | ForEach-Object {
        $mockups += @{
            name = Format-Name $_.Name
            url = "Mockups/$($_.Name)"
        }
    }
}

# 3. Posters
if (Test-Path $postersDir) {
    Get-ChildItem -Path $postersDir -File | Where-Object { $_.Extension -match '\.(png|jpg|jpeg|webp)$' } | ForEach-Object {
        if (!($_.Name.ToLower().StartsWith("nusrat") -and !$_.Name.ToLower().Contains("design"))) {
            $posters += @{
                name = Format-Name $_.Name
                url = "Posters & Creatives/$($_.Name)"
            }
        }
    }
}

# 4. Videos
if (Test-Path $videosDir) {
    $videoFiles = Get-ChildItem -Path $videosDir -File | Where-Object { $_.Extension -match '\.(mp4|webm|ogg|mov)$' }
    $imgFiles = Get-ChildItem -Path $videosDir -File | Where-Object { $_.Extension -match '\.(png|jpg|jpeg|webp)$' }
    
    # Custom mapping for known video thumbnails
    $customThumbnailMap = @{
        "VN20260206_040716.mp4" = "Gemini_Generated_Image_azemzazemzazemza.png"
        "VN20260206_044119.mp4" = "Gemini_Generated_Image_jooh8ajooh8ajooh.png"
        "lv_0_20260620210221.mp4" = "Gemini_Generated_Image_sexhcesexhcesexh.png"
    }

    foreach ($video in $videoFiles) {
        $videoBase = [System.IO.Path]::GetFileNameWithoutExtension($video.Name)
        # 1. Search for matching base name (exact, starts with, or contains)
        $matchingImgName = $imgFiles | Where-Object { 
            $imgBase = [System.IO.Path]::GetFileNameWithoutExtension($_.Name).ToLower()
            $vBase = $videoBase.ToLower()
            $imgBase -eq $vBase -or $imgBase.StartsWith($vBase) -or $imgBase.Contains($vBase)
        } | Select-Object -First 1
        
        $thumb = ""
        if ($matchingImgName) {
            $thumb = "Vedio Animation/$($matchingImgName.Name)"
        } elseif ($customThumbnailMap.ContainsKey($video.Name)) {
            $thumb = "Vedio Animation/$($customThumbnailMap[$video.Name])"
        }
        
        $videos += @{
            name = Format-Name $video.Name
            url = "Vedio Animation/$($video.Name)"
            thumbnail = $thumb
        }
    }
}

# Construct Manifest
$manifest = @{
    uiux = $uiux
    mockups = $mockups
    posters = $posters
    videos = $videos
}

# Convert to JSON
$manifestJson = $manifest | ConvertTo-Json -Depth 10

# Write manifest.json (UTF-8 without BOM)
[System.IO.File]::WriteAllText($manifestJsonPath, $manifestJson, [System.Text.Encoding]::UTF8)

# Write manifest.js
$manifestJs = "window.portfolioManifest = $manifestJson;"
[System.IO.File]::WriteAllText($manifestJsPath, $manifestJs, [System.Text.Encoding]::UTF8)

Write-Host "Success! manifest.json and manifest.js created successfully with:"
Write-Host "- $($uiux.Count) UI/UX Projects"
Write-Host "- $($mockups.Count) Mockups"
Write-Host "- $($posters.Count) Posters"
Write-Host "- $($videos.Count) Videos"
