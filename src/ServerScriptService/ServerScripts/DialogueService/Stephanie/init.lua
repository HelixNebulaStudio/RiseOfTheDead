local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);

local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");

local npcName = script.Name;

return function(player, dialog, dialogueData)
	remoteSetHeadIcon:FireClient(player, 0, npcName, "Guide");
	
	local mission3 = modMission:GetMission(player, 3);
	if mission3 == nil then
		dialog:AddChoice("pre_findBook");
	end
	
	local mission9 = modMission:GetMission(player, 9);
	if mission3 and mission3.Type == 3 and (mission9 == nil or mission9.Type ~= 3) then
		dialog:AddChoice("findBook_whatsInTheBook");
	end
end
