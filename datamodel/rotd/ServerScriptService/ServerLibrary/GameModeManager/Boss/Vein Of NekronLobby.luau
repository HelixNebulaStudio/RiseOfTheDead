local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local BossArena = {};

function BossArena.BindLoad(room)
end

function BossArena.BindBegin(room)
	if shared.WorldName ~= "TheHarbor" and shared.WorldName ~= "BioXResearch" then return end;

	local areanModel = room.LobbyPrefab;
	local gate = areanModel.Scene:WaitForChild("VonBossGate");
	local gateCf = gate:GetPivot();
	
	task.delay(15, function()
		gate.Union:Destroy();
		gate.Base:Destroy();
		
		local debris = gate.Debris;
		debris.Parent = workspace.Debris;
		game.Debris:AddItem(debris, 20);
		
		for _, obj in pairs(debris:GetChildren()) do
			if obj:IsA("BasePart") then
				obj.Anchored = false;
			end
		end

		modAudio.Play("MetalCollapse", gateCf.Position); 
	end)
end

function BossArena.BindEnded(room)
end

return BossArena;