local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);

local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;

function Component.new(npcClass: NpcClass)
	local self = {
		NpcClass = npcClass;
	};
	
	setmetatable(self, Component);
	return self;
end

function Component:__call(explosionPoint, explosionDamage, explosionRadius)
	local npcClass: NpcClass = self.NpcClass;
	local properties = npcClass.Properties;

	local projectileInstance: ProjectileInstance = modProjectile.fire("arcbomb", {
		CharacterClass = npcClass;
		OriginCFrame = CFrame.new(explosionPoint);
		Properties = {
			Damage = explosionDamage;
			Radius = explosionRadius*2;
		}
	});
end

return Component;