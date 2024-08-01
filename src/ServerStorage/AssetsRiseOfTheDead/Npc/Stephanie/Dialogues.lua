local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Hmmmm..? What do you want?";
	};
	["init2"]={
		Reply="Need something or what?";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
		local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");

		local npcName = dialog.Name;

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
end

return Dialogues;