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
	
	clothing.RegisteredProperties = {};
	clothing.ActiveProperties = {};
	clothing.RegisteredTypes = {};
	
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
		for k, _ in pairs(clothing) do keys[k] = true end;
		for k, _ in pairs(self) do keys[k] = true end;
		return pairs(keys);
	end
	
	return self;
end

function ClothingProperties:RegisterPlayerProperty(k, v)
	self.RegisteredProperties[k] = v;
	self.ActiveProperties[k] = true;
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
	table.clear(self.ActiveProperties);
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