local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Modules
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

local Human = {};

function Human.new(self)
	return function()
		self:KillNpc();
		
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
		
		modOnGameEvents:Fire("OnNpcDeath", self);
	end
end

return Human;