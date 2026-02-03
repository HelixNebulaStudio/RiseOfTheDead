local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="What do you want, hippy.";
	};
	["init2"]={
		Reply="What's the big idea man?";
	};
	["init3"]={
		Reply="Get out of here, trying to do some work here.";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["shop_ratShop"]={
		Say="Do you sell anything?";
		Reply="No, go talk to the others..";
	};
	
	["general_mean"]={
		Say="Why are you so mean?";
		Reply="You imbecile, mind your own gawd darn business and stop whining so much about things that are out of your control.";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local npcClass: NpcClass = dialog:GetNpcClass();
		local statusComp: StatusComp = npcClass.StatusComp;

		local sleepingStatus = statusComp:GetOrDefault("Sleeping");
		if sleepingStatus then
			dialog:SetInitiate("Are you seriously waking me up for nothing?!", "Angry");
		end
		
		dialog:AddChoice("shop_ratShop", function()
			local npcModel = dialog.Prefab;
			if npcModel:FindFirstChild("shopInteractable") then
				dialog:InteractRequest(npcModel.shopInteractable, npcModel.PrimaryPart, "interact");
			end
		end)
		dialog:AddChoice("general_mean");
	end 
end

return Dialogues;