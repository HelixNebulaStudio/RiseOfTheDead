local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local Zombie = {};

function Zombie.new(self)
	return {
		Begin=function()
			local spawnPoint = self.FakeSpawnPoint or self.SpawnPoint;

			if (spawnPoint.p-self.RootPart.Position).Magnitude <= 32 then
				self.Movement:EndMovement();

				if random:NextInteger(0,10) > 8 then
					self.PlayAnimation("Idle");
					modAudio.Play("ZombieIdle"..random:NextInteger(1, 4), self.RootPart).PlaybackSpeed = random:NextNumber(0.8, 1.2);
				end
				
				self.Logic:Timeout("Idle", random:NextNumber(8, 26), function()
					self.StopAnimation("Idle");
					self.Movement:IdleMove(20);
					
					self.Logic:Timeout("Idle", random:NextNumber(8, 26), function()
						self.Movement:EndMovement();
					end);
				end);
				self.StopAnimation("Idle");
				self.Movement:EndMovement();
				
			else
				self.Movement:Move(spawnPoint.p);

			end
			
		end;
		Cancel=function()
			self.StopAnimation("Idle");
			self.Movement:EndMovement();
		end;
	};
end

return Zombie;