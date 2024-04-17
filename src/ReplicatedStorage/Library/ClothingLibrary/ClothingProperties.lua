local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
--
local ClothingProperties = {}
ClothingProperties.__index = ClothingProperties;
ClothingProperties.Configurations={ModCapacity=5;};
ClothingProperties.Class = "Clothing";

--== Script;
function ClothingProperties.new(clothing)
	local self = {};
	
	clothing = clothing or {};
	
	for k, v in pairs(clothing) do
		if k:sub(1,4) == "Base" then
			local nk = k:sub(5, #k);
			clothing["Mod"..nk] = v;
		end
	end
	
	clothing.RegisteredTypes = {};
	clothing.RegisteredProperties = {};
	clothing.PreRegisteredProperties = {};
	
	setmetatable(self, clothing);
	setmetatable(clothing, ClothingProperties);
	clothing.__index = clothing;
	
	function clothing:GetPersistent(k)
		return clothing[k];
	end
	
	function clothing:SetPersistent(k, v)
		clothing[k] = v;
	end
	
	function clothing:GetKeys()
		local keys = {};
		for k, _ in pairs(clothing) do
			if k == "RegisteredTypes" then continue end;
			if k == "RegisteredProperties" then continue end;
			if k == "PreRegisteredProperties" then continue end;

			keys[k] = true 
		end;
		for k, _ in pairs(self) do keys[k] = true end;
		return pairs(keys);
	end
	
	return self;
end

function ClothingProperties:RegisterPlayerProperty(k, v, isMod: boolean) -- This will never be called again server side due to caching.
	self.RegisteredProperties[k] = v;

	if isMod then
		self.ActiveProperties[k] = v;
	else
		self.PreRegisteredProperties[k] = v;
	end
end


function ClothingProperties:RegisterTypes(modLib, storageItem)
	if storageItem then
		storageItem.Values.StackConflict = nil;
	end
	local exist = false;
	
	for k, v in pairs(modLib.Stackable) do
		if self.RegisteredTypes[k] then
			exist = true;
			if storageItem then
				if RunService:IsClient() then
					storageItem.Values.StackConflict = k;
				end
			end
			break;
		end
	end

	if exist then return true end;
	
	for k, v in pairs(modLib.Stackable) do
		self.RegisteredTypes[k] = true;
	end
	
	return false;
end

function ClothingProperties:Reset()
	for k, _ in pairs(self) do
		self[k] = nil;
	end
	for k, _ in pairs(self.RegisteredTypes) do
		self.RegisteredTypes[k] = nil;
	end
	-- Note to self: This method clears after newToolLib and before mods.
	self.ActiveProperties = {};
end

function ClothingProperties:PreMod()
	for k, v in pairs(self.PreRegisteredProperties) do
		self.ActiveProperties[k] = v;
	end
end

function ClothingProperties:PostMod()
end


function ClothingProperties:ApplySeed(storageItem)
	local itemValues = storageItem.Values;
	
	local seed = itemValues.Seed;
	local randomTemplate = Random.new(seed);
	
	if self.HasFlinchProtection then
		local random = randomTemplate:Clone();
		self.FlinchProtection = random:NextInteger(1, 99 * math.pow(random:NextNumber(), 3))/100;
	end
	
end

return ClothingProperties;