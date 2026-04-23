local WorldClip = {};
WorldClip.__index = WorldClip;

local CollectionService = game:GetService("CollectionService");

local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

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
		local playerClass: PlayerClass = shared.modPlayers.get(player);

		modStatusEffects.VexBile(player, 5);

		local conGasMask = playerClass.Configurations.GasMask;
		if conGasMask then
			skipDmg = true;
		end
	end

	if skipDmg then return end;

	if rootPart then
		local healthComp: HealthComp? = modHealthComponent.getByModel(character);
		if healthComp then
			-- Calculate damage
			local val = healthComp.MaxHealth * WorldClip.Config.DamageRatio;
			if WorldClip.Config.Damage then
				val = WorldClip.Config.Damage;
			end

			-- Play audio effect
			modAudio.Play("BurnTick"..math.random(1, 3), character.PrimaryPart).PlaybackSpeed = math.random(50,70)/100;

			-- Apply damage
			local dmgData = DamageData.new{
				Damage=val;
				DamageBy=nil;
				TargetModel=character;
				DamageType = "IgnoreArmor";
			};
			healthComp:TakeDamage(dmgData);
		end
	end
end

function WorldClip:Load(basePart)
	basePart.Parent = script;

	clipTouchHandler:AddObject(basePart);
end

return WorldClip;