local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);
local modRegionMission = shared.require(game.ServerScriptService.ServerLibrary.RegionMission);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local modTilePrototypeClass = shared.require(game.ReplicatedStorage.Library.WaveCollapseSystem.TilePrototypeClass);

local TilePrototypePackage = {};
--==
function TilePrototypePackage.onRequire()

end

function TilePrototypePackage:Init(raidController, waveCollapseSystem)
	if self.Initiated == true then return; end;
	self.Initiated = true;
	
	local regionMission = modRegionMission.new(89);

	Debugger:Warn("Init Dark Room");
	self.Controller = raidController;
	self.WaveCollapseSystem = waveCollapseSystem;
	
	self.WaveCollapseSystem.DarkRoomIndex = (self.WaveCollapseSystem.DarkRoomIndex or 0) + 1;
	
	local newModel = self.Model:WaitForChild("Layout");
	local rewardSpawnPart = newModel:WaitForChild("RewardSpawn");
	local lockedDoorPrefab = newModel:WaitForChild("LockedDoor");

	local gameFolder = newModel:WaitForChild("Game");
	local mapRegion = gameFolder:WaitForChild("MissionRegion");
	mapRegion.Parent = script;
	regionMission:UpdateRegion(mapRegion);
	
	local hitVolume = gameFolder:WaitForChild("HitVolume");
	hitVolume.Parent = nil;
	
	local darkRoomKey = `DarkRoomLever{self.WaveCollapseSystem.DarkRoomIndex}`;

	local tempLever = {};
	for _, obj in pairs(newModel.Parent:GetDescendants()) do
		if obj.Name == "ElectricalLever" and obj:IsA("Model") then
			local interactConfig = obj:FindFirstChild("Interactable");
			if interactConfig == nil or not interactConfig:IsA("Configuration") then continue end;

			interactConfig:SetAttribute("_Uses", 1);
			local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
			
			interactable.Id = darkRoomKey;
			interactable.Values.Prefab = obj;
			interactable.Values.DarkRoomKey = darkRoomKey;
			
			if obj:GetAttribute("Main") == true then
				interactable.Values.Main = true;
				table.insert(self.Levers, interactable);
				
			else
				table.insert(tempLever, interactable);
				
			end
			
		end
	end
	
	local maxLevers = math.min(#tempLever, 4);
	
	for a=2, maxLevers do
		local interactable = table.remove(tempLever, math.random(1, #tempLever));
		table.insert(self.Levers, interactable);
	end
	
	for a=1, #tempLever do
		game.Debris:AddItem(tempLever[a].Values.Prefab, 0);
	end
	
	local gasLeakStage = 0;
	local gasLeakTimer = 120;
	
	local function startGasLeak()
		task.spawn(function()
			local startTime = workspace:GetServerTimeNow();
			regionMission:Progress(function(coopMission)
				coopMission.SaveData.Timers = {
					Timer1 = {
						Duration = gasLeakTimer;
						StartTime = startTime;
						DefaultText = "Toxic leak detected!";
						TimeoutText = "Toxic Gas imminent, get out of there!";
					};
				};
			end)
			modAudio.Play("DeathCertificate", workspace);
			
			while workspace:GetServerTimeNow() <= startTime+gasLeakTimer do
				task.wait(1);
			end

			local effectList = {};
			gasLeakStage = 2;
			while gasLeakStage == 2 do
				local charactersList = CollectionService:GetTagged("PlayerCharacters");
				
				if #charactersList <= 0 then task.wait(1); continue; end
				
				local randomCharacter = charactersList[math.random(1, #charactersList)];
				local randomRootPart = randomCharacter.PrimaryPart;
				
				if randomRootPart == nil then task.wait(1); continue end;
				
				if #effectList > 0 then
					local randomEffect = effectList[math.random(1, #effectList)];
					if randomEffect then
						task.spawn(function()
							for a=1, 8 do
								randomEffect:Emit(1);
								task.wait();
							end
						end)
					end
					
				end
				
				local overlapParam = OverlapParams.new();
				overlapParam.FilterType = Enum.RaycastFilterType.Include;
				overlapParam.FilterDescendantsInstances = {randomRootPart};
				
				local hitList = workspace:GetPartsInPart(hitVolume, overlapParam);
				
				if #hitList > 0 then
					local pointAtt = Debugger:Point(Vector3.new(randomRootPart.Position.X, hitVolume.Position.Y-16, randomRootPart.Position.Z));
					
					local newEffect = gameFolder.ParticleEmitter:Clone();
					game.Debris:AddItem(pointAtt, 60);
					newEffect.Parent = pointAtt;
					
					task.spawn(function()
						for a=1, 16 do
							newEffect:Emit(1);
							task.wait();
						end
					end)
					
					local dmg = 20;
					local player = game.Players:FindFirstChild(randomCharacter.Name);
					local playerClass: PlayerClass = shared.modPlayers.get(player);

					if playerClass then
						if playerClass.Configurations.GasProtection then
							dmg = 10;
						end

						playerClass.HealthComp:TakeDamage(DamageData.new{
							Damage = dmg;
							DamageType = "IgnoreArmor";
							TargetPart = randomRootPart;
						});
					end
					
					table.insert(effectList, newEffect);
				end
				
				task.wait(math.random(2,4));
			end

		end)
	end

	local wonReward = false;
	local function onLeverToggle()
		local activeCount = 0;
		for a=1, #self.Levers do
			local interactable: InteractableInstance = self.Levers[a];
			if interactable.Values.IsActive then
				activeCount = activeCount +1;
			end
		end
		
		regionMission:Progress(function(coopMission)
			if coopMission.CheckPoint <= 2 then
				coopMission.CheckPoint = 2;

				coopMission.SaveData.Count = activeCount;
				coopMission.SaveData.Total = #self.Levers;

				if activeCount >= 4 then
					coopMission.CheckPoint = 3;
				end
			end
		end)
		Debugger:Warn("Active: ", activeCount, "/", #self.Levers);
		
		if activeCount >= 4 then
			if wonReward == true then return end;
			wonReward = true;
			
			local itemDrop = modItemDrops.ChooseDrop(modRewardsLibrary:Find("ab:darkroomdrop"));
			if itemDrop then
				modItemDrops.spawn{
					ItemId = itemDrop.ItemId;
					Quantity = itemDrop.Quantity;
					SpawnCFrame = rewardSpawnPart.CFrame;
					Players = self.Controller.Players;
					DespawnDuration = false;
					Anchored = true;
					DisableTouchPickup = true;
				};
			end
			lockedDoorPrefab.Interactable:SetAttribute("Locked", false);
			
		else
			if wonReward == true then return end;
		end
		
		if gasLeakStage == 0 then
			gasLeakStage = 1;
			
			task.spawn(startGasLeak)
		end
	end

	for a=1, #self.Levers do
		local interactable = self.Levers[a];
		interactable.Values.OnChanged:Connect(function(k, nv, ov)
			if k ~= "IsActive" then return end;
			onLeverToggle();
		end)
	end

end

function TilePrototypePackage.new(tileModel)
	local self = modTilePrototypeClass.new(TilePrototypePackage);

	self.Model = tileModel;
	self.Active = false;
		
	self.Controller = nil;
	self.WaveCollapseSystem = nil;
			
	self.Doors = {};
	self.Levers = {};

	return self;
end

return TilePrototypePackage;
