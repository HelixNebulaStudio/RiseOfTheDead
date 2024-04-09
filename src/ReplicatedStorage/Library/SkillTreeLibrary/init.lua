local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = {
	Authority=require(script.Authority);
	Endurance=require(script.Endurance);
	Synergy=require(script.Synergy);
	Triggers = {};
};

library.Authority:Sort(function(A, B) return A.Level < B.Level end);
library.Endurance:Sort(function(A, B) return A.Level < B.Level end);
library.Synergy:Sort(function(A, B) return A.Level < B.Level end);

function library:Find(id)
	if library.Authority.Library[id] then
		return library.Authority.Library[id], "Authority";
		
	elseif library.Endurance.Library[id] then
		return library.Endurance.Library[id], "Endurance";
		
	elseif library.Synergy.Library[id] then
		return library.Synergy.Library[id], "Synergy";
		
	end
end

function library:CalStats(lib, pts)
	local level = pts/lib.UpgradeCost;
	level = math.clamp(level, 0, lib.MaxLevel);
	
	local s = {};
	
	for k, stat in pairs(lib.Stats) do
		if stat.Base and stat.Max then
			local i = (stat.Max-stat.Base)/lib.MaxLevel;
			
			local v = level == lib.MaxLevel and stat.Base+(i*level) or stat.Base+(i*(level-1));
			if level == 0 then
				v = 0;
			end
			
			s[k] = {
				Interval = i;
				Value = v;
				Default = stat.Default;
			};
		end
	end
	return level, s;
end

return library;
