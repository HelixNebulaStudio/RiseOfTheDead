local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
return function()
	--== Configuration;
	
	--== Variables;
	local TweenService = game:GetService("TweenService");
	
	local localPlayer = game.Players.LocalPlayer;
	local camera = workspace.CurrentCamera;
	
	local modRemotesManager = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("RemotesManager"));
	local remotePrimaryFire = modRemotesManager:Get("PrimaryFire");
	local remoteCharacterRemote = modRemotesManager:Get("CharacterRemote");
	
	local weaponsLibrary = game.ReplicatedStorage.Library.Weapons;
	local weaponsMechanicsModule = game.ReplicatedStorage.Library.WeaponsMechanics;
	
	local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	local modAudio = require(game.ReplicatedStorage.Library.Audio);
	local modWeaponsLibrary = require(weaponsLibrary);
	local modWeaponMechanics = require(weaponsMechanicsModule);
	local _modProjectile = require(game.ReplicatedStorage.Library.Projectile);
	local modAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
	local modArcParticles = require(game.ReplicatedStorage.Particles.ArcParticles);
	local modInstrumentModule = require(game.ReplicatedStorage.Library.InstrumentModule);
	
	--== Script;
	local function replicatePrimaryFire(weaponItemId, weapon, data, skipAudio)
		if weapon == nil then return end;
		local handle = weapon:FindFirstChild("Handle");
		if handle == nil or not handle:IsDescendantOf(workspace) then return end;
		local weaponData = modWeaponsLibrary[weaponItemId] or modWeaponsLibrary["p250"];
		
		local weaponModule = weaponData.NewToolLib();
		
		local weaponConfigurations = weaponModule.Configurations;
		local audio = weaponModule.Audio;
	
		local muzzleOrigin = weapon:FindFirstChild("MuzzleOrigin", true);
		local bulletOrigin = handle:FindFirstChild("BulletOrigin");
	
		if weaponConfigurations then
			if weaponConfigurations.BulletMode == modAttributes.BulletModes.Hitscan then
				if audio.PrimaryFire.Looped then
					
				else
					if skipAudio ~= true then
						modAudio.Play(audio.PrimaryFire.Id, handle);
					end
				end
				if bulletOrigin then
					local raycastParams = RaycastParams.new();
					raycastParams.FilterType = Enum.RaycastFilterType.Include
					raycastParams.IgnoreWater = true
					raycastParams.CollisionGroup = "Raycast";
					raycastParams.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};
					
					for a=1, #data.TargetPoints do
						local targetDir = (data.TargetPoints[a]-bulletOrigin.WorldPosition).Unit;
						if weaponConfigurations.GenerateTracers ~= false then
							modWeaponMechanics.CreateTracer(bulletOrigin, data.TargetPoints[a], camera);
						end;
						if weaponConfigurations.GeneratesBulletHoles then
							local originP = data.TargetPoints[a]-(targetDir*0.1);
							local raycastResult = workspace:Raycast(originP, targetDir, raycastParams);
							
							local rayBasePart, rayPoint, rayNormal, _rayMaterial;
							if raycastResult then
								rayBasePart = raycastResult.Instance;
								rayPoint = raycastResult.Position;
								rayNormal = raycastResult.Normal;
								_rayMaterial = raycastResult.Material;
								
								modWeaponMechanics.CreateBulletHole(rayBasePart, rayPoint, rayNormal);
							end
						end; 
					end
				end
				if muzzleOrigin and weaponConfigurations.GenerateMuzzle ~= false then
					modWeaponMechanics.CreateMuzzle(muzzleOrigin, bulletOrigin, data.TargetPoints and #data.TargetPoints or 1);
				end;
			elseif weaponConfigurations.BulletMode == modAttributes.BulletModes.Projectile then
				local _projectile = data;
				if audio.PrimaryFire.Looped then
					
				else
					if skipAudio ~= true then
						modAudio.Play(audio.PrimaryFire.Id, handle);
					end
				end
				
				
			end
		end
	end
	
	remotePrimaryFire.OnClientEvent:Connect(function(weaponItemId, weapon, data, skipAudio)
		if type(data) == "table" and data.ClassName ~= "Projectile" then
			replicatePrimaryFire(weaponItemId, weapon, {TargetPoints=data}, skipAudio);
		else
			replicatePrimaryFire(weaponItemId, weapon, data, skipAudio);
		end
	end)
	
	local remoteGenerateArcParticles = modRemotesManager:Get("GenerateArcParticles");
	remoteGenerateArcParticles.OnClientEvent:Connect(function(duration, ...)
		local arc = modArcParticles.new(...);
		delay(duration or 0.1, function() arc:Destroy(); end);
	end)
	
	remoteCharacterRemote.OnClientEvent:Connect(function(action, paramPacket)
		--local action, paramPacket = unpack(data);
		local character = paramPacket.Character;
		if character == nil then return end;
		
		if action == 1 then -- 1 updatebodymotors

			if paramPacket.B and typeof(paramPacket.B) == "buffer" then
				local waistC0X = buffer.readi16(paramPacket.B, 0)/100;
				local waistC0Z = buffer.readi16(paramPacket.B, 2)/100;
				local waistC1Y = buffer.readi16(paramPacket.B, 4)/100;
				local waistC1X = buffer.readi16(paramPacket.B, 6)/100;

				local waistMotor = character:FindFirstChild("Waist", true);
				if waistMotor and waistMotor:IsA("Motor6D") then
					local properties = {
						C0 = CFrame.new(waistMotor.C0.Position) * CFrame.Angles(waistC0X, 0, 0) * CFrame.Angles(0, 0, waistC0Z);
						C1 = CFrame.new(waistMotor.C1.Position) * CFrame.Angles(0, waistC1Y, 0) * CFrame.Angles(waistC1X, 0, 0);
					};

					TweenService:Create(waistMotor, TweenInfo.new(0.6), properties):Play();
				end

				local neckC0Y = buffer.readi16(paramPacket.B, 8)/100;
				local neckC1X = buffer.readi16(paramPacket.B, 10)/100;

				local neckMotor = character:FindFirstChild("Neck", true);
				if neckMotor and neckMotor:IsA("Motor6D") then
					local properties = {
						C0 = CFrame.new(neckMotor.C0.Position) * CFrame.Angles(0, neckC0Y, 0);
						C1 = CFrame.new(neckMotor.C1.Position) * CFrame.Angles(neckC1X, 0, 0);
					};

					TweenService:Create(neckMotor, TweenInfo.new(0.6), properties):Play();
				end
			end
		end
	end)
	
	local debrisCounter = 0;
	workspace.Debris.ChildAdded:Connect(function(child)
		if modData.Settings.ReduceMaxDebris then
			debrisCounter = debrisCounter+1;
			child:SetAttribute("DebrisCounter", debrisCounter);
			
			
			local debrisList = workspace.Debris:GetChildren();
			
			if #debrisList > 100 then
				local oldestDrbris = nil;
				local oldestDebrisInt = math.huge;
				
				for a=1, #debrisList do
					local dc = debrisList[a]:GetAttribute("DebrisCounter");
					if dc == nil then continue end;
					
					if dc < oldestDebrisInt then
						oldestDrbris = debrisList[a];
						oldestDebrisInt = debrisList[a]:GetAttribute("DebrisCounter");
					end
				end
				
				if oldestDrbris then
					oldestDrbris:Destroy();
				end
				
				return;
			end
		end
		
		if modData:GetSetting("LimitParticles") == 1 then
			local children = child:GetChildren();
			for a=1, #children do 
				local particle = children[a];
				if particle.ClassName == "ParticleEmitter" then
					particle.Rate = math.clamp((particle.Rate >= 16 and particle.Rate/4 or particle.Rate/2), 3, 500);
				end
			end
		end
	end)

	modInstrumentModule:InitClient();
end