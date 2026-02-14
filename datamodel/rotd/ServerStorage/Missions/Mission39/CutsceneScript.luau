local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

--== Variables;
local MISSION_ID = 39;

if RunService:IsServer() then
	wallTriggers = script.Parent:WaitForChild("WallTriggers");

	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	if modBranchConfigurations.IsWorld("TheMall") then
		shared.modEventService:OnInvoked("Interactables_BindButtonInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			if interactable.Id ~= "SpikingUp:Add" then return end;

			local subId = interactable.Values.SubId;
			if subId == nil then Debugger:Warn("SpikingUp:Add>>  Missing sub id."); return end;

			local profile = shared.modProfile:Get(player);
			local inventory = profile.ActiveInventory;

			local mission = modMission:Progress(player, MISSION_ID);
			if mission and mission.ObjectivesCompleted[subId] ~= true then
				local build = false;
				
				local quantity = 0;
				local itemsList = profile.ActiveInventory:ListByItemId("wood");
				for a=1, #itemsList do quantity = quantity +itemsList[a].Quantity; end
				
				if quantity >= 20 then
					local storageItem = inventory:FindByItemId("wood");
					inventory:Remove(storageItem.ID, 20);
					shared.Notify(player, "20 Wooden Parts removed from your Inventory.", "Negative");
					
					build = true;
				else
					shared.Notify(player, `Not enough Wooden Parts, need {math.clamp(quantity, 0, 20)}/20 more.`, "Negative");
				end
				
				if build then
					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ObjectivesCompleted[subId] = true;
					end)
					
					local wallObjects = interactable.Part:FindFirstChild("Objects");
					local interactables = interactable.Part:FindFirstChild("Interactables");
					
					if interactables then 
						modReplicationManager.ReplicateIn(player, interactables, workspace.Interactables);
					end;
					modReplicationManager.ReplicateIn(player, wallObjects, workspace.Environment);
					local parts = wallObjects and wallObjects:GetDescendants();
					for a=1, #parts do
						if parts[a]:IsA("BasePart") then
							parts[a].CanCollide = true;
							parts[a].Transparency = 0;
						end
					end
					if wallObjects and wallObjects.PrimaryPart then
						modAudio.Play("Repair", wallObjects.PrimaryPart);
					end
					interactable.Part:Destroy();
				end

			else
				shared.Notify(player, "That is already built.", "Negative");

			end

		end)
	end
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigurations.IsWorld("TheMall") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			

		local loaded = false;
		local function load()
			if loaded then return end;
			loaded = true;
			for _, obj in pairs(wallTriggers:GetChildren()) do
				local newObj = obj:Clone();
				local built = mission.ObjectivesCompleted[obj.Name];
				
				if built ~= true then
					local parts = newObj:WaitForChild("Objects"):GetDescendants();
					for a=1, #parts do
						if parts[a]:IsA("BasePart") then
							parts[a].CanCollide = false;
							parts[a].Transparency = 0.5;
						end
					end

					local newInteractConfig = modInteractables.createInteractable("ButtonRotd");
					newInteractConfig:SetAttribute("_Id", "SpikingUp:Add");
					newInteractConfig:SetAttribute("_Label", "Build spiked fence with 20 wood");
					newInteractConfig:SetAttribute("SubId", obj.Name);
					newInteractConfig.Parent = newObj;
					
					modReplicationManager.ReplicateIn(player, newObj, workspace.Interactables);

				else
					modReplicationManager.ReplicateIn(player, newObj:WaitForChild("Objects"), workspace.Environment);
					if newObj:FindFirstChild("Interactables") then
						modReplicationManager.ReplicateIn(player, newObj.Interactables, workspace.Interactables);
					end

				end
			end
		end


		if modMission:IsComplete(player, MISSION_ID) then
			load();
			return;
		end
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				load();
			elseif mission.Type == 3 then -- OnComplete
				mission.OnChanged:Disconnect(OnChanged);
			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;