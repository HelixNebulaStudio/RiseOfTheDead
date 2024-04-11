local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local GarbageHandler = {
	ClassName = "GarbageHandler";
	Trash = {};
};
GarbageHandler.__index = GarbageHandler;
export type GarbageHandler = typeof(GarbageHandler);

GarbageHandler.Destructors = {
	["function"] = function(item)
		local s, e = pcall(item);
		if not s then warn(e) end;
	end;
	["RBXScriptConnection"] = function(item)
		item:Disconnect();
	end;
	["Instance"] = function(item)
		item:Destroy();
	end;
	["table"] = function(item)
		for k,v in pairs(item) do
			item[k] = nil;
		end
	end;
}

function GarbageHandler:Tag(item)
	if item == nil then return end;
	if GarbageHandler.Destructors[typeof(item)] then
		self.Trash[#self.Trash + 1] = item;
		
		if typeof(item) == "Instance" then
			item.Destroying:Once(function()
				self:Untag(item);
			end)
		end
	end
end

function GarbageHandler:Untag(item)
	if item then
		local trash = self.Trash;
		for a=#trash, 1, -1 do
			if trash[a] == item then
				table.remove(trash, a);
			end
		end
	else
		self.Trash = {};
	end
end

function GarbageHandler:Destruct()
	local trash = self.Trash;
	for a=1, #trash do
		local item = trash[a];
		if GarbageHandler.Destructors[typeof(item)] then
			GarbageHandler.Destructors[typeof(item)](item);
		end
	end
	table.clear(self.Trash);
end

function GarbageHandler.new() : GarbageHandler
	local self = setmetatable({}, GarbageHandler);
	self.Trash={};
	return self;
end

return GarbageHandler;