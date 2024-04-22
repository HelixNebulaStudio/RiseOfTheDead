local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Flags = {};
Flags.__index = Flags;
--== Variables;

--== Script;
function Flags:Get(eventId, default)
	for a=1, #self.Data do
		if self.Data[a].Id == eventId then
			return self.Data[a], a;
		end;
	end
	
	if default then
		return self:Add(default);
	end
	return;
end

function Flags:Add(data)
	self:Remove(data.Id);
	table.insert(self.Data, data);
	
	return data;
end

function Flags:Remove(id)
	for a=#self.Data, 1, -1 do
		if self.Data[a].Id == id then
			table.remove(self.Data, a);
		end
	end
end

function Flags:Sync()
	if self.Sync then
		self:Sync();
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

function Flags.new(player, syncFunc)
	local meta = {
		Player = player;
		Sync = syncFunc;
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