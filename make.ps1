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
    Creates a manifest string for a web extension.

.DESCRIPTION
    Generates a manifest file content for a web extension, adding additional properties if provided (useful for browser-specific settings).

.PARAMETER ScriptDetails
    Hashtable containing script details: Author, Description, Name, Version.

.PARAMETER AdditionalProperties
    String containing additional properties to be included in the manifest, such as browser-specific settings.

.OUTPUTS
    String representing the content of the manifest file.

.EXAMPLE
    $Manifest = Create-Manifest -ScriptDetails $Details -AdditionalProperties $FirefoxProperties
#>
function Create-Manifest ($ScriptDetails, $AdditionalProperties) {
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
    ]$(if ($AdditionalProperties) { ",$AdditionalProperties" })
}
"@
    return $Manifest
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

    Get-ChildItem "$ScriptDirectory" -Exclude README.md | Copy-Item -Destination $PackageDirectory -Recurse -Force

    $ManifestContent | Out-File -NoNewline -Encoding ascii -FilePath "$PackageDirectory/manifest.json"

    $ZipFileName = (Split-Path -Path $PackageDirectory -Leaf) + ".zip"
    Compress-Archive -Path "$PackageDirectory/*" -DestinationPath "..\$ZipFileName" -Force
}

# Firefox specific additional properties for the manifest
$FirefoxAdditionalProperties = '
    "browser_specific_settings": {
        "gecko": {
            "id": "{d6d93eb4-66e7-43df-bf7a-3500f9a35e26}",
            "strict_min_version": "109.0"
        }
    }
}'

# Clean up and prepare for new package creation
Remove-Item -Force pandora_media_session* -Recurse -ErrorAction SilentlyContinue
git clone git@github.com:snaphat/pandora_media_session.git
$ScriptDirectory = "$(Get-Location)/pandora_media_session"
$ScriptPath = "$ScriptDirectory/pandora_media_session.user.js"
$ScriptDetails = Get-ScriptDetails -ScriptPath $ScriptPath

# Create and package the Chrome extension
$ChromePackageDirectory = $ScriptDirectory + "_chrome"
$ChromeManifest = Create-Manifest $ScriptDetails
Create-Package $ChromePackageDirectory $ChromeManifest

# Create and package the Firefox extension
$FirefoxPackageDirectory = $ScriptDirectory + "_firefox"
$FirefoxManifest = Create-Manifest $ScriptDetails $FirefoxAdditionalProperties
Create-Package $FirefoxPackageDirectory $FirefoxManifest
