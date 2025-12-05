local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local SoundService = game:GetService("SoundService");
local CollectionService = game:GetService("CollectionService");


local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modMarkers = shared.require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("Markers"));
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
local modParticleSprinkler = shared.require(game.ReplicatedStorage.Particles.ParticleSprinkler);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local environment = workspace:WaitForChild("Environment");
local gameObjects = environment:WaitForChild("Game");
local doorObjects = gameObjects:WaitForChild("Doors");
local controllerBase = gameObjects:WaitForChild("Controller");

local liftPointA = CFrame.new(147.606, -2.738, -79.615);

local Cache: anydict = {};
--== Server Variables;
if RunService:IsServer() then
	modNpcs = shared.require(game.ServerScriptService.ServerLibrary.Entity.Npcs);
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Destructibles_BindDestroyed", function(eventPacket: EventPacket, ...)
		local players = eventPacket.Players;
		local destructible: DestructibleInstance = ...;

		if destructible.Id == nil then return end;
		if destructible.Id ~= "LadderSkip" then return end;

		-- Debugger:Log("Coop ladder skip")
		-- local entityTallGate = modEntity:GetEntity(doorObjects.TallGate);
		-- entityTallGate.Door.OnDoorToggle:Fire(player);
	end)

    shared.modEventService:OnInvoked("Interactables_BindButtonInteract", function(eventPacket: EventPacket, ...)
        local interactable: InteractableInstance = ...;
		local interactPart: BasePart = interactable.Part;
        local variantId = interactable.Variant;

		if variantId == nil then return end;
        Debugger:StudioLog("Interactables_BindButtonInteract", eventPacket, interactable);

		if variantId == "MilitaryRadio" then

		end
    end)

	shared.modEventService:OnInvoked("Doors_BindDoorToggle", function(eventPacket: EventPacket, ...)
		local doorInstance: DoorInstance = ...;
		local doorConfig = doorInstance.Config;
		
	end)

else
	modData = shared.require(localPlayer:WaitForChild("DataModule"));

end


--== Script;
local MISSION_ID = 56;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("Genesis") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
		
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

		local startDoorInteractConfig = doorObjects.StartArmoredDoor.Interactable;
		startDoorInteractConfig:SetAttribute("Locked", true);

		local endDoorInteractConfig = doorObjects.EndArmoredDoor.Interactable;
		endDoorInteractConfig:SetAttribute("Locked", true);

		local rustyGateInteractConfig = doorObjects.RustyGateDoor.Interactable;
		rustyGateInteractConfig:SetAttribute("Locked", true);

		local stageIndex = 1;
		gameController:SetHeader("");
		gameController:SetStatus("Exit the safe room");

		local locationsChecklist = {};
		gameController.OnPlayersLocationChanged:Connect(function(data: {Players: {[Player]: string}; PlayersCount: number})
			for player, location in pairs(data.Players) do
				if locationsChecklist[location] ~= nil then continue end; 
				locationsChecklist[location] = true;

				Debugger:Log("Player "..player.Name.." reached "..location);
			end

			if locationsChecklist["test"] == true then
			elseif locationsChecklist["Closed-off Train Station"] == true and stageIndex < 8 then
				gameController:SetStatus("Get the Elevator working");
				stageIndex = 8;

			elseif locationsChecklist["Abandoned Safehouse"] == true and stageIndex < 6 then
				gameController:SetStatus("Respond to the radio distress call");
				stageIndex = 6;

			elseif locationsChecklist["Garage"] == true and stageIndex < 3 then
				gameController:SetStatus("Get the Garage gates open");
				stageIndex = 3;

			end
		end)

		Debugger:Warn("Difficulty", gameController.Difficulty);
		
		modConfigurations.Set("BaseWoundedDuration", 60);

		local cutsceneIndex = gameController.Index;
		local function checkGameIndex()
			if gameController.Index ~= cutsceneIndex then
				Debugger:Warn("Game index changed, aborting cutscene.", debug.traceback());
				return true;
			end
			return false;
		end

		gameObjects.DestructionSmoke.Smoke.Enabled = false;
		
		local elevatorModel = environment:WaitForChild("Elevator1");
		elevatorModel:PivotTo(liftPointA);
		modAudio.Play("StartBoom", workspace);
		
		CutsceneSequence:NextScene("starting");

		for _, player in pairs(gameController.Players) do
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint < 4 then mission.ProgressionPoint = 4; end;
			end)
		end
		
		-- Initialize;
		if Cache.Jet then
			Cache.Jet:Destroy();
		end
		Cache.Jet = cutsceneAssets.Jet:Clone();
		Cache.Jet.Parent = workspace;

		if Cache.BlowUpProp then
			Cache.BlowUpProp:Destroy();
		end

		Cache.BlowUpProp = cutsceneAssets.BlowUp:Clone();
		Cache.BlowUpProp.Parent = workspace.Environment;

		if Cache.CarRig then
			Cache.CarRig:Destroy();
		end

		Cache.CarRig = cutsceneAssets.CarRig:Clone();
		Cache.CarRig.Parent = workspace.Environment;
		-- Initialize;
		
		startDoorInteractConfig:SetAttribute("Locked", false);

		local startDoor: Configuration = doorObjects.StartArmoredDoor.Door;
		startDoor:GetAttributeChangedSignal("DoorOpen"):Wait();
		gameController:BeginCoop();

		gameController:SetStatus("Find a way to the surface");
		stageIndex = 2;
		
		Debugger:Log("Begin level");
		if checkGameIndex() then return; end;
		
		TweenService:Create(gameController.Soundtrack, TweenInfo.new(20), {Volume=0.3}):Play();
		
		local tallGateInteractConfig: Configuration = doorObjects.TallGate.GateButton.Interactable;
		task.spawn(function()
			tallGateInteractConfig:GetAttributeChangedSignal("IsOpen"):Wait();
			if checkGameIndex() then return; end;

			Debugger:Warn(`Triggered Tall Gate`);

			TweenService:Create(gameController.Soundtrack, TweenInfo.new(5), {Volume=0.6}):Play();
			task.delay(10, function()
				TweenService:Create(gameController.Soundtrack, TweenInfo.new(15), {Volume=0.3}):Play();
			end)

			modAudio.Play("HordeGrowl", workspace);
			gameController:SetStatus("Find a way to the other side of Bloxmart");
			stageIndex = 4;

			gameController.HordeTimer = tick();

			for _, player in pairs(gameController.Players) do
				modNpcs.attractNpcs(player.Character, 256, function(npcClass: NpcClass)
					if npcClass.HumanoidType ~= "Zombie" then return false end;
					npcClass.Properties.HordeAggression = true;
					return true;
				end);
			end
		end)

		
		local jetTriggered = false;
		if Cache.JetTriggerConn then Cache.JetTriggerConn:Disconnect() end;
		Cache.JetTriggerConn = gameObjects.JetTrigger.Touched:Connect(function(hitPart)
			if jetTriggered then return end;
			local playerTouch = false;
			for a=1, #gameController.Players do
				if gameController.Players[a].Character and hitPart:IsDescendantOf(gameController.Players[a].Character) then
					playerTouch = true;
					break;
				end
			end
			
			if playerTouch then
				jetTriggered = true;
			end
		end)
		
		repeat
			task.wait()
		until jetTriggered or checkGameIndex();
		if checkGameIndex() then return; end;
		
		modAudio.Play("JetAmbient", workspace);
		gameController:SetStatus("Investigate the safehouse building");
		stageIndex = 5;
		
		local jetOriginCf = Cache.Jet.PrimaryPart.CFrame;
		TweenService:Create(Cache.Jet.PrimaryPart, TweenInfo.new(4, Enum.EasingStyle.Linear), {
			CFrame=CFrame.new(380.397034, 96.1059113, -210.394272, -1, 0, 0, 0, 1, 0, 0, 0, -1);
		}):Play();
		
		wait(0.5);
		Cache.Jet.PrimaryPart.Swoosh:Play();
		
		if Cache.MilitaryZombie then
			Cache.MilitaryZombie:Destroy();
		end
		
		modNpcs.spawn2{
			Name = "Zombie";
			CFrame = CFrame.new(-0.959411621, 42.6933365, -292.28183, -3.7252903e-09, 0, 1, 0, 1, 0, -1.00000012, 0, 3.7252903e-09);
			BindSetup = function(npcClass: NpcClass)

				npcClass.PresetShirt = {Id="rbxassetid://267032596"};
				npcClass.PresetPants = {Id="rbxassetid://197707345"};
				cutsceneAssets:WaitForChild("Desert Soldier"):Clone().Parent = npcClass.Character;
			end;
		};

		Debugger:Warn("Wait for MilitaryRadio");
		local milRadioInteractConfig = workspace.Interactables.MilitaryRadio.Interactable;
		
		repeat
			task.wait();
		until milRadioInteractConfig:GetAttribute("IsActive") == true or checkGameIndex();
		if checkGameIndex() then return; end;
		Debugger:Warn("MilitaryRadio active");
		gameController:SetStatus("[Radio]: Missiles are inbound, stay inside as adviced. *Static*");

		modAudio.Play("HordeGrowl", workspace);
		TweenService:Create(gameController.Soundtrack, TweenInfo.new(5), {Volume=0.75}):Play();
		gameController.HordeTimer = tick();
		wait(25);
		if checkGameIndex() then return; end;

		gameController.Soundtrack.TimePosition = 85;
		TweenService:Create(gameController.Soundtrack, TweenInfo.new(3), {Volume=1}):Play();
		
		Cache.Jet.PrimaryPart.CFrame = jetOriginCf;
		TweenService:Create(Cache.Jet.PrimaryPart, TweenInfo.new(4, Enum.EasingStyle.Linear), {
			CFrame=CFrame.new(380.397034, 96.1059113, -210.394272, -1, 0, 0, 0, 1, 0, 0, 0, -1);
		}):Play();
		
		wait(1);
		if checkGameIndex() then return; end;
		Cache.Jet.PrimaryPart.Swoosh:Play();
		
		task.spawn(function()
			local targetPoint = Vector3.new(19.491, 38.784, -256.372);
			for a=1, 3 do
				local origin = Cache.Jet.PrimaryPart.CFrame;

				local projectile: ProjectileInstance = modProjectile.fire("rpgrocket", {
					OriginCFrame = origin;
				});
				projectile.Properties.ExplosionRadius = 128;
				projectile.Properties.Damage = 5000;
				projectile.Properties.TargetableTags = {Zombie=1;};

				local velocity = projectile.ArcTracer:GetVelocityByTime(origin.p, targetPoint, 1);
				modProjectile.serverSimulate(projectile, {
					Velocity = velocity;
				});
				wait(0.5);
			end
		end)

		task.wait(1.5);
		
		local debriOrigin = Vector3.new(20.778, 37.657, -235.472);
		Cache.BlowUpProp:Destroy();
		gameController:SetStatus("Find a way through th sewers");
		
		local animationController = Cache.CarRig:WaitForChild("AnimationController");
		local explosionAnim = animationController:LoadAnimation(cutsceneAssets.ExplosionAnim);
		
		task.spawn(function()
			explosionAnim.Stopped:Wait();
			explosionAnim:Play();
			explosionAnim:AdjustSpeed(0);
			explosionAnim.TimePosition = explosionAnim.Length -0.01;
		end)
		explosionAnim:Play();
		
		local particlePacket = {
			Type=1;
			Origin=CFrame.new(debriOrigin);
			Velocity=Vector3.new(0, 1, 0);
			SizeRange={Min=5; Max=15};
			Material=Enum.Material.Slate;
			DespawnTime=10;
			Speed=100;
		};
		
		gameObjects.DestructionSmoke.Smoke.Enabled = true;
		particlePacket.Color = Color3.fromRGB(65, 42, 33);
		task.spawn(CutsceneSequence.NextScene, CutsceneSequence, "camShake");
		modAudio.Play("Explosion4", Cache.CarRig.PrimaryPart).RollOffMaxDistance = 4096;
		modParticleSprinkler:Emit(particlePacket);
		particlePacket.Color = Color3.fromRGB(91, 81, 68);
		modParticleSprinkler:Emit(particlePacket);
		modAudio.Play("Explosion2", Cache.CarRig.PrimaryPart).RollOffMaxDistance = 4096;
		wait(0.5);
		modParticleSprinkler:Emit(particlePacket);
		modAudio.Play("Explosion4", Cache.CarRig.PrimaryPart).RollOffMaxDistance = 4096;
		task.spawn(CutsceneSequence.NextScene, CutsceneSequence, "camShake");
		wait(0.5);
		modParticleSprinkler:Emit(particlePacket);
		modAudio.Play("Explosion3", Cache.CarRig.PrimaryPart).RollOffMaxDistance = 4096;
		
		gameController:SetStatus("Find a way through th sewers");
		stageIndex = 7;
		wait(5);
		Cache.Jet:Destroy();
		Cache.Jet = nil;
		
		task.delay(5, function()
			if checkGameIndex() then return; end;
			TweenService:Create(gameController.Soundtrack, TweenInfo.new(20), {Volume=0.3}):Play();
		end)
		
		--MARK: Fix Elevator 
		elevatorModel:GetAttributeChangedSignal("IsPowered"):Wait();
		if checkGameIndex() then return; end;
		gameController:SetStatus("Take the elevator out of the train station");
		stageIndex = 9;

		local finDoorDoorConfig = doorObjects.FinalDoors.Door;
		finDoorDoorConfig:GetAttributeChangedSignal("DoorOpen"):Wait();
		if checkGameIndex() then return; end;
		gameController:SetStatus("Find your way through");
		stageIndex = 10;
		
		gameController.HordeTimer = tick();
		modAudio.Play("HordeGrowl", workspace);
		
		--== Boss sequence
		Debugger:Warn("Boss door wait");
		local bossInteractConfig = doorObjects.BossMetalDoor.Interactable;
		local bossDoorInteractable = modInteractables.getOrNew(bossInteractConfig);

		local bossDoorConfig = doorObjects.BossMetalDoor.Door;
		bossDoorConfig:GetAttributeChangedSignal("DoorOpen"):Wait();
		if checkGameIndex() then return; end;
		gameController:SetStatus("Defeat the boss");
		stageIndex = 11;
		
		local bossSpawnPart = gameObjects.BossSpawns.BossSpawn;

		local hasMission56 = false;

		for _, player in pairs(gameController.Players) do
			local mission56 = modMission:GetMission(player, MISSION_ID);
			if mission56 and mission56.ProgressionPoint >= 3 then
				hasMission56 = true;
			end
		end
		
		if hasMission56 then
			local infectorNpcClass: NpcClass = modNpcs.spawn2{
				Name = "Robert";
				CFrame = bossSpawnPart.CFrame;
				PackageOverride = "Infector";
				NetworkOwners = table.clone(gameController.Players);
			};
			Debugger:Log("Spawn boss");

			local robertTrigger = false;
			if Cache.RobertTrigger then Cache.RobertTrigger:Disconnect() end;
			Cache.RobertTrigger = gameObjects.RobertTrigger.Touched:Connect(function(hitPart)
				if robertTrigger then return end;
				local playerTouch = false;
				local players = gameController.Players;
				for a=1, #players do
					if players[a].Character and hitPart:IsDescendantOf(players[a].Character) then
						playerTouch = true;
						break;
					end
				end

				if playerTouch then
					robertTrigger = true;

					infectorNpcClass.Move:Face(Vector3.new(151.283, 5.397, -157.124))
					infectorNpcClass.Chat(game.Players:GetPlayers(), "You have no idea what you got yourself into.");

					for _, player in pairs(players) do
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint < 5 then mission.ProgressionPoint = 5; end;
						end)
					end

					task.wait(5);
					local targetHandlerComp = infectorNpcClass:GetComponent("TargetHandler");
					for _, player in pairs(players) do
						targetHandlerComp:AddTarget(player.Character);
					end
				end
			end)

			infectorNpcClass.HealthComp.OnIsDeadChanged:Connect(function()
				if not infectorNpcClass.HealthComp.IsDead then return end;
				infectorNpcClass.Chat(game.Players:GetPlayers(), "Nooo... Don't let them capture me... *dies*");
			end)
			repeat
				task.wait(0.1);
			until infectorNpcClass.HealthComp.IsDead or checkGameIndex();
			Debugger:Warn("Infector defeated");

			modAudio.Play("ZombieDeath3", infectorNpcClass.RootPart.Position).PlaybackSpeed = 0.5;

		else
			local randomBossList = {"The Prisoner";}; -- "Tanker"; "Fumes"; "Corrosive"
			local selectedBossName = randomBossList[math.random(1, #randomBossList)];
			
			local bossNpcClass: NpcClass = modNpcs.spawn2{
				Name = selectedBossName;
				CFrame = bossSpawnPart.CFrame;
				BindSetup = function(npcClass: NpcClass)
					npcClass.Properties.Level = gameController.Difficulty;
				end;
			};
			for _, player in pairs(gameController.Players) do
				bossNpcClass:GetComponent("TargetHandler"):AddTarget(player.Character);
			end
			
			repeat
				task.wait(0.1);
			until bossNpcClass.HealthComp.IsDead or checkGameIndex();
			if checkGameIndex() then return end;
			Debugger:Warn("Boss defeated");
			
			modAudio.Play("ZombieDeath3", bossNpcClass.RootPart.Position).PlaybackSpeed = 0.5;
		end

		for _, player in pairs(gameController.Players) do
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint < 6 then mission.ProgressionPoint = 6; end;
			end)
		end

		rustyGateInteractConfig:SetAttribute("Locked", false);
		endDoorInteractConfig:SetAttribute("Locked", false);

		gameController:SetStatus("Escape through the saferoom door");
		stageIndex = 12;
		
		--MARK: Game Exit Door
		local endExitInteractConfig = workspace.Interactables.endExit.Interactable;
		local endExitInteractable: InteractableInstance = modInteractables.getOrNew(endExitInteractConfig);
		endExitInteractable.CanInteract = false;
		endExitInteractable.Label = "Close armored door to end the run";
		endExitInteractable:Sync();

		local endDoorDoorConfig = doorObjects.EndArmoredDoor.Door;
		
		local winDebounce = false;
		local lastHintedTick = tick();
		local doorCloseGraceTick = nil;
		task.spawn(function()
			while true do
				local isDoorOpen = endDoorDoorConfig:GetAttribute("DoorOpen");
				if isDoorOpen then
					doorCloseGraceTick = nil;
					if tick() > lastHintedTick then
						lastHintedTick = tick()+5;
						shared.Notify(game.Players:GetPlayers(), "Close the exit door to end.", "Inform", "endhint");
					end

					task.wait(0.1);
					continue;
				end

				if doorCloseGraceTick == nil then
					doorCloseGraceTick = tick()+3;
				end

				if tick() <= doorCloseGraceTick then
					task.wait(0.1);
					continue;
				end


				-- wait for players
				local alivePlayers = {};
				local namesTable = {};
				
				for a=1, #gameController.Players do
					if not gameController.Players[a]:IsDescendantOf(game.Players) then continue end;
					
					local playerClass: PlayerClass = shared.modPlayers.get(gameController.Players[a]);
					if playerClass.HealthComp.IsDead == false then
						table.insert(alivePlayers, gameController.Players[a]);
						table.insert(namesTable, gameController.Players[a].Name)
					end
				end
				
				for _, player in pairs(gameController.Players) do
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 6 then
							modMission:CompleteMission(player, MISSION_ID);
						end;
					end)
				end
							
				local winRoomHitboxs = workspace.CurrentCamera.winRoomHitboxes:GetChildren();
				local overlapParam = OverlapParams.new();
				overlapParam.FilterType = Enum.RaycastFilterType.Include;
				overlapParam.FilterDescendantsInstances = CollectionService:GetTagged("PlayerRootParts");
				
				local playersInWinRoom = {};
				
				for a=1, #winRoomHitboxs do
					local hitParts = workspace:GetPartsInPart(winRoomHitboxs[a], overlapParam);
					
					for b=1, #hitParts do
						local player = game.Players:GetPlayerFromCharacter(hitParts[b].Parent);
						if player then
							for c=1, #alivePlayers do
								if alivePlayers[c] == player then
									table.insert(playersInWinRoom, player);
									break;
								end
							end
						end
					end
				end
				
				local waitingForList = {};
				for a=1, #namesTable do
					local exist = false;
					for b=1, #playersInWinRoom do
						if playersInWinRoom[b].Name == namesTable[a] then
							exist = true;
							break;
						end
					end
					if not exist then
						table.insert(waitingForList, namesTable[a])
					end
				end


				if #playersInWinRoom < #alivePlayers then
					shared.Notify(game.Players:GetPlayers(), ("Waiting for "..table.concat(waitingForList, ", ")), "Inform", "endhint");
					task.wait(1);
					continue;
				end;

				Debugger:Log("EndFunc");
				
				if winDebounce then return end;
				winDebounce = true;

				endDoorInteractConfig:SetAttribute("Locked", true);

				gameController:SetStatus("Genesis Complete!");
				gameController:CompleteCoop();
				stageIndex = 13;
				
				local namesString = table.concat(namesTable, ", ")
				if #namesTable == 1 then
					namesString = "Only "..namesString;
				end
				shared.Notify(game.Players:GetPlayers(), namesString.." survived Genesis..", "Positive", "endhint");
				
				gameController.Soundtrack.TimePosition = 243;
				TweenService:Create(gameController.Soundtrack, TweenInfo.new(1), {Volume=1}):Play();

				endExitInteractable.CanInteract = true;
				endExitInteractable.Label = "Exit Genesis";
				endExitInteractable:Sync();
			end
		end)
	end)
	
	CutsceneSequence:NewScene("starting", function()
		modMarkers.ClearMarker("Cutscene");
		
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