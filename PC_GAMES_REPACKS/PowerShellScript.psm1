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
    # Define the base directory name where games are located
$baseDirectoryName = "Repacks"

# Get the path to the exclusion file, assuming it's in the same directory as the script
$exclusionFilePath = Join-Path -Path $PSScriptRoot -ChildPath "Exclusion.txt"

# Initialize the exclusion arrays
$folderExclusions = @()
$exeExclusions = @()

# Check if the exclusion file exists
if (Test-Path -Path $exclusionFilePath) {
    # Read the contents of the exclusion file
    $exclusions = Get-Content -Path $exclusionFilePath -Raw

    # Separate the folder and exe exclusions
    $folderExclusions = ($exclusions -split 'Folders:\r?\n')[1] -split '\r?\n' | Where-Object { $_ -and $_ -notmatch '^Exe:$' } | ForEach-Object { $_ -replace '^"|"$', '' }
    $exeExclusions = ($exclusions -split 'Exe:\r?\n')[1] -split '\r?\n' | Where-Object { $_ } | ForEach-Object { $_ -replace '^"|"$', '' }
}

# Get all available drives and sort them alphabetically
$drives = Get-PSDrive -PSProvider 'FileSystem' | Sort-Object -Property Name

# Create a dictionary to track existing games by install directory
$existingGamesByInstallDir = @{}

foreach ($drive in $drives) {
    $baseDirectoryPath = Join-Path -Path $drive.Root -ChildPath $baseDirectoryName

    if (Test-Path -Path $baseDirectoryPath) {
        $gameFolders = Get-ChildItem -Path $baseDirectoryPath -Directory

        foreach ($gameFolder in $gameFolders) {
            # Remove text within square brackets and parentheses from the game folder name
            $gameName = $gameFolder.Name -replace '\[.*?\]', '' -replace '\(.*?\)', '' -replace ' - ', ': '

            # Check if the game already exists in Playnite by install directory
            $existingGame = $PlayniteAPI.Database.Games | Where-Object { $_.Name -eq ($gameName -replace ': ', ' - ') -or $_.InstallDirectory -eq $gameFolder.FullName }

            if ($existingGame -ne $null) {
                # Update existing game entry with the new installation directory if not installed
                if (-not $existingGame.IsInstalled) {
                    $existingGame.InstallDirectory = $gameFolder.FullName
                    # You can add any other necessary updates here
                }
            } else {
                # Create a new game object
                $newGame = New-Object Playnite.SDK.Models.Game
                $newGame.Name = $gameName
                $newGame.InstallDirectory = $gameFolder.FullName
                $newGame.IsInstalled = $false

                # Retrieve the platform GUID by name (e.g., "PC (Windows)") and add it to the game's platform IDs
                $platformName = "PC (Windows) Repacks"
                $platform = $PlayniteAPI.Database.Platforms | Where-Object { $_.Name -eq $platformName }
                if ($platform -ne $null) {
                    $newGame.PlatformIds = New-Object System.Collections.Generic.List[System.Guid]
                    $newGame.PlatformIds.Add($platform.Id)
                }

                # Initialize the GameActions collection
                $newGame.GameActions = New-Object System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.GameAction]

                # Find all .exe files in the game folder and its subfolders
                $exeFiles = Get-ChildItem -Path $gameFolder.FullName -Filter *.exe -Recurse

                foreach ($exeFile in $exeFiles) {
                    # Check if the file path contains 'redist' directory
                    if (-not $exeFile.FullName.ToLower().Contains('\redist\')) {
                        # Check if the exe is excluded
                        if ($exeExclusions -notcontains $exeFile.Name.ToLower()) {
                            $playAction = New-Object Playnite.SDK.Models.GameAction
                            $playAction.Name = "Install"
                            $playAction.Path = "{InstallDir}\$($exeFile.FullName.Substring($gameFolder.FullName.Length + 1))"
                            $playAction.WorkingDir = '{InstallDir}'
                            $playAction.IsPlayAction = $true

                            # Add the play action to the game's GameActions
                            $newGame.GameActions.Add($playAction)
                        }
                    }
                }

                # Add the game to Playnite's database
                $PlayniteAPI.Database.Games.Add($newGame)
            }

            # Track existing games by install directory
            $existingGamesByInstallDir[$gameFolder.FullName] = $true
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
