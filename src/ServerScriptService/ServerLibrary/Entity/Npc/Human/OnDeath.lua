local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Modules
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modExperience = require(game.ServerScriptService.ServerLibrary.Experience);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);
local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);

local Human = {};

function Human.new(self)
	return function(players)
		self:KillNpc();
		--self.Prefab:BreakJoints();
		
		if self.Logic then self.Logic.Cancelled = true; end
		self.DeathPosition = self.RootPart.CFrame.p;
		self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
		if self.StopAllAnimations then self.StopAllAnimations(); end;
		
		if self.Configuration and self.Configuration.Audio and self.Configuration.Audio.Death and self.Configuration.Audio.Death ~= false then
			modAudio.Play(self.Configuration.Audio.Death, self.RootPart).PlaybackSpeed = math.random(10, 12)/10;
		elseif self.Configuration and self.Configuration.Audio and self.Configuration.Audio.Death == false then
		else
			modAudio.Play("HumanDeath", self.RootPart);
		end
		
		if players and #players > 0 then
			modOnGameEvents:Fire("OnNpcDeath", players, self);
		end
		
	end
end

return Human;