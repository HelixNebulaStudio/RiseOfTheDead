local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Knockout Trigger";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Binds.OnBulletHit(modifier: ItemModifierInstance, packet: OnBulletHitPacket)
    Debugger:StudioLog("KnockoutTrigger OnBulletHit", modifier, packet);
end

return modifierPackage;