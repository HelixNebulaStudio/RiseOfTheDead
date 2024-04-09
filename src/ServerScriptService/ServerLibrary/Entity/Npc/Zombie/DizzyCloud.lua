local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local random = Random.new();

local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local Zombie = {};

local touchHandler = modTouchHandler.new("DizzyCloud", 1);
touchHandler.ScanType = modTouchHandler.ScanTypes.Sphere;
touchHandler.IgnoreTouch = true;
touchHandler.MaxParts = 32;

function touchHandler:WhitelistFunc()
	local rayWhitelist = CollectionService:GetTagged("EntityRootPart") or {};
	for _, playerRoots in pairs(CollectionService:GetTagged("PlayerRootParts")) do
		table.insert(rayWhitelist, playerRoots);
	end
	
	return rayWhitelist;
end

function touchHandler:OnHumanoidTouch(humanoid, basePart, part)
	local targetModel = part.Parent;
	local player = targetModel and game.Players:GetPlayerFromCharacter(targetModel);
	
	if player then
		modStatusEffects.Dizzy(player, 3, "bloater");
		
	else
		local npcStatus = targetModel:FindFirstChild("NpcStatus") and require(targetModel.NpcStatus);
		local npcModule = npcStatus and npcStatus:GetModule();
		
		if npcModule and npcModule.Humanoid and npcModule.Humanoid.Name == "Zombie" and npcModule.Humanoid.Health > 0 
			and npcModule.Properties and npcModule.Properties.BasicEnemy == true then
			
			local ratio = math.clamp(1 - (npcModule.EntityStatus:GetOrDefault("ToxicMod") or 0) , 0, 1);
			
			local newDmgSrc = modDamagable.NewDamageSource{
				Damage=-(npcModule.Humanoid.MaxHealth*0.1 * ratio);
			}
			npcStatus:TakeDamagePackage(newDmgSrc);
			
		end
	end
	
end

local tweenInfo = TweenInfo.new(1);
function Zombie.new(self)
	return function(duration)
		task.spawn(function()
			local folder = workspace.Entities:FindFirstChild("DizzyCloud");
			if folder == nil then
				folder = Instance.new("Folder");
				folder.Name = "DizzyCloud";
				folder.Parent = workspace.Entities;
			end
			
			local selfLevel = (self.Configuration.Level or 1);
			
			local spawnPosition = self.DeathPosition;
			local startSize = 6;
			local baseSize = 32;
			local cloudSize = baseSize;
			
			for _, obj in pairs(folder:GetChildren()) do
				if (obj.Position-self.DeathPosition).Magnitude <= obj.Size.Y+(baseSize/2) then
					spawnPosition = spawnPosition:Lerp(obj.Position, 0.5);
					startSize = cloudSize;
					cloudSize = cloudSize +(baseSize/2);
					game.Debris:AddItem(obj, 1);
				end
			end
			
			local newGasCloud = script:WaitForChild("dizzyCloud"):Clone();
			game.Debris:AddItem(newGasCloud, duration or 10);
			
			newGasCloud.Size = Vector3.new(startSize, startSize, startSize);
			newGasCloud.Position = spawnPosition;
			newGasCloud.Parent = folder;

			TweenService:Create(newGasCloud, tweenInfo, {Size=Vector3.new(baseSize, baseSize, baseSize)}):Play();
			task.wait(1);
			touchHandler:AddObject(newGasCloud);
			TweenService:Create(newGasCloud, TweenInfo.new(duration-1), {Size=Vector3.new(cloudSize, cloudSize, cloudSize)}):Play();
		end)
	end
end

return Zombie;