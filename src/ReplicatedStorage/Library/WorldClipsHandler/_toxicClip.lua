local WorldClip = {};
WorldClip.__index = WorldClip;

local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local clipTouchHandler = modTouchHandler.new("ToxicClips", 5);

WorldClip.Config = {
	Damage = nil;
	DamageRatio = 0.2;
}

function clipTouchHandler:OnHumanoidTouch(humanoid, basePart, touchPart)
	local character = humanoid.Parent;
	local rootPart = humanoid.RootPart;
	
	local skipDmg = false;
	local player = game.Players:GetPlayerFromCharacter(character);
	if player then
		local classPlayer = shared.modPlayers.Get(player);

		classPlayer:SetProperties("Toxic", {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+5.5;
			Duration=5.5;
		});
		
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
				Dealer=self.Prefab;
				DamageType="IgnoreArmor";
			};
			
			damagable:TakeDamagePackage(newDmgSrc);
		end
	end
end

function WorldClip:Load(basePart)
	basePart.Parent = script;
	
	clipTouchHandler:AddObject(basePart);
end

return WorldClip;
