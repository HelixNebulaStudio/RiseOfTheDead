local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local Component = {};

function Component.new(self)
	return {
		Begin=function()
			if (self.SpawnPoint.p-self.RootPart.Position).Magnitude <= 16 then
				self.Movement:EndMovement();
				
				self.PlayAnimation("Idle");

				self.Logic:Timeout("Idle", random:NextNumber(5, 10), function()
					self.StopAnimation("Idle");
					self.Movement:IdleMove(16, true);

					self.Logic:Timeout("Idle", random:NextNumber(5, 10), function()
						self.Movement:EndMovement();
					end);
				end)
			else
				self.Movement:Move(self.SpawnPoint.p);
			end
		end;
		Cancel=function()
			self.Movement:EndMovement();
			self.StopAnimation("Idle");
		end;
	};
end

return Component;