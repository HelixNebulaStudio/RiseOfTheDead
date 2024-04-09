local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local ClientSquad = {};
local modData = {};

function ClientSquad.new(data)
	local meta = {};
	meta.__index = meta;
	
	function meta:Update(data)
		for k, v in pairs(data) do
			self[k] = v;
		end
	end
	
	function meta:Destroy()
		self = nil;
	end
	
	function meta:LoopPlayers(callback)
		local c=0;
		for name, data in pairs(self.Members) do
			if callback then
				local r = callback(name, data);
				if r ~= nil then break; end;
			end
			c=c+1;
		end
		return c;
	end
	
	function meta:FindMember(playerName)
		return self.Members and self.Members[playerName] or nil;
	end
	
	local squad = setmetatable({}, meta);
	squad.Members = {};
	
	return squad;
end

return function(moddata)
	modData = moddata;
	return ClientSquad;
end;
