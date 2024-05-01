local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local CollectionService = game:GetService("CollectionService");

--== Modules
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modExperience = require(game.ServerScriptService.ServerLibrary.Experience);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

local Zombie = {};

function Zombie.new(self)
	return function()
		local prefab = self.Prefab;

		self:KillNpc();
		CollectionService:RemoveTag(prefab, "TargetableEntities");
		prefab.Parent = workspace.Entities;
		delay(2, function() prefab:Destroy(); end)
		
		if self.Logic then self.Logic.Cancelled = true; end
		self.DeathPosition = self.RootPart.CFrame.p;
		self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
		if self.StopAllAnimations then self.StopAllAnimations(); end;
		
		modAudio.Play("ZombieDeath4", self.RootPart).PlaybackSpeed = 1;
		

		modOnGameEvents:Fire("OnZombieDeath", self);

		local playerTags = modDamageTag:Get(self.Prefab, "Player");
		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player = playerTag.Player;
			local playerSave = modProfile:Get(player):GetActiveSave();

			if playerSave and playerSave.AddStat then
				playerSave:AddStat("Kills", 1);
			end
		end
	end
end

return Zombie;