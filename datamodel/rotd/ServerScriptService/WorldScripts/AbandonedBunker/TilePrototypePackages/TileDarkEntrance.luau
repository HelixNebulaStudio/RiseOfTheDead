local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local modTilePrototypeClass = shared.require(game.ReplicatedStorage.Library.WaveCollapseSystem.TilePrototypeClass);

local TilePrototypePackage = {};
--==
function TilePrototypePackage.onRequire()

end

function TilePrototypePackage:Init(raidController, waveCollapseSystem)
	if self.Initiated == true then return; end;
	self.Initiated = true;
	
	Debugger:Warn("Init Dark Room");
	self.Controller = raidController;
	self.WaveCollapseSystem = waveCollapseSystem;
	
	self.WaveCollapseSystem.DarkRoomIndex = (self.WaveCollapseSystem.DarkRoomIndex or 0) + 1;
	
	local newModel = self.Model:WaitForChild("Layout");
	local rewardSpawnPart = newModel:WaitForChild("RewardSpawn");
	local lockedDoorPrefab = newModel:WaitForChild("LockedDoor");
	
	local hitVolume = script:WaitForChild("HitVolume");
	hitVolume.Parent = nil;
	
	local darkRoomKey = `DarkRoomLever{self.WaveCollapseSystem.DarkRoomIndex}`;

	local tempLever = {};
	for _, obj in pairs(newModel.Parent:GetDescendants()) do
		if obj.Name == "ElectricalLever" and obj:IsA("Model") then
			local interactConfig = obj:FindFirstChild("Interactable");
			if interactConfig == nil or not interactConfig:IsA("Configuration") then continue end;

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
	
	local function startGasLeak()
		task.spawn(function()
			local header = "Toxic Leak Detected";
			local status = "Toxic leak detected in the dark room.";

			self.Controller:Hud{
				Header=header;
				Status=status;
				PlayMusic=false;
			};
			modAudio.Play("DeathCertificate", workspace);
			
			for a=60, 0, -1 do
				self.Controller:Hud{
					Header=header;
					Status=status.." "..a.."s ";
				};
				task.wait(1);
			end
			
			self.Controller:Hud{
				Header=header;
				Status=status.." Toxic imminent!";
			};
			
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
					
					local newEffect = script.ParticleEmitter:Clone();
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
			if self.Levers[a].Active then
				activeCount = activeCount +1;
			end
		end
		
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
			lockedDoorPrefab:SetAttribute("StateRequired", nil);
			shared.Notify(game.Players:GetPlayers(), "Dark Room: Door Unlocked!", "Inform");
			self.Controller:Hud{
				PlayMusic=true;
			};
			
		else
			if wonReward == true then return end;
			lockedDoorPrefab:SetAttribute("StateRequired", "Unlock with "..activeCount.."/"..maxLevers.." Levers");
			shared.Notify(game.Players:GetPlayers(), lockedDoorPrefab:GetAttribute("StateRequired"), "Inform");
			
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
