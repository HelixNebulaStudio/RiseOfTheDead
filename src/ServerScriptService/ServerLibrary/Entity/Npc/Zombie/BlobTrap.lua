local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local random = Random.new();

local TweenService = game:GetService("TweenService");

local Zombie = {};

local explosionEffectPrefab = script:WaitForChild("ExplosionEffect");
local blobPrefab = script:WaitForChild("Blob");

local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In, -1, false, 0);

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local floorGoop = {script:WaitForChild("goop1"); script:WaitForChild("goop2"); script:WaitForChild("goop3");};

local touchHandler = modTouchHandler.new("FloorGoop", 0.5);
function touchHandler:OnPlayerTouch(player, basePart, part)
	modStatusEffects.Slowness(player, 14, 1);
end

function Zombie.new(self)
	self.BlobTrapSize = 40;
	self.BlobTraps = {};
	
	return function(position)
		local new = blobPrefab:Clone();
		local blobCf = CFrame.new(position);
		new:SetPrimaryPartCFrame(blobCf * CFrame.Angles(0, math.rad(math.random(0, 360)), 0));
		new.Parent = workspace.Debris;

		local blob = new:WaitForChild("blob");
		
		local scale = 1.3;
		self.TickTween = TweenService:Create(blob, tweenInfo, {Size = Vector3.new(scale,scale,scale)});
		self.TickTween:Play();
		
		local countdown = 5;
		repeat
			countdown = countdown -1;
			modAudio.Play("ZombieAttack"..random:NextInteger(1, 3), self.RootPart).PlaybackSpeed = random:NextNumber(3.5, 3.8);
		until self.IsDead or countdown <= 0 or not wait(1);

		--local explosion = Instance.new("Explosion");
		--explosion.BlastPressure = 30;
		--explosion.BlastRadius = self.BlobTrapSize;
		--explosion.DestroyJointRadiusPercent = 0;
		--explosion.Visible = false;
		--explosion.Position = position;

		local newEffect = explosionEffectPrefab:Clone();
		newEffect.CFrame = blobCf;
		local effectMesh = newEffect:WaitForChild("Mesh");
		newEffect.Parent = workspace.Debris;
		local speed = 0.5;
		TweenService:Create(effectMesh, TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Scale = Vector3.new(self.BlobTrapSize, self.BlobTrapSize, self.BlobTrapSize)}):Play();
		TweenService:Create(newEffect, TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play();
		game.Debris:AddItem(newEffect, speed+0.1);
		modAudio.Play("TicksZombieExplode", new.PrimaryPart).PlaybackSpeed = random:NextNumber(0.8, 1);

		game.Debris:AddItem(new, 1);
		if self.IsDead then return end;
		
		local newGoop = floorGoop[math.random(1, #floorGoop)]:Clone();
		
		local sizeX = random:NextNumber(20, 25);
		newGoop.Size = Vector3.new(sizeX, 1.6, sizeX);
		newGoop.Position = position;
		newGoop.Parent = workspace.Entities;
		
		touchHandler:AddObject(newGoop);
		table.insert(self.BlobTraps, newGoop);
		
		game.Debris:AddItem(newGoop, random:NextNumber(60, 120));
	end
end

return Zombie;