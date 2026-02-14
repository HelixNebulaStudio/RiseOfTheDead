local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local SoundService = game:GetService("SoundService");
local CollectionService = game:GetService("CollectionService");


local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modMarkers = shared.require(game.ReplicatedStorage.Library.Markers);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modParticleSprinkler = shared.require(game.ReplicatedStorage.Particles.ParticleSprinkler);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

local environment = workspace:WaitForChild("Environment");
local gameObjects = environment:WaitForChild("Game");
local doorObjects = gameObjects:WaitForChild("Doors");
local controllerBase = gameObjects:WaitForChild("Controller");

--== Server Variables;
if RunService:IsServer() then
	modNpcs = shared.require(game.ServerScriptService.ServerLibrary.Entity.Npcs);
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

else
	modData = shared.require(localPlayer:WaitForChild("DataModule"));

end


--== Script;
local MISSION_ID = 57;
local disconnectDoorToggle;
local winDebounce;
return function(CutsceneSequence)
	CutsceneSequence:Initialize(function()
		local gameController = shared.GameController;
		
		if gameController.Soundtrack then
			gameController.Soundtrack:Destroy();
		end
		gameController.Soundtrack = modAudio.Play(script:WaitForChild("Inside Tracks - We Wish You A Merry Christmas"), workspace);
		gameController.Soundtrack.SoundGroup = SoundService:WaitForChild("BackgroundMusic");

		gameController:SetHeader("");
		gameController:SetStatus("Complete the Klaws Obby");

		local locationsChecklist = {};
		gameController.OnPlayersLocationChanged:Connect(function(data: {Players: {[Player]: string}; PlayersCount: number})
			for player, location in pairs(data.Players) do
				if locationsChecklist[location] ~= nil then continue end; 
				locationsChecklist[location] = true;

				Debugger:Log("Player "..player.Name.." reached "..location);
			end
		end)

		Debugger:Warn("Difficulty", gameController.Difficulty);

		for _, player in pairs(gameController.Players) do
			if not modMission:IsComplete(player, MISSION_ID) then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 1 then
						mission.ProgressionPoint = 2;
					end
				end)
			end
		end
		
		modConfigurations.Set("BaseWoundedDuration", 60);
		CutsceneSequence:NextScene("starting");

		local chain1Destructible: DestructibleInstance = modDestructibles.getOrNew(workspace.Environment.Game.Chains1.Destructible);
		chain1Destructible.OnDestroy:Connect(function() 
			local ladder1 = workspace.Environment.Game.Ladder1;
			
			TweenService:Create(ladder1.PrimaryPart, TweenInfo.new(3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
				CFrame=CFrame.new(62.7170181, 9.42611027, 20.8895569, 0, 1, 0, 0, 0, 1, 1, 0, 0);
			}):Play();
			
			local sound = modAudio.Play("GateDrop", ladder1.PrimaryPart);
			sound.PlaybackSpeed = 1.8;
			sound.Volume = 1;
			
			local chain1Model = chain1Destructible.Model;
			local origin = chain1Model.chain.CFrame;
			chain1Model.chain:Destroy();
			
			for a=1, 3 do
				modParticleSprinkler:Emit{
					Type=2;
					Origin=origin;
					Count=2;
				};
				task.wait(0.3);
			end
		end)

		local liftDestructible: DestructibleInstance = modDestructibles.getOrNew(workspace.Environment.Game.LiftChains.Destructible);
		chain1Destructible.OnDestroy:Connect(function() 
			local lift = workspace.Environment.Game.Lift;
			
			TweenService:Create(lift.PrimaryPart, TweenInfo.new(5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
				CFrame=CFrame.new(34.9118156, 5.6289649, -29.9117756, -1, 0, 0, 0, 1, 0, 0, 0, -1);
			}):Play();
			
			local sound = modAudio.Play("GateDrop", lift.PrimaryPart);
			sound.PlaybackSpeed = 0.8;
			sound.Volume = 2;
			
			local model = liftDestructible.Model;
			for _, obj in pairs(model.chains:GetChildren()) do
				modParticleSprinkler:Emit{
					Type=2;
					Origin=obj.CFrame;
					Count=3;
					Size=Vector3.new(1.041, 1.511, 0.278);
					Material=Enum.Material.DiamondPlate;
				};
				obj:Destroy();
			end
			game.Debris:AddItem(model.Part1, 0);
			game.Debris:AddItem(model.Part2, 0);
		end)

		--MARK: Game Exit Door
		local exitDoorModel = workspace.Interactables.EndDoubleDoors;
		local door: DoorInstance = modDoors.getOrNew(exitDoorModel.Door);
		door:Toggle(true);
		
		if disconnectDoorToggle then
			disconnectDoorToggle();
		end
		disconnectDoorToggle = modDoors.OnDoorToggle:Connect(function(door, player)
			if winDebounce then return end;
			winDebounce = true;

			gameController:SetStatus(`Mr. Klaws Workshop Complete!`);
			gameController:CompleteCoop();
			
			gameController.Soundtrack.TimePosition = 5;
			TweenService:Create(gameController.Soundtrack, TweenInfo.new(1), {Volume=0.2}):Play();
			
			shared.Notify(game.Players:GetPlayers(), "Merry Christmas, everybody!", "Positive");
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
	
	return CutsceneSequence;
end;