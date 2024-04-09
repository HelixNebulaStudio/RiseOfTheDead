local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local HttpService = game:GetService("HttpService");

local Serializer = {};
Serializer.__index = Serializer;

function Serializer.new()
	local self = {
		Class = {};
	};
	
	setmetatable(self, Serializer);
	return self;
end

function Serializer:AddClass(className, new)
	self.Class[className] = new;
end

function Serializer:Deserialize(rawVariant)
	if rawVariant == nil then return nil; end;
	local data;
	if typeof(rawVariant) == "table" then
		data = rawVariant;
		
	elseif typeof(rawVariant) == "string" then
		local s, e = pcall(function()
			data = HttpService:JSONDecode(rawVariant);
		end)
		if not s then
			data = rawVariant;
		end
		
	else
		data = rawVariant;
		
	end
	if typeof(data) ~= "table" then return data; end;
	
	local function load(rawData)
		-- rawData is table;
		local function fit(newData)
			for k, v in pairs(newData) do
				if rawData[k] == nil then continue end;
				
				if typeof(v) == "table" then
					newData[k] = load(rawData[k]);
				else
					newData[k] = rawData[k] or v;
				end
			end
			for k, v in pairs(rawData) do
				if newData[k] == nil then continue end;
				
				if typeof(v) == "table" then
					newData[k] = rawData[k];
				else
					if newData[k] ~= rawData[k] then
						newData[k] = rawData[k];
					end
				end
			end
			
			return newData;
		end
		
		local class = rawData._class;
		if class and self.Class[class] then
			local newObj = self.Class[class]();
			return fit(newObj)
			
		else
			return fit(rawData);
			
		end
	end
	
	local object = load(data);
	
	if object.OnDeserialize then
		object:OnDeserialize(data);
	end
	return object;
end

function Serializer:Serialize(object)
	if typeof(object) ~= "table" then return object end;
	
	local function setClass(t)
		if t.ClassType then
			t._class = t.ClassType;
		end
		for k, v in pairs(t) do
			if typeof(v) == "table" then
				setClass(v);
			end
		end
	end

	if object.OnSerialize then
		object:OnSerialize();
	end
	
	setClass(object);
	return object;
	--return HttpService:JSONEncode(object);
end

return Serializer;
