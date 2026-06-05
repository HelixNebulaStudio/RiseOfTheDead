local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local npcPackage = {
    Name = "Vein Of Nekron";
    HumanoidType = "Zombie";
    
	Configurations = {
        MaxHealth = 100;
    };
    Properties = {
        BasicEnemy = false;
        IsHostile = true;
        SkipMoveInit = true;
        HordeAggression = true;

        TargetableDistance = 512;

        Level = 1;
        BaseExperience = 1000;
        MoneyReward = NumberRange.new(5000, 5500);

        KnockbackResistant = 1;

        SporeCount = 0;
        VeinLaunched = 0;
		
        ThornResist = 0.95;
    };

    AddComponents = {
        "TargetHandler";
        "BodyDestructibles";
    };
    AddBehaviorTrees = {
        "HasEnemy";
    };
    
    ThinkCycle = 0.1;
};

function npcPackage.onRequire()
    PLAQUE_PREFAB = script:WaitForChild("Plaque");
    MOLD_TEXTURE = script:WaitForChild("Mold");

    local overlapParams = OverlapParams.new();
    overlapParams.MaxParts = 64;
    overlapParams.FilterType = Enum.RaycastFilterType.Include;
    overlapParams.FilterDescendantsInstances = {workspace.Environment:FindFirstChild("Scene")};

end

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<anydict> = npcClass.Properties;
    local healthComp = npcClass.HealthComp;
    local rootPart = npcClass.RootPart;

    local isHard = properties.HardMode;
    local level = math.max(properties.Level, 0);

    local baseHealth = 204800; if RunService:IsStudio() then baseHealth = 10000 end;
    configurations.BaseValues.BaseHealth = baseHealth;
    local baseMaxHealth = 4000000; if RunService:IsStudio() then baseMaxHealth = 40000 end;
    configurations.BaseValues.BaseMaxHealth = baseMaxHealth;

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(baseMaxHealth, 100);
        configurations.BaseValues.AttackDamage = 10;
    else
        configurations.BaseValues.MaxHealth = math.max(baseMaxHealth, 100);
        configurations.BaseValues.AttackDamage = 5;
    end

    local veinModel = Instance.new("Model");
    veinModel.Name = `VeinModel`;
    veinModel.Parent = npcClass.Character;
    properties.VeinModel = veinModel;
    

    local taggedObjects = {};
    local sporeObjects = {}; properties.SporeObjects = sporeObjects;
    local plaqueObjects = {};

    npcClass.Garbage:Tag(function()
        for a=#taggedObjects, 1, -1 do
			local part = taggedObjects[a];
			pcall(function()
				if part and part:GetAttribute("VeinOfNekronInfected") then
					for _, obj in pairs(part:GetChildren()) do
						if obj.Name == "VeinOfNekronSpread" then
							obj:Destroy();
							
						end
					end
					
					part:SetAttribute("VeinOfNekronInfected", nil);
					part:SetAttribute("RootVeinOfNekron", nil);
				end
			end)
			taggedObjects[a] = nil;
			
			if math.fmod(a, 10) == 0 then
				task.wait();
			end
		end
		table.clear(taggedObjects);
		
		for a=1, #sporeObjects do
			if sporeObjects[a] then
				sporeObjects[a].Cancelled = true;
			end
		end
		table.clear(sporeObjects);
		table.clear(plaqueObjects);
    end)
    
    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

	--MARK: Plaque Spread
    function properties.Spread(spawnOnPart)
        if healthComp.IsDead then return end;
        
		if spawnOnPart.Anchored == false then return end;

		local isInfectedTick = spawnOnPart:GetAttribute("VeinOfNekronInfected");
		if isInfectedTick and tick()-isInfectedTick < 60 then return end
		if spawnOnPart.Size.Magnitude >= 200 then return end;
		
		spawnOnPart:SetAttribute("VeinOfNekronInfected", tick());
		table.insert(taggedObjects, spawnOnPart);
		
		if #taggedObjects >= 16 then
			local part = table.remove(taggedObjects, 1);
			if part and part:GetAttribute("VeinOfNekronInfected") then
				for _, obj in pairs(part:GetChildren()) do
					if obj.Name == "VeinOfNekronSpread" then
						obj:Destroy();
					end
				end
				
				part:SetAttribute("VeinOfNekronInfected", nil);
				part:SetAttribute("RootVeinOfNekron", nil);
			end
		end
		
		local size = spawnOnPart.Size.Magnitude;
		
		for _, side in pairs(Enum.NormalId:GetEnumItems()) do
			local newTexture = MOLD_TEXTURE:Clone();
			newTexture.Name = "VeinOfNekronSpread";
			
			newTexture.Face = side;
			newTexture.Parent = spawnOnPart;
			
			task.spawn(function()
				for t=1, 0.35, -((1-0.35)/10) do
					newTexture.Transparency = t;
					task.wait(size/100);
					if healthComp.IsDead then return end;
				end
			end)
			
			game.Debris:AddItem(newTexture, 300);
		end
		
		local timelapsed = (tick()-npcClass.SpawnTime);
		if timelapsed <= 10 then return end;

		if spawnOnPart.ClassName == "Part" and spawnOnPart.Shape == Enum.PartType.Block and size >= 5 then
			local axis = {Vector3.xAxis; Vector3.zAxis; -Vector3.xAxis; -Vector3.zAxis; Vector3.yAxis; -Vector3.yAxis;};
			
			for p=1, #axis do
				local randomAxis = axis[p];
				
				local surfaceSize;
				
				if randomAxis.X ~= 0 then
					surfaceSize = Vector3.new(spawnOnPart.Size.Z, spawnOnPart.Size.Y, 0);
					
				elseif randomAxis.Y ~= 0 then
					surfaceSize = Vector3.new(spawnOnPart.Size.Z, spawnOnPart.Size.X, 0);
					
				elseif randomAxis.Z ~= 0 then
					surfaceSize = Vector3.new(spawnOnPart.Size.X, spawnOnPart.Size.Y, 0);
					
				end
				
				local ratio = math.max(surfaceSize.X/surfaceSize.Y, surfaceSize.Y/surfaceSize.X);
				
				if not (ratio <= 4 and size >= 7 and surfaceSize.X >= 4 and surfaceSize.Y >= 4) then continue end;
				-- pick this randomAxis;

				local visibleRayParam = RaycastParams.new();
				visibleRayParam.IncludeInstances = {workspace.Environment; workspace.Terrain};
				local excludeList = {};
				visibleRayParam.ExcludeInstances = excludeList;

				local surfaceCf = spawnOnPart.CFrame * CFrame.new(spawnOnPart.Size/2 * randomAxis);

				local isSurfaceVisible = false;
				for _, player in pairs(game.Players:GetPlayers()) do
					if player.Character == nil then continue end;

					for a=1, 8 do
						local tarPos = player.Character:GetPivot().Position + Vector3.new(0, 1.5, 0);
						local checkDir = (surfaceCf.Position-tarPos);

						local ray = Ray.new(surfaceCf.Position, checkDir);
						local raycastResult = workspace:Raycast(ray.Origin, ray.Direction, visibleRayParam);
						
						-- local dbRay = Debugger:Ray(
						-- 	ray, 
						-- 	raycastResult and raycastResult.Instance,
						-- 	raycastResult and raycastResult.Position,
						-- 	raycastResult and raycastResult.Normal
						-- );
						-- dbRay.Parent = workspace;
						-- Debugger:Expire(dbRay, 5);

						if raycastResult == nil or raycastResult.Instance == spawnOnPart then
							isSurfaceVisible = true;
							break;
						else
							local hitPart = raycastResult.Instance;
							if hitPart.Size.Magnitude <= 64 then
								table.insert(excludeList, hitPart);
								visibleRayParam.ExcludeInstances = excludeList;
								task.wait();
							else
								break;
							end
						end
					end
				end

				if not isSurfaceVisible then continue end;
				
				local surfaceCenterCFrame = CFrame.lookAt(
					surfaceCf.p, 
					(surfaceCf * CFrame.new(randomAxis*100)).Position, 
					surfaceCf.UpVector
				);
				
				local lookVec = surfaceCenterCFrame.LookVector;
				local zSize = math.clamp((surfaceSize.X+surfaceSize.Y)/20, 1, 10);
				
				properties.VeinLaunched = properties.VeinLaunched +1;
				
				local plaqueName = `Nekros Plaque{properties.VeinLaunched}`;
				local plaqueModel = Instance.new("Model");
				plaqueModel.Name = plaqueName;
				plaqueModel.Parent = veinModel;
				table.insert(plaqueObjects, plaqueModel);

				local newPlaque = PLAQUE_PREFAB:Clone();
				newPlaque.Name = "PrimaryPart";
				newPlaque.Parent = plaqueModel;
				newPlaque.CFrame = surfaceCenterCFrame * CFrame.new(lookVec);
				newPlaque.Size = surfaceSize;
				plaqueModel.PrimaryPart = newPlaque;

				local newPlaqueDestructible: DestructibleInstance = bodyDestructiblesComp:Create(plaqueName, plaqueModel);
				newPlaqueDestructible.OwnerStatusCompLink = true;

				newPlaqueDestructible.HealthComp:SetMaxHealth(baseHealth * 0.1);
				newPlaqueDestructible.HealthComp:Reset();

				newPlaqueDestructible:SetupHealthbar{
					Size = UDim2.new(1.2, 0, 0.25, 0);
					Distance = 64;
					OffsetWorldSpace = Vector3.new(0, 1, 0);
					ShowLabel = false;
				};
				newPlaqueDestructible:SetHealthbarEnabled(true);
				
				newPlaqueDestructible.HealthComp.OnHealthChanged:Connect(function(curHealth, oldHealth, damageData)
					if newPlaqueDestructible.HealthComp.IsDead then return end;
					if curHealth == oldHealth then return end;
					if damageData.Damage == nil then return end;

					damageData = damageData:Clone();
					damageData.HideBubble = true;

					healthComp:TakeDamage(damageData);
				end)

				newPlaqueDestructible.OnDestroy:Connect(function()
					Debugger.Expire(plaqueModel, 2);
					
					newPlaque.Color = Color3.fromRGB(48, 30, 30);
					modAudio.Play("NekronHurt", newPlaque).PlaybackSpeed = math.random(50, 60)/100;
					
					local amount = baseHealth * 0.35;
										
					local fireStatues = npcClass.StatusComp:ListStatusWithTags{"Fire"};
					if #fireStatues > 0 then
						amount += baseHealth * 0.25;
					end
					
					healthComp:TakeDamage(DamageData.new{
						Damage = amount;
						TargetPart = newPlaque;
					});
					for a=#plaqueObjects, 1, -1 do
						if plaqueObjects[a] == plaqueModel then
							table.remove(plaqueObjects, a);
						end
					end
				end)
				
				task.spawn(function()
					local step = 0.1;
					local t = size/10 * step;
					
					local oCf = newPlaque.CFrame;
					local eSize = surfaceSize + Vector3.new(0, 0, zSize);
					for a=0, 1, step do
						newPlaque.CFrame = oCf:Lerp(surfaceCenterCFrame, a);
						newPlaque.Size = surfaceSize:Lerp(eSize, a);
						task.wait(t);
						if healthComp.IsDead then return end;
					end
				end)

			end
		end
    end

	properties.LastVeinSpawn = tick();
	properties.LastHeal = tick();

    --MARK: Heal mechanics;
    npcClass.OnThink:Connect(function()
        local timelapsed = (tick()-npcClass.SpawnTime);
        local healEffectiveness = 0;

		if timelapsed <= 5 then
			healEffectiveness = timelapsed/5;
		elseif timelapsed <= 10 then
			healEffectiveness = 1 + timelapsed/10;
		elseif timelapsed <= 25 then
			healEffectiveness = 1 + (40-(timelapsed-25))/15;
		else
			healEffectiveness = math.clamp(healEffectiveness-(1/600), 0, 2);
		end

		local randomPlaquePart = nil;
		if #plaqueObjects > 0 then
			randomPlaquePart = plaqueObjects[math.random(1, #plaqueObjects)];
			if randomPlaquePart and randomPlaquePart.PrimaryPart then
				randomPlaquePart = randomPlaquePart.PrimaryPart;
			end
		end
		if randomPlaquePart == nil or randomPlaquePart:IsA("Model") then
			randomPlaquePart = npcClass.RootPart;
		end

		local toxicStatues = npcClass.StatusComp:ListStatusWithTags{"Toxic"};
        if #taggedObjects > 0 then
			if tick()-properties.LastHeal >= 0.5 then
				properties.LastHeal = tick();
				
				local healAmt = math.ceil(#taggedObjects * (baseHealth * 0.0025));
				
				if #toxicStatues > 0 then
					healAmt = healAmt * 0.5;
				end
				
				healthComp:TakeDamage(DamageData.new{
					Damage = -healAmt;
					TargetPart = randomPlaquePart;
                    DamageType = "Heal";
				});
			end
		end
    end)
end

function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local npcChar = npcClass.Character;
    local rootPart = npcClass.RootPart;

    npcClass.Character:SetAttribute("EntityHudHealth", true);
    rootPart.CollisionGroup = "CollisionOff";

    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    npcClass.OnThink:Connect(function()
        for _, player in pairs(game.Players:GetPlayers()) do
            local playerClass: PlayerClass = shared.modPlayers.get(player);
            if playerClass == nil then continue end;

            if npcClass.HealthComp:CanTakeDamageFrom(playerClass) then
                targetHandlerComp:AddTarget(playerClass.Character, playerClass.HealthComp);
            end
        end
    end)
end

return npcPackage;