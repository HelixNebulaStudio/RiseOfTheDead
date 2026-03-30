local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local PhysicsService = game:GetService("PhysicsService");

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modStatusLibrary = shared.require(game.ReplicatedStorage.Library.StatusLibrary);
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Chivalrous Kick";
	
	Tags = {};
	Binds = {};

	TouchHandler = nil;
};
local templateGreavesAndSabatonsModel;
--==

function modifierPackage.onRequire()
	modStatusLibrary:Add(modStatusClass.new{
		Id = "ChivalrousKick";
	});

	if RunService:IsClient() then return end;

	templateGreavesAndSabatonsModel = game.ReplicatedStorage.Prefabs.Effects:WaitForChild("GreavesAndSabatons");

	local chivKickKnockbackTouchHandler = modTouchHandler.new("ChivKickKnockback", 0.1);

	function chivKickKnockbackTouchHandler:OnHumanoidTouch(humanoid, hitbox, part)
		if hitbox.Parent == nil then return end;

		local characterTag = hitbox.Parent:FindFirstChild("CharacterTag");
		if characterTag == nil then return end;

		local character: Model = characterTag.Value;

		local characterClass: CharacterClass = shared.modPlayers.getByModel(character);
		if characterClass == nil then return end;

		local targetModel = part.Parent;
		if not targetModel then return end;

		local healthComp: HealthComp = modHealthComponent.getByModel(targetModel);
		if not healthComp then return end;
		targetModel = healthComp:GetModel();

		local damageTo: CharacterClass = healthComp.CompOwner :: CharacterClass;
		if not healthComp:CanTakeDamageFrom(characterClass) then return end;

		local modifierId = characterTag:GetAttribute("mId");
		local modifier: ItemModifierInstance? = characterClass.WieldComp:GetOrDefaultItemModifier(modifierId);
		if modifier == nil then return end;

		modifierPackage.Kick(modifier, targetModel);
	end

	modifierPackage.TouchHandler = chivKickKnockbackTouchHandler;
end

function modifierPackage.Kick(modifier: ItemModifierInstance, targetModel)
	if modifier.WieldComp == nil then return end;
	local ownerClass: CharacterClass = modifier.WieldComp.CompOwner :: CharacterClass;

	local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
	if healthComp == nil or healthComp.IsDead then return end;
	targetModel = healthComp:GetModel();

	local targetClass: CharacterClass = healthComp.CompOwner :: CharacterClass;
	if targetClass.ClassName ~= "NpcClass" then return end;

	if targetClass.HealthComp:CanTakeDamageFrom(ownerClass) == false then return end;

	local statusComp: StatusComp? = targetClass.StatusComp;
	if statusComp == nil then return end;

	local statusClass: StatusClassInstance? = statusComp:GetOrDefault("ChivalrousKick");
	if statusClass then return end;

	statusComp:Apply("ChivalrousKick", {
		Expires = workspace:GetServerTimeNow() + 3;
		Duration = 3;
		ApplyBy = ownerClass;
		Values = {};
	});

	local rootPart: BasePart = targetModel.PrimaryPart;
	if rootPart and rootPart.Anchored ~= true then
		local position = ownerClass:GetCFrame().Position;
		local dir = (rootPart.Position-position).Unit;
		
		local dForce = (dir * 100) + Vector3.new(0, 50, 0);

		local knockbackResistance = targetClass.Configurations.KnockbackResistant or 0;
		if targetClass.Properties.BasicEnemy and targetClass.HealthComp.CurArmor <= 0 and knockbackResistance < 1 then
			targetClass.StatusComp:Apply("ExplosionRagdoll", {
				Expires = workspace:GetServerTimeNow() + 1;
				Values = {
					Ragdoll=true;
				}
			});
		end

		if knockbackResistance < 1 then
			rootPart:ApplyImpulse(dForce 
				* rootPart.AssemblyMass 
				* (1-knockbackResistance)
			);
		end
	end
end

function modifierPackage.Binds.CharacterClassIsSlidingChanged(modifier: ItemModifierInstance, isSliding: boolean)
	if modifier.WieldComp == nil then return end;

	local playerClass: PlayerClass = modifier.WieldComp.CompOwner :: PlayerClass;
	if isSliding == false then return end

	local character: Model = playerClass.Character;

	if RunService:IsServer() then 
		task.spawn(function()
			local newGreavesAndSabatons: Model = templateGreavesAndSabatonsModel:Clone();
			
			local charTag = Instance.new("ObjectValue");
			charTag.Name = "CharacterTag";
			charTag.Value = character;
			charTag:SetAttribute("mId", modifier.Id);
			charTag.Parent = newGreavesAndSabatons;

			local rigidConstraint = Instance.new("RigidConstraint");
			rigidConstraint.Attachment0 = newGreavesAndSabatons:WaitForChild("sabatons"):WaitForChild("RightFootAttachment");
			rigidConstraint.Attachment1 = character:WaitForChild("RightFoot"):WaitForChild("RightFootAttachment");
			rigidConstraint.Parent = newGreavesAndSabatons;

			newGreavesAndSabatons.Parent = workspace.Debris;

			local hitBox = newGreavesAndSabatons:WaitForChild("hitBox");
			modifierPackage.TouchHandler:AddObject(hitBox);
			playerClass.CharacterGarbage:Tag(newGreavesAndSabatons);

			while playerClass.Properties.IsSliding == true do
				task.wait(0.1);
			end
			Debugger.Expire(newGreavesAndSabatons, 0);
			playerClass.CharacterGarbage:Untag(newGreavesAndSabatons);
		end)

	elseif RunService:IsClient() then
		task.spawn(function()
			local collisionRootPart = character:WaitForChild("CollisionRootPart");
			collisionRootPart.CollisionGroup = "PlayersPhase";
			while playerClass.Properties.IsSliding == true do
				task.wait(0.1);
			end
			collisionRootPart.CollisionGroup = "Players";
		end)

	end;
end


return modifierPackage;