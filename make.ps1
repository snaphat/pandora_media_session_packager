Remove-Item -Force pandora_media_session -Recurse -ErrorAction SilentlyContinue
Remove-Item -Force .\pandora_media_session.zip -ErrorAction SilentlyContinue
git clone git@github.com:snaphat/pandora_media_session.git
$file = "pandora_media_session.user.js"
$directory = "$(Get-Location)/pandora_media_session"
$script = "$directory/$file"
$script = Get-Content $script
$author      = ($script | Select-String -pattern "@author +([A-z0-9 ].*)").Matches.Groups[1]
$description = ($script | Select-String -pattern "@description +([A-z0-9 ].*)").Matches.Groups[1]
$name        = ($script | Select-String -pattern "@name +([A-z0-9 ].*)").Matches.Groups[1]
$version     = ($script | Select-String -pattern "@version +([A-z0-9 ].*)").Matches.Groups[1]


$manifest="{
    `"author`": `"$author`",
    `"manifest_version`": 2,
    `"name`": `"$name`",
    `"version`": `"$version`",
    `"description`": `"$description`",
    `"minimum_chrome_version`": `"88.0.0.0`",
    `"content_scripts`": [
        {
            `"matches`": [`"*://*.pandora.com/*`"],
            `"js`": [`"$file`"],
            `"run_at`": `"document_start`"
        }
    ],
        `"browser_action`": {
        `"default_title`": `"$name`"
    },
        `"permissions`": [
        `"*://*.pandora.com/*`"
    ]
}"
$manifest | Out-File -Encoding ascii -FilePath "$directory/manifest.json"
zip pandora_media_session.zip "$directory/*"
