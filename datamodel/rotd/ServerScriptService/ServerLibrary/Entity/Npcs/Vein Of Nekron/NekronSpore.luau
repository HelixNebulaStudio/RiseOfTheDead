local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local NekronSpore = {};
NekronSpore.__index = NekronSpore;
NekronSpore.Count = 0;

function NekronSpore.onRequire()
    SPORE_PREFAB = script:WaitForChild("sporePart");
end

function NekronSpore.spawn(origin, veinTargetPart, param)
	NekronSpore.Count = NekronSpore.Count + 1;
	param = param or {};
	
	local self = {
		Cancelled = false;
	};
	
	local hostNpcClass: NpcClass = param.HostNpcClass;
	local incubateTime = param.IncubationTime or 3;
	
	local tweenInfo = TweenInfo.new(incubateTime);
	
	local sporeDestructible: DestructibleInstance = param.SporeDestructible;
	
	local newSporePart = SPORE_PREFAB:Clone();
    
	newSporePart.Transparency = 0;
	newSporePart.Size = Vector3.zero;
	newSporePart.CFrame = CFrame.new(origin);
	newSporePart.Name = `PrimaryPart`;
	newSporePart.CollisionGroup = "Default";
	newSporePart.CanCollide = false;
	newSporePart.Material = Enum.Material.Neon;
	newSporePart:SetAttribute("IgnoreWeaponRay", nil);
	newSporePart.Parent = sporeDestructible.Model;
	sporeDestructible.Model.PrimaryPart = newSporePart;
	
	if param.WeldTo then
		newSporePart.Anchored = false;
		newSporePart.Massless = true;
		
		local weld = Instance.new("Weld");
		weld.Parent = newSporePart;
		weld.Part0 = newSporePart;
		weld.Part1 = param.WeldTo;
		weld.C0 = CFrame.new(param.WeldTo.CFrame:PointToObjectSpace(origin));
	end
	
	TweenService:Create(newSporePart, tweenInfo, {
		Size=Vector3.new(6, 6, 6);
	}):Play();
	
	self.Destroy = function() end;

	task.delay(incubateTime, function()
		if self.Cancelled == true then return end;
		if sporeDestructible.HealthComp.IsDead then return end;

		newSporePart.Color = Color3.fromRGB(77, 34, 34);
		
		local targetPoint = veinTargetPart;
		if veinTargetPart:IsA("BasePart")  then
			targetPoint = veinTargetPart.Position;
		end
		
        local originCf = CFrame.new(origin);
        local projectileInstance: ProjectileInstance = modProjectile.fire("nekronvein", {
            OriginCFrame = originCf;
        });
        local projPart = projectileInstance.Part;
        local projProperties = projectileInstance.Properties;

        projPart.Parent = sporeDestructible.Model;


        local targetDir = (targetPoint-origin).Unit;
		local velocity = targetDir * projectileInstance.ArcTracerConfig.Velocity;

        local veinLaunchCounter = hostNpcClass.Properties.VeinLaunched;
        if veinLaunchCounter == nil then
            veinLaunchCounter = 0;
            hostNpcClass.Properties.VeinLaunched = veinLaunchCounter;
        end
        veinLaunchCounter = veinLaunchCounter +1;
        hostNpcClass.Properties.VeinLaunched = veinLaunchCounter;

		projProperties.Host = hostNpcClass;
		projProperties.NekronVeinSpread = param.NekronSpreadFunc;

		projProperties.OnPlayerStrike = function(player)
			if sporeDestructible.HealthComp.IsDead then return end;

			local playerClass: PlayerClass = shared.modPlayers.get(player);
            local statusComp: StatusComp = playerClass.StatusComp;
			if hostNpcClass.HealthComp:CanTakeDamageFrom(playerClass) == false then return end;

			local nekronsGripStatus: StatusClassInstance = statusComp:GetOrDefault("NekronsGrip");
			if nekronsGripStatus then
				nekronsGripStatus.IsExpired = true;
				nekronsGripStatus:Sync();
			end

			task.wait(0.2);
			if hostNpcClass.HealthComp.IsDead then return end;
			if sporeDestructible.HealthComp.IsDead then return end;

			nekronsGripStatus = statusComp:Apply("NekronsGrip", {
				Expires = workspace:GetServerTimeNow() + 10;
				Duration = 10;
				Values = {
					SporeDestructConfig = sporeDestructible.Config;
				};
			});
			if nekronsGripStatus then
				nekronsGripStatus.Garbage:Tag(function()
					if sporeDestructible.HealthComp.IsDead then return end;
					sporeDestructible.HealthComp:SetIsDead(true);
				end)
			end

			sporeDestructible.OnDestroy:Connect(function()
				local nekronsGripStatus: StatusClassInstance = statusComp:GetOrDefault("NekronsGrip");
				if nekronsGripStatus then
					nekronsGripStatus.IsExpired = true;
					nekronsGripStatus:Sync();
				end

				projectileInstance:Destroy();
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

        modProjectile.serverSimulate(projectileInstance, {
            RayWhitelist = rayWhitelist;
            Velocity = velocity;
        });
	end)
		
	setmetatable(self, NekronSpore);
	
	return self;
end

return NekronSpore;