local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modRaycastUtil = shared.require(game.ReplicatedStorage.Library.Util.RaycastUtil);
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

function toolPackage.onRequire()
	shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
		local player: Player? = eventPacket.Player;
		if player == nil then return end;

		local playerClass: PlayerClass = shared.modPlayers.get(player);
		if playerClass == nil then return end;

		if playerClass.WieldComp.ToolHandler == nil then return end;
		if playerClass.WieldComp.ItemId ~= toolPackage.ItemId then return end;

		local hitChar = playerClass.WieldComp.ToolHandler.Binds.HitCharacter;
		if hitChar == nil then return end;

		eventPacket.Returns.BindTeleport = function()
			hitChar:PivotTo(playerClass:GetCFrame());
		end
	end)
end

function toolPackage.ClientPrimaryFire(handler)
	local localPlayer = game.Players.LocalPlayer;
	local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
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

	shotData.RayPoint = modRaycastUtil.castHitscanRay{
		Origin = mouseProperties.Focus.p;
		Direction = mouseProperties.Direction;
		IncludeInstances = rayWhitelist;
		Range = 20;
		
		OnCastFunc = onCast;
	};
	
	pcall(function()
		local prefab = handler.Prefabs[1];

		modAudio.Play("Shock", prefab.PrimaryPart);	
		if prefab:FindFirstChild("glow") then
			prefab.glow.Material = Enum.Material.Plastic;
			task.delay(handler.UseCooldown, function()
				if prefab:FindFirstChild("glow") == nil then return end;
				prefab.glow.Material = Enum.Material.Neon;
			end)
		end
	end)
	
	return shotData;
end

function toolPackage.ServerUnequip(toolHandler: ToolHandlerInstance)
	local weaponModel = toolHandler.MainToolModel;
	weaponModel:SetAttribute("Leashed", nil);
end

function toolPackage.ActionEvent(toolHandler: ToolHandlerInstance, packet)
	local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

	if packet.ActionIndex ~= 1 then return end;

	local shotdata = packet.ClientPacket;
	if shotdata == nil then return end;
	
	local playerClass: PlayerClass = toolHandler.CharacterClass :: PlayerClass;
	if playerClass.ClassName ~= "PlayerClass" then return end;
	local player: Player = playerClass:GetInstance();
	
	local weaponModel = toolHandler.MainToolModel;
	local hookPoints = weaponModel.points;
	
	if toolHandler.Binds.Cache == nil then
		toolHandler.Binds.Cache = {};
		toolHandler.Garbage:Tag(toolHandler.Binds.Cache);
		toolHandler.Garbage:Tag(function()
			toolHandler.Binds.HitCharacter = nil;
		end)
	end
	local cacheBinds = toolHandler.Binds.Cache;

	local function clear()
		for _, obj in pairs(cacheBinds) do
			obj:Destroy();
		end
		table.clear(cacheBinds);
		toolHandler.Binds.HitCharacter = nil;
		weaponModel:SetAttribute("Leashed", nil);

		for _, obj in pairs(weaponModel:GetChildren()) do
			if obj.Name == "HookPoints" or obj.Name == "RopeConstraint" then
				Debugger.Expire(obj, 0);
			end
		end
		
		modStatusEffects.Ragdoll(player, false, true);
		RunService.Heartbeat:Wait();
		if playerClass.RootPart:CanSetNetworkOwnership() then
			playerClass.RootPart:SetNetworkOwner(player);
		end;
	end
	clear();

	toolHandler.Garbage:Tag(function()
		modStatusEffects.Ragdoll(player, false, true);
		if playerClass.RootPart:CanSetNetworkOwnership() then
			playerClass.RootPart:SetNetworkOwner(player);
		end;
	end)
	
	if shotdata.Target then
		local hitPart = shotdata.Target;
		local model = hitPart.Parent;

		local healthComp: HealthComp? = modHealthComponent.getByModel(model);
		local canLatch = true;
		if healthComp == nil
		or healthComp.IsDead
		or not healthComp:CanTakeDamageFrom(playerClass) then
			canLatch = false;
		end
		if healthComp then
			if healthComp.CompOwner.ClassName == "NpcClass" then
				local npcClass = healthComp.CompOwner :: NpcClass;
				if npcClass.Properties.BasicEnemy ~= true then
					canLatch = false;
				end
			end
		end

		if canLatch then
			toolHandler.Binds.HitCharacter = model;
		end
	end
	
	if shotdata.Target then
		if toolHandler.Binds.HitCharacter then
			local targetHealthComp: HealthComp? = modHealthComponent.getByModel(toolHandler.Binds.HitCharacter);

			if targetHealthComp then
				toolHandler.Garbage:Tag(targetHealthComp.OnIsDeadChanged:Connect(function(isDead)
					if isDead then
						clear();
					end
				end))
				if targetHealthComp.IsDead then
					clear();
				end
				local targetEntityClass: EntityClass = targetHealthComp.CompOwner :: EntityClass;
	
				local event: EventPacket = shared.modEventService:ServerInvoke("EntityLeash_OnLeash", {
					ReplicateTo = {player};
				}, targetEntityClass);
				if event.Cancelled ~= true then
					if targetEntityClass.ClassName == "NpcClass" then
						local npcClass = targetEntityClass :: NpcClass;
						local statusComp: StatusComp = npcClass.StatusComp;

						weaponModel:SetAttribute("Leashed", true);
						statusComp:Apply("EntityLeash", {
							ApplyBy = playerClass;
							Values = {
								WeaponModel = weaponModel;
							};
						});
					end
				end
			end
			
		else
			-- Ragdoll on target;
			local hitPart = shotdata.Target;
			
			if hitPart:IsDescendantOf(workspace.Entity) then
				return;
			end
			
			if playerClass.Humanoid:GetAttribute("IsSwimming") == true then
				return;
			end
			
			for _, oPlayer in pairs(game.Players:GetChildren()) do
				if oPlayer.Character and hitPart:IsDescendantOf(oPlayer.Character) then
					return;
				end
			end
			if not hitPart.Anchored then
				Debugger:Log("Hooked server not anchored");
				if playerClass.RootPart:CanSetNetworkOwnership() then
					playerClass.RootPart:SetNetworkOwner();
				else
					return;
				end;
			end
			
			modStatusEffects.Ragdoll(player, true, true);
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
				
				toolHandler.Garbage:Tag(pAtt);
				toolHandler.Garbage:Tag(newRope);
				table.insert(cacheBinds, pAtt);
				table.insert(cacheBinds, newRope);
				
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