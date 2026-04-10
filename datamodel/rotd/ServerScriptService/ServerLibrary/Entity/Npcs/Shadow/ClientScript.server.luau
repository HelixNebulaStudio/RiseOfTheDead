local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local noiseBeamParticle = game.ReplicatedStorage.Particles:WaitForChild("NoiseBeam");

local characterTag = script:WaitForChild("Character");
repeat task.wait(0.1) until characterTag.Value ~= nil;

local character = characterTag.Value;
if not workspace:IsAncestorOf(character) then return end;

local localplayer = game.Players.LocalPlayer;
local playerClass: PlayerClass = shared.modPlayers.get(localplayer);

local playerRootPart = playerClass.RootPart;
--==
local humanoid = character:WaitForChild("Zombie");
local rootPart = character:WaitForChild("HumanoidRootPart");

local templateShadowBody = character;

local raycastParams = RaycastParams.new();
raycastParams.FilterType = Enum.RaycastFilterType.Include;
raycastParams.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};

local enemyTargetTag: ObjectValue = character:WaitForChild("EnemyTarget");

local shadowsList = {};
local motorsList = {};


local function getPrefab(index, mirrorPrefab)
	local newSpawn = false;
	local shadowPrefab = shadowsList[index];
	if shadowPrefab == nil or shadowPrefab.Parent == nil then
		newSpawn = true;

		shadowPrefab = templateShadowBody:Clone();
		shadowPrefab.Name = `ShadowIllusion{index}`;
		shadowPrefab:WaitForChild("Zombie"):Destroy();
		for _, obj in pairs(shadowPrefab:GetDescendants()) do
			if obj:IsA("BasePart") then
				if obj.Name ~= "HumanoidRootPart" then
					obj.Transparency = 0;
				else
					-- is HumanoidRootPart;
					obj.Name = "PrimaryPart";
					obj.Anchored = true;
				end
				obj.CanCollide = false;
				obj.CanQuery = false;

			elseif obj:IsA("Motor6D") then
				local list = motorsList[obj.Name];
				if list == nil then
					list = {};
					motorsList[obj.Name] = list;
				end
				table.insert(list, obj);
			else
				obj:Destroy();
			end;
		end

		shadowPrefab.Parent = workspace.Debris;
		shadowsList[index] = shadowPrefab;

		game.ReplicatedStorage:WaitForChild("NpcThread"):Fire(function()
			humanoid:GetAttributeChangedSignal("IsDead"):Connect(function()
				if humanoid:GetAttribute("IsDead") ~= true then return end;

				for _, obj in pairs(shadowPrefab:GetChildren()) do
					if obj.Name == "PrimaryPart" then
						game.Debris:AddItem(obj, 0);
					else
						if obj:IsA("BasePart") then
							obj.CanCollide = true;
							obj:ClearAllChildren();
							game.Debris:AddItem(obj, math.random(2, 4));
						end
					end
				end
			end)
		end)

		if mirrorPrefab then
			local beam: Beam = noiseBeamParticle:Clone();

			local att1 = Instance.new("Attachment");
			att1.Parent = mirrorPrefab.PrimaryPart;

			local att2 = Instance.new("Attachment");
			att2.Parent = shadowPrefab;

			beam.Parent = att1;
			beam.Attachment0 = att1;
			beam.Attachment1 = att2;
			TweenService:Create(
				beam, 
				TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true, 3), {
				TextureSpeed = -10;
			}):Play();

		end
	end

	return shadowPrefab, newSpawn;
end

local rngRayLength = {32;32;32;32};
local rngRot = {0;0;90;};
character:GetAttributeChangedSignal("BlinkCount"):Connect(function()
	rngRayLength = {
		math.random(4, 32);
		math.random(4, 32);
		math.random(4, 32);
		math.random(4, 32);
	};
	rngRot = {math.random(0, 360);math.random(0, 360);math.random(0, 360);};
end)

local function onHeartbeat(delta, index)
	local playerPos = Vector3.new(playerRootPart.Position.X, rootPart.Position.Y, playerRootPart.Position.Z);

	local originPos = rootPart.Position;

	local posShadowPrefab, _posPrefabNew = getPrefab(index);
	local negShadowPrefab, _negPrefabNew = getPrefab(index+1, posShadowPrefab);

	local enemyCf = enemyTargetTag.Value and (enemyTargetTag.Value :: Model):GetPivot() or rootPart.CFrame;

	local posRayPoint, negRayPoint;

	local curRot = rngRot[index];
	
	local originCf = CFrame.new(originPos) * CFrame.Angles(0, math.rad(curRot), 0);
	local dir = originCf.LookVector;

	local rayOrigin = originPos;
		
	--pos
	local posRayDir = dir * rngRayLength[index];
	local posRayResult = workspace:Raycast(rayOrigin, posRayDir, raycastParams);

	posRayPoint = rayOrigin + posRayDir;
	if posRayResult then
		posRayPoint = posRayResult.Position - (dir*3);
	end

	posRayPoint = Vector3.new(posRayPoint.X, originPos.Y, posRayPoint.Z);
	local posDir = (enemyCf.Position - posRayPoint).Unit;
	posShadowPrefab:PivotTo(CFrame.lookAlong(posRayPoint, posDir));

	--neg
	local negRayDir = dir * -rngRayLength[index+1];
	local negRayResult = workspace:Raycast(rayOrigin, negRayDir, raycastParams);

	negRayPoint = rayOrigin + negRayDir;
	if negRayResult then
		negRayPoint = negRayResult.Position + (dir*3);
	end
	negRayPoint = Vector3.new(negRayPoint.X, originPos.Y, negRayPoint.Z);
	local negDir = (enemyCf.Position - negRayPoint).Unit;
	negShadowPrefab:PivotTo(CFrame.lookAlong(negRayPoint, negDir));
end

local charDescendants = character:GetDescendants();

local function onHitReveal()
	for _, obj in pairs(charDescendants) do
		if not obj:IsA("BasePart") then continue end;
		if obj.Name == "HumanoidRootPart" then continue end;

		if obj:IsA("MeshPart") then
			obj.TextureID = ``;
		end
		obj.Material = Enum.Material.Neon;
		obj.Transparency = 0;
		
		TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1;
		}):Play();
	end
end
character:GetAttributeChangedSignal("HitReveal"):Connect(onHitReveal)

for _, obj in pairs(charDescendants) do
	if not obj:IsA("BasePart") then continue end;
	obj.Transparency = 1;
end

RunService.Heartbeat:Connect(function(d)
	for _, obj in pairs(charDescendants) do
		if obj:IsA("BasePart") then
			obj.CanCollide = false;

		elseif obj:IsA("Motor6D") then
			local mList = motorsList[obj.Name];
			if mList == nil then continue end;

			for a=1, #mList do
				local m: Motor6D = mList[a];
				m.C0 = obj.C0;
				m.C1 = obj.C1;
				m.Transform = obj.Transform;
			end
		end
	end

	onHeartbeat(d, 1);
	onHeartbeat(d, 3);
end)
