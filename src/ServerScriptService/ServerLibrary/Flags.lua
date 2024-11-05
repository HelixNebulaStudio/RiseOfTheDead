local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Flags = {};
Flags.__index = Flags;
--== Variables;

--== Script;
function Flags:Get(flagId, default)
	local rawGet, rawIndex;
	for a=1, #self.Data do
		if self.Data[a].Id == flagId then
			rawGet, rawIndex = self.Data[a], a;
			break;
		end;
	end

	if rawGet == nil and default then
		rawGet, rawIndex = self:Add(default);
	end
	
	if self.GetHooks[flagId] then
		rawGet, rawIndex = self:Add(self.GetHooks[flagId](rawGet));
	end

	return rawGet, rawIndex;
end

function Flags:Add(data)
	self:Remove(data.Id);
	table.insert(self.Data, data);
	
	return data, #self.Data;
end

function Flags:Remove(id)
	for a=#self.Data, 1, -1 do
		if self.Data[a].Id == id then
			table.remove(self.Data, a);
		end
	end
end

function Flags:Sync(flagId)
	if self.Sync then
		self:Sync(flagId);
	end
end

function Flags:Load(rawData)
	if rawData == nil then return self end;
	
	for k, v in pairs(rawData) do
		if k ~= "Data" then
			self[k] = v;
		end
	end
	
	local data = rawData.Data;
	if data then
		for k, v in pairs(data) do
			local eventData = self:Add(v);
			if eventData and eventData.Script then
				task.spawn(function()
					local module = script:FindFirstChild(eventData.Script);
					if module then
						require(module)(eventData);
					end
				end)
			end
		end
	end
	
	return self;
end

function Flags:HookGet(flagId, func)
	if self.GetHooks[flagId] then 
		Debugger:Warn(`FlagId {flagId} is already hooked for {self.Player}!`);
		return 
	end;

	self.GetHooks[flagId] = func;
end

function Flags.new(player, syncFunc)
	local meta = {
		Player = player;
		Sync = syncFunc;
		GetHooks = {};
	}
	meta.__index = meta;
	
	local self = {
		Data={};
	};
	
	setmetatable(meta, Flags);
	setmetatable(self, meta);
	return self;
end

return Flags;