local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modWeaponsMechanics = shared.require(game.ReplicatedStorage.Library.WeaponsMechanics);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=6984018985;};
	};
	Audio={};
	Configurations={
		UseCooldown = 1;
		HideCrosshair = false;
	};
	Properties={};
};

function toolPackage.ClientPrimaryFire(handler)
	local localplayer = game.Players.LocalPlayer;
	local modData = shared.require(localplayer:WaitForChild("DataModule") :: ModuleScript);
	local modCharacter = modData:GetModCharacter();
	
	local mouseProperties = modCharacter.MouseProperties;
	
	local rayWhitelist = CollectionService:GetTagged("TargetableEntities") or {};
	table.insert(rayWhitelist, workspace.Environment);
	table.insert(rayWhitelist, workspace.Entity);
	table.insert(rayWhitelist, workspace.Characters);
	
	local shotData = {
		Origin=mouseProperties.Focus.p;
		Direction=mouseProperties.Direction;
	}
	
	local function onCast(basePart, position, normal, material, index, distance)
		if basePart == nil then return end;
		if position == nil then return end;
		
		local targetDist = (position-modCharacter.RootPart.Position).Magnitude;
		if targetDist >= 24 then return end;
		
		local model = basePart.Parent;
		if model:IsA("Accessory") then
			model = model.Parent;
		end
	
		local npcInstanceModule = model:FindFirstChild("NpcClassInstance");
		local humanoid = model:FindFirstChildWhichIsA("Humanoid");
		
		if (humanoid and humanoid.Health > 0 or npcInstanceModule) then
			local hitSoundRoll = math.random(1,2) == 1 and "BulletBodyImpact" or "BulletBodyImpact2";
			modAudio.Play(hitSoundRoll, nil, false, 1/((index+1)*0.9));
		end
		
		shotData.Target = basePart;
	end

	shotData.RayPoint = modWeaponsMechanics.CastHitscanRay{
		Origin = mouseProperties.Focus.p;
		Direction = mouseProperties.Direction;
		IncludeList = rayWhitelist;
		Range = 20;
		
		OnCastFunc = onCast;
	};
	
	pcall(function()
		local prefab = handler.Prefabs[1];

		modAudio.Play("Shock", prefab.PrimaryPart);	
		if prefab:FindFirstChild("glow") then
			prefab.glow.Material = Enum.Material.Plastic;
			delay(handler.UseCooldown, function()
				if prefab:FindFirstChild("glow") == nil then return end;
				prefab.glow.Material = Enum.Material.Neon;
			end)
		end
	end)
	
	return shotData;
end

function toolPackage.OnActionEvent(handler, packet)
	local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent)

	local remotes = game.ReplicatedStorage.Remotes;
	local bindOnDoorEnter = remotes.Interactable.OnDoorEnter;

	if packet.ActionIndex ~= 1 then return end;

	local shotdata = packet.ClientPacket;
	if shotdata == nil then return end;
	
	local classPlayer = shared.modPlayers.get(handler.Player);
	
	local weaponModel = handler.Prefabs[1];
	local hookPoints = weaponModel.points;
	
	local function clear()
		if handler.Cache == nil then handler.Cache = {}; end;
		for _, obj in pairs(handler.Cache) do
			obj:Destroy();
		end
		table.clear(handler.Cache);
		
		for _, obj in pairs(weaponModel:GetChildren()) do
			if obj.Name == "HookPoints" or obj.Name == "RopeConstraint" then
				Debugger.Expire(obj, 0);
			end
		end
		
		if handler.NpcModule then
			if handler.NpcModule.RootPart and handler.NpcModule.FakeBody and handler.NpcModule.FakeBody.PrimaryPart then
				handler.NpcModule.RootPart.CFrame = handler.NpcModule.FakeBody:GetPrimaryPartCFrame();
			end
			
			if handler.NpcModule.FakeBody then
				Debugger.Expire(handler.NpcModule.FakeBody, 0);
			end
			if handler.NpcModule.Humanoid then
				handler.NpcModule.Humanoid.PlatformStand = false;
			end
			handler.NpcModule.Disabled = nil;
			handler.NpcModule = nil;
		end
		
		modStatusEffects.Ragdoll(handler.Player, false, true);
		RunService.Heartbeat:Wait();
		if classPlayer.RootPart:CanSetNetworkOwnership() then
			classPlayer.RootPart:SetNetworkOwner(handler.Player);
		end;
	end
	clear();
	
	if handler.ClearRagdollConn == nil then
		handler.ClearRagdollConn = true;
		local desConn;
		desConn = weaponModel:GetPropertyChangedSignal("Parent"):Connect(function()
			if weaponModel.Parent == workspace.Debris or weaponModel.Parent == nil then
				clear();
				handler.ClearRagdollConn = nil;
				desConn:Disconnect();
				handler.DoorEnterConn:Disconnect();
				handler.DoorEnterConn = nil;
			end
		end)
	end
	if handler.DoorEnterConn == nil then
		handler.DoorEnterConn = bindOnDoorEnter.Event:Connect(function(player, interactData)
			local classPlayer = shared.modPlayers.get(player);
			
			if handler.NpcModule and not handler.NpcModule.IsDead then
				handler.NpcModule.RootPart.CFrame = classPlayer.RootPart.CFrame;
			end
		end)
	end
	
	if shotdata.Target then
		local hitPart = shotdata.Target;
		local model = hitPart.Parent;
		local healthComp: HealthComp? = modHealthComponent.getByModel(model);
	
		if healthComp and not healthComp.IsDead and healthComp.CompOwner.ClassName == "NpcClass" then
			local npcClass = healthComp.CompOwner :: NpcClass;
			
			if npcClass.Humanoid.Name == "Zombie" then
				if npcClass.Properties.BasicEnemy then
					handler.NpcModule = npcClass;
					
				else
					Debugger:Log("Attempt to latch on to non-basic enemy")
					
				end
			end
		else
			handler.NpcModule = nil;
		end
	end
	
	if shotdata.Target then
		if handler.NpcModule and handler.NpcModule.Humanoid and handler.NpcModule.Humanoid.Health > 0 then
			local prefab: Model = handler.NpcModule.Prefab;
			
			local fakeBody: Model = prefab:Clone();
			fakeBody:PivotTo(prefab:GetPivot());
			fakeBody.Parent = workspace.Entities;
			
			Debugger.Expire(fakeBody, 300);
			handler.NpcModule:TeleportHide();
			
			local fakeHumanoid = fakeBody:FindFirstChildWhichIsA("Humanoid");
			if fakeHumanoid then
				fakeHumanoid.PlatformStand = true;
				
				fakeHumanoid.Died:Connect(function()
					clear()
					if handler.NpcModule then
						handler.NpcModule:KillNpc();
					end
				end)
			end
			
			prefab.Destroying:Connect(function()
				clear();
				fakeBody:Destroy();
			end)
			
			local fakeNpcInstance = fakeBody:FindFirstChild("NpcClassInstance");
			if fakeNpcInstance then
				fakeNpcInstance:Destroy();
			end
			
			
			local fakeRootPart = fakeBody:WaitForChild("HumanoidRootPart");
			fakeRootPart.Massless = true;

			for _, obj in pairs(fakeBody:GetDescendants()) do
				if obj:IsA("Sound") then
					obj:Destroy();
				elseif obj:IsA("BasePart") then
					obj.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.5, 1, 0.3, 1);
				end
			end
			if fakeRootPart:CanSetNetworkOwnership() then
				fakeRootPart:SetNetworkOwner(handler.Player);
			end;
			wait(0.1);
			
			for _, obj in pairs(game.StarterPlayer.StarterCharacter:GetChildren()) do
				if obj:FindFirstChild("BallSocketConstraint") and fakeBody:FindFirstChild(obj.Name) then
					local fBodyPart = fakeBody[obj.Name];
					local oCon = obj.BallSocketConstraint;
					
					local attA = oCon.Attachment0;
					local attB = oCon.Attachment1;
					local attAParent = attA.Parent.Name;
					local attBParent = attB.Parent.Name;
					
					if fakeBody:FindFirstChild(attAParent) and fakeBody:FindFirstChild(attBParent) then
						local nAttA = attA:Clone();
						nAttA.Parent = fakeBody[attAParent];
						local nAttB = attB:Clone();
						nAttB.Parent = fakeBody[attBParent];
						
						local nCon = obj.BallSocketConstraint:Clone();
						nCon.Parent = fBodyPart;
						
						nCon.Attachment0 = nAttA;
						nCon.Attachment1 = nAttB;
						
						local jointMotor = fBodyPart:FindFirstChildWhichIsA("Motor6D");
						if jointMotor then
							jointMotor.Enabled = false;
						end
						
						nCon.Enabled = true;
					end
				end
			end
			
			if handler.NpcModule.FakeBody then	Debugger.Expire(handler.NpcModule.FakeBody, 0); end
			handler.NpcModule.FakeBody = fakeBody;
			handler.NpcModule.Disabled = true;
			handler.NpcModule.Humanoid.PlatformStand = true;
			handler.NpcModule.Think:Fire();
			
			for _, obj in pairs(fakeBody:GetChildren()) do
				if obj:IsA("BasePart") then
					obj.Massless = true;
					obj.CollisionGroup = "Characters";
				end;
			end
			
			for _, hook in pairs(hookPoints:GetChildren()) do
				local targetAtt = fakeBody:FindFirstChild(hook.Name, true);
				if targetAtt then
					
					local newRope = Instance.new("RopeConstraint");
					newRope.Parent = weaponModel;
					newRope.Visible = true;
					newRope.Attachment0 = hook;
					newRope.Attachment1 = targetAtt;
					
					newRope.Length = 4;
					newRope.Color = BrickColor.new(Color3.fromRGB(0, 142, 170));
					
				end
			end
			fakeBody:SetAttribute("Leashed", handler.Player.Name);
			
			modMission:Progress(handler.Player, 53, function(mission)
				if mission.ProgressionPoint == 5 then
					mission.ProgressionPoint = 6;
				end
			end)
			
		else
			-- Ragdoll on target;
			local hitPart = shotdata.Target;
			
			if hitPart:IsDescendantOf(workspace.Entity) then
				return;
			end
			
			if classPlayer.Humanoid:GetAttribute("IsSwimming") == true then
				return;
			end
			
			for _, oPlayer in pairs(game.Players:GetChildren()) do
				if oPlayer.Character and hitPart:IsDescendantOf(oPlayer.Character) then
					return;
				end
			end
			if not hitPart.Anchored then
				Debugger:Log("Hooked server not anchored");
				if classPlayer.RootPart:CanSetNetworkOwnership() then
					classPlayer.RootPart:SetNetworkOwner();
				else
					return;
				end;
			end
			
			modStatusEffects.Ragdoll(handler.Player, true, true);
			for _, hook in pairs(hookPoints:GetChildren()) do
				local pAtt = Instance.new("Attachment");
				pAtt.Parent = hitPart;
				pAtt.WorldPosition = shotdata.RayPoint;
				
				local newRope = Instance.new("RopeConstraint");
				newRope.Parent = hitPart;
				newRope.Visible = true;
				newRope.Attachment0 = hook;
				newRope.Attachment1 = pAtt;
				
				newRope.Length = (shotdata.RayPoint-hook.WorldPosition).Magnitude-0.5;
				newRope.Color = BrickColor.new(Color3.fromRGB(0, 142, 170));
				
				table.insert(handler.Cache, pAtt);
				table.insert(handler.Cache, newRope);
				
				Debugger.Expire(pAtt, 300);
				Debugger.Expire(newRope, 300);
				
				local newLength = math.clamp(newRope.Length-4, 2, 20);
				TweenService:Create(newRope, TweenInfo.new(0.2), {
					Length=newLength;
				}):Play();
			end
		end
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;