local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local PseudoRandom = {};
PseudoRandom.Cache = {};

PseudoRandom.CValues = {
	[5]=0.0038;
	[10]=0.0147;
	[15]=0.0322;
	[20]=0.0557;
	[25]=0.0847;
	[30]=0.1189;
	[35]=0.1579;
	[40]=0.2015;
	[45]=0.2493;
	[50]=0.3021;
	[55]=0.3603;
	[60]=0.4226;
	[65]=0.4811;
	[70]=0.5714;
	[75]=0.6666;
	[80]=0.7500;
	[85]=0.8235;
	[90]=0.8888;
	[95]=0.9473;
	[100]=1;
}

PseudoRandom.__index = PseudoRandom;
--==

local failRandom = Random.new();
local randomLoop = 10000;
--== Script;
function PseudoRandom.new(player)
	local meta = {
		Player = player;
		Randoms = {};
	};
	meta.__index=meta;
	
	local self = {};
	
	setmetatable(self, meta);
	setmetatable(meta, PseudoRandom);
	
	if player then
		PseudoRandom.Cache[player.Name] = self; 
	end
	return self;
end

function PseudoRandom:Get(player)
	return self.Cache[player.Name];
end

function PseudoRandom:Load(data)
	for k, v in pairs(data) do
		self[k] = v;
	end
	return self;
end

function PseudoRandom:GetRandom(key)
	if self[key] == nil then
		self[key] = 0;
	end
	if self.Randoms[key] == nil then
		local seed = self.Player and self.Player.UserId or tick();
		if modBranchConfigs.CurrentBranch.Name == "Dev" then
			seed = seed -1;
		end
		self.Randoms[key] = Random.new(seed);
		
		if self[key] >= randomLoop then
			self[key] = 0;
		end
		for a=1, (self[key] or 0) do
			self.Randoms[key]:NextNumber();
		end
	end
	return self.Randoms[key];
end

function PseudoRandom:Clone(player, key)
	local rng = self:Get(player);
	if rng then
		local random = rng:GetRandom(key) or failRandom;
		return random:Clone();
		
	else
		Debugger:Warn("Missing save for player (",player.Name,").");
	end;
end

function PseudoRandom:NextNumber(player, key, min, max)
	local rng = self:Get(player);
	if rng then
		local random = rng:GetRandom(key);
		rng[key] = rng[key] +1;
		
		return random:NextNumber(min, max);
	else
		Debugger:Warn("Missing save for player (",player.Name,").");
	end;
	return failRandom:NextNumber(min, max);
end

function PseudoRandom:NextInteger(player, key, min, max)
	local rng = self:Get(player);
	if rng then
		local random = rng:GetRandom(key);
		rng[key] = rng[key] +1;

		return random:NextInteger(min, max);
	else
		Debugger:Warn("Missing save for player (",player.Name,").");
	end;
	return failRandom:NextInteger(min, max);
end

local function lerp(a, b, t) return a * (1-t) + (b*t); end

function PseudoRandom:PrdRandom(key, p)
	key = key or "nil";
	local random = self:GetRandom(key);
	self[key] = self[key] +1;
	
	local k = math.ceil(p*100/5)*5;
	k = math.min(k * self[key], 100);
	
	local min = PseudoRandom.CValues[k-5] or 0;
	local max = PseudoRandom.CValues[k] or 1;
	
	local t = math.fmod(p*100, 5)/5;
	local c = lerp(min, max, 1-t);
	
	local hit = random:NextNumber(0, 1) <= c;
	
	if hit then
		self[key] = 0;
	end
	
	return hit;
end

function PseudoRandom:FairCrit(key, p)
	key = key or "nil";
	local random = self:GetRandom(key);
	self[key] = self[key] +1;
	
	if p <= 0 then
		return false;
	end
	
	local hitRate = 1/p;
	local hit = false;
	
	if hitRate > 4 then
		hit = self[key] >= hitRate
		
		if random:NextNumber(0, 1) <= (p*1/4) then
			hit = true;
		end
		
	else
		hit = random:NextNumber(0, 1) <= p;
		
	end
	
	--local hitMean = 1/math.clamp(p, 0, 1);
	--local hitSd = hitMean*0.25;
	--local hitMin = hitMean-hitSd;
	--local hitChance = p/100;
	
	--if self[key] >= hitMin then
	--	hitChance = ((self[key]-hitMin)/hitSd);
	--end
	
	--hitChance = math.clamp(hitChance, 0.001, 0.75);
	--local hit = random:NextNumber(0, 1) <= hitChance;
	
	if hit then
		self[key] = 0;
	end
	
	return hit;
end

return PseudoRandom;