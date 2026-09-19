local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modTilePrototypeClass = shared.require(game.ReplicatedStorage.Library.WaveCollapseSystem.TilePrototypeClass);

local TilePrototypePackage = {};
--==

function TilePrototypePackage:Init(raidController, waveCollapseSystem)
	if self.Initiated == true then return; end;
	self.Initiated = true;
	
	Debugger:Warn("Init Green Room");
	self.Controller = raidController;
	self.WaveCollapseSystem = waveCollapseSystem;
	
	self.VoxelGates = waveCollapseSystem:GetGatesFromGroup(self.Model);
	for a=1, #self.VoxelGates do
		local voxelPoint = self.VoxelGates[a].VoxelPoint;
		local gateAxis = self.VoxelGates[a].Axis;
		
		voxelPoint:SetTraversable(gateAxis, false);
	end
	
	local layout = self.Model:WaitForChild("Layout");

	local lockedDoors = {};
	for _, child in pairs(layout:GetChildren()) do
		if child.Name == "GreenDoor" then
			local newInteractConfig = modInteractables.createInteractable("DoorRotd");
			newInteractConfig:SetAttribute("Locked", true);
			newInteractConfig:SetAttribute("KeyLocked", "abgreenkey");
			newInteractConfig.Parent = child;

			local interactable = modInteractables.getOrNew(newInteractConfig);
			table.insert(lockedDoors, interactable);

			interactable.Values.OnChanged:Connect(function(k, v)
				if k == "Locked" and v == false then
					for _, i: InteractableInstance in pairs(lockedDoors) do
						i.Values.Locked = false;
						i:Sync();
					end
				end
			end)
		end
	end

	modDoors.OnDoorToggle:Connect(function(doorInstance: DoorInstance, player: Player)
		if not layout:IsAncestorOf(doorInstance.Model) then return end;
		if not doorInstance.IsOpen then return end;

		if self.Active ~= true then
			self.Active = true;

			shared.Notify(game.Players:GetPlayers(), `{player.Name} has unlocked the Green Room.`, "Positive");
			self:Start(player);
		end
	end)
end

function TilePrototypePackage:Start(player)
	for a=1, #self.VoxelGates do
		local voxelPoint = self.VoxelGates[a].VoxelPoint;
		local gateAxis = self.VoxelGates[a].Axis;

		voxelPoint:SetTraversable(gateAxis, true);
	end
	
	local layout = self.Model:WaitForChild("Layout");
	local specialSpawn = layout.SpecialSpawn:WaitForChild("RewardSpawn");
	
	local miniBossName = "Jaws";
	local npcClass: NpcClass = shared.modNpcs.spawn2{
		Name = miniBossName;
		CFrame = specialSpawn.WorldCFrame;
		AddComponents = {
        	"DropReward";
		};
		BindSetup = function(npcClass: NpcClass)
			local properties = npcClass.Properties;
			properties.Level = math.max(properties.Level + self.Controller.Difficulty, 1);
			properties.TargetableDistance = 256;
			properties.ForgetEnemies = false;
			properties.DropRewardId = "ab:greenroomdrop";
			
			local targetHandlerComp = npcClass:GetComponent("TargetHandler");
			if targetHandlerComp then
				targetHandlerComp:AddTarget(player.Character);
			end
		end;
	};
end

function TilePrototypePackage.new(tileModel)
	local self = modTilePrototypeClass.new(TilePrototypePackage);

	self.Model = tileModel;
	self.Active = false;
		
	self.Controller = nil;
	self.WaveCollapseSystem = nil;
			
	self.Doors = {};

	return self;
end

return TilePrototypePackage;

