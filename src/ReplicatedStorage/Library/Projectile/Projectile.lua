local Projectile = {};
Projectile.__index = Projectile;
Projectile.ClassName = "Projectile";

Projectile.MaxDamage = 50000;

function Projectile:Init(player, weaponModule)
	self.Owner = player;
	
	if weaponModule then
		self.WeaponModule = weaponModule;
		
		local metaConfig = self.Configurations;
		self.Configurations = weaponModule.Configurations;
		
		if metaConfig then
			for k, v in pairs(metaConfig) do
				if typeof(v) ~= "table" then
					if self.Configurations[k] == nil then
						self.Configurations[k] = v;
					end
				end
			end
		end
		
		if self.WeaponModule.ArcTracerConfig then
			for k, v in pairs(self.WeaponModule.ArcTracerConfig) do
				self.ArcTracerConfig[k] = v;
			end
		end
		
		self.Properties = weaponModule.Properties;
	end
end

return Projectile;