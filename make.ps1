<#
.SYNOPSIS
    Creates a manifest string for a web extension.

.DESCRIPTION
    Generates a manifest file content for a web extension.

.PARAMETER ScriptDetails
    Hashtable containing script details: Author, Description, Name, Version.

.OUTPUTS
    String representing the content of the manifest file.

.EXAMPLE
    $Manifest = Create-Manifest -ScriptDetails $Details
#>
function Create-Manifest-V3 ($ScriptDetails) {
    $Manifest = @"
{
    "author": "$($ScriptDetails.Author)",
    "manifest_version": 3,
    "name": "$($ScriptDetails.Name)",
    "version": "$($ScriptDetails.Version)",
    "description": "$($ScriptDetails.Description)",
    "minimum_chrome_version": "88.0.0.0",
    "content_scripts": [
        {
            "matches": ["*://*.pandora.com/*"],
            "js": ["pandora_media_session.user.js"],
            "run_at": "document_start"
        }
    ],
    "icons": {
        "64": "assets/pandora_64x64.png",
        "128": "assets/pandora_128x128.png"
    },
    "action": {
        "default_title": "$($ScriptDetails.Name)",
        "default_icon": "assets/pandora_64x64.png"
    },
    "host_permissions": [
        "*://*.pandora.com/*"
    ]
}

"@
    return $Manifest
}

<#
.SYNOPSIS
    Creates a manifest v2 string for a web extension.

.DESCRIPTION
    Generates a manifest file content for a web extension.

.PARAMETER ScriptDetails
    Hashtable containing script details: Author, Description, Name, Version.

.OUTPUTS
    String representing the content of the manifest file.

.EXAMPLE
    $Manifest = Create-Manifest-V2 -ScriptDetails $Details
#>
function Create-Manifest-V2 ($ScriptDetails, $AdditionalProperties) {
    $Manifest = @"
{
    "author": "$($ScriptDetails.Author)",
    "manifest_version": 2,
    "name": "$($ScriptDetails.Name)",
    "version": "$($ScriptDetails.Version)",
    "description": "$($ScriptDetails.Description)",
    "minimum_chrome_version": "87.0.0.0",
    "content_scripts": [
        {
            "matches": ["*://*.pandora.com/*"],
            "js": ["pandora_media_session.user.js"],
            "run_at": "document_start"
        }
    ],
    "icons": {
        "64": "assets/pandora_64x64.png",
        "128": "assets/pandora_128x128.png"
    },
    "browser_action": {
        "default_title": "$($ScriptDetails.Name)",
        "default_icon": "assets/pandora_64x64.png"
    },
    "permissions": [
        "*://*.pandora.com/*"
    ]
}

"@
    return $Manifest
}

<#
.SYNOPSIS
    Extracts script details from a user script file.

.DESCRIPTION
    Reads a specified script file and extracts metadata such as author, description, name, and version.

.PARAMETER ScriptPath
    Path to the user script file.

.OUTPUTS
    Hashtable containing script details: Author, Description, Name, Version.

.EXAMPLE
    $Details = Get-ScriptDetails -ScriptPath "path/to/script.js"
#>
function Get-ScriptDetails ($ScriptPath) {
    $ScriptContent = Get-Content $ScriptPath
    $ScriptDetails = @{}
    $ScriptDetails.Author = ($ScriptContent | Select-String -Pattern "@author +([A-z0-9 ].*)").Matches.Groups[1].Value
    $ScriptDetails.Description = ($ScriptContent | Select-String -Pattern "@description +([A-z0-9 ].*)").Matches.Groups[1].Value
    $ScriptDetails.Name = ($ScriptContent | Select-String -Pattern "@name +([A-z0-9 ].*)").Matches.Groups[1].Value
    $ScriptDetails.Version = ($ScriptContent | Select-String -Pattern "@version +([A-z0-9 ].*)").Matches.Groups[1].Value
    return $ScriptDetails
}

<#
.SYNOPSIS
    Creates a package directory, copies necessary files, and creates a ZIP package.

.DESCRIPTION
    Sets up a package directory for a web extension, copies specified assets and other necessary files, writes the manifest file, and compresses the package into a ZIP file.

.PARAMETER PackageDirectory
    The directory where the package will be created.

.PARAMETER ManifestContent
    The content of the manifest file to be included in the package.

.EXAMPLE
    Create-Package -PackageDirectory "./package" -ManifestContent $Manifest
#>
function Create-Package ($PackageDirectory, $ManifestContent) {
    $AssetsDirectory = "$PackageDirectory/assets"
    mkdir $AssetsDirectory -Force

    Copy-Item "./assets/pandora_64x64.png" -Destination $AssetsDirectory
    Copy-Item "./assets/pandora_128x128.png" -Destination $AssetsDirectory

    Get-ChildItem "$ScriptDirectory" -Exclude README.md, .gitignore | Copy-Item -Destination $PackageDirectory -Recurse -Force

    $ManifestContent | Out-File -NoNewline -Encoding ascii -FilePath "$PackageDirectory/manifest.json"

    $ZipFileName = (Split-Path -Path $PackageDirectory -Leaf) + ".zip"

     # The Compress-Archive cmdlet cannot be used because the Firefox validator doesn't work with its archives.
    7z a -mfb=258 -mpass=15 -r $ZipFileName $PackageDirectory/*
}

# Clean up and prepare for new package creation
Remove-Item -Force pandora_media_session* -Recurse -ErrorAction SilentlyContinue
git clone git@github.com:snaphat/pandora_media_session.git
$ScriptDirectory = "$(Get-Location)/pandora_media_session"
$ScriptPath = "$ScriptDirectory/pandora_media_session.user.js"
$ScriptDetails = Get-ScriptDetails -ScriptPath $ScriptPath

# Create manifest contents
$ManifestV2 = Create-Manifest-V2 $ScriptDetails
$ManifestV3 = Create-Manifest-V3 $ScriptDetails

# Setup package directories
$PackageDirectoryV2 = $ScriptDirectory + "_package_v2"
$PackageDirectoryV3 = $ScriptDirectory + "_package_v3"

# Create and package the extension
Create-Package $PackageDirectoryV2 $ManifestV2
Create-Package $PackageDirectoryV3 $ManifestV3
