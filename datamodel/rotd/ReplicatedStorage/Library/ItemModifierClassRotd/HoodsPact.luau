local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modifierPackage = {
	Name = "HoodsPact";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.onRequire()
	if RunService:IsClient() then return end;

	function modifierPackage.Binds.CharacterClassTakenDamage(modifier: ItemModifierInstance, damageData: DamageData)
		local characterClass: CharacterClass? = (modifier.WieldComp and modifier.WieldComp.CompOwner or nil) :: CharacterClass;
		if characterClass == nil then return end;

		local damageBy: CharacterClass = damageData.DamageBy :: CharacterClass;
		if damageBy == nil
		or damageBy.ClassName ~= "NpcClass"
		or not damageBy.HealthComp:CanTakeDamageFrom(characterClass)
		or damageBy.HumanoidType ~= "Zombie" then
			return;
		end;

		local lastSpawnTick = modifier.Properties.LastCultistSpawnTick;
		if lastSpawnTick and workspace:GetServerTimeNow() < lastSpawnTick then
			return;
		end
		modifier.Properties.LastCultistSpawnTick = workspace:GetServerTimeNow() + 15;

		shared.modNpcs.spawn2{
			Name = "Cultist";
			CFrame = characterClass:GetCFrame();
			Player = characterClass.ClassName == "PlayerClass" and (characterClass :: PlayerClass):GetInstance() or nil;
			BindSetup = function(npcClass: NpcClass)
				npcClass.HealthComp:SetCanBeHurtBy("!Player");

				local targetHandlerComp = npcClass:GetComponent("TargetHandler");
				targetHandlerComp:AddTarget(damageBy.Character);

				task.spawn(function()
					(npcClass.Character:WaitForChild("Hood"):WaitForChild("Handle") :: BasePart).Color = Color3.fromRGB(70, 102, 101);
				end)

				local timeSinceLastTarget = nil;
				npcClass.OnThink:Connect(function()
					local curTarget = npcClass.Properties.EnemyTargetData;
					if curTarget then
						timeSinceLastTarget = nil;
					else
						if timeSinceLastTarget then
							if tick()-timeSinceLastTarget > 10 then
								npcClass.Character:Destroy();
							end
						else
							timeSinceLastTarget = tick();
							if tick()-npcClass.SpawnTime > 60 then
								npcClass.Character:Destroy();
							end
						end
					end
					if tick()-npcClass.SpawnTime > 60*3 then
						npcClass.Character:Destroy();
					end
				end)

				local attractNpcsComp = npcClass:GetComponent("AttractNpcs");
				if attractNpcsComp then
					attractNpcsComp.AttractHumanoidType = {"Zombie"};
					attractNpcsComp.SelfAttractAlert = true;
					attractNpcsComp:Activate();
				end

			end;
		};
	end
end

return modifierPackage;