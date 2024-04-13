local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local gameMode = script:GetAttribute("GameMode");
local stageMode = script:GetAttribute("Stage");

local Door = Interactable.GameModeExit(gameMode, stageMode, "Extract");
Door.Enabled = true;

return Door;