local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local CollectionService = game:GetService("CollectionService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local fireTouchHandler = modTouchHandler.new("FireObjects", 1);

function fireTouchHandler:WhitelistFunc()
	local whitelist = {workspace.Entity; workspace.Interactables}; --workspace.Environment; 
	for _, player in pairs(game.Players:GetPlayers()) do
		if player and player.Character then
			table.insert(whitelist, player.Character);
		end
	end
	
	for _, obj in pairs(CollectionService:GetTagged("Flammable")) do
		table.insert(whitelist, obj);
	end
	
	return whitelist;
end

local remotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = remotes.IsInDuel;

local fireParticle = game.ReplicatedStorage.Particles.Fire2;
--== Script;
local Flammable = {};
Flammable.__index = Flammable;

function Flammable:Ignite(part)
	if not CollectionService:HasTag(part, "Flammable") then return end;
	
	CollectionService:RemoveTag(part, "Flammable");
	
	local newFire = fireParticle:Clone();
	newFire.Parent = part;
	
	if math.random(1, 2) == 1 then
		local sound = modAudio.Play("Fire", part, true);
		sound.Volume = math.random(1, 3)/10;
	end;
	
	fireTouchHandler:AddObject(part);
end

function Flammable:FireDamage(target, basePart, hitPart)
	local ownerName = basePart:GetAttribute("Owner") or "";
	local fireOwner = game.Players:FindFirstChild(ownerName); 
	
	local targetModel = hitPart.Parent;

	local damagable = modDamagable.NewDamagable(targetModel);
	
	if damagable == nil then return end;

	local player = game.Players:GetPlayerFromCharacter(targetModel);
	if fireOwner and player == fireOwner then

	elseif damagable:CanDamage(fireOwner) then
		modDamageTag.Tag(targetModel, fireOwner and fireOwner.Character);

		local damage = 1;
		
		if damagable.Object.ClassName == "NpcStatus" then
			local healthInfo = damagable:GetHealthInfo();

			local npcModule = damagable.Object:GetModule() or nil;
			if npcModule and npcModule.Infector == true then
				damage = healthInfo.MaxHealth*0.05;
				
			else
				damage = math.clamp(healthInfo.MaxHealth*0.05, 35, 5000);
				
			end

			local dmgMulti = modConfigurations.TargetableEntities[damagable.HealthObj.Name];
			damage = damage*dmgMulti;

		elseif damagable.Object.ClassName == "PlayerClass" then
			modStatusEffects.Burn(damagable.Object:GetInstance(), 35, 5);

		end

		damagable:TakeDamagePackage(modDamagable.NewDamageSource{
			Dealer=fireOwner;
			Damage=damage;
			ToolStorageItem=self.StorageItem;
			TargetPart=hitPart;
			DamageType="FireDamage";
		});
	end
end

function fireTouchHandler:OnPlayerTouch(player, basePart, part)
	Flammable:FireDamage(player, basePart, part);
end

function fireTouchHandler:OnHumanoidTouch(humanoid, basePart, part)
	Flammable:FireDamage(humanoid, basePart, part);
end

function fireTouchHandler:OnPartTouch(basePart, part)
	if part.Name == "_Water" and part:IsDescendantOf(workspace.Debris) then game.Debris:AddItem(basePart, 0); return end;
	if part and CollectionService:HasTag(part, "Flammable") then
		Flammable:Ignite(part);
	end
end

return Flammable;
