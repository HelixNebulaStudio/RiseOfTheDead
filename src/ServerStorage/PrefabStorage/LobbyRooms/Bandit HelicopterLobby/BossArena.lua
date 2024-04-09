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
	pcall(function()
		modAudio.Play("TornadoWarning", workspace.Environment.Residentials.ParkingLotDecor.RaidSiren.SirenMotor.sirenSpeaker); 
	end)
end

function BossArena:End()
	
end

function Initialize()
	
end

Initialize();
return BossArena;
