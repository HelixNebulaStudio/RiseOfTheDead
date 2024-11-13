local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

local RunService = game:GetService("RunService");

local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local toxinTexture = script:WaitForChild("ToxinTexture");

local faces = {Enum.NormalId.Back; Enum.NormalId.Bottom; Enum.NormalId.Front; Enum.NormalId.Left; Enum.NormalId.Right; Enum.NormalId.Top;};


function itemMod.Activate(packet)
	local module = packet.WeaponModule;
	local modStorageItem = packet.ModStorageItem;

	local info = itemMod.Library.Get(modStorageItem.ItemId);

	local rLayerInfo = itemMod.Library.GetLayer("R", packet);
	local rValue, rTweakVal = rLayerInfo.Value, rLayerInfo.TweakValue;

	if rTweakVal then
		rValue = rValue + rTweakVal;
	end
	
	local tLayerInfo = itemMod.Library.GetLayer("T", packet);
	local tValue, tTweakVal = tLayerInfo.Value, tLayerInfo.TweakValue;

	if tTweakVal then
		tValue = tValue + tTweakVal;
	end
	
	module.Configurations.Element = info.Element;
	module.Configurations.PropertiesOfMod = {
		Reduction = rValue;
		Duration = tValue;
	}

	module:SetPrimaryModHook({
		StorageItemID=modStorageItem.ID; 
		Activate=itemMod.ActivateMod;
	}, info);
	
	--local modStorageItem, toolModule = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local reduction = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["R"], info.Upgrades[1].MaxLevel);
	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local bonusReduction = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	reduction = reduction + bonusReduction;
	--end
	
	
	--local duration = ModsLibrary.NaturalInterpolate(info.Upgrades[2].BaseValue, info.Upgrades[2].MaxValue, values["T"], info.Upgrades[2].MaxLevel);
	--if paramPacket.TweakStat and info.Upgrades[2].TweakBonus then
	--	local bonusDuration = info.Upgrades[2].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	duration = duration + bonusDuration;
	--end

	--toolModule.Configurations.Element = info.Element;
	--toolModule.Configurations.PropertiesOfMod = {
	--	Reduction = reduction;
	--	Duration = duration;
	--}

	--toolModule:SetPrimaryModHook({
	--	StorageItemID=modStorageItem.ID; 
	--	Activate=Mod.ActivateMod;
	--}, info);
end


if RunService:IsServer() then
	function itemMod.OnActivate(toolHandler)
		local modLib = itemMod.Library.Get("toxicmod");
		
		local toxicEmitter = script.ToxicEmitter;
		for _, prefab in pairs(toolHandler.Prefabs) do
			local muzzleOrigin = prefab:FindFirstChild("MuzzleOrigin", true);
			if muzzleOrigin == nil then continue end;
			
			for _, obj in pairs(muzzleOrigin:GetChildren()) do
				if obj.Name ~= toxicEmitter.Name then continue end;
				obj:Destroy();
			end
			
			local newEmitter = toxicEmitter:Clone();
			newEmitter.Parent = muzzleOrigin;
			Debugger.Expire(newEmitter, modLib.ActivationDuration);
		end
	end
	
	local statusKey = script.Name;
	function itemMod.ActivateMod(damageSource)
		local player = damageSource.Dealer;
		local weaponItem, weaponModel, toolModule = damageSource.ToolStorageItem, damageSource.ToolModel, damageSource.ToolModule;
		local targetModel, targetPart = damageSource.TargetModel, damageSource.TargetPart;

		local propertiesOfMod = toolModule.Configurations.PropertiesOfMod;
		local configurations = toolModule.Configurations;
		local preModDamage = configurations.PreModDamage;
		
		local bonusDmgRatio = itemMod.Library.NaturalInterpolate(0.05, 0.25, weaponItem.Values["R"], 10, 1.25);

		local damagable = modDamagable.NewDamagable(targetModel);

		if damagable and damagable:CanDamage(player) then
			if damagable.Object.ClassName == "NpcStatus" then
				local npcStatus = damagable.Object;

				if npcStatus then
					local npcModule = npcStatus:GetModule();
					local entityStatus = npcModule.EntityStatus;

					local statusTable = entityStatus:GetOrDefault(statusKey);
					if statusTable == nil then
						entityStatus:Apply(statusKey, propertiesOfMod.Reduction);

						if npcModule and npcModule.Prefab then
							local bodyParts = npcModule.Prefab:GetChildren();
							for a=1, #bodyParts do
								if bodyParts[a]:IsA("BasePart") and bodyParts[a].Name ~= "HumanoidRootPart" and bodyParts[a].Transparency ~= 1 then
									for b=1, #faces do
										local new = toxinTexture:Clone();
										new.Face = faces[b];
										new.Parent = bodyParts[a];
										Debugger.Expire(new, propertiesOfMod.Duration);
									end
								end
							end
						end

						pcall(function() 
							task.wait(propertiesOfMod.Duration);
							entityStatus:Apply(statusKey);
						end)
					end
					
				end
			end
		end
	end
	
else
	function itemMod.ActivateMod(damageSource)
		local weaponModel = damageSource.ToolModel;
		if weaponModel == nil then return end;

		local toxicEmitter = weaponModel.PrimaryPart:FindFirstChild(script.ToxicEmitter.Name, true);
		if toxicEmitter then
			toxicEmitter:Emit(32);
		end
	end
	
	
end

return itemMod;