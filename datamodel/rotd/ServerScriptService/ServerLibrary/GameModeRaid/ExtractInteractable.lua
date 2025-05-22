local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local gameMode = script:GetAttribute("GameMode");
local stageMode = script:GetAttribute("Stage");

return modInteractables:Instance("GameModeExit", script, nil, gameMode, stageMode, "Extract");