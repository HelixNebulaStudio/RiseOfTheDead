local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local PhysicsService = game:GetService("PhysicsService");
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local touchHandler = modTouchHandler.new("BarbedFence", 1);
return function(handler)
	local Structure = {};
	Structure.WaistRotation = math.rad(0);
	Structure.PlaceOffset = CFrame.Angles(0, math.rad(-90), 0);
	
	Structure.Prefab = "barbedwooden";
	Structure.BuildDuration = 1;
	Structure.BuildAvoidTags = {"TrapStructures"};
	
	function Structure:OnSpawn(prefab: Model)
		prefab:AddTag("TrapStructures");
		
		if modConfigurations.ExpireDeployables == true then
			Debugger.Expire(prefab, 300);
		end
		
		local modDestructible = require(prefab:WaitForChild("Destructible"));
		modAudio.Play("Repair", prefab.PrimaryPart);
		
		local debris = prefab:WaitForChild("debris");
		local hitbox = debris:WaitForChild("Hitbox");
		hitbox.Anchored = true;
		
		debris.Parent = workspace.Entities;
		
		prefab.Destroying:Connect(function()
			debris:Destroy();
			Debugger.Expire(debris, 0);
		end)
		prefab:GetAttributeChangedSignal("Destroyed"):Connect(function()
			if prefab:GetAttribute("Destroyed") ~= true then return end;
			
			Debugger.Expire(hitbox, 0);
			for _, obj in pairs(debris:GetChildren()) do
				if not obj:IsA("BasePart") then continue end
				obj.CanCollide = true;
				obj.Anchored = false;
			end
			
		end)
		touchHandler:AddObject(hitbox);
		
		local player = handler.Player;
		function touchHandler:OnHumanoidTouch(humanoid, basePart, hitPart)
			local targetModel = hitPart.Parent;
			if targetModel == nil or not targetModel:IsA("Model") then return end;
			
			local damagable = modDamagable.NewDamagable(targetModel);
			if damagable == nil or damagable.Object.ClassName ~= "NpcStatus" then return end;

			local npcStatus = damagable.Object;
			local npcModule = npcStatus:GetModule();
			
			if player == nil or damagable:CanDamage(player) then
				local healthInfo = damagable:GetHealthInfo();
				
				local damage = math.clamp(healthInfo.MaxHealth * 0.001, 10, math.huge);
				local newDmgSrc = modDamagable.NewDamageSource{
					Damage=damage;
					Dealer=player;
					ToolStorageItem=handler.StorageItem;
					TargetPart=hitPart;
				}
				damagable:TakeDamagePackage(newDmgSrc);
				
				local entityStatus = npcModule.EntityStatus;
				
				entityStatus:Apply(script.Name, {
					Expires = tick()+2;
					SlowValue = 4;
				})
				
				if npcModule.Movement then
					local barbWs = npcModule.Movement.DefaultWalkSpeed * 0.2;
					npcModule.Movement:SetWalkSpeed(script.Name, barbWs, 5, 1);
					task.delay(1.1, function()
						if npcModule.Movement == nil then return end;
						npcModule.Movement:UpdateWalkSpeed();
					end)
				end
				
				modDestructible:TakeDamagePackage(modDamagable.NewDamageSource{
					Damage=30;
				});
			end
		end
	end
	
	setmetatable(Structure, handler);
	return Structure;
end;
