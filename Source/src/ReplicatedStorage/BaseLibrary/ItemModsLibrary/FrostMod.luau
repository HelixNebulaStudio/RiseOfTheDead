local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = require(game.ReplicatedStorage.Library.ItemModifierClass);
local modHealthComp = require(game.ReplicatedStorage.Components.HealthComponent);

local ItemModifier: ItemModifier = modItemModifierClass.new(script);
local statusKey = "Frostbite";
--

function ItemModifier.Update(modifier: ItemModifierInstance)
	local sLayerInfo = ItemModifier.Library.calculateLayer(modifier, "S");
	local sValue, sTweakVal = sLayerInfo.Value, sLayerInfo.TweakValue;
	if sTweakVal then
		sValue = sValue + sTweakVal;
	end

	local tLayerInfo = ItemModifier.Library.calculateLayer(modifier, "T");
	local tValue, tTweakVal = tLayerInfo.Value, tLayerInfo.TweakValue;
	if tTweakVal then
		tValue = tValue + tTweakVal;
	end

	modifier.Values = {
		Radius = sValue;
		Targets = tValue;
	}

end


if RunService:IsServer() then
	ItemModifier:Hook("OnBulletHit", function(modifier: ItemModifierInstance, packet: OnBulletHitPacket)
		local playerClass: PlayerClass;
		if modifier.Player then
			playerClass = shared.modPlayers.Get(modifier.Player);
		end
		local characterClass: CharacterClass = playerClass;
		
		local healthComp: HealthComp = modHealthComp.getFromModel(packet.TargetModel);
		if healthComp == nil or not healthComp:CanTakeDamageFrom(characterClass) then return end;
	
		if modifier.Values.Counter > 1 then
			modifier.Values.Counter = modifier.Values.Counter -1;
			modifier:Sync({"Counter"});
			return;
		else
			modifier.Values.Counter = 5;
			modifier:Sync({"Counter"})
		end

		local configurations = modifier.EquipmentClass and modifier.EquipmentClass.Configurations;

		if healthComp.OwnerClass.ClassName == "NpcClass" then
			local npcClass: NpcClass = healthComp.OwnerClass :: NpcClass;

			local targetImmunity = npcClass:GetImmunity("FrostDamage");
			if targetImmunity >= 1 then return end;

			local statusComp: StatusComp = npcClass.StatusComp;
			
			local frostbiteStatusClass: StatusClassInstance = statusComp:GetOrDefault(statusKey);
			if frostbiteStatusClass == nil then
				statusComp:Apply(statusKey, {
					Expires = workspace:GetServerTimeNow() + 5;
					Values = {
						ApplyBy = characterClass;

						Damage = configurations.Damage; 
						Radius = modifier.Values.Radius;
						Targets = modifier.Values.Targets;
					};
				});
			end

		end; 
	end)
	

elseif RunService:IsClient() then
	ItemModifier:Hook("OnWeaponRender", function(modifier: ItemModifierInstance, toolStatusHud: anydict)
		if modifier.Enabled == false then return end;

		if toolStatusHud.Frostbite == nil then
			toolStatusHud.Frostbite = {
				ModItemId = "frostmod";
				Order=1;
			};
		end

		local frostbiteHudData = toolStatusHud.Frostbite;
		frostbiteHudData.Text = `{frostbiteHudData.Counter}`;
		frostbiteHudData.ColorPercent = frostbiteHudData.Counter/5;

	end);

end

return ItemModifier;