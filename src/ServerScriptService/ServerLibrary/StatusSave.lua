local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modStatusLibrary = require(game.ReplicatedStorage.Library.StatusLibrary);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

--== Variables;
local StatusSave = {};
StatusSave.__index = StatusSave;

--== Script;
function StatusSave.new(player)
	local meta = {};
	meta.__index = meta;
	meta.Player = player;
	
	local self = {};
	
	setmetatable(meta, StatusSave);
	setmetatable(self, meta);
	return self;
end

function StatusSave:Load(data)
	for id, status in pairs(data) do
		self[id] = status;
	end
	
	return self;
end

function StatusSave:Save(statuses)
	for id, status in pairs(statuses) do
		if typeof(status) == "table" then
			local statusLib = modStatusLibrary:Find(id);

			if statusLib and status.PresistUntilExpire and status.Expires and modSyncTime.Clock.Value < status.Expires then
				self[id] = status;
			end
		end
	end
end

function StatusSave:ApplyEffects()
	local classPlayer = modPlayers.GetByName(self.Player.Name);
	if classPlayer then
		for id, status in pairs(self) do
			if modStatusEffects[id] and typeof(status.PresistUntilExpire) == "table" then
				local statusExpireTime = status.Expires;
				if statusExpireTime then
					local durationLeft = math.max(statusExpireTime-modSyncTime.GetTime(), 1);
					
					local params = {};
					for _, arg in pairs(status.PresistUntilExpire) do
						if arg == "Duration" then
							table.insert(params, durationLeft);
						else
							table.insert(params, status[arg]);
						end
					end
					
					modStatusEffects[id](self.Player, unpack(params));
				else
					Debugger:Warn("Status load no expire time: ", id);
				end
			else
				classPlayer:SetProperties(id, status);
			end
		end
	end
end

return StatusSave;