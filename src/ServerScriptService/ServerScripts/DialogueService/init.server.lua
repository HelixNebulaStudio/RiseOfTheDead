local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
repeat task.wait() until shared.MasterScriptInit == true;

--==
local modDialogueService = require(game.ReplicatedStorage.Library.DialogueService);
modDialogueService:InitServer(script);