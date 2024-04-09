local WorldClip = {};
WorldClip.__index = WorldClip;

local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

function WorldClip:Load(basePart)
	basePart.Transparency = 1;
	
	basePart.Touched:Connect(function(hitPart: BasePart)
		local humanoid = hitPart.Parent:FindFirstChildWhichIsA("Humanoid");
		if humanoid == nil then return end;
		
		if hitPart.AssemblyRootPart ~= humanoid.RootPart then return end;
		
		local character = humanoid.Parent;
		
		local damagable = modDamagable.NewDamagable(character);
		if damagable then
			local healthInfo = damagable:GetHealthInfo();

			local newDmgSrc = modDamagable.NewDamageSource{
				Damage=healthInfo.MaxHealth;
				Dealer=modDamagable.Dealer;
				DamageType="IgnoreArmor";
			}
			damagable:TakeDamagePackage(newDmgSrc);
		end
	end)
	
end

return WorldClip;
