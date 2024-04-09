local Destructible = require(game.ServerScriptService.ServerLibrary.Destructibles).new(script.Parent);
--== Script;
Destructible.Enabled = true;
Destructible.DamagableBy = {Zombie=true;};

function Destructible.OnDamaged(damage)
	local healthPercent = (Destructible.Health/Destructible.MaxHealth);
	if healthPercent <= 0 then
		for _, obj in pairs(script.Parent:GetDescendants()) do
			if obj:IsA("JointInstance") then
				obj:Destroy();
			end
		end
		game.Debris:AddItem(script.Parent, 60);
	end
end

return Destructible;
