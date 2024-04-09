local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;

--== Modules;
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);


local ToolHandler = {};
ToolHandler.__index = ToolHandler;
--== Script;

function ToolHandler:OnPrimaryFire(isActive, ...)
	if typeof(self.Player) == "Instance" and self.Player:IsA("Player") then
		self.Character = self.Player.Character;
	end
	
	local character = self.Character;
	local humanoid = character and character:FindFirstChild("Humanoid");
	
	if humanoid and humanoid.Health > 0 then
		if self.ToolConfig.OnPrimaryFire then
			self.ToolConfig.OnPrimaryFire(self, isActive, ...);
		end
	end
end

function ToolHandler:OnSecondaryFire(...)
	if typeof(self.Player) == "Instance" and self.Player:IsA("Player") then
		self.Character = self.Player.Character;
	end
	
	local character = self.Character;
	local humanoid = character and character:FindFirstChild("Humanoid");
	
	if humanoid and humanoid.Health > 0 then
		if self.ToolConfig.OnSecondaryFire then
			self.ToolConfig.OnSecondaryFire(self, ...);
		end
	end
end

function ToolHandler:OnToolEquip(toolModule)
	if self.ToolConfig.OnEquip then
		self.ToolConfig.OnEquip(self);
	end
end

function ToolHandler:OnToolUnequip()
	if self.ToolConfig.OnUnequip then
		self.ToolConfig.OnUnequip(self);
	end
	
	if self.Garbage then
		self.Garbage:Destruct();
	end
end

function ToolHandler:OnInputEvent(inputData)
	if typeof(self.Player) == "Instance" and self.Player:IsA("Player") then
		self.Character = self.Player.Character;
	end
	
	local character = self.Character;
	local humanoid = character and character:FindFirstChild("Humanoid");
	
	if humanoid and humanoid.Health > 0 then
		if self.ToolConfig.OnInputEvent then
			self.ToolConfig.OnInputEvent(self, inputData);
		end
	end
end

function ToolHandler.new(player, storageItem, toolPackage, toolModels)
	local self = {
		Player = player;
		StorageItem = storageItem;
		Prefabs = toolModels;
		ToolPackage = toolPackage;
		
		Garbage = modGarbageHandler.new();
	};
	self.ToolConfig = toolPackage.NewToolLib(self);

	if typeof(player) == "Instance" and player:IsA("Player") then
		self.Character = player.Character;
	end
	
	if storageItem and storageItem.MockItem then
		self.MockItem = true;
	end
	
	setmetatable(self, ToolHandler);
	return self;
end

return ToolHandler;
