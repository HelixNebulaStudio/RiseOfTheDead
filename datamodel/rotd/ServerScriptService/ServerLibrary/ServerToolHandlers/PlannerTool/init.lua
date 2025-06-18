local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local CollectionService = game:GetService("CollectionService");

--== Modules;
local modTools = shared.require(game.ReplicatedStorage.Library.ToolsLibrary);
local modGarbageHandler = shared.require(game.ReplicatedStorage.Library.GarbageHandler);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBlueprintLibrary = shared.require(game.ReplicatedStorage.Library.BlueprintLibraryRotd);

local modPlannerInterface = shared.require(game.ReplicatedStorage.Library.InterfacesRotd.PlannerInterface);

local modProfile = shared.require(game.ServerScriptService.ServerLibrary.Profile);

local remoteEngineersPlanner = modRemotesManager:Get("EngineersPlanner");

local plannerLibrary = modPlannerInterface.PlannerLibrary;


local plansFolder = Instance.new("Folder");
plansFolder.Name = "EngineersPlans";
plansFolder.Parent = game.ReplicatedStorage;


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

function ToolHandler.new(player, storageItem, toolLib, toolModels)
	local self = {
		Player = player;
		StorageItem = storageItem;
		ToolLib = toolLib;
		Prefabs = toolModels;
		ToolConfig = toolLib.NewToolLib();
		Garbage = modGarbageHandler.new();
	};

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
