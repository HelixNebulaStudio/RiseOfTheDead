local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local TweenService = game:GetService("TweenService");
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local BossArenaMeta = {};
BossArenaMeta.__index = BossArenaMeta;
BossArenaMeta.Enemies = {};
local BossArena = setmetatable({}, BossArenaMeta);

--== Variables;

--== Script;
function BossArena:SetRoom(room)
	BossArenaMeta.Room = room;
end

function BossArena:Start()
	local gate = script.Parent.Scene:WaitForChild("BossGate");
	
	task.delay(15, function()
		gate.Union:Destroy();
		gate.Base:Destroy();
		
		local debris = gate.Debris;
		debris.Parent = workspace.Debris;
		game.Debris:AddItem(debris, 20);
		
		local soundPart
		for _, obj in pairs(debris:GetChildren()) do
			if obj:IsA("BasePart") then
				obj.Anchored = false;
				if soundPart == nil then
					soundPart = obj;
				end
			end
		end
		modAudio.Play("MetalCollapse", soundPart); 
	end)
end

function BossArena:End()
	
end

function Initialize()
	
end

Initialize();
return BossArena;
