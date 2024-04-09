local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");
local PhysicsService = game:GetService("PhysicsService");

local modMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local remoteGenerateArcParticles = modRemotesManager:Get("GenerateArcParticles");
local remotes = game.ReplicatedStorage.Remotes;
local bindOnDoorEnter = remotes.Interactable.OnDoorEnter;

local random = Random.new();

local starterCharacter = game.StarterPlayer:WaitForChild("StarterCharacter");

if RunService:IsServer() then
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	
end

local Arc = {
	Color = Color3.fromRGB(29, 0, 255);
	Color2 = Color3.new(1, 1, 1);
	Amount = 4;
	Thickness = 0.3;
};
return function()
	local Tool = {};
	Tool.IsActive = false;
	Tool.UseCooldown = 1;
	Tool.HideCrosshair = false;
	
	function Tool:ClientPrimaryFire()
		local localplayer = game.Players.LocalPlayer;
		local modData = require(localplayer:WaitForChild("DataModule"));
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
			
			local distance = (position-modCharacter.RootPart.Position).Magnitude;
			if distance >= 24 then return end;
			
			local model = basePart.Parent;
			if model:IsA("Accessory") then
				model = model.Parent;
			end
			
			local npcStatus = model:FindFirstChild("NpcStatus");
			local humanoid = model:FindFirstChildWhichIsA("Humanoid");
			
			if (humanoid and humanoid.Health > 0 or npcStatus) then
				local hitSoundRoll = random:NextNumber(0,1) == 1 and "BulletBodyImpact" or "BulletBodyImpact2";
				modAudio.Play(hitSoundRoll, nil, false, 1/((index+1)*0.9));
			end
			
			shotData.Target = basePart;
		end

		shotData.RayPoint = modMechanics.CastHitscanRay{
			Origin = mouseProperties.Focus.p;
			Direction = mouseProperties.Direction;
			IncludeList = rayWhitelist;
			Range = 20;
			
			OnCastFunc = onCast;
		};
		
		pcall(function()
			modAudio.Play("Shock", self.Handle);	
			if self.Prefab:FindFirstChild("glow") then
				self.Prefab.glow.Material = Enum.Material.Plastic;
				delay(self.UseCooldown, function()
					if self.Prefab:FindFirstChild("glow") == nil then return end;
					self.Prefab.glow.Material = Enum.Material.Neon;
				end)
			end
		end)
		
		return shotData;
	end
	
	function Tool:OnPrimaryFire(isActive, ...)
		local shotdata = ...;
		if shotdata == nil then return end;
		
		local classPlayer = modPlayers.Get(self.Player);
		
		local weaponModel = self.Prefabs[1];
		local handle = weaponModel.Handle;
		local hookPoints = weaponModel.points;
		
		local function clear()
			if self.Cache == nil then self.Cache = {}; end;
			for _, obj in pairs(self.Cache) do
				obj:Destroy();
			end
			table.clear(self.Cache);
			
			for _, obj in pairs(weaponModel:GetChildren()) do
				if obj.Name == "HookPoints" or obj.Name == "RopeConstraint" then
					Debugger.Expire(obj, 0);
				end
			end
			
			if self.NpcModule then
				if self.NpcModule.RootPart and self.NpcModule.FakeBody and self.NpcModule.FakeBody.PrimaryPart then
					self.NpcModule.RootPart.CFrame = self.NpcModule.FakeBody:GetPrimaryPartCFrame();
				end
				
				if self.NpcModule.FakeBody then
					Debugger.Expire(self.NpcModule.FakeBody, 0);
				end
				if self.NpcModule.Humanoid then
					self.NpcModule.Humanoid.PlatformStand = false;
				end
				self.NpcModule.Disabled = nil;
				self.NpcModule = nil;
			end
			
			modStatusEffects.Ragdoll(self.Player, false, true);
			RunService.Heartbeat:Wait();
			if classPlayer.RootPart:CanSetNetworkOwnership() then
				classPlayer.RootPart:SetNetworkOwner(self.Player);
			end;
		end
		clear();
		
		if self.ClearRagdollConn == nil then
			self.ClearRagdollConn = true;
			local desConn;
			desConn = weaponModel:GetPropertyChangedSignal("Parent"):Connect(function()
				if weaponModel.Parent == workspace.Debris or weaponModel.Parent == nil then
					clear();
					self.ClearRagdollConn = nil;
					desConn:Disconnect();
					self.DoorEnterConn:Disconnect();
					self.DoorEnterConn = nil;
				end
			end)
		end
		if self.DoorEnterConn == nil then
			self.DoorEnterConn = bindOnDoorEnter.Event:Connect(function(player, interactData)
				local classPlayer = modPlayers.GetByName(player.Name);
				
				if self.NpcModule and not self.NpcModule.IsDead then
					self.NpcModule.RootPart.CFrame = classPlayer.RootPart.CFrame;
				end
			end)
		end
		
		if shotdata.Target then
			local hitPart = shotdata.Target;
			local model = hitPart.Parent;
			local damagable = modDamagable.NewDamagable(model);
			
			
			if damagable and damagable.Object.ClassName == "NpcStatus" then
				local npcStatus = damagable.Object;
				local npcModule = npcStatus:GetModule();
				
				
				if npcModule.Humanoid.Name == "Zombie" then
					if npcModule.Properties.BasicEnemy then
						self.NpcModule = npcModule;
						
					else
						Debugger:Log("Attempt to latch on to non-basic enemy")
						
					end
				end
			else
				self.NpcModule = nil;
			end
		end
		
		if shotdata.Target then
			if self.NpcModule and self.NpcModule.Humanoid and self.NpcModule.Humanoid.Health > 0 then
				local prefab: Model = self.NpcModule.Prefab;
				
				local fakeBody: Model = prefab:Clone();
				fakeBody:PivotTo(prefab:GetPivot());
				fakeBody.Parent = workspace.Entities;
				
				Debugger.Expire(fakeBody, 300);
				self.NpcModule:TeleportHide();
				
				local fakeHumanoid = fakeBody:FindFirstChildWhichIsA("Humanoid");
				if fakeHumanoid then
					fakeHumanoid.PlatformStand = true;
					
					fakeHumanoid.Died:Connect(function()
						clear()
						if self.NpcModule then
							self.NpcModule:KillNpc();
						end
					end)
				end
				
				prefab.Destroying:Connect(function()
					clear();
					fakeBody:Destroy();
				end)
				
				local fakeNpcStatus = fakeBody:FindFirstChild("NpcStatus");
				if fakeNpcStatus then
					fakeNpcStatus:Destroy();
				end
				
				
				local fakeRootPart = fakeBody:WaitForChild("HumanoidRootPart");
				fakeRootPart.Massless = true;

				for _, obj in pairs(fakeBody:GetDescendants()) do
					if obj:IsA("Sound") then
						obj:Destroy();
					elseif obj:IsA("BasePart") then
						obj.CustomPhysicalProperties = PhysicalProperties.new(0, 0.5, 1, 0.3, 1);
					end
				end
				if fakeRootPart:CanSetNetworkOwnership() then
					fakeRootPart:SetNetworkOwner(self.Player);
				end;
				wait(0.1);
				
				for _, obj in pairs(starterCharacter:GetChildren()) do
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
				
				if self.NpcModule.FakeBody then	Debugger.Expire(self.NpcModule.FakeBody, 0); end
				self.NpcModule.FakeBody = fakeBody;
				self.NpcModule.Disabled = true;
				self.NpcModule.Humanoid.PlatformStand = true;
				self.NpcModule.Think:Fire();
				
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
				fakeBody:SetAttribute("Leashed", self.Player.Name);
				
				modMission:Progress(self.Player, 53, function(mission)
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
				
				modStatusEffects.Ragdoll(self.Player, true, true);
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
					
					table.insert(self.Cache, pAtt);
					table.insert(self.Cache, newRope);
					
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
	
	return Tool;
end;