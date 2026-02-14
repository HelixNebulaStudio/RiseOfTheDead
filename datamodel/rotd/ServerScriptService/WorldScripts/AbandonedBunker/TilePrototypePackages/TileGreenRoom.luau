local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);

local modTilePrototypeClass = shared.require(game.ReplicatedStorage.Library.WaveCollapseSystem.TilePrototypeClass);

local TilePrototypePackage = {};
--==

function TilePrototypePackage:Init(raidController, waveCollapseSystem)
	if self.Initiated == true then return; end;
	self.Initiated = true;
	
	Debugger:Warn("Init Green Room");
	self.Controller = raidController;
	self.WaveCollapseSystem = waveCollapseSystem;
	
	self.VoxelGates = waveCollapseSystem:GetGatesFromGroup(script.Parent.Parent);
	for a=1, #self.VoxelGates do
		local voxelPoint = self.VoxelGates[a].VoxelPoint;
		local gateAxis = self.VoxelGates[a].Axis;
		
		voxelPoint:SetTraversable(gateAxis, false);
	end
	
	for _, child in pairs(script.Parent:GetChildren()) do
		if child:FindFirstChild("Door") and child.Door:IsA("ModuleScript") then
			local doorObject = modDoors:GetDoor(child);
			table.insert(self.Doors, doorObject);
			
			doorObject.OnDoorToggle:Connect(function(player)
				Debugger:Warn("OnDoorToggle", player);
				
				for a=1, #self.Doors do
					local doorObj = self.Doors[a];
					if doorObj.Prefab then
						doorObj.Prefab:SetAttribute("KeyRequired", nil);
					end
				end
				
				if self.Active ~= true then
					self.Active = true;

					shared.Notify(game.Players:GetPlayers(), player.Name .." has unlocked the Green Room.", "Positive");
					self:Start(player);
				end
			end)
		end
	end
end

function TilePrototypePackage:Start(player)
	for a=1, #self.VoxelGates do
		local voxelPoint = self.VoxelGates[a].VoxelPoint;
		local gateAxis = self.VoxelGates[a].Axis;

		voxelPoint:SetTraversable(gateAxis, true);
	end
	
	local specialSpawn = script.Parent.SpecialSpawn:WaitForChild("RewardSpawn");
	
	local miniBossName = "Jaws";
	local npcClass: NpcClass = shared.modNpcs.spawn2{
		Name = miniBossName;
		CFrame = specialSpawn.WorldCFrame;
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

