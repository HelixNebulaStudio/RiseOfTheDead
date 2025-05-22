local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	["Jack Reap"]={};
};

local missionId = 43;
--==

-- MARK: Jack Reap Dialogues
Dialogues["Jack Reap"].DialogueStrings = {
	["missingbody_init"]={
		CheckMission=missionId;
		Say="Hey.. You look really pale. Are you alright?";
		Reply="You.. Help me.. I am finding something.. Head in, you will find it..";
	};
	
	["missingbody_voodoo"]={
		Say="What happened to the place!? Something's wrong with the place and I didn't find anything.."; 
		Reply="Oh no, it was there.. Here take this..";
	};

	["missingbody_takevoodoo"]={
		Say="*Take Voodoo Doll*"; 
		Reply="This doll will guide you to where you need to go..";
	};
	
	["missingbody_invfull"]={
		Say="*Take Voodoo Doll*"; 
		Reply="Your inventory is full.";
	};
};

if RunService:IsServer() then
	-- MARK: Jack Reap Handler
	Dialogues["Jack Reap"].DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			
			dialog:SetInitiate("Well..?");
			if stage == 2 then
				dialog:AddChoice("missingbody_voodoo", function(dialog)
					local profile = shared.modProfile:Get(player);
					local activeInventory = profile.ActiveInventory;

					local hasSpace = activeInventory:SpaceCheck{{ItemId="voodoodoll"}};
					if not hasSpace then
						dialog:AddChoice("missingbody_invfull");
						
					else
						dialog:AddChoice("missingbody_takevoodoo", function(dialog)
							if mission.ProgressionPoint == 2 then mission.ProgressionPoint = 3; end;
							activeInventory:Add("voodoodoll");
							shared.Notify(player, "You recieved a Voodoo Doll.", "Reward");
						end)
						
					end
				end);
				
			elseif stage == 3 then
				
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("Memories.. Last breath.. Where?..", "Happy");
			dialog:AddChoice("missingbody_init", function(dialog)
				modMission:StartMission(player, missionId);
			end);
			
		end
	end
end


return Dialogues;