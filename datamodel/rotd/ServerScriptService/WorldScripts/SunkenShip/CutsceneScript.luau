local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local SoundService = game:GetService("SoundService");


local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local environment = workspace:WaitForChild("Environment");
local interactablesFolder = workspace:WaitForChild("Interactables");
local gameObjects = environment:WaitForChild("Game");
local controllerBase = gameObjects:WaitForChild("Controller");

--==

if RunService:IsServer() then
	modNpcs = shared.require(game.ServerScriptService.ServerLibrary.Entity.Npcs);
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	modRegionMission = shared.require(game.ServerScriptService.ServerLibrary.RegionMission);

	local mysteriousEngineerNpcLib = modNpcProfileLibrary:Find("Mysterious Engineer");
	local mysteriousEngineerAvatar = mysteriousEngineerNpcLib.Avatar;

	shared.modEventService:OnInvoked("Destructibles_BindDestroyed", function(eventPacket: EventPacket, ...)
		local regionMission = modRegionMission:GetById("CoopMission");

		local players = eventPacket.Players;
		local destructible: DestructibleInstance = ...;
		if destructible == nil then return end;

		local modelCf = destructible.Model:GetPivot();

		if destructible.Id == "SleepingElderVex" then
			regionMission:Progress(function(coopMission)
				if coopMission.CheckPoint <= 1 then
					coopMission.CheckPoint = 2;
				end
			end)

		elseif destructible.Id == "NekronChunk1" then
			modAudio.Play("NekronHurt", modelCf.Position).PlaybackSpeed = math.random(50, 60)/100;

			local freeDivingSuit = false;
			for _, player in pairs(game.Players:GetPlayers()) do
				if modEvents:GetEvent(player, "freeDivingSuit") == nil then
					freeDivingSuit = true;
					break;
				end
			end

			local text = "Good luck! I'll be waiting for the Nekron Particulate tubes..";
			if freeDivingSuit then
				text = "Come back with 4 tubes of Nekron Particulate and I'll give you a diving suit.";
			end
			regionMission:Progress(function(coopMission)
				if coopMission.CheckPoint <= 4 then
					coopMission.SaveData.Dialogues = {
						Dialogue1 = {
							AvatarId = mysteriousEngineerAvatar;
							Text = text;
						};
					};
				end
			end)

		elseif destructible.Id == "NekronChunk2" then
			modAudio.Play("NekronHurt", modelCf.Position).PlaybackSpeed = math.random(50, 60)/100;

		end
	end)

	shared.modEventService:OnInvoked("Generic_BindItemPickup", function(eventPacket: EventPacket, ...)
		local regionMission = modRegionMission:GetById("CoopMission");

		local player: Player? = eventPacket.Player;
		if player == nil then return end;

		local interactable: InteractableInstance = ...;
		if interactable.Values.ItemId ~= "nekronparticulate" then return end;
		regionMission:Progress(function(coopMission)
			if coopMission.SaveData.PickupCount == nil then
				coopMission.SaveData.PickupCount = 8;
			end
			coopMission.SaveData.PickupCount -= 1;
			Debugger:StudioLog(`coopMission.SaveData.PickupCount`, coopMission.SaveData.PickupCount);

			if coopMission.SaveData.PickupCount <= 0 then
				coopMission.SaveData.Dialogues = {
					Dialogue1 = {
						AvatarId = mysteriousEngineerAvatar;
						Text = "Nice! You got it all, c'mon back up. Whether you want to exchange them with me, that's up to you.";
					};
				};
				coopMission.Checkpoint = 7;
			end
		end)
	end)

    shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
		local regionMission = modRegionMission:GetById("CoopMission");

        local triggerId: string, interactable: InteractableInstance = ...;

        Debugger:StudioLog("Interactables_BindButtonInteract", eventPacket, interactable);

		if triggerId == "LeverA" or triggerId == "LeverB" or triggerId == "LeverC" then
			local leverAInteractable = modInteractables.getById("LeverA");
			local leverBInteractable = modInteractables.getById("LeverB");
			local leverCInteractable = modInteractables.getById("LeverC");
			local isLightOn = {
				SystemLight1 = leverAInteractable.Values.IsActive == true;
				SystemLight2 = leverBInteractable.Values.IsActive == true;
				SystemLight3 = leverCInteractable.Values.IsActive == true;
			};
			Debugger:StudioLog(`LeverActivation`, isLightOn);
			for _, model in ipairs(interactablesFolder.Levers:GetChildren()) do
				for partName, isOn in pairs(isLightOn) do
					local lightPart = model:FindFirstChild(partName);
					if lightPart then
						lightPart.Material = isOn and Enum.Material.Neon or Enum.Material.SmoothPlastic;
					end
				end
			end

			local count = 0;
			for partName, isOn in pairs(isLightOn) do
				if not isOn then continue end;
				count += 1;
			end

			regionMission:Progress(function(coopMission)
				coopMission.SaveData.Count = count;
				coopMission.SaveData.Total = 3;

				if coopMission.CheckPoint == 3 then
					coopMission.CheckPoint = 4;
				end
				
				if count == 1 then
					coopMission.SaveData.Dialogues = {
						Dialogue1 = {
							AvatarId = mysteriousEngineerAvatar;
							Text = "Oh hey! You found a lever. There should be 2 more lever somewhere.";
						};
					};
				elseif count == 2 then
					coopMission.SaveData.Dialogues = {
						Dialogue1 = {
							AvatarId = mysteriousEngineerAvatar;
							Text = "Nice! 1 more lever to go.";
						};
					};
				elseif count == 3 then
					coopMission.SaveData.Dialogues = {
						Dialogue1 = {
							AvatarId = mysteriousEngineerAvatar;
							Text = "Awesome, the cargo hold should be open. You'll find tubes there.";
						};
					};

					if coopMission.CheckPoint == 5 then
						coopMission.CheckPoint = 6;
					end
				end

			end)
		end

    end)

else
	modData = shared.require(localPlayer:WaitForChild("DataModule"));

end


--== Script;
return function(CutsceneSequence)
	if not modBranchConfigurations.IsWorld("SunkenShip") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
		
	local cutsceneAssets = game.ReplicatedStorage:WaitForChild("CutsceneAssets");

	local customAudio = cutsceneAssets:WaitForChild("Audio");
	for _, obj in pairs(customAudio:GetChildren()) do
		modAudio.Load(obj, "BackgroundMusic");
	end

	for _, obj in pairs(SoundService:GetChildren()) do
		if obj:IsA("Sound") then
			obj.SoundGroup = SoundService:WaitForChild("BackgroundMusic");
		end
	end
	
	CutsceneSequence:Initialize(function()
		local gameController = shared.GameController;
		local regionMission = modRegionMission:GetById("CoopMission");

		regionMission:UpdateRegion(workspace.Clips:WaitForChild("MissionRegion"));

		local sleepingElderVexDestructible: DestructibleInstance = modDestructibles.getById("SleepingElderVex");
		local elderVexSpawnCf = sleepingElderVexDestructible.Model:GetPivot() + (-Vector3.yAxis * 64);

		local function createPickupable()
			local config = modInteractables.createInteractable("PickupableRotd");
			config:SetAttribute("ItemId", "nekronparticulate");
			config:SetAttribute("Quantity", math.random(1, 2));
			config:SetAttribute("TouchPickup", false);
			return config;
		end

		local randomContainers = gameObjects:WaitForChild("NekronContainers"):WaitForChild("RandomNekronContainers"):GetChildren();
		for a=1, #randomContainers do
			randomContainers[a].Parent = script;
		end
		local winContainers = gameObjects:WaitForChild("NekronContainers"):WaitForChild("WinContainers"):GetChildren();
		for a=1, #winContainers do
			winContainers[a].Parent = script;
		end

		local nekronChunk1Destructible: DestructibleInstance = modDestructibles.getById("NekronChunk1");
		nekronChunk1Destructible:SetEnabled(false);

		local function OnMissionChanged(coopMission, firstRun)
			if coopMission.Type ~= 1 then return end;

			Debugger:StudioLog(`coopMission OnMissionChanged`, coopMission);
			if firstRun then
				local firstTimeCache = gameObjects:WaitForChild("NekronContainers"):WaitForChild("FirstTimeCache");
				firstTimeCache.Parent = script;

				for _, player in pairs(gameController.Players) do
					if modEvents:GetEvent(player, "sunkenFirstCache") == nil or RunService:IsStudio() then
						Debugger:Warn(`Spawned first time cache for testing. Has event flag:`, modEvents:GetEvent(player, "sunkenFirstCache") ~= nil);
						
						local pickupable = createPickupable();
						pickupable:SetAttribute("Quantity", 4);

						local newCacheModel = firstTimeCache:Clone();
						pickupable.Parent = newCacheModel;

						modReplicationManager.ReplicateIn(player, newCacheModel, workspace.Interactables);

						modEvents:NewEvent(player, {Id="sunkenFirstCache"});
					end
				end
				

				for a=1, 5 do
					local randomContainer = table.remove(randomContainers, math.random(1, #randomContainers));
					local pickupable = createPickupable();
					pickupable:SetAttribute("Quantity", math.random(1, 3));

					local newCacheModel = randomContainer:Clone();
					pickupable.Parent = newCacheModel;

					newCacheModel.Parent = interactablesFolder;
				end
			end

			if coopMission.CheckPoint == 1 then

			elseif coopMission.CheckPoint == 2 then
				game.Debris:AddItem(gameObjects:FindFirstChild("ElderVexDoor"), 0);
				gameController:BeginCoop();
				
				local elderVexeronNpcClass: NpcClass = shared.modNpcs.spawn2{
					Name = "ElderVexeron";
					CFrame = elderVexSpawnCf;
				};
				elderVexeronNpcClass.Properties.OnChanged:Connect(function(k, v, ov) 
					if k == "State" then
						if v == "Snooze" then
							regionMission:Progress(function()
								if coopMission.CheckPoint == 2 then
									coopMission.CheckPoint = 3;
									coopMission.SaveData.Timers = {
										Timer1 = {
											Duration = 300;
											StartTime = workspace:GetServerTimeNow();
											DefaultText = "The Elder Vexeron is in slumber..";
											TimeoutText = "The Elder Vexeron has awoken!";
										};
									};
								end
							end)
						elseif ov == "Snooze" then
							modAudio.Play("DoomAlarm", workspace);
						end
					end
				end)

			elseif coopMission.CheckPoint == 3 then
				local engineerNpcClass: NpcClass = shared.modNpcs.getByModel(workspace.Entity["Mysterious Engineer"]) :: NpcClass;
				local targetHandlerComp = engineerNpcClass:GetComponent("TargetHandler");

				while coopMission.CheckPoint == 3 do
					task.wait(0.2);
					
					local firstMatch: NpcTargetData? = targetHandlerComp:MatchFirstTarget(function(targetData: NpcTargetData)
						if targetData.HealthComp == nil then return end;
						local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner :: CharacterClass;
						if targetCharacterClass.ClassName ~= "PlayerClass" then return false; end;
						if targetData.Distance >= 25 then return false; end;

						return true;
					end)

					if firstMatch then
						regionMission:Progress(function(coopMission)
							if coopMission.CheckPoint == 3 then
								coopMission.CheckPoint = 4;
							end
						end)

						break;
					else
						Debugger:Warn(`Waiting for a nearby player`);
					end
				end

			elseif coopMission.CheckPoint == 4 then
				nekronChunk1Destructible:SetEnabled(true);

			elseif coopMission.CheckPoint == 5 then

			elseif coopMission.CheckPoint == 6 then
				modAudio.Play("GateDrop", workspace);
				game.Debris:AddItem(gameObjects:FindFirstChild("Gate"), 0);
				for a=1, #winContainers do
					local pickupableConfig = createPickupable();
					pickupableConfig.Parent = winContainers[a];
					winContainers[a].Parent = interactablesFolder;
				end
				gameController:CompleteCoop();

			elseif coopMission.CheckPoint == 7 then

			end
		end
		regionMission.CoopMission.OnChanged:Connect(OnMissionChanged);
		OnMissionChanged(regionMission.CoopMission, true);

		modAudio.Play("StartBoom", workspace);
		CutsceneSequence:NextScene("starting");
	end)
	
	CutsceneSequence:NewScene("starting", function()
		modClientGuis.toggleGameBlinds(false, 0);
		task.wait(2);
		modClientGuis.toggleGameBlinds(true, 20);
		
		local modCharacter = modData:GetModCharacter();
		
		modCharacter.CharacterProperties.CanMove = false;
		modCharacter.CharacterProperties.CanInteract = false;
		modCharacter.CharacterProperties.CharacterCameraEnabled = false;

		local modCameraGraphics = require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);
		local cameraKeyframes = modCameraGraphics:InitCameraTransitions(controllerBase, 8);
		modCameraGraphics:PlayKeyframes(cameraKeyframes);
		
		modCharacter.CharacterProperties.CanMove = true;
		modCharacter.CharacterProperties.CanInteract = true;
		modCharacter.CharacterProperties.CharacterCameraEnabled = true;
	end)
	
	
	CutsceneSequence:NewScene("camShake", function()
		local modCharacter = modData:GetModCharacter();
		modCharacter.CameraShakeAndZoom(20, 5, 1, 0.01, true);
	end)
	
	return CutsceneSequence;
end;