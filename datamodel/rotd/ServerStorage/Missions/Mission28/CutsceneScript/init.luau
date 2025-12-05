local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local wallTriggers = script:WaitForChild("WallTriggers");

--== Variables;
local MISSION_ID = 28;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modDialogues = shared.require(game.ServerScriptService.ServerLibrary.DialogueSave);
	
	if modBranchConfigs.IsWorld("TheUnderground") then
		shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...) 
			local player = event.Player;
			if player == nil then return end;

			local triggerId: string, interactable: InteractableInstance = ...;
			if triggerId ~= "SafetySafehouse:Add" then return end;

			local subId = interactable.Values.SubId;
			if subId == nil then Debugger:Warn("SafetySafehouse:Add>>  Missing sub id."); return end;
			
			local mission = modMission:Progress(player, MISSION_ID);
			if mission == nil then return end;

			if mission.ObjectivesCompleted[subId] == true then
				shared.Notify(player, "That is already built.", "Negative");
				return;
			end

			local profile = shared.modProfile:Get(player);
			local inventory = profile.ActiveInventory;

			local playerGaveMetal = interactable.Values.GaveMetal == true;
			local build = false;
			
			if not playerGaveMetal then
				local quantity = 0;
				local itemsList = inventory:ListByItemId("metal");
				for a=1, #itemsList do quantity = quantity +itemsList[a].Quantity; end
				
				if quantity >= 100 then
					local storageItem = inventory:FindByItemId("metal");
					inventory:Remove(storageItem.ID, 100);
					shared.Notify(player, "100 Metal Scraps removed from your Inventory.", "Negative");
					
					build = true;
				else
					shared.Notify(player, "Not enough Metal Scraps, need "..math.clamp(quantity, 0, 100).."/100 more.", "Negative");
				end
			else
				build = true;
			end

			if build then
				modMission:Progress(player, MISSION_ID, function(mission)
					mission.ObjectivesCompleted[subId] = true;
				end)
				
				local interactPart = interactable.Part;
				local wallObjects = interactPart and interactPart:FindFirstChild("Objects");
				local interactables = interactPart and interactPart:FindFirstChild("Interactables");
				
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

				interactPart:Destroy();
			end
				
		end)
	end

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheUnderground") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local carlsonDialogueData = modDialogues:Get(player, "Carlson");
		local gaveMetal = carlsonDialogueData:Get("thebackup_gaveMetal") == true;

		local loaded = false;
		local function load()
			if loaded then return end;
			loaded = true;
			
			for _, obj in pairs(wallTriggers:GetChildren()) do
				local newObj = obj:Clone();
				local built = mission.ObjectivesCompleted[obj.Name];
				
				if built == false then
					local parts = newObj:WaitForChild("Objects"):GetDescendants();
					for a=1, #parts do
						if parts[a]:IsA("BasePart") then
							parts[a].CanCollide = false;
							parts[a].Transparency = 0.5;
						end
					end

					local newInteractConfig = modInteractables.createInteractable("ButtonRotd");
					newInteractConfig:SetAttribute("_Id", "SafetySafehouse:Add");

					if gaveMetal then
						newInteractConfig:SetAttribute("_Label", obj.Name == "addDoorway" and "Build doorway" or "Build wall");
					else
						newInteractConfig:SetAttribute("_Label", obj.Name == "addDoorway" and "Build doorway with 100 metal scrap" or "Build wall with 100 metal scrap");
					end

					newInteractConfig:SetAttribute("SubId", obj.Name);
					newInteractConfig:SetAttribute("GaveMetal", gaveMetal);
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

		if mission.Type ~= 3 then
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

			return;
		end

		-- Completed
		load();
	end)
	
	return CutsceneSequence;
end;