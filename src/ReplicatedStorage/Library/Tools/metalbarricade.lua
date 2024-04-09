local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local PhysicsService = game:GetService("PhysicsService");
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function(handler)
	local Structure = {};
	Structure.WaistRotation = math.rad(85);
	Structure.PlaceOffset = CFrame.Angles(0, math.rad(-90), 0);
	
	Structure.Prefab = "metalbarricade";
	Structure.BuildDuration = 1;
	
	function Structure:OnSpawn(prefab)
		if modConfigurations.ExpireDeployables == true then
			Debugger.Expire(prefab, 300);
		end
		
		modAudio.Play("Repair", prefab.PrimaryPart);
		
		local size = prefab:GetExtentsSize();
		local enemyClip = Instance.new("Part");
		enemyClip.Name = "_enemyClip";
		enemyClip.Anchored = true;
		enemyClip.CanCollide = true;
		enemyClip.Transparency = 1;
		enemyClip.Size = Vector3.new(1, size.Y+2, size.Z+0.2);
		enemyClip.CFrame = prefab:GetPrimaryPartCFrame() * CFrame.new(-1, 4, 0);
		enemyClip.Parent = workspace.Clips;
		
		prefab.Destroying:Connect(function()
			enemyClip:Destroy();
		end)
		
		task.spawn(function()
			while enemyClip:IsAncestorOf(workspace) do
				task.wait(math.random(10, 30));
				enemyClip.CanCollide = false;
				task.wait(math.random(1,3));
				enemyClip.CanCollide = true;
			end
		end)
		
		local destructibleObject = require(prefab:WaitForChild("Destructible"));
		--task.spawn(function()
		--	repeat
		--		task.wait(5);
		--		destructibleObject:TakeDamagePackage(modDamagable.NewDamageSource{
		--			Damage = 10;
		--			TargetModel = prefab;
		--			TargetPart = prefab.PrimaryPart;
		--		});
		--	until destructibleObject.Health <= 0;
		--	enemyClip:Destroy();
		--end)
	end
	
	setmetatable(Structure, handler);
	return Structure;
end;
