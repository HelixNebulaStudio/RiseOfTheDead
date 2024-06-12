local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local NekronSpore = {};
NekronSpore.__index = NekronSpore;
NekronSpore.Count = 0;

local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);


local sporePrefab = script:WaitForChild("sporePart");
--==

function NekronSpore.Spawn(origin, veinTargetPart, parent, param)
	NekronSpore.Count = NekronSpore.Count + 1;
	param=param or {};
	
	local self = {
		Prefab=nil;
	};
	
	local hostNpcModule = param.HostNpcModule;
	local incubateTime = param.IncubationTime or 3;
	
	local tweenInfo = TweenInfo.new(incubateTime);
	
	if hostNpcModule.SporeCount == nil then
		hostNpcModule.SporeCount = 0;
	end
	
	local newSpore = sporePrefab:Clone();
	self.Prefab = newSpore;
	newSpore.Transparency = 0;
	newSpore.Size = Vector3.zero;
	newSpore.CFrame = CFrame.new(origin);
	newSpore.Name = "Nekros Spore".. hostNpcModule.SporeCount;
	newSpore.CollisionGroup = "Default";
	newSpore.Parent = parent;
	newSpore.CanCollide = false;
	newSpore.Material = Enum.Material.Neon;
	newSpore:SetAttribute("IgnoreWeaponRay", nil);
	Debugger.Expire(newSpore, 10);
	
	if param.WeldTo then
		newSpore.Anchored = false;
		newSpore.Massless = true;
		
		local weld = Instance.new("Weld");
		weld.Parent = newSpore;
		weld.Part0 = newSpore;
		weld.Part1 = param.WeldTo;
		weld.C0 = CFrame.new(param.WeldTo.CFrame:PointToObjectSpace(origin));
	end
	
	TweenService:Create(newSpore, tweenInfo, {
		Size=Vector3.new(6, 6, 6);
	}):Play();
	
	task.delay(incubateTime, function()
		self.Prefab.Color = Color3.fromRGB(77, 34, 34);
		self.Prefab = nil;
		if self.Cancelled == true then return end;
		
		local targetPoint = veinTargetPart;
		if veinTargetPart:IsA("BasePart")  then
			targetPoint = veinTargetPart.Position;
		end
		
		local projectileObject = modProjectile.Fire("nekronVein", CFrame.new(origin));
		local velocity = (targetPoint-origin).Unit * projectileObject.ArcTracerConfig.Velocity;
		projectileObject.Prefab.Parent = parent;

		projectileObject.OnNewVein = function(_, projPart)
			if hostNpcModule.VeinLaunched == nil then
				hostNpcModule.VeinLaunched = 0;
			end
			hostNpcModule.VeinLaunched = hostNpcModule.VeinLaunched +1;

			local projectileName = "Nekros Vein"..hostNpcModule.VeinLaunched;
			local healthObj = hostNpcModule.CustomHealthbar:Create(projectileName, 100, projPart);

			healthObj.SporeObject = newSpore;
			healthObj.ProjectileObject = projectileObject;

			projPart.Name = projectileName;
		end

		projectileObject.Host = hostNpcModule;
		projectileObject.NekronVeinSpread = param.NekronSpreadFunc;
		projectileObject:OnNewVein(projectileObject.Prefab);

		projectileObject.OnPlayerStrike = function(player, character)
			local classPlayer = shared.modPlayers.Get(player);
			
			if classPlayer.Properties.NekroVeinDeath ~= nil then
				classPlayer.Properties.NekroVeinDeath:Destroy();
			end
			classPlayer.Properties.NekroVeinDeath = projectileObject;
			
			local groundPart, originPosition = classPlayer:CastGroundRay(64);
			if groundPart == nil then
				originPosition = classPlayer.RootPart.Position;
			end
			
			modStatusEffects.AntiGravity(player, 1000);
			
			local originAnchor = Debugger:PointPart(originPosition);
			originAnchor.Transparency = 1;
			originAnchor.Parent = character;

			local oAtt = Instance.new("Attachment");
			oAtt.Parent = originAnchor;

			local rope = Instance.new("RopeConstraint");
			rope.Attachment0 = classPlayer.RootPart.RootRigAttachment;
			rope.Attachment1 = oAtt;
			rope.Visible = false;
			rope.Length = 16;
			rope:SetAttribute("FPIgnore", true);
			rope.Parent = originAnchor;
			Debugger.Expire(originAnchor, 10);
			Debugger.Expire(rope, 10);

			task.spawn(function()
				local damage = classPlayer.Humanoid.MaxHealth * 0.025;

				for a=0, 10, 0.25 do
					hostNpcModule:DamageTarget(character, damage);
					classPlayer.RootPart.AssemblyLinearVelocity = Vector3.new(0, 10, 0);
					task.wait(0.25);
					if self.Cancelled or classPlayer.Humanoid.Health <= 0 or projectileObject.Destroyed == true then
						break;
					end
				end
				
				game.Debris:AddItem(rope, 0);
				game.Debris:AddItem(originAnchor, 0);

				if classPlayer.Properties.NekroVeinDeath == projectileObject then
					modStatusEffects.AntiGravity(player, nil);
					classPlayer.Properties.NekroVeinDeath = nil;
				end
				
			end)
			return true;
		end

		local rayWhitelist = {workspace.Environment:FindFirstChild("Scene");};
		local charactersList = CollectionService:GetTagged("PlayerCharacters");
		if charactersList then 
			for a=1, #charactersList do
				table.insert(rayWhitelist, charactersList[a]);
			end
		end

		modProjectile.ServerSimulate(projectileObject, origin, velocity, rayWhitelist);
	end)
		
	setmetatable(self, NekronSpore);
	
	return self;
end

return NekronSpore;
