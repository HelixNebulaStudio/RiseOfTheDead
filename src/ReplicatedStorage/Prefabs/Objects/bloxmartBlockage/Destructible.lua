--== Configurations;
local MaxHealth = 200;

--== Script;
local PhysicsService = game:GetService("PhysicsService");
local RunService = game:GetService("RunService");
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local Destructible = require(game.ServerScriptService.ServerLibrary.Destructibles).new(script.Parent);
Destructible.Enabled = false;
Destructible.Health = MaxHealth;

local BarricadeParts = script.Parent:GetChildren();

if RunService:IsServer() then
	for _, c in pairs(BarricadeParts) do
		if c:IsA("BasePart") and c.Name:match("_playerClip") == nil then
			pcall(function()
				c.CollisionGroup = "PlayerClips";
			end)
		end
	end
end

function Destructible.OnDamaged(damage)
	local healthPercent = (Destructible.Health/MaxHealth);
	modAudio.Play("StorageWoodDrop", script.Parent:FindFirstChildWhichIsA("BasePart"));
	if healthPercent <= 0 then
		script.Parent.E.Anchored = false;
		for _, c in pairs(BarricadeParts) do
			if c.Name:match("_playerClip") then
				c:Destroy();
			elseif c:IsA("BasePart") then
				c.Anchored = false;
			end
		end
	elseif healthPercent < 0.25 then
		script.Parent.D.Anchored = false;
	elseif healthPercent < 0.5 then
		script.Parent.C.Anchored = false;
	elseif healthPercent < 0.75 then
		script.Parent.B.Anchored = false;
	elseif healthPercent < 1 then
		script.Parent.A.Anchored = false;
	end
end

return Destructible;
