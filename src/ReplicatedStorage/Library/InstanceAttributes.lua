local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Attributes = {};
Attributes.__index = Attributes;

local library = {};
Attributes.Library = library;

local RunService = game:GetService("RunService");

local gcTimer = tick();
--== Script;
local function checkGc()
	if tick()-gcTimer >= 60 then
		gcTimer = tick();
		
		spawn(function()
			for obj, _ in pairs(library) do
				if obj.Parent == nil then
					library[obj] = nil;
				end
			end
		end)
	end
end

function Attributes:SetAttribute(obj, name, value)
	--Debugger:Warn("Deprecated ", debug.traceback());
	if typeof(obj) ~= "Instance" then Debugger:Warn("Object",obj,name,"is not an instance.") return end;
	local attributes = library[obj];
	
	if attributes == nil then
		library[obj] = {};
		attributes = library[obj];
		
		obj.Destroying:Connect(function()
			library[obj] = nil;
		end)
		
		checkGc();
	end
	
	if attributes then
		attributes[name] = value;
		
		if typeof(value) == "Instance" then
			value.AncestryChanged:Connect(function(c, p)
				if c == obj and p == nil then
					attributes[name] = nil;
				end
			end)
		end
	end
end

function Attributes:GetAttribute(obj, name)
	--Debugger:Warn("Deprecated ", debug.traceback());
	if typeof(obj) ~= "Instance" then Debugger:Warn("Object",obj,"is not an instance.") return end;
	
	local attributes = library[obj];
	return attributes and attributes[name];
end

return Attributes;
