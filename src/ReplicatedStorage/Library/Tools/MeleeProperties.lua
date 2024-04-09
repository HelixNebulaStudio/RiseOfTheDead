local MeleeConfigurations = {};
MeleeConfigurations.__index = MeleeConfigurations;
--==

function MeleeConfigurations:Reset()
	for k, _ in pairs(self.Configurations) do self.Configurations[k] = nil; end
	
	self.Configurations.Knockback = self.Configurations.BaseKnockback;
	self.Configurations.Damage = self.Configurations.BaseDamage;
	
	
end

function MeleeConfigurations.new(modMelee)
	modMelee.__index = modMelee;
	modMelee.Class = "Melee";
	
	local self = {
		Configurations = {};
		
		CalculateDps=function(self)
			local dmg = self.Configurations.Damage;
			local rate = self.Configurations.PrimaryAttackSpeed;
			
			if dmg and rate then
				self.Configurations.Dps = dmg/rate;
			end
		end;
	};
	
	modMelee.Configurations.__index = modMelee.Configurations;
	setmetatable(self.Configurations, modMelee.Configurations);
	
	setmetatable(modMelee, MeleeConfigurations)
	setmetatable(self, modMelee);
	self:Reset();
	return self;
end
	

return MeleeConfigurations;
