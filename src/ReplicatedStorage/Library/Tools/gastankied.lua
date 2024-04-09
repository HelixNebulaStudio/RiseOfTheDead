local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local PhysicsService = game:GetService("PhysicsService");
local RunService = game:GetService("RunService");

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modExplosionHandler = require(game.ReplicatedStorage.Library.ExplosionHandler);

local TargetableEntities = modConfigurations.TargetableEntities;

local remotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = remotes.IsInDuel;

local random = Random.new();

return function(handler)
	local Structure = {};
	Structure.WaistRotation = math.rad(0);
	Structure.PlaceOffset = CFrame.Angles(0, math.rad(-90), 0);
	
	Structure.Prefab = "gastankied";
	Structure.BuildDuration = 1;
	
	Structure.Duration = 10;
	Structure.Distance = 64;
	Structure.BlastForce = 100;
	
	function Structure:OnSpawn(prefab)
		local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);
		local player = self.Player;
		local base = prefab.PrimaryPart;
		
		local textLabel = prefab:WaitForChild("Screen"):WaitForChild("SurfaceGui"):WaitForChild("timer");
		
		local startTime = modSyncTime.GetTime()+Structure.Duration;
		local clock;
		clock = modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
			textLabel.Text = math.clamp(math.floor(startTime-modSyncTime.GetTime()), 0, Structure.Duration);
			modAudio.Play("ClockTick", base);
			
			if modSyncTime.GetTime() <= startTime then return end;
			
			local lastPosition = base.Position;
			
			modAudio.Play("ClockTick", base);
			modAudio.Play(random:NextInteger(1, 2) == 1 and "Explosion" or "Explosion2", base);
			local ex = Instance.new("Explosion");
			ex.DestroyJointRadiusPercent = 0;
			ex.BlastRadius = Structure.Distance;
			ex.BlastPressure = 0;
			ex.Position = lastPosition;
			ex.Parent = workspace;
			
			for _, obj in pairs(prefab:GetChildren()) do if obj ~= base then obj:Destroy() end; end
			clock:Disconnect();
			Debugger.Expire(prefab, 6);
			

			local hitLayers = modExplosionHandler:Cast(lastPosition, {
				Radius = Structure.Distance;
			});

			modExplosionHandler:Process(lastPosition, hitLayers, {
				OnPartHit=function(hitPart)
					if hitPart.Anchored then return end
					if not workspace.Environment:IsAncestorOf(hitPart) then return end;


					local rootModel = hitPart;
					while rootModel:GetAttribute("DynamicPlatform") == nil do
						rootModel = rootModel.Parent;
						if rootModel == workspace or rootModel == game then break; end
					end
					if rootModel:GetAttribute("DynamicPlatform") then return end;


					local assemblyRootPart = hitPart:GetRootPart();
					if assemblyRootPart and assemblyRootPart.Anchored ~= true then
						assemblyRootPart.Velocity = (assemblyRootPart.Position-lastPosition).Unit*30;
					end
				end;

				Owner = player;

				DamageRatio = 0.24;
				MinDamage = 120;
				MaxDamage = 100000;
				ExplosionStun = 10;
			});
			
		end)
		
	end
	
	setmetatable(Structure, handler);
	return Structure;
end;