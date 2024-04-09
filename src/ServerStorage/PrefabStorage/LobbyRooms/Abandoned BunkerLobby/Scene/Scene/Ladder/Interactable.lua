local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local Door = Interactable.GameModeExit("Coop", "Abandoned Bunker", "Return to W.D.");
Door.Enabled = true;

return Door;