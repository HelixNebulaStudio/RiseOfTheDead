local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);

local MISSION_ID = 55;
--==
return function(player, dialog, data, mission)
	if not modBranchConfigurations.IsWorld("Safehome") then return end;

	local survivorNpcClass: NpcClass = dialog:GetNpcClass();
	if survivorNpcClass.Player ~= player then
		if survivorNpcClass.Player then
			dialog:SetInitiate(`I'm so glad {survivorNpcClass.Player.Name} rescued me..`, "Excited");
		else
			dialog:SetInitiate(`I'm so glad I got rescued..`, "Excited");
		end
		return;
	end

	Debugger:StudioLog("mission", mission);
	
	if mission.SaveData and mission.SaveData.NpcName ~= survivorNpcClass.Name then return end;
	
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

					task.spawn(function()
						local npcClass: NpcClass = dialog:GetNpcClass();
						local worldSafehomeClass = shared.WorldCore.SafehomeClass;
						
						local standSpotAtt = worldSafehomeClass:GetNpcSpot(npcClass.Name);
						
						npcClass.Move:SetMoveSpeed("set", "walk", 8, npcClass.Move.MoveSpeedPriority.Movement, 10);
						npcClass.Move:MoveTo(standSpotAtt.Position);
					end)
				end

				modMission:CompleteMission(player, MISSION_ID);
				modEvents:NewEvent(player, {Id="acceptedFirstSurvivor";});
			end)

			local acceptedFirstSurvivor = modEvents:GetEvent(player, "acceptedFirstSurvivor");
			if acceptedFirstSurvivor then
				dialog:AddChoice("shelter_decline", function(dialog)
					modMission:CompleteMission(player, MISSION_ID);

					if dialog.Character then
						if dialog.Character:FindFirstChild("Interactable") then
							dialog.Character.Interactable:Destroy();
						end
						local face = dialog.Character:FindFirstChild("face", true);
						if face then
							face.Texture = "rbxassetid://141728515";
						end

						local npcClass: NpcClass = dialog:GetNpcClass();
						task.delay(3, function() 
							npcClass:TeleportHide();
						end)
					end
				end)
			end

		end
	end
end