local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local Component = {};

function Component.new(self)
	return {
		Begin=function()
			if (self.SpawnCFrame.p-self.RootPart.Position).Magnitude <= 16 then
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
				self.Movement:Move(self.SpawnCFrame.p);
			end
		end;
		Cancel=function()
			self.Movement:EndMovement();
			self.StopAnimation("Idle");
		end;
	};
end

return Component;