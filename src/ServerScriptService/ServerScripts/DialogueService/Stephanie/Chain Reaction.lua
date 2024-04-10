local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);

local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");

local npcName = script.Parent.Name;
--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		dialog:AddChoice("guide_battery");
		dialog:AddChoice("guide_wires");
		remoteSetHeadIcon:FireClient(player, 1, npcName, "Guide");
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("$PlayerName, I worked out another interesting mod blueprint. They almost seems as if they are elemental.", "Surprise");
		dialog:AddChoice("chainReaction_start", function(dialog)
			dialog:AddChoice("chainReaction_useful", function(dialog)
				dialog:AddChoice("chainReaction_otherTwo", function(dialog)
					modMission:StartMission(player, 15, function(successful)
						if successful then
							modBlueprints.UnlockBlueprint(player, "electricbp");
							
							dialog:AddChoice("guide_battery");
							dialog:AddChoice("guide_wires");
							remoteSetHeadIcon:FireClient(player, 1, npcName, "Guide");
						end
					end);
				end)
			end)
		end)
		
	end
end
