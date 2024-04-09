local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Entity = {};
Entity.__index = Entity;
Entity.ClassName = "Entity";

local CollectionService = game:GetService("CollectionService");

local modDoors = require(game.ReplicatedStorage.Library.Doors);
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);

local templateEntityObj = script:WaitForChild("EntityObject");

--== Script;

function Entity.new(src)
	if not (src:IsA("ModuleScript") and src.Name == "EntityObject") then
		return;
	end
	
	local self = {};
	self.Script = src;
	
	setmetatable(self, Entity);
	return self;
end

function Entity.newScript(parent)
	local new = templateEntityObj:Clone();
	new.Parent = parent;
	
	return new;
end

function Entity:GetEntity(instance)
	local src = instance:FindFirstChild("EntityObject");
	
	local entityObject = src and src:IsA("ModuleScript") and require(src);
	
	if src == nil then
		local doorSrc, doorObj = instance:FindFirstChild("Door");
		if doorSrc and doorSrc:IsA("ModuleScript") then
			doorObj = require(doorSrc);
		end
		
		local interactSrc, interactObj = instance:FindFirstChild("Interactable");
		if interactSrc and interactSrc:IsA("ModuleScript") then
			interactObj = require(interactSrc);
		end
		
		if doorObj or interactObj then
			src = Entity.newScript(instance);
			
			entityObject = require(src);
			
			entityObject.Door = doorObj;
			entityObject.Interactable = interactObj;
			entityObject.Interactable.Script = interactSrc;
		end
	end
	
	return entityObject;
end

function Entity:GetDestructible(model)
	while model:GetAttribute("DestructibleParent") do model = model.Parent; end

	local destructibleModule = model:FindFirstChild("Destructible");
	if not destructibleModule:IsA("ModuleScript") then return end;
	
	local destructible = require(destructibleModule);
	return destructible;
end


function Entity:AddType(entityType, ...)
	local src = script:FindFirstChild(entityType);
	
	if entityType == "Door" then
		local prefab = ...;
		self.Door = modDoors.new(self, prefab);
		
	elseif entityType == "Interactable" then
		local interactType = ...;
		self[entityType] = modInteractables[interactType]();
			
	elseif src then
		local modSrc = require(src);
		if modSrc.new then
			self[entityType] = modSrc.new(self, ...);
			
		end
	else
		Debugger:Warn("Entity type (",entityType,") does not exist. (",self.Script.Parent,")");
	end
end

function Entity:AddInteractable(module)
	local interactData = require(module);
	
	self.Interactable = interactData;
end

return Entity;