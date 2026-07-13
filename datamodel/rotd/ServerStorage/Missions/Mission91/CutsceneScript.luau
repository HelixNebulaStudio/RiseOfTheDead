local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

if RunService:IsServer() then
	cutsceneAssets = script.Parent:WaitForChild("CutsceneAssets");
	
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

local MISSION_ID = 91;
--==

return function(CutsceneSequence)
	if shared.WorldName ~= "BioXResearch" and modBranchConfigurations.WorldInfo.OverWorldIndex == nil then
		return;
	end

    local PLAQUE_PREFAB = cutsceneAssets:WaitForChild("Plaque");
    local MOLD_TEXTURE = cutsceneAssets:WaitForChild("Mold");

    local rayParam = RaycastParams.new();
    rayParam.FilterType = Enum.RaycastFilterType.Include;
    rayParam.IgnoreWater = true;
    rayParam.CollisionGroup = "Raycast";
    rayParam.FilterDescendantsInstances = {workspace.Environment;};

	local taggedObjects = {};
	local function spawnOvergrowth(targetRootPart)
		local targetPoint = targetRootPart.Position;

		local raycastResult;
		for a=1, 16 do
			local aimPoint = CFrame.new(targetPoint) 
				* CFrame.Angles(0, math.rad(math.random(1, 360)), 0)
				* CFrame.Angles(math.rad(math.random(30, 50)), 0, 0) 
				* CFrame.new(0, 0, 1024);
			
			local aimDir = (aimPoint.p-targetPoint).Unit;
			raycastResult = workspace:Raycast(targetPoint, aimDir*256, rayParam);
			
			task.wait();
			if raycastResult and raycastResult.Instance and raycastResult.Instance.Anchored then
				break;
			end
		end

		if math.random(1, 5) ~= 1 then return end;
		if raycastResult == nil then return end;

		local spawnOnPart = raycastResult.Instance;

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
		
		if spawnOnPart.ClassName == "Part" 
		and spawnOnPart.Shape == Enum.PartType.Block 
		and size >= 5 then
			local axis = {Vector3.xAxis; Vector3.zAxis; -Vector3.xAxis; 
						-Vector3.zAxis; Vector3.yAxis; -Vector3.yAxis;};
			
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
						local wallRaycastResult = workspace:Raycast(ray.Origin, ray.Direction, visibleRayParam);
						
						if wallRaycastResult == nil or wallRaycastResult.Instance == spawnOnPart then
							isSurfaceVisible = true;
							break;
						else
							local hitPart = wallRaycastResult.Instance;
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
				
				local plaqueName = `Corruption`;
				local plaqueModel = Instance.new("Model");
				plaqueModel.Name = plaqueName;
				plaqueModel.Parent = workspace.Environment;

				local newPlaque = PLAQUE_PREFAB:Clone();
				newPlaque.Name = "PrimaryPart";
				newPlaque.Parent = plaqueModel;
				newPlaque.CFrame = surfaceCenterCFrame * CFrame.new(lookVec);
				newPlaque.Size = surfaceSize;
				plaqueModel.PrimaryPart = newPlaque;

                local destructibleConfig = modDestructibles.createDestructible();
                destructibleConfig.Parent = plaqueModel;
				Debugger.Expire(plaqueModel, 150);

				local newPlaqueDestructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
				newPlaqueDestructible.Name = "Corruption";

				newPlaqueDestructible.HealthComp:SetMaxHealth(5000);
				newPlaqueDestructible.HealthComp:Reset();

				-- newPlaqueDestructible:SetupHealthbar{
				-- 	Size = UDim2.new(1.2, 0, 0.25, 0);
				-- 	Distance = 64;
				-- 	OffsetWorldSpace = Vector3.new(0, 1, 0);
				-- 	ShowLabel = false;
				-- };
				-- newPlaqueDestructible:SetHealthbarEnabled(true);
				
				local healthComp = newPlaqueDestructible.HealthComp;

				newPlaqueDestructible.OnDestroy:Connect(function()
					Debugger.Expire(plaqueModel, 2);
					
					newPlaque.Color = Color3.fromRGB(48, 30, 30);

					for _, player in pairs(game.Players:GetPlayers()) do
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.SaveData.Kills = mission.SaveData.Kills -1;
							if mission.SaveData.Kills <= 0 then
								modMission:CompleteMission(player, MISSION_ID);
							end
						end)
					end
				end)
				
				for _, side in pairs(Enum.NormalId:GetEnumItems()) do
					local newTexture = MOLD_TEXTURE:Clone();
					newPlaqueDestructible.Garbage:Tag(newTexture);

					newTexture.Name = "VeinOfNekronSpread";
					
					newTexture.Face = side;
					newTexture.Parent = spawnOnPart;
					
					task.spawn(function()
						for t=1, 0.35, -((1-0.35)/10) do
							newTexture.Transparency = t;
							task.wait(size/100);
						end
					end)
				end

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

				break;
			end
		end
	end

	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		local loopActive = false;
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				
				if loopActive then return end;
				loopActive = true;

				task.spawn(function()
					local playerClass: PlayerClass = shared.modPlayers.get(player);

					while loopActive do
						if not game.Players:IsAncestorOf(player) then break; end;
						if mission.Type ~= 1 then break; end;

						spawnOvergrowth(playerClass.RootPart);
						
						task.wait(1);
					end
				end)

			elseif mission.Type == 3 then -- OnComplete

			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;