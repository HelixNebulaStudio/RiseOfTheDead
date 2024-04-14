local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modParallelData = require(game.ReplicatedStorage.ParallelLibrary:WaitForChild("DataModule"));
--
local Ticks = {}
Ticks.__index = Ticks;

function Ticks.new(localNpc)
	local meta = {};
	meta.__index = meta;
	meta.LocalNpc = localNpc;

	local self = {};
	
	setmetatable(meta, Ticks);
	setmetatable(self, meta);

	local prefab: Actor = self.LocalNpc.Prefab;
	local humanoid: Humanoid = self.LocalNpc.Humanoid;
	local rootPart: BasePart = self.LocalNpc.RootPart;
	
	local explosiveBlobs = prefab:WaitForChild("ExplosiveTickBlobs"):GetChildren();
	
	local activeDetonationTick = nil;
	
	local function OnDetonationTrigger()
		local newDetonationTick = prefab:GetAttribute("DetonationTime");
		
		if activeDetonationTick == newDetonationTick then return end;
		activeDetonationTick = newDetonationTick;
		
		local timeToDetonate = activeDetonationTick and (activeDetonationTick-workspace:GetServerTimeNow()) or 0;
		
		for _, obj in pairs(explosiveBlobs) do
			if not workspace:IsAncestorOf(obj) then continue end
			
			if timeToDetonate > 0 then
				if obj:GetAttribute("DefaultSize") == nil then
					obj:SetAttribute("DefaultSize", obj.Size);
				end
				
				local tweenInfo = TweenInfo.new(timeToDetonate+math.random(5,20)/100, 
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.In, 
					0,
					false,
					math.random(0,20)/100);

				local newSize = math.random(50,150)/100;
				TweenService:Create(obj, tweenInfo, {
					Size=Vector3.new(newSize, newSize, newSize);
				}):Play();
				
			else
				local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In);

				TweenService:Create(obj, tweenInfo, {
					Size=obj:GetAttribute("DefaultSize") ;
				}):Play();
				
			end
		end
	end
	
	prefab:GetAttributeChangedSignal("DetonationTime"):Connect(OnDetonationTrigger)
	OnDetonationTrigger()

	humanoid:GetAttributeChangedSignal("IsDead"):Connect(function()
		if humanoid:GetAttribute("IsDead") ~= true then return end;

		for _, obj in pairs(explosiveBlobs) do
			if not workspace:IsAncestorOf(obj) then continue end
			game.Debris:AddItem(obj, 0);
		end
		
		if modParallelData:GetSetting("DisableDeathRagdoll") == 1 then return end;
		
		local explosionPoint = rootPart.Position + Vector3.new(math.random(-20,20)/100, -1, math.random(-20,20)/100);
		for _, obj in pairs(prefab:GetChildren()) do
			if not obj:IsA("BasePart") then continue end;

			local dir = (obj.Position-explosionPoint).Unit;
			local vel = dir * obj:GetMass() *100;
			obj:ApplyImpulse(vel);
		end
	end)
	
	function self:OnRemoteEvent(action, packet)
		if action == "Detonate" then
			local effectMesh = packet[1];
			local newEffect = effectMesh.Parent;
			local speed = packet[2];
			local range = packet[3];

			Debugger.Expire(newEffect, speed);
			local duration = speed +0.3;
			TweenService:Create(effectMesh, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = Vector3.new(range,range,range)}):Play();
			TweenService:Create(newEffect, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.8}):Play();
		end
	end

	return self;
end

return Ticks;