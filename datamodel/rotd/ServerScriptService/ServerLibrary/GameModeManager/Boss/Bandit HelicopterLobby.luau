local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local BossArena = {};

function BossArena.BindLoad(room)
end

function BossArena.BindBegin(room)
	if shared.WorldName ~= "TheResidentials" and shared.WorldName ~= "BioXResearch" then return end;
	modAudio.Play("TornadoWarning", Vector3.new(1223.232, 93.045, 36.035)); 
end

function BossArena.BindEnded(room)
end

return BossArena;