local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local StatusClass = require(script.Parent.StatusClass).new();
local localPlayer = game.Players.LocalPlayer;

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local RunService = game:GetService("RunService");
--==
function StatusClass.OnApply(classPlayer, status)
	if classPlayer:GetInstance() ~= localPlayer then return; end

	classPlayer:SetProperties("Ragdoll", 1);
	classPlayer.Humanoid.PlatformStand = true;
end

function StatusClass.OnExpire(classPlayer, status)
	local humanoid = classPlayer.Humanoid;
	
	classPlayer:SetProperties("Ragdoll", 0);
	classPlayer.Humanoid.PlatformStand = false;
	humanoid.Health = math.max(humanoid.Health, 1);
	
	if RunService:IsClient() then
		if classPlayer:GetInstance() ~= localPlayer then return; end
		
		local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();
		
		modCharacter.CharacterProperties.IsWounded = false;
	end
end

function StatusClass.OnTick(classPlayer, status, tickPack)
	local humanoid = classPlayer.Humanoid;
	
	humanoid.Health = math.clamp(humanoid.Health + (tickPack.Delta/status.Duration *humanoid.MaxHealth), 1, humanoid.MaxHealth);
	
	if humanoid.Health >= humanoid.MaxHealth then
		status.Expires=modSyncTime.GetTime();
		return true;
	end
end

return StatusClass;