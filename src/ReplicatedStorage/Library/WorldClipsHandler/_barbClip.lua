local WorldClip = {};
WorldClip.__index = WorldClip;

local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

local clipTouchHandler = modTouchHandler.new("BarbClips", 0.5, 1);
function clipTouchHandler:OnHumanoidTouch(humanoid, basePart, touchPart)
	local character = humanoid.Parent;
	local rootPart = humanoid.RootPart;

	if rootPart then
		local playerVel = rootPart.Velocity.Magnitude;
		if playerVel > 0 then

			local damagable = modDamagable.NewDamagable(character);
			if damagable then
				if damagable.Object.ClassName == "NpcStatus" then
					local npcModule = damagable.Object:GetModule();
					if npcModule and npcModule.Properties and npcModule.Properties.BasicEnemy ~= true then
						return;
					end
				end
				
				local healthInfo = damagable:GetHealthInfo();
				local val = healthInfo.MaxHealth * 0.01;
				
				local newDmgSrc = modDamagable.NewDamageSource{
					Damage=(val * playerVel);
					Dealer=self.Prefab;
				}
				damagable:TakeDamagePackage(newDmgSrc);
			end
		end
	end

	local player = game.Players:GetPlayerFromCharacter(character);
	if player then
		modStatusEffects.Slowness(player, 14, 2);
	end
end

function WorldClip:Load(basePart)
	basePart.Parent = script;

	basePart.Transparency = 1;
	clipTouchHandler:AddObject(basePart);
end

return WorldClip;
