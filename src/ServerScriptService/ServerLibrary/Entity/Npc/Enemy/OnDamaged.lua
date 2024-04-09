local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local Enemy = {};

function Enemy.new(self)
	return function(amount, attacker, weaponItem, bodyPart)
		if attacker == nil then return end;
		if self.Weapons == nil then self.Weapons = {} end;
		
		amount = amount and math.ceil(amount) or 0;
		if amount > 0 then
			if attacker.ClassName == "Player" then
				if self.Weapons[attacker.Name] == nil then self.Weapons[attacker.Name] = {} end;
				if weaponItem then
					if self.Weapons[attacker.Name][weaponItem.ID] == nil then self.Weapons[attacker.Name][weaponItem.ID] = {Damaged=0; Weapon=weaponItem} end;
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
			if self.OnTarget then self.OnTarget(attacker); end -- spawn(function() end)
			if self.OnDamagedEvent then self.OnDamagedEvent(attacker:IsA("Player") and attacker.Character or attacker); end
		else
			if weaponItem then
				Debugger:Warn("Attacker (",attacker.Name,") dealt 0 damage with a (", weaponItem.ItemId,")");
			else
				Debugger:Warn("Attacker (",attacker.Name,") dealt 0 damage.");
			end
		end
	end
end

return Enemy;