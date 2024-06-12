local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local VexSpitter = {}
VexSpitter.__index = VexSpitter;
--


local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

local spitterHeadPrefab = script:WaitForChild("VexeronSpitterHead");

function VexSpitter.Spawn(origin, parent, param)
	local self = {};
	
	local newSpitterHead = spitterHeadPrefab:Clone();
	newSpitterHead.Name = "Vexsplitter"
	newSpitterHead.CFrame = CFrame.new(origin);
	newSpitterHead.CollisionGroup = "Default";
	newSpitterHead.Parent = parent;
	newSpitterHead.CanCollide = false;
	
	newSpitterHead:SetNetworkOwner(nil);
	
	self.SpitterHead = newSpitterHead;
	
	if param.WeldTo then
		newSpitterHead.Anchored = false;
		newSpitterHead.Massless = true;

		local weld = Instance.new("Motor6D");
		weld.Parent = newSpitterHead;
		weld.Part0 = newSpitterHead;
		weld.Part1 = param.WeldTo;
		weld.C0 = CFrame.new(0, -20, 0) * CFrame.Angles(math.rad(90), math.rad(math.random(1, 360)), 0);
	end
	
	setmetatable(self, VexSpitter);
	return self;
end

function VexSpitter:FireProj(targetPart)
	if self.Destroyed then return end;

	local targetPoint = targetPart;
	if targetPart:IsA("BasePart")  then
		targetPoint = targetPart.Position;
	end
	
	local projectileObject = modProjectile.Fire("ElderVexSpit", CFrame.new(self.SpitterHead.Position));
	local velocity = (targetPoint-self.SpitterHead.Position).Unit * projectileObject.Configurations.ProjectileVelocity;
	
	local rayWhitelist = {workspace.Environment:FindFirstChild("Scene");};
	local charactersList = CollectionService:GetTagged("PlayerCharacters");
	if charactersList then 
		for a=1, #charactersList do
			table.insert(rayWhitelist, charactersList[a]);
		end
	end
	
	modProjectile.ServerSimulate(projectileObject, self.SpitterHead.Position, velocity, rayWhitelist);
end


return VexSpitter;
