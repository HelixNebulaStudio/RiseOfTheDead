local PhysicsService = game:GetService("PhysicsService");
local RunService = game:GetService("RunService");
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);

local Destructible = require(game.ServerScriptService.ServerLibrary.Destructibles).new(script.Parent);

local dmgDisplayGui = script.Parent:WaitForChild("DmgDisplay");
local lastDmgTag = dmgDisplayGui:WaitForChild("lastDmgTag");
local dpsTag = dmgDisplayGui:WaitForChild("dpsTag");
local dpmTag = dmgDisplayGui:WaitForChild("dpmTag");

Destructible.Stats = {};
local updateTick = tick();
--== Script;
Destructible.Enabled = true;
Destructible.MaxHealth = 1000000;
Destructible.Health = Destructible.MaxHealth;

local highestDamag = 0;
function Destructible.OnDamaged(damage)
	Destructible.Health = math.clamp(Destructible.Health + damage, 0, Destructible.MaxHealth);
	
	Destructible.Stats.ShotCount = (Destructible.Stats.ShotCount or 0) + 1;
	Destructible.Stats.LastHit = tick();
	Destructible.Stats.LastDamage = damage;
	Destructible.Stats.TotalDamage = (Destructible.Stats.TotalDamage or 0) + damage;
	highestDamag = math.max(highestDamag, damage);
	
	if Destructible.Stats.StartTick == nil then
		Destructible.Stats.StartTick = tick();
		updateTick = tick();
	end
end

RunService.Heartbeat:Connect(function()
	local nTick = tick();
	if Destructible.Stats.StartTick then
		lastDmgTag.Text = "Damage: ".. modFormatNumber.Beautify(math.floor(Destructible.Stats.TotalDamage*10 or 0)/10) .. "  (".. Destructible.Stats.ShotCount ..")";
		
		if (nTick-updateTick) >= 0.5 then
			local dps = (Destructible.Stats.TotalDamage/(Destructible.Stats.LastHit-Destructible.Stats.StartTick));
			dpsTag.Text = "DPS: ".. modFormatNumber.Beautify(math.floor(dps*10 or 0)/10);
			
			dpmTag.Text = "Max: ".. modFormatNumber.Beautify(math.floor(highestDamag*10 or 0)/10);
		end
		
		if nTick-Destructible.Stats.LastHit >= 10 then
			Destructible.Stats = {};
			highestDamag = 0;
		end
	else
		lastDmgTag.Text = "";
		dpsTag.Text = "Ready";
		dpmTag.Text = "";
	end
end)

return Destructible;
