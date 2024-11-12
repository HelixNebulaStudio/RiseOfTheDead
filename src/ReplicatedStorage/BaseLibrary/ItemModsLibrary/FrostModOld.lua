local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

local RunService = game:GetService("RunService");

local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local frostParticle = game.ReplicatedStorage.Particles:WaitForChild("Frost");
local frostTexture = script:WaitForChild("FrostTexture");
local frostSpark = game.ReplicatedStorage.Particles:WaitForChild("FrostSpark");
local iceDecor = script:WaitForChild("IceDecor");

local faces = {Enum.NormalId.Back; Enum.NormalId.Bottom; Enum.NormalId.Front; Enum.NormalId.Left; Enum.NormalId.Right; Enum.NormalId.Top;};

function itemMod.Activate(paramPacket)
	local modStorageItem, toolModule = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	local info = itemMod.Library.Get(modStorageItem.ItemId);
	local values = modStorageItem.Values;
	
	local slowness = itemMod.Library.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["S"], info.Upgrades[1].MaxLevel);
	local duration = itemMod.Library.NaturalInterpolate(info.Upgrades[2].BaseValue, info.Upgrades[2].MaxValue, values["T"], info.Upgrades[2].MaxLevel);

	if paramPacket.TweakStat and info.Upgrades[2].TweakBonus then
		local bonusDuration = info.Upgrades[2].TweakBonus * math.abs(paramPacket.TweakStat/100);

		duration = duration + bonusDuration;
	end
	
	toolModule.Configurations.Element = info.Element;
	toolModule.Configurations.PropertiesOfMod = {
		Slowness = slowness;
		Duration = duration;
	}

	toolModule:SetPrimaryModHook({
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
		local maxStage = 5;
		
		local damagable = modDamagable.NewDamagable(targetModel);

		if damagable and damagable:CanDamage(player) then
			if damagable.Object.ClassName == "NpcStatus" then
				local npcStatus = damagable.Object;

				local npcModule = npcStatus:GetModule();
				local entityStatus = npcModule.EntityStatus;
				
				local isBasicEnemy = npcModule and npcModule.Properties and npcModule.Properties.BasicEnemy == true;
				
				if npcModule then
					local initSpeed = npcModule.Humanoid.WalkSpeed;
					local frostStack = entityStatus:GetOrDefault(statusKey);
					local cache;
					
					if frostStack == nil then
						frostStack = {
							InitTick=tick();
							Tick=tick()-0.3;
							Stacks=0;
							InitialSpeed=initSpeed;
							Cache={};
							SlowValue=initSpeed;
						}
						entityStatus:Apply(statusKey, frostStack);
						cache = frostStack.Cache;
						
						
						local bodyParts = targetModel:GetChildren();
						for a=1, #bodyParts do
							if bodyParts[a]:IsA("BasePart") and bodyParts[a].Name ~= "HumanoidRootPart" and bodyParts[a].Transparency ~= 1 then
								for b=1, #faces do
									local new = frostTexture:Clone();
									new.Face = faces[b];
									new.Parent = bodyParts[a];
									table.insert(cache, new);
								end
								if bodyParts[a].Name == "Head" then
									local newFrostParticle = frostParticle:Clone();
									newFrostParticle.Parent = bodyParts[a];
									table.insert(cache, newFrostParticle);
								end
								if bodyParts[a].Name:find("Foot") then
									local newIceRock = iceDecor:Clone();

									local newVal = Instance.new("ObjectValue");
									newVal.Name = "TargetFoot";
									newVal.Value = bodyParts[a];
									newVal.Parent = newIceRock;

									game.Debris:AddItem(newIceRock, 10);
									table.insert(cache, newIceRock);
								end
							end
						end
						
						frostStack.UpdateEffects = function()
							local stackRatio = 1-math.clamp(frostStack.Stacks/maxStage, 0, isBasicEnemy and 0.9 or 1);
							local t = modMath.MapNum(stackRatio, 1, 0, 1, 0.3);
							
							for a=1, #cache do
								local obj = cache[a];
								
								if obj.Name == "FrostTexture" then

									if frostStack.CompleteTick then
										obj.Transparency = t* math.clamp(frostStack.CompleteTick-tick(), 0, 5)/5;
										obj.Color3 = Color3.fromRGB(255, 255, 255);
										
									else
										obj.Transparency = t + ((tick()-frostStack.Tick)/2)*(1-t);
										obj.Color3 = Color3.fromRGB(181, 235, 255);
										
									end
									

								elseif obj.Name == "IceDecor" then
									local targetFootVal = obj:FindFirstChild("TargetFoot") and obj.TargetFoot;
									if targetFootVal and targetFootVal.Value then
										local footPart = targetFootVal.Value;

										if frostStack.CompleteTick and stackRatio >= 1 then
											obj.Size = footPart.Size*2;
										else
											obj.Size = footPart.Size*0;
										end

										obj.CFrame = footPart.CFrame;
										obj.Parent = workspace.Debris;
									end

								end
								
							end
						end
						
						task.spawn(function()
							repeat
								frostStack = entityStatus:GetOrDefault(statusKey);
								if frostStack == nil then break; end
								
								frostStack.UpdateEffects();
								task.wait(0.2);
								
								if frostStack.CompleteTick then
									if tick() >= frostStack.CompleteTick then
										break;
									end
									
								elseif tick()-frostStack.Tick >= 2 then
									break;
									
								end
							until frostStack == nil;
							
							--if npcModule.AnimationController then npcModule.AnimationController:SetTimescale(1); end
							--if npcModule.Movement then npcModule.Movement:SetWalkSpeed(script.Name, nil); end
							
							for a=1, #cache do
								game.Debris:AddItem(cache[a], 0);
							end
							
							entityStatus:Apply(statusKey, nil);
						end)
					end
					
					if frostStack and tick() - frostStack.Tick >= 0.2 then
						frostStack.Tick = tick();
						frostStack.Stacks = frostStack.Stacks +1;
						
						local currentStack = frostStack.Stacks;
						
						local newParticle = frostSpark:Clone();
						newParticle.Parent = targetPart;
						newParticle:Emit(10);
						game.Debris:AddItem(newParticle, 2);
						modAudio.Play("IceCracks", targetPart).PlaybackSpeed = math.random(90,120)/100;
						
						local stackRatio = 1-math.clamp(currentStack/maxStage, 0, isBasicEnemy and 1 or 0.9); -- 1 to 0
						local slowedWalkSpeed = frostStack.InitialSpeed * stackRatio;

						--if npcModule.AnimationController then
						--	npcModule.AnimationController:SetTimescale(stackRatio);
						--end
						--if npcModule.Movement then
						--	npcModule.Movement:SetWalkSpeed(script.Name, slowedWalkSpeed, 100);
						--end
						
						frostStack.SlowValue=slowedWalkSpeed;
						npcModule.StatusLogic();
						
						if currentStack >= maxStage then
							frostStack.CompleteTick = tick() + (isBasicEnemy and propertiesOfMod.Duration or propertiesOfMod.Duration * 0.15);
							
							task.delay(0.1, function()
								damageSource.Damage=toolModule.Configurations.Damage;
								damageSource.DamageType="FrostDamage";
								damagable:TakeDamagePackage(damageSource);
							end)
						end
						
						frostStack.UpdateEffects();
					end

				end
			end
		end
	end
	
else
	
	
end

return itemMod;