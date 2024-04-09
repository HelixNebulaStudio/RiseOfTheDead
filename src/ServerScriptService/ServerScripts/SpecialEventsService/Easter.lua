local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local SpecialEvent = {};

local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

local EventSpawns = workspace:WaitForChild("Event");

local bunnyManSpawn = EventSpawns:WaitForChild("Bunny Man");
--==
modNpc.Spawn("Bunny Man", bunnyManSpawn.CFrame);

return SpecialEvent;
