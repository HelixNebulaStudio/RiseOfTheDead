local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local characterTag = script:WaitForChild("Character");
repeat task.wait(0.1) until characterTag.Value ~= nil;

local character = characterTag.Value;
if not workspace:IsAncestorOf(character) then return end;

local localplayer = game.Players.LocalPlayer;
local modData = shared.require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = modData:GetModCharacter();
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
local function onHeartbeat(delta, index) 
	local playerPos = Vector3.new(playerRootPart.Position.X, rootPart.Position.Y, playerRootPart.Position.Z)
	local playerDisplace = (playerPos - rootPart.Position);
	local playerDir = playerDisplace.Unit;
	local playerMag = math.clamp(playerDisplace.Magnitude, 6, 26);
	
	local pivotPos = (playerPos + rootPart.Position)/2;
	
	local randomDir = playerDir;

	local fakeDir;
	if index == 1 then
		fakeDir = randomDir;
	elseif index == 2 then
		fakeDir = randomDir:Cross(Vector3.yAxis);
	elseif index == 3 then
		fakeDir = -randomDir:Cross(Vector3.yAxis);
	elseif index == 4 then
		fakeDir = -randomDir;
	end
	
	local rayOrigin = pivotPos;
	local rayDir = fakeDir * playerMag;
	local rayResult = workspace:Raycast(rayOrigin, rayDir, raycastParams);
	
	local rayPoint = rayOrigin + rayDir;
	if rayResult then
		rayPoint = rayResult.Position - (fakeDir*3);
	end
	
	local shadowPrefab = shadowsList[index];
	
	if shadowPrefab == nil or shadowPrefab.Parent == nil then
		shadowPrefab = templateShadowBody:Clone();
		shadowPrefab:WaitForChild("Zombie"):Destroy();
		for _, obj in pairs(shadowPrefab:GetDescendants()) do
			if obj:IsA("BasePart") then
				if obj.Name ~= "HumanoidRootPart" then
					obj.Transparency = 0;
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

		character.Destroying:Connect(function()
			shadowPrefab:Destroy();
		end)
	end
	
	local enemyCf = enemyTargetTag.Value and (enemyTargetTag.Value :: Model):GetPivot() or rootPart.CFrame;
	local enemyDir = (enemyCf.Position - rayPoint).Unit;
	if shared.IsNan(enemyDir) then
		enemyDir = (rootPart.CFrame.Position - rayPoint).Unit;
	end

	local shadowCf = CFrame.lookAlong(rayPoint, enemyDir);
	shadowPrefab:PivotTo(shadowCf);
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
	onHeartbeat(d, 2);
	onHeartbeat(d, 3);
	onHeartbeat(d, 4);
end)
