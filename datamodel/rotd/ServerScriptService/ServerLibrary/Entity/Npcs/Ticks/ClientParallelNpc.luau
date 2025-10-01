
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modParallelData = shared.require(game.ReplicatedStorage.ParallelLibrary:WaitForChild("DataModule"));

local clientNpc = {};

function clientNpc.init(localNpc)
    local character: Actor = localNpc.Character;
	local humanoid: Humanoid = localNpc.Humanoid;
	local rootPart: BasePart = localNpc.RootPart;
	
	local explosiveBlobs = character:WaitForChild("ExplosiveTickBlobs"):GetChildren();
	
	local activeDetonationTick = nil;
	
	local function OnDetonationTrigger()
		local newDetonationTick = character:GetAttribute("DetonationTime");
		
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
					Transparency=1;
				}):Play();
				
			else
				local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.In);

				TweenService:Create(obj, tweenInfo, {
					Size=obj:GetAttribute("DefaultSize");
					Transparency=1;
				}):Play();
				
			end
		end
	end
	
	character:GetAttributeChangedSignal("DetonationTime"):Connect(OnDetonationTrigger)
	OnDetonationTrigger()

	humanoid:GetAttributeChangedSignal("IsDead"):Connect(function()
		if humanoid:GetAttribute("IsDead") ~= true then return end;

		for _, obj in pairs(explosiveBlobs) do
			if not workspace:IsAncestorOf(obj) then continue end
			game.Debris:AddItem(obj, 0);
		end
		
		if modParallelData:GetSetting("DisableDeathRagdoll") == 1 then return end;
		
		local explosionPoint = rootPart.Position + Vector3.new(math.random(-20,20)/100, -1, math.random(-20,20)/100);
		for _, obj in pairs(character:GetChildren()) do
			if not obj:IsA("BasePart") then continue end;

			local dir = (obj.Position-explosionPoint).Unit;
			local vel = dir * obj:GetMass() *100;
			obj:ApplyImpulse(vel);
		end
	end)

    local self = {};
	
	function self:OnRemoteEvent(action, packet)
		if action == "detonate" then
			local effectMesh = packet[1];
			if not workspace:IsAncestorOf(effectMesh) then return end; -- Probably not streamed in.

			local newEffect = effectMesh.Parent;
			local speed = packet[2];
			local range = packet[3];

			Debugger.Expire(newEffect, speed);
			local duration = speed +0.3;
			TweenService:Create(effectMesh, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = Vector3.new(range,range,range)}):Play();
			TweenService:Create(newEffect, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.8}):Play();
		end
	end

    localNpc[character.Name] = self;
end

return clientNpc;