local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);

local GlobalRandom = {};
GlobalRandom.__index = GlobalRandom;

GlobalRandom.Mem = modDatabaseService:GetDatabase("PseudoRngStore");
--==

local failRandom = Random.new();
local randomLoop = 10000;
--== Script;
GlobalRandom.Mem:OnUpdateRequest("inc", function(requestPacket)
	local v = (requestPacket.RawData or 0);

	if v >= randomLoop then
		v = 0;
	end

	v=v+1;
	return v;
end)

function GlobalRandom:NextNumber(key, min, max)
	min = min or 0;
	max = max or 1;
	local roll = failRandom:NextNumber(min, max);
	
	if key == nil then
		error("GlobalRandom:NextNumber Missing key.");
	end
	local s, e = pcall(function()
		local returnPacket = GlobalRandom.Mem:UpdateRequest(key, "inc");
		if returnPacket.Success then
			local newV = returnPacket.Data;

			local rng = Random.new(0);
			for a=1, newV do
				roll = rng:NextNumber();
			end
		end
		
		--GlobalRandom.Mem:Update(key, function(oldV)
		--	local v = (oldV or 0);
			
		--	if v >= randomLoop then
		--		v = 0;
		--	end
		
		--	roll = rng:NextNumber(min, max)
			
		--	v=v+1;
		--	return v;
		--end)
	end)
	if not s then Debugger:Warn(e) end;
	
	return roll;
end

function GlobalRandom:NextInteger(key, min, max)
	local roll = failRandom:NextInteger(min, max);
	
	if key == nil then
		error("GlobalRandom:NextNumber Missing key.");
	end
	local s, e = pcall(function()
		local returnPacket = GlobalRandom.Mem:UpdateRequest(key, "inc");
		if returnPacket.Success then
			local newV = returnPacket.Data;

			local rng = Random.new(0);
			for a=1, newV do
				roll = rng:NextInteger(min, max);
			end
		end
		
		--GlobalRandom.Mem:Update(key, function(oldV)
		--	local v = (oldV or 0);
			
		--	if v >= randomLoop then
		--		v = 0;
		--	end
			
		--	local rng = Random.new(0);
		--	for a=1, v do
		--		rng:NextInteger();
		--	end
			
		--	roll = rng:NextInteger(min, max)
			
		--	v=v+1;
		--	return v;
		--end)
	end)
	if not s then Debugger:Warn(e) end;
	
	return roll;
end

return GlobalRandom;
