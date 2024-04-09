local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local TweenService = game:GetService("TweenService");
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

local BossArenaMeta = {};
BossArenaMeta.__index = BossArenaMeta;
BossArenaMeta.Enemies = {};
local BossArena = setmetatable({}, BossArenaMeta);

--== Variables;
local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In);

--== Script;
function BossArena:SetRoom(room)
	BossArenaMeta.Room = room;
end

function BossArena:Start()
end

function BossArena:End()
	
end

function Initialize()
	
end

Initialize();
return BossArena;
