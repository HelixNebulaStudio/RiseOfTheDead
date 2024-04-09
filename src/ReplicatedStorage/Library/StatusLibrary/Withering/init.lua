local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local StatusClass = require(script.Parent.StatusClass).new();
local localPlayer = game.Players.LocalPlayer;

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local modMath = require(game.ReplicatedStorage.Library.Util.Math);

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local remotePlayerProperties = modRemotesManager:Get("PlayerProperties");
--

local witheringScreenEffect = script:WaitForChild("witheringEye");

if RunService:IsClient() then
	modData, modCharacter, mainInterface = nil, nil, nil;
end
--==
function StatusClass.OnApply(classPlayer, status)
	if RunService:IsServer() then
		
	else
		modData = require(localPlayer:WaitForChild("DataModule"));
		modCharacter = modData:GetModCharacter();
		mainInterface = modData:GetInterfaceModule();

		if mainInterface.ScreenEffects.WitheringEye == nil then
			mainInterface.ScreenEffects.WitheringEye = witheringScreenEffect:Clone();
			mainInterface.ScreenEffects.WitheringEye.Parent = mainInterface.CameraInterface;
		end
		
	end

end

function StatusClass.OnExpire(classPlayer, status)
	if mainInterface == nil then return end;
	if mainInterface.ScreenEffects.WitheringEye then
		mainInterface.ScreenEffects.WitheringEye:Destroy();
		mainInterface.ScreenEffects.WitheringEye = nil;
	end
end

function StatusClass.OnTick(classPlayer, status, tickPack)
	if RunService:IsServer() then
		if tickPack.ms500 ~= true then return end;
		
		local amt = (status.Amount or 0);
		if amt > 0 then
			classPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
				Damage=amt;
				DamageType="ArmorOnly";
			});
		end
		
	else
		if classPlayer:GetInstance() ~= localPlayer then return; end
		
		if mainInterface.ScreenEffects.WitheringEye then
			local screenEffect = mainInterface.ScreenEffects.WitheringEye;
			local camera = workspace.CurrentCamera;
			
			local witherers = CollectionService:GetTagged("Witherer");
			
			local minRad = math.pi;
			local activeEyeball = nil;
			
			for _, eyeBall in pairs(witherers) do
				local dist = (eyeBall.CFrame.Position-classPlayer.RootPart.Position).Magnitude;
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
				alpha = alpha + (1/4*tickPack.Delta);
				
			else
				if alpha < 1 then
					alpha = alpha - (1/4*tickPack.Delta);
					
				else
					alpha = alpha - (1/8*tickPack.Delta);
					
				end
				
			end
			alpha = math.clamp(alpha, 0, 2);
			screenEffect:SetAttribute("Alpha", alpha);
			
			
			if tickPack.ms500 ~= true then return end;
			local alpha = screenEffect:GetAttribute("Alpha");
			
			remotePlayerProperties:FireServer("Relay", script.Name, alpha);
		end
	end;
end

function StatusClass.OnRelay(classPlayer, status, ...)
	local alpha = ...;
	
	if alpha >= 1 then
		local maxArmor = classPlayer.Properties.MaxArmor;
		status.Amount = math.round(maxArmor * 0.0333 * 100)/100;
	end
end

return StatusClass;