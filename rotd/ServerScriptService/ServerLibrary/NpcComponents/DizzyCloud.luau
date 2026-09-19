local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local tweenInfo = TweenInfo.new(1);

local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;

Component.DizzyCloudTouchHandler = nil;
--==

function Component.onRequire()
	local touchHandler = modTouchHandler.new("DizzyCloud", 1);
	touchHandler.ScanType = modTouchHandler.ScanTypes.Sphere;
	touchHandler.IgnoreTouch = true;
	touchHandler.MaxParts = 32;

	function touchHandler:WhitelistFunc()
		local rayWhitelist = CollectionService:GetTagged("EntityRootPart") or {};
		for _, playerRoots in pairs(CollectionService:GetTagged("PlayerRootParts")) do
			table.insert(rayWhitelist, playerRoots);
		end

		return rayWhitelist;
	end

	function touchHandler:OnHumanoidTouch(humanoid, basePart, part)
		local touchHealthComp: HealthComp? = modHealthComponent.getByModel(humanoid.Parent);
		if touchHealthComp == nil or touchHealthComp.IsDead then return end;

		local touchModel: Model? = touchHealthComp:GetModel();
		if touchModel == nil then return end;

		local player = touchModel and game.Players:GetPlayerFromCharacter(touchModel);

		if player then
			modStatusEffects.Dizzy(player, 3, "bloater");

		elseif touchHealthComp.CompOwner.ClassName == "NpcClass" then
			local touchedNpcClass: NpcClass = touchHealthComp.CompOwner :: NpcClass;

			if touchedNpcClass.HumanoidType ~= "Zombie" then return end;
			if touchedNpcClass.Properties.BasicEnemy ~= true then return end;
			if touchHealthComp.IsDead then return end;

			local toxicStatus = touchedNpcClass.StatusComp:GetOrDefault("ToxicMod");
			if toxicStatus then return end;

			local dmgData = DamageData.new{
				Damage = touchHealthComp.MaxHealth * 0.1,
				DamageType = "Heal"
			};

			touchHealthComp:TakeDamage(dmgData);
		end

	end

	Component.DizzyCloudTouchHandler = touchHandler;
end

function Component.new(npcClass: NpcClass)
	local self = {
		NpcClass = npcClass;
	};
	
	setmetatable(self, Component);
	return self;
end

function Component:__call(duration)
	local npcClass = self.NpcClass;
	local touchHandler = Component.DizzyCloudTouchHandler;

	task.spawn(function()
		local folder = workspace.Entities:FindFirstChild("DizzyCloud");
		if folder == nil then
			folder = Instance.new("Folder");
			folder.Name = "DizzyCloud";
			folder.Parent = workspace.Entities;
		end

		local deathPos = npcClass.RootPart.Position;
		local startSize = 6;
		local baseSize = 32;
		local cloudSize = baseSize;

		for _, obj in pairs(folder:GetChildren()) do
			if (obj.Position - deathPos).Magnitude <= obj.Size.Y+(baseSize/2) then
				deathPos = deathPos:Lerp(obj.Position, 0.5);
				startSize = cloudSize;
				cloudSize = cloudSize +(baseSize/2);
				Debugger.Expire(obj, 1);
			end
		end

		local newGasCloud = game.ReplicatedStorage.Prefabs.NpcAbilities:WaitForChild("DizzyCloud"):Clone();
		Debugger.Expire(newGasCloud, duration or 10);

		newGasCloud.Size = Vector3.new(startSize, startSize, startSize);
		newGasCloud.Position = deathPos;
		newGasCloud.Parent = folder;

		TweenService:Create(newGasCloud, tweenInfo, {
			Size = Vector3.new(baseSize, baseSize, baseSize);
		}):Play();
		task.wait(1);
		touchHandler:AddObject(newGasCloud);

		TweenService:Create(newGasCloud, TweenInfo.new(duration-1), {
			Size = Vector3.new(cloudSize, cloudSize, cloudSize);
		}):Play();
	end)
end

return Component;