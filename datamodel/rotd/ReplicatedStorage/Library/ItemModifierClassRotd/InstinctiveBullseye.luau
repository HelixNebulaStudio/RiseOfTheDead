local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local modifierPackage = {
	Name = "Instinctive Bullseye";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.onRequire()
	if RunService:IsServer() then return end;

	-- function modifierPackage.Binds.WeaponShotBulletHit(modifier: ItemModifierInstance, packet: BulletHitData)

	-- end
end

return modifierPackage;