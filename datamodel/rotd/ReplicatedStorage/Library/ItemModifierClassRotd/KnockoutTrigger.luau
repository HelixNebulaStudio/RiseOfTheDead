local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local modifierPackage = {
	Name = "Knockout Trigger";
	StatusId = "KnockoutRagdollCd";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Binds.WeaponShotBulletHit(modifier: ItemModifierInstance, packet: BulletHitData)
	if RunService:IsClient() then return end;
	-- modifier: {
		-- ["ArrayValues"] = {},
		-- ["BaseValues"] = {},
		-- ["Enabled"] = true,
		-- ["EquipmentClass"] =  ▶ {...},
		-- ["Id"] = "#66:KnockoutTrigger",
		-- ["MaxValues"] = {},
		-- ["MinValues"] = {},
		-- ["OnEnabledChanged"] =  ▶ {...},
		-- ["Priority"] = 1,
		-- ["ProductValues"] = {},
		-- ["SetEnabled"] = "function",
		-- ["SetValues"] =  ▶ {...},
		-- ["SumValues"] = {},
		-- ["Tags"] =  ▶ {...},
		-- ["Values"] = {},
		-- ["WieldComp"] =  ▶ {...}
	-- }
	-- packet: {
		-- ["HitInfo"] =  ▶ {...},
		-- ["OriginPoint"] = 111.875259, -4.04006624, -18.7007599,
		-- ["TargetDistance"] = 27.59324264526367,
		-- ["TargetIndex"] = 0,
		-- ["TargetMaterial"] = Plastic,
		-- ["TargetModel"] = Zombie,
		-- ["TargetNormal"] = -0.0935543329, 0.976323485, -0.195038751,
		-- ["TargetPart"] = LeftUpperArm,
		-- ["TargetPoint"] = 129.76973, -14.2668982, -32.4912148
	-- }
	
	if modifier.Enabled == false then return end;

	local hitInfo = packet.HitInfo;
	if hitInfo == nil then return end;
	if hitInfo.Part == nil or not workspace:IsAncestorOf(hitInfo.Part) then return end;
	if hitInfo.Part.Name ~= "Head" then return end;
	if hitInfo.Index ~= 0 then return end;

	local targetModel = hitInfo.Part.Parent;
	if targetModel == nil then return end;

	local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
	if healthComp == nil or healthComp.IsDead then return end;
	targetModel = healthComp:GetModel();

	local targetClass: CharacterClass = healthComp.CompOwner;
	if targetClass.ClassName ~= "NpcClass" then return end;

	local knockbackResistance = targetClass.Properties.KnockbackResistant or 0;
	if healthComp.CurArmor > 0 or knockbackResistance >= 1 then return end;

	local statusComp: StatusComp? = targetClass.StatusComp;
	if statusComp == nil then return end;

	local knockoutStatusClass: StatusClassInstance? = statusComp:GetOrDefault(modifierPackage.StatusId);
	if knockoutStatusClass then return end;

	if modifier.EquipmentClass == nil then return end;
	local knockoutDuration = modifier.EquipmentClass.Configurations.KnockoutDuration;

	statusComp:Apply(modifierPackage.StatusId, {
		Expires = workspace:GetServerTimeNow() + knockoutDuration;
		Values = {
			Ragdoll = true;
		}
	});
end

return modifierPackage;