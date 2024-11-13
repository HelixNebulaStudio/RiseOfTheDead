local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

local remoteGenerateArcParticles = modRemotesManager:Get("GenerateArcParticles");

local overlapParams = OverlapParams.new();
overlapParams.FilterType = Enum.RaycastFilterType.Include;
overlapParams.MaxParts = 5;

local Arc = {
	Color = Color3.fromRGB(255, 179, 0);
	Color2 = Color3.new(1, 1, 1);
	Amount = 1;
	Thickness = 0.2;
};
function itemMod.Activate(packet)
	local module = packet.WeaponModule;
	
	local modStorageItem = packet.ModStorageItem;
	local info = itemMod.Library.Get(modStorageItem.ItemId);
	

	local dLayerInfo = itemMod.Library.GetLayer("D", packet);
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end
	
	local tLayerInfo = itemMod.Library.GetLayer("T", packet);
	local tValue, tTweakVal = tLayerInfo.Value, tLayerInfo.TweakValue;
	
	if tTweakVal then
		tValue = tValue + tTweakVal;
	end
	
	tValue = math.ceil(tValue);

	module.Configurations.Element = info.Element;
	module.Configurations.PropertiesOfMod = {
		Targets = tValue;
		DamagePercent = dValue;
	}

	module:SetPrimaryModHook({
		StorageItemID=modStorageItem.ID; 
		Activate=itemMod.ActivateMod;
	}, info);
	
end

if RunService:IsServer() then
	local statusKey = script.Name;
	function itemMod.ActivateMod(damageSource)
		local player = damageSource.Dealer;
		local weaponItem, weaponModel, toolModule = damageSource.ToolStorageItem, damageSource.ToolModel, damageSource.ToolModule;
		local targetModel, targetPart = damageSource.TargetModel, damageSource.TargetPart;
		
		local propertiesOfMod = toolModule.Configurations.PropertiesOfMod;
		
		local targetsHit = 0;

		local function StrikeTarget(originPosition, strikeModel, strikePart, genArc)
			local damagable = modDamagable.NewDamagable(strikeModel);

			if damagable and damagable:CanDamage(player) then
				if damagable.Object.ClassName == "NpcStatus" then
					local npcStatus = damagable.Object;
					local npcModule = npcStatus:GetModule();
					local entityStatus = npcModule.EntityStatus;
					local humanoid = npcStatus.NpcModule.Humanoid;

					if humanoid.Health <= 0 then return end

					local targetImmunity = npcStatus:GetImmunity("ElectricDamage");
					if targetImmunity >= 1 then return end;

					local hitTick = tick();
					local statusTable = entityStatus:GetOrDefault(statusKey);
					if statusTable == nil or hitTick-statusTable >= 1 then
						entityStatus:Apply(statusKey, hitTick);
						
						if targetsHit < propertiesOfMod.Targets then
							task.delay(0.1, function()
								modDamageTag.Tag(strikeModel, player.Character, {
									WeaponItemId=weaponItem.ItemId;
									IsHeadshot=strikePart.Name == "Head" and true or nil;
								});

								local weaponDamage = toolModule.Configurations.PreModDamage;
								local dmgRatio = math.clamp(propertiesOfMod.DamagePercent - 0.02*targetsHit, 0.05, 1);
								local damage = math.max(weaponDamage*dmgRatio, 1);
								
								damageSource.Damage=damage;
								damageSource.DamageType="ElectricDamage";
								damagable:TakeDamagePackage(damageSource);

								local targetPosition = strikePart.Position;
								overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("Enemies");

								if genArc ~= false then
									for _, otherPlayer in pairs(game.Players:GetPlayers()) do
										if otherPlayer == player or otherPlayer:DistanceFromCharacter(originPosition) <= 64 then
											remoteGenerateArcParticles:FireClient(otherPlayer, 0.2, originPosition, targetPosition, Arc.Color, Arc.Color2, Arc.Amount, Arc.Thickness);
										end
									end
								end

								local rootParts = workspace:GetPartBoundsInRadius(targetPosition, 10, overlapParams);
								for a=1, #rootParts do
									local enemyRootPart = rootParts[a];
									local npcPrefab = enemyRootPart.Parent;
									if npcPrefab ~= strikeModel then
										local striked = StrikeTarget(targetPosition, npcPrefab, enemyRootPart);
										if striked == true then break; end;
									end
								end
							end)
						end
						targetsHit = targetsHit +1;
						return true;
					end
				end
			end

			return false;
		end

		if weaponModel.PrimaryPart then
			local striked = StrikeTarget(weaponModel.PrimaryPart.Position, targetModel, targetPart, false);
			if striked == true then
				for _, otherPlayer in pairs(game.Players:GetPlayers()) do
					if otherPlayer ~= player and otherPlayer:DistanceFromCharacter(weaponModel.PrimaryPart.Position) <= 64  then
						remoteGenerateArcParticles:FireClient(otherPlayer, 0.2, weaponModel.PrimaryPart.Position, targetPart.Position, Arc.Color, Arc.Color2, Arc.Amount, Arc.Thickness);
					end
				end
			end
		end
	end
	
else
	local modArcParticles = require(game.ReplicatedStorage.Particles.ArcParticles);
	
	function itemMod.ActivateMod(damageSource)
		local weaponModel, shotData = damageSource.ToolModel, damageSource.ShotData;
		if shotData.Victims then
			for a=1, #shotData.Victims do
				local targetPosition = shotData.Victims[a] and shotData.Victims[a].Object and shotData.Victims[a].Object.Position;
				local arc = modArcParticles.new(shotData.ShotPoint, targetPosition, Arc.Color, Arc.Color2, Arc.Amount, Arc.Thickness);
				task.delay(0.2, function() arc:Destroy(); end);
			end
		end
	end
	
end

return itemMod;