local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Zombie = {};

function Zombie.new(self)
	return function(amount, attacker, weaponItem, bodyPart)
		if attacker == nil then return end;
		if self.Weapons == nil then self.Weapons = {} end;
		
		Debugger:StudioLog("Attacker (",attacker.Name,") dealt",amount,"damage with a (",weaponItem and weaponItem.ItemId or "nil",")");
		
		amount = amount and math.ceil(amount) or 0;
		if amount > 0 then
			if attacker and attacker.Name and attacker == game.Players:FindFirstChild(attacker.Name) then
				if self.Weapons[attacker.Name] == nil then self.Weapons[attacker.Name] = {} end;
				if weaponItem then
					if self.Weapons[attacker.Name][weaponItem.ID] == nil then 
						self.Weapons[attacker.Name][weaponItem.ID] = {
							Damaged=0; 
							Weapon=weaponItem
						};
					end;
					self.Weapons[attacker.Name][weaponItem.ID].Damaged = self.Weapons[attacker.Name][weaponItem.ID].Damaged + amount;
				end
			end
			
			if self.Enemies then
				for a=#self.Enemies, 1, -1 do
					if self.Enemies[a] and self.Enemies[a].Character and self.Enemies[a].Character.Name == attacker.Name then
						self.Enemies[a].DamageDealt = self.Enemies[a].DamageDealt + amount;
						break;
					end
				end
			end
			
			if self.OnTarget then
				task.spawn(self.OnTarget, attacker);
			end
		else
			Debugger:StudioLog("Attacker (",attacker.Name,") dealt 0 damage with a (",weaponItem and weaponItem.ItemId or "nil",")");
		end
	end
end

return Zombie;