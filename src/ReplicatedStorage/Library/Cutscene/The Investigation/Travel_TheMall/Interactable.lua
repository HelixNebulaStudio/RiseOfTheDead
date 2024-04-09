local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local travel = Interactable.Travel("TheMall", "Fast Travel To Radio Station"); 
travel.SetSpawn = "radioStationExit";

return travel;