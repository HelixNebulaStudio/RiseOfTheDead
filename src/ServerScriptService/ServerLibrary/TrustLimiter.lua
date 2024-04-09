local TrustLimiter = {};
local mem = {};

function newMem(name)
	if mem[name] == nil then
		local memMeta = {LastUpdate = tick();}; 
		memMeta.Tick = function(self) memMeta.LastUpdate = tick() end;
		memMeta.Destroy = function(self) if tick()-self.LastUpdate > 60 then mem[name] = nil; else delay(60, function() self:Destroy() end) end; end;
		memMeta.__index = memMeta;
		memMeta.__cooldown = {};
		memMeta.SetCooldown = function(self, key, value) memMeta.__cooldown[key] = value; end;
		mem[name] = setmetatable({}, memMeta);
		delay(60, function() mem[name]:Destroy() end);
	end;
end

function TrustLimiter.Check(client, key, func) if client == nil or key == nil or func == nil then error("Trust Limiter>> Missing arguements.", 2); end;
	local name = client.Name;
	newMem(name);
	if mem[name][key] then
		return func(mem[name][key]);
	else
		return false;
	end
end

function TrustLimiter.Set(client, key, value)
	local name = client.Name;
	newMem(name);
	mem[name]:Tick();
	if type(value) == "function" then
		mem[name][key] = value(mem[name][key]);
	else
		mem[name][key] = value;
	end
end

function TrustLimiter.Reset(client, key, sec)
	local name = client.Name;
	if mem[name] and mem[name][key] and mem[name].__cooldown[key] == nil then
		mem[name]:SetCooldown(key, true);
		delay(sec or 1, function()
			mem[name][key] = nil;
			mem[name]:SetCooldown(key, nil);
		end)
	end
end

return TrustLimiter;