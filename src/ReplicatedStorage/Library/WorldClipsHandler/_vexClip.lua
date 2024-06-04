local WorldClip = {};
WorldClip.__index = WorldClip;

local CollectionService = game:GetService("CollectionService");

local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local clipTouchHandler = modTouchHandler.new("VexClips", 2);

clipTouchHandler.WhitelistFunc = function()
	return CollectionService:GetTagged("PlayerRootParts");
end

WorldClip.Config = {
	Damage = nil;
	DamageRatio = 0.1;
}

function clipTouchHandler:OnHumanoidTouch(humanoid, basePart, touchPart)
	local character = humanoid.Parent;
	local rootPart = humanoid.RootPart;
	
	local skipDmg = false;
	local player = game.Players:GetPlayerFromCharacter(character);
	if player then
		local classPlayer = shared.modPlayers.Get(player);
		
		modStatusEffects.VexBile(player, 5);
		
		local gasMaskProtection = classPlayer:GetBodyEquipment("GasMask");
		if gasMaskProtection then
			skipDmg = true;
		end
	end
	
	if skipDmg then return end;
	
	if rootPart then
		local damagable = modDamagable.NewDamagable(character);
		if damagable then
			local healthInfo = damagable:GetHealthInfo();
			
			local val = healthInfo.MaxHealth * WorldClip.Config.DamageRatio;
			if WorldClip.Config.Damage then
				val = WorldClip.Config.Damage;
			end
			
			local newDmgSrc = modDamagable.NewDamageSource{
				Damage=val;
				Dealer=character.PrimaryPart;
				DamageType="IgnoreArmor";
			};

			modAudio.Play("BurnTick"..math.random(1, 3), character.PrimaryPart).PlaybackSpeed = math.random(50,70)/100;
			
			damagable:TakeDamagePackage(newDmgSrc);
		end
	end
end

function WorldClip:Load(basePart)
	basePart.Parent = script;
	
	clipTouchHandler:AddObject(basePart);
end

return WorldClip;