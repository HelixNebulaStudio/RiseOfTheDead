local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local PhysicsService = game:GetService("PhysicsService");
local modAudio = require(game.ReplicatedStorage.Library.Audio);

return function(handler)
	local Structure = {};
	Structure.WaistRotation = math.rad(0);
	Structure.PlaceOffset = CFrame.Angles(0, math.rad(-90), 0);
	
	Structure.Prefab = "snowman";
	Structure.BuildDuration = 1;
	
	function Structure:OnSpawn(prefab)
		modAudio.Play("Repair", prefab.PrimaryPart);
		local humanoid = prefab:WaitForChild("Structure");
		humanoid.Parent = nil;
		
		prefab.Name = self.Player.Name.."'s Snowman";
		local rootPart = prefab:WaitForChild("root");
		rootPart.Name = "HumanoidRootPart";
		
		humanoid.Parent = prefab;
		
		local appearance = self.Player:FindFirstChild("Appearance");
		local head = prefab:FindFirstChild("Head");
		if appearance and head then
			for _, accessory in pairs(appearance:GetChildren()) do
				local attachment = accessory:FindFirstChildWhichIsA("Attachment", true);
				
				if attachment and head:FindFirstChild(attachment.Name) then
					local new = accessory:Clone();
					new.Parent = prefab;
				end
			end
		end
		if head then
			head.CollisionGroup = "Debris";
		end
		
		local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
		spawn(function()
			repeat
				humanoid.Health = humanoid.Health -0.2;
				modNpc.AttractEnemies(prefab, 64, function(modNpcModule)
					local isZombie = modNpcModule.Humanoid and modNpcModule.Humanoid.Name == "Zombie";
					local isBasicEnemy = modNpcModule.Properties and modNpcModule.Properties.BasicEnemy == true;

					return isZombie and isBasicEnemy;
				end);
			until humanoid.Health <= 0 or not wait(1);
		end)
	end
	
	setmetatable(Structure, handler);
	return Structure;
end;