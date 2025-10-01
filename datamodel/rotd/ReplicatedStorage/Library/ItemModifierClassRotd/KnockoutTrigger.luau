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
	
	-- if hitInfo.Part == nil or not workspace:IsAncestorOf(hitInfo.Part) then return end;
	-- if hitInfo.Part.Name ~= "Head" then return end;
	
	-- local targetModel = hitInfo.Part.Parent;
	-- if not workspace:IsAncestorOf(targetModel) then return end;
	
	-- local damagable = modDamagable.NewDamagable(targetModel);
	-- if damagable == nil then return end;
	
	
	-- local healthInfo = damagable:GetHealthInfo();
	-- local knockbackResistance = 1;
	
	-- if damagable.Object.ClassName == "NpcStatus" then
	-- 	local npcModule = damagable.Object:GetModule();
	-- 	knockbackResistance = npcModule.KnockbackResistant or 0;
		
	-- 	if healthInfo.Armor > 0 or knockbackResistance >= 1 then return end;
		
	-- 	if npcModule.EntityStatus:GetOrDefault("knockoutRagdollCd") then return end;
	-- 	npcModule.EntityStatus:GetOrDefault("knockoutRagdollCd", {
	-- 		Expires=tick()+5;
	-- 	});
		
	-- 	npcModule.EntityStatus:GetOrDefault("knockoutRagdoll", {
	-- 		Ragdoll=true;
	-- 		Expires=tick()+2;
	-- 	});
	-- end
end

return modifierPackage;