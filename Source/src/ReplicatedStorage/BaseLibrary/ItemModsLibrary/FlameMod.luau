local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modItemModifierClass = require(game.ReplicatedStorage.Library.ItemModifierClass);

local modHealthComp = require(game.ReplicatedStorage.Components.HealthComponent);

local ItemModifier: ItemModifier = modItemModifierClass.new(script);
local statusKey = "IncendiaryRounds";
--

function ItemModifier.Update(modifier: ItemModifierInstance)
	local dLayerInfo = ItemModifier.Library.calculateLayer(modifier, "D");
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end

	local tLayerInfo = ItemModifier.Library.calculateLayer(modifier, "T");
	local tValue, tTweakVal = tLayerInfo.Value, tLayerInfo.TweakValue;
	if tTweakVal then
		tValue = tValue + tTweakVal;
	end

	modifier.Values = {
		Damage = dValue;
		Duration = tValue;
	};
end

if RunService:IsServer() then
	ItemModifier:Hook("OnBulletHit", function(modifier: ItemModifierInstance, packet: OnBulletHitPacket)
		local duration = modifier.Values.Duration;

		local playerClass: PlayerClass;
		if modifier.Player then
			playerClass = shared.modPlayers.Get(modifier.Player);
		end
		local characterClass: CharacterClass = playerClass;
		
		local healthComp: HealthComp = modHealthComp.getFromModel(packet.TargetModel);
		if healthComp == nil or not healthComp:CanTakeDamageFrom(characterClass) then return end;

		if healthComp.OwnerClass.ClassName == "NpcClass" then
			local npcClass: NpcClass = healthComp.OwnerClass :: NpcClass;
			local statusComp: StatusComp = npcClass.StatusComp;
			
			local targetImmunity = npcClass.Status:GetImmunity("FireDamage"); 
			if targetImmunity >= 1 then return end;

			local fireTickStatus: StatusClassInstance = statusComp:GetOrDefault(statusKey);
			if fireTickStatus then
				fireTickStatus.Expires = workspace:GetServerTimeNow() + duration;
				fireTickStatus.Values.Stacks = fireTickStatus.Values.Stacks +1;

				return;
			end

			statusComp:Apply(statusKey, {
				Expires = workspace:GetServerTimeNow() + duration;
				Values = {
					ApplyBy = characterClass;

					Damage = modifier.Values.Damage;
					Stacks = 0;
					TargetPart = packet.TargetPart;
				};
			});

		elseif healthComp.OwnerClass.ClassName == "Destructible" then
			--MARK: TODO; add to destructible status comp;
			local targetPart = packet.TargetPart;
			if CollectionService:HasTag(targetPart, "Flammable") then
				local modFlammable = Debugger:Require(game.ServerScriptService.ServerLibrary.Flammable);
				modFlammable:Ignite(targetPart);
			end
			
		end	
	end)
end

return ItemModifier;
