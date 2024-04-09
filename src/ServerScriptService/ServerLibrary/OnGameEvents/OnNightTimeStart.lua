local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modSkillTree = require(game.ServerScriptService.ServerLibrary.SkillTree);


return function(player, storageItem)
	for _, player in pairs(game.Players:GetPlayers()) do
		modSkillTree:TriggerSkills(player, script.Name);
	end
end;
