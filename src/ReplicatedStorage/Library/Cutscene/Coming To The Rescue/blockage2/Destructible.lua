--== Configurations;
local MaxHealth = 10000;

--== Script;
local PhysicsService = game:GetService("PhysicsService");
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local Destructible = require(game.ServerScriptService.ServerLibrary.Destructibles).new(script.Parent);
Destructible.Enabled = true;
Destructible.Health = MaxHealth;
Destructible.MissionIdTag = 48;

local BarricadeParts = script.Parent:GetChildren();
for _, c in pairs(BarricadeParts) do
	if c:IsA("BasePart") and c.Name:match("_playerClip") == nil then
		pcall(function()
			c.CollisionGroup = "Debris";
		end)
	end
end

function Destructible.OnDamaged(damage)
	local healthPercent = (Destructible.Health/MaxHealth);
	modAudio.Play("StorageWoodDrop", script.Parent:FindFirstChildWhichIsA("BasePart"));
	if healthPercent <= 0 then
		script.Parent.C.Anchored = false;
		for _, c in pairs(BarricadeParts) do
			if c.Name:match("_playerClip") then
				c:Destroy();
			elseif c:IsA("BasePart") then
				c.Anchored = false;
			end
		end
	elseif healthPercent < 0.5 then
		script.Parent.B.Anchored = false;
		
	elseif healthPercent < 1 then
		script.Parent.A.Anchored = false;
		
	end
end

return Destructible;
