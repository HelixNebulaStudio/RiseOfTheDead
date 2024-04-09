local random = Random.new();

local Human = {};
function Human.new(self)
	delay(5, function()
		if workspace:FindFirstChild("Interactables") and workspace.Interactables:FindFirstChild("radio") and workspace.Interactables.radio:FindFirstChild("RadioActive") then
			local radioActive = workspace.Interactables.radio.RadioActive;
			radioActive:GetPropertyChangedSignal("Value"):Connect(function()
				if radioActive.Value then
					wait(random:NextNumber(1, 3));
					self.PlayAnimation("Dance");
				else
					self.StopAnimation("Dance");
				end
			end)
		end
	end);
end

return Human;