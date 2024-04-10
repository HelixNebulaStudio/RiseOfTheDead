local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

--==
return function(player, dialog, data, mission)
	if not modBranchConfigs.IsWorld("Safehome") then return end;
	local ownerPlayer = modServerManager.PrivateWorldCreator;
	local isOwner = ownerPlayer == player;
	
	if not isOwner then
		dialog:SetInitiate("I'm so glad "..ownerPlayer.Name.." rescued me..", "Excited");
		return;
	end
	
	Debugger:Warn("mission", mission);
	
	if mission.SaveData and mission.SaveData.NpcName ~= dialog.Name then return end;
	
	if mission.Type == 1 then -- Active
		if mission.ProgressionPoint == 1 then
			dialog:SetInitiateTag("shelter_init");
			dialog:AddChoice("shelter_accept", function(dialog)

				local profile = shared.modProfile:Get(player);
				local safehomeData = profile.Safehome;

				--local npcData = safehomeData.Npc[];
				local npcData = safehomeData:GetNpc(dialog.Name);
				if npcData then
					npcData.Active = os.time();
				end

				modMission:CompleteMission(player, 55);
				modEvents:NewEvent(player, {Id="acceptedFirstSurvivor";});
			end)

			if modEvents:GetEvent(player, "acceptedFirstSurvivor") then
				dialog:AddChoice("shelter_decline", function(dialog)
					modMission:CompleteMission(player, 55);

					if dialog.Prefab then
						if dialog.Prefab:FindFirstChild("Interactable") then
							dialog.Prefab.Interactable:Destroy();
						end
						local face = dialog.Prefab:FindFirstChild("face", true);
						if face then
							face.Texture = "rbxassetid://141728515";
						end

						local npcModule = modNpc.GetNpcModule(dialog.Prefab);
						delay(3, function()
							npcModule:TeleportHide();
						end)
					end
				end)
			end
		end
	end
end
