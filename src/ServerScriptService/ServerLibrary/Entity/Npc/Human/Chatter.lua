local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local Human = {};

function Human.new(self)
	if self.Speeches == nil then return end;
	spawn(function()
		repeat
			if self.Speeches == nil then return end;
			self.Chat(game.Players:GetPlayers(), self.Speeches[random:NextInteger(1, #self.Speeches)]);
		until self == nil or self.IsDead or self.Humanoid.RootPart == nil or not wait(random:NextNumber(480, 600));
	end)
end

return Human;