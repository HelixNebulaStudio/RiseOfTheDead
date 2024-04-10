local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);


local generic = require(script.Parent.Survivor);
--==
if modBranchConfigs.IsWorld("Safehome") then
	return generic;
	
else
	return function(Player, Dialog, Data)
		
		Dialog:AddChoice("heal_request", function()
			if not Dialog.InRange() then return end;
			modStatusEffects.FullHeal(Player, 0.15);
		end)
	end

end
