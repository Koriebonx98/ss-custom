function OnApplicationStarted()
{
    $__logger.Info("OnApplicationStarted")
    # Define the base directory name where games are located
$baseDirectoryName = "Test\PC\Games"

# Get all drives
$drives = Get-PSDrive -PSProvider 'FileSystem'

# Loop through each drive
foreach ($drive in $drives) {
    # Define the path to "Test/PC/Games" on the current drive
    $baseDirectoryPath = Join-Path -Path $drive.Root -ChildPath $baseDirectoryName

    # Check if the "Games" directory exists on this drive
    if (Test-Path -Path $baseDirectoryPath) {
        # Get all game folders within the "Games" directory
        $gameFolders = Get-ChildItem -Path $baseDirectoryPath -Directory

        # Loop through each game folder
        foreach ($gameFolder in $gameFolders) {
            # Create a new game object
            $newGame = New-Object Playnite.SDK.Models.Game
            $newGame.Name = $gameFolder.Name
            $newGame.InstallDirectory = $gameFolder.FullName
            $newGame.IsInstalled = $true

            # Retrieve the platform GUID by name and add it to the game's platform IDs
            $platformName = "Pc (windows)"
            $platform = $PlayniteAPI.Database.Platforms | Where-Object { $_.Name -eq $platformName }
            if ($platform -ne $null) {
                $newGame.PlatformIds = New-Object System.Collections.Generic.List[System.Guid]
                $newGame.PlatformIds.Add($platform.Id)
            }

            # Initialize the GameActions collection
            $newGame.GameActions = New-Object System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.GameAction]

            # Find all .exe files in the game folder and its subfolders
            $exeFiles = Get-ChildItem -Path $gameFolder.FullName -Filter *.exe -Recurse

            # Loop through each .exe file and add it as a play action, excluding 'redist' directories
            foreach ($exeFile in $exeFiles) {
                # Check if the file path contains 'redist' directory
                if (-not $exeFile.FullName.ToLower().Contains('\redist\')) {
                    $playAction = New-Object Playnite.SDK.Models.GameAction
                    $playAction.Name = $exeFile.BaseName
                    $playAction.Path = $exeFile.FullName
                    # Set the working directory to the directory of the .exe file
                    $playAction.WorkingDir = $exeFile.DirectoryName
                    $playAction.IsPlayAction = $true

                    # Add the play action to the game's GameActions
                    $newGame.GameActions.Add($playAction)
                }
            }

            # Add the game to Playnite's database
            $PlayniteAPI.Database.Games.Add($newGame)
        }
    }
}

}

function OnApplicationStopped()
{
    $__logger.Info("OnApplicationStopped")
}

function OnLibraryUpdated()
{
    $__logger.Info("OnLibraryUpdated")
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
