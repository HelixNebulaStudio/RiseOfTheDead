local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local WITHERING_SCREEN_EFFECT;
--==
local statusPackage = {
	Id="Withering";
	Icon="rbxassetid://15948741680";
	Name="Withering";
	Description="Withering because a Wither is nearby. Looking at them will start Withering and slowly drains armor over time.";
	Buff=false;
	Tags = {"DOT";};
	Cleansable=true;
	ExpiresOnDeath=true;
};

function statusPackage.onRequire()
	WITHERING_SCREEN_EFFECT = script:WaitForChild("witheringEye");
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
	if RunService:IsServer() then return end;
	
	local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	local modCharacter = modData:GetModCharacter();

	local screenGui = modClientGuis.ActiveInterface.CameraScreenGui;
	if screenGui:FindFirstChild(WITHERING_SCREEN_EFFECT.Name) == nil then
		local new = WITHERING_SCREEN_EFFECT:Clone();
		new.Parent = screenGui;
	end
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
	if RunService:IsServer() then return end;

	local screenGui = modClientGuis.ActiveInterface.CameraScreenGui;
	for _, obj in pairs(screenGui:GetChildren()) do
		if obj.Name == WITHERING_SCREEN_EFFECT.Name then
			obj:Destroy();
		end
	end
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
	local characterClass: CharacterClass = statusClass.StatusOwner;
	if characterClass == nil then return end;

	if RunService:IsServer() then
		if tickData.ms500 ~= true then return end;

		local amt = (statusClass.Values.Amount or 0);
		if amt <= 0 then return end;

		local healthComp: HealthComp? = characterClass.HealthComp;
		if healthComp == nil then return end;

		local dmgData = DamageData.new{
			Damage = amt;
			DamageType = "ArmorOnly";
		};

		healthComp:TakeDamage(dmgData);
		
	elseif RunService:IsClient() then
		if (characterClass :: PlayerClass):GetInstance() ~= localPlayer then return; end

		local screenGui = modClientGuis.ActiveInterface.CameraScreenGui;
		local screenEffect = screenGui:FindFirstChild(WITHERING_SCREEN_EFFECT.Name);
		if screenEffect == nil then
			local witherers = CollectionService:GetTagged("Witherer");

			local minRad = math.pi;
			local activeEyeball = nil;

			for _, eyeBall in pairs(witherers) do
				local dist = (eyeBall.CFrame.Position-characterClass.RootPart.Position).Magnitude;
				if dist > 64 then continue end;
				local lookVec = camera.CFrame.LookVector;
				local objVec = (eyeBall.CFrame.Position-camera.CFrame.Position).Unit

				local angle = lookVec:Angle(objVec);

				if angle < minRad then
					minRad = angle;
					activeEyeball = eyeBall;
				end
			end

			if activeEyeball then
				local screenPoint, onScreen = camera:WorldToViewportPoint(activeEyeball.Position);

				if onScreen then
					local vpRay: Ray = camera:ViewportPointToRay(screenPoint.X, screenPoint.Y);

					local rayParam = RaycastParams.new();
					rayParam.FilterDescendantsInstances = {workspace.Terrain; workspace.Environment; activeEyeball};
					rayParam.FilterType = Enum.RaycastFilterType.Include;
					rayParam.IgnoreWater = true;

					local rayResult = workspace:Raycast(vpRay.Origin, vpRay.Direction*64, rayParam);
					if rayResult and rayResult.Instance ~= activeEyeball then
						minRad = math.pi;
					end

				else
					minRad = math.pi;
				end

			else
				minRad = math.pi;
			end

			local ang = math.clamp(minRad/math.pi, 0, 1);
			local isInWision = ang < 0.35;

			local alpha = screenEffect:GetAttribute("Alpha") or 0;
			if isInWision then
				alpha = alpha + (1/4*tickData.Delta);

			else
				if alpha < 1 then
					alpha = alpha - (1/4*tickData.Delta);

				else
					alpha = alpha - (1/8*tickData.Delta);

				end

			end
			alpha = math.clamp(alpha, 0, 2);
			screenEffect:SetAttribute("Alpha", alpha);

			statusClass.Values.Alpha = math.clamp(alpha, 0, 1);

			if tickData.ms500 ~= true then return end;

			alpha = screenEffect:GetAttribute("Alpha");

			statusClass:Relay(alpha);
		end
	end;
end

function statusPackage.BindRelay(statusClass: StatusClassInstance, ...)
	local characterClass: CharacterClass = statusClass.StatusOwner;
	if characterClass == nil then return end;

	local alpha = ...;

	if alpha >= 1 then
		local maxArmor = characterClass.Properties.MaxArmor;
		statusClass.Values.Amount = math.round(maxArmor * 0.0333 * 100)/100;
	end

	statusClass.Values.Alpha = math.clamp(alpha, 0, 1);
end

return modStatusClass.new(statusPackage);