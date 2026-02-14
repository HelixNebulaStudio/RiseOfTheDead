local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modTweenModel = shared.require(game.ReplicatedStorage.Library.TweenModel);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

local modTilePrototypeClass = shared.require(game.ReplicatedStorage.Library.WaveCollapseSystem.TilePrototypeClass);

local PISTON_TWEEN_INFO = TweenInfo.new(0.5);
local PISTON_YUPDIST = 32.3;

local TilePrototypePackage = {};
--==

function TilePrototypePackage.onRequire()
	modDoors.OnDoorToggle:Connect(function(doorInstance: DoorInstance, player: Player?)
		if doorInstance.Values.BindOnDoorToggle then
			doorInstance.Values.BindOnDoorToggle(doorInstance, player);
		end
	end)
end

function TilePrototypePackage:Init(raidController, waveCollapseSystem)
	if self.Initiated == true then return; end;
	self.Initiated = true;
	
	Debugger:Warn("Init Spiral Chamber");
	self.Controller = raidController;
	self.WaveCollapseSystem = waveCollapseSystem;

	self.WaveCollapseSystem.SpiralChamberIndex = (self.WaveCollapseSystem.SpiralChamberIndex or 0) + 1;

	local triggerTag = `SpiralChamber{self.WaveCollapseSystem.SpiralChamberIndex}`;
	
	local newModel = self.Model:WaitForChild("Layout");
	local lootSpawns = {newModel.LootSpawn:WaitForChild("RewardSpawn")}
	
	local chosenNum = math.random(2, 7);
	local binStr = modMath.NumberToBinStr(chosenNum, "000");

	local pistonGroups = {};
	local primaryGroup = nil;
	
	local hintClipboardInteractable = nil;
	local blacklightHintInteractable = nil;
	
	local function onDoorToggle(doorInstance: DoorInstance, player: Player?)
		Debugger:Warn("OnDoorToggle", player);
		
		if self.Active ~= true then
			self.Active = true;

			local itemDrop = modItemDrops.ChooseDrop(modRewardsLibrary:Find("ab:arelshiftpartsdrop"));
			if itemDrop then
				modItemDrops.spawn{
					ItemId = itemDrop.ItemId;
					Quantity = itemDrop.Quantity;
					SpawnCFrame = lootSpawns[math.random(1, #lootSpawns)].WorldCFrame;
					DespawnDuration = false;
					Anchored = true;
					DisableTouchPickup = true;
				}
			end
		end
	end


	local function updatePistons()
		local activeValue = 0;
		for a=3, 1, -1 do
			local leverInteractable: InteractableInstance = self.Levers[a];
			local isActive = leverInteractable.Values.IsActive == true;

			activeValue = activeValue + (isActive and 2^(a-1) or 0);
		end

		Debugger:Warn("activeValue", activeValue, "chosenValue", chosenNum);

		for a=1, #self.Pistons do
			local pistonModel = self.Pistons[a];
			local pistonValue = pistonModel:GetAttribute("Value");
			local defaultCf = pistonModel:GetAttribute("OriginalCFrame");

			if activeValue > 0 and math.fmod(activeValue, pistonValue) == 0 then
				modTweenModel.TweenModulePosition(pistonModel, PISTON_TWEEN_INFO, (defaultCf * CFrame.new(0, PISTON_YUPDIST, 0)).Position);

			else
				modTweenModel.TweenModulePosition(pistonModel, PISTON_TWEEN_INFO, defaultCf.Position);

			end
		end
	end

	for _, child in pairs(newModel:GetChildren()) do
		if child:FindFirstChild("Door") and child.Door:IsA("Configuration") then
			local door: DoorInstance = modDoors.getOrNew(child.Door);
			
			door.Values.BindOnDoorToggle = onDoorToggle;
			
		elseif child.Name == "ElectricalLever" and child.Interactable:IsA("Configuration") then
			local interactable: InteractableInstance = modInteractables.getOrNew(child.Interactable);
			if interactable == nil then continue end;

			local leverIndex = child:GetAttribute("Index");
			interactable.Id = triggerTag;
			self.Levers[leverIndex] = interactable;

			interactable.Values.OnChanged:Connect(function(k, nv, ov)
				updatePistons();
			end)

		elseif child.Name == "Clipboard" and child.Interactable:IsA("Configuration") then
			hintClipboardInteractable = modInteractables.getOrNew(child.Interactable);

		elseif child.Name == "PillarGroup"  then
			table.insert(pistonGroups, child);

		elseif child.Name == "DecorPillarGroup"  then
			for _, obj in pairs(child:GetChildren()) do
				if obj.Name == "piston" then
					obj:SetAttribute("Value", math.random(0, 7) );
					obj:SetAttribute("OriginalCFrame", obj:GetPivot());
					table.insert(self.Pistons, obj);
				end
			end
			
		elseif child.Name == "HintPart" then
			blacklightHintInteractable = modInteractables.getOrNew(child.Interactable);
			
		end
	end
	
	
	primaryGroup = pistonGroups[math.random(1, #pistonGroups)];
	
	local factorNums = modMath.GetFactors(chosenNum);
	table.remove(factorNums, 1);
	
	local nonFactors = {};
	for a=2, 7 do
		if math.fmod(a, 2) == 1 or table.find(factorNums, a)  == nil then
			table.insert(nonFactors, a);
		end
	end
	
	for a=1, #pistonGroups do
		if pistonGroups[a] == primaryGroup then
			for _, obj in pairs(pistonGroups[a]:GetChildren()) do
				if obj.Name == "piston" then
					obj:SetAttribute("Value", factorNums[math.random(1, #factorNums)]);
					obj:SetAttribute("OriginalCFrame", obj:GetPivot());
					table.insert(self.Pistons, obj);
				end
			end
			
		else
			for _, obj in pairs(pistonGroups[a]:GetChildren()) do
				if obj.Name == "piston" then
					obj:SetAttribute("Value", nonFactors[math.random(1, #nonFactors)] );
					obj:SetAttribute("OriginalCFrame", obj:GetPivot());
					table.insert(self.Pistons, obj);
				end
			end
		end
	end
	
	
	hintClipboardInteractable.Config:SetAttribute("Text", [[States:
	[Active] <font color='rgb(159, 255, 157)'>]]..chosenNum..[[</font>
	*The rest of the page has been ripped off.*
]]);
	
	blacklightHintInteractable.Config:SetAttribute("BlacklightText", binStr:sub(1,2).."?");
	
	updatePistons();
end


function TilePrototypePackage.new(tileModel)
	local self = modTilePrototypeClass.new(TilePrototypePackage);

	self.Model = tileModel;
	self.Active = false;
		
	self.Controller = nil;
	self.WaveCollapseSystem = nil;

	self.Levers = {};
	self.Pistons = {};

	return self;
end

return TilePrototypePackage;

