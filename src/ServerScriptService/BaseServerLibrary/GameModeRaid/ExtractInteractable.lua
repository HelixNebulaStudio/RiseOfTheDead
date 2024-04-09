local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local Door = Interactable.GameModeExit("Raid", "Abandoned Bunker", "Extract");
Door.Enabled = true;

return Door;