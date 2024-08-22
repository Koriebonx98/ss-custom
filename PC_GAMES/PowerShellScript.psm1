function OnApplicationStarted()
{
   $__logger.Info("OnApplicationStarted")
   
}

function OnApplicationStopped()
{
    $__logger.Info("OnApplicationStopped")
}

function OnLibraryUpdated()
{
    $__logger.Info("OnLibraryUpdated")
    $baseDirectoryName = "Games"
$exclusionFilePath = Join-Path -Path (Get-Location) -ChildPath "Exclusion.txt"

# Read exclusions from the file
$exclusions = Get-Content -Path $exclusionFilePath | ForEach-Object { $_.Trim('"') }

$drives = Get-PSDrive -PSProvider 'FileSystem' | Sort-Object -Property Name

foreach ($drive in $drives) {
    $baseDirectoryPath = Join-Path -Path $drive.Root -ChildPath $baseDirectoryName

    if (Test-Path -Path $baseDirectoryPath) {
        $gameFolders = Get-ChildItem -Path $baseDirectoryPath -Directory

        foreach ($gameFolder in $gameFolders) {
            try {
                # Remove text within square brackets, parentheses, and curly brackets from the game folder name for matching
                $cleanedGameFolderName = $gameFolder.Name -replace '\[.*?\]|\(.*?\)|\{.*?\}', ''

                # Replace dashes with spaces around them to colons with a space after
                $cleanedGameFolderName = $cleanedGameFolderName -replace ' - ', ': '

                # Ensure correct spacing around colons
                $cleanedGameFolderName = $cleanedGameFolderName -replace '\s*:\s*', ': '

                # Trim any leading or trailing spaces
                $cleanedGameFolderName = $cleanedGameFolderName.Trim()

                # Match the cleaned game folder name with the game name in Playnite
                $existingGame = $PlayniteAPI.Database.Games | Where-Object { $_.Name -eq $cleanedGameFolderName }

                if ($existingGame -ne $null) {
                    if (-not $existingGame.IsInstalled -and $existingGame.InstallDirectory -eq $null) {
                        $existingGame.InstallDirectory = $gameFolder.FullName
                    }

                    # Add any .exe file found as an action, excluding those in the exclusion list
                    $exeFiles = Get-ChildItem -LiteralPath $gameFolder.FullName -Filter *.exe -Recurse

                    foreach ($exeFile in $exeFiles) {
                        if ($exclusions -contains $exeFile.Name) {
                            Write-Output "Skipping excluded file: $($exeFile.Name)"
                            continue
                        }

                        $playAction = New-Object Playnite.SDK.Models.GameAction
                        $playAction.Name = $exeFile.Name
                        $playAction.Path = "{InstallDir}\$($exeFile.FullName.Substring($gameFolder.FullName.Length + 1))"
                        $playAction.WorkingDir = '{InstallDir}'
                        $playAction.IsPlayAction = $true

                        $existingGame.GameActions.Add($playAction)
                    }
                } else {
                    $newGame = New-Object Playnite.SDK.Models.Game
                    $newGame.Name = $cleanedGameFolderName
                    $newGame.IsInstalled = $true
                    $newGame.InstallDirectory = $gameFolder.FullName

                    $platformName = "PC (Windows)"
                    $platform = $PlayniteAPI.Database.Platforms | Where-Object { $_.Name -eq $platformName }
                    if ($platform -ne $null) {
                        $newGame.PlatformIds = New-Object System.Collections.Generic.List[System.Guid]
                        $newGame.PlatformIds.Add($platform.Id)
                    }

                    $newGame.GameActions = New-Object System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.GameAction]

                    $exeFiles = Get-ChildItem -LiteralPath $gameFolder.FullName -Filter *.exe -Recurse

                    foreach ($exeFile in $exeFiles) {
                        if ($exclusions -contains $exeFile.Name) {
                            Write-Output "Skipping excluded file: $($exeFile.Name)"
                            continue
                        }

                        $playAction = New-Object Playnite.SDK.Models.GameAction
                        $playAction.Name = $exeFile.Name
                        $playAction.Path = "{InstallDir}\$($exeFile.FullName.Substring($gameFolder.FullName.Length + 1))"
                        $playAction.WorkingDir = '{InstallDir}'
                        $playAction.IsPlayAction = $true

                        $newGame.GameActions.Add($playAction)
                    }

                    $PlayniteAPI.Database.Games.Add($newGame)
                }
            } catch {
                Write-Error "An error occurred processing folder $($gameFolder.FullName): $_"
            }
        }
    }
}


}

function OnGameStarting()
{
    param($evnArgs)
    $__logger.Info("OnGameStarting $($evnArgs.Game)")
}

function OnGameStarted()
{
    param($evnArgs)
    $__logger.Info("OnGameStarted $($evnArgs.Game)")
}

function OnGameStopped()
{
    param($evnArgs)
    $__logger.Info("OnGameStopped $($evnArgs.Game) $($evnArgs.ElapsedSeconds)")
}

function OnGameInstalled()
{
    param($evnArgs)
    $__logger.Info("OnGameInstalled $($evnArgs.Game)")
}

function OnGameUninstalled()
{
    param($evnArgs)
    $__logger.Info("OnGameUninstalled $($evnArgs.Game)")
}

function OnGameSelected()
{
    param($gameSelectionEventArgs)
    $__logger.Info("OnGameSelected $($gameSelectionEventArgs.OldValue) -> $($gameSelectionEventArgs.NewValue)")
}