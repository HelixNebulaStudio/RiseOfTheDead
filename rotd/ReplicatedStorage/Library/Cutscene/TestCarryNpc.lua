local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

--==
if RunService:IsServer() then

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule"));
end

--== Script;
return function(CutsceneSequence)
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		
		local playerClass: PlayerClass = shared.modPlayers.get(player);

		local strangerNpcClass: NpcClass = shared.modNpcs.spawn2{
			Name = "Stranger";
			Player = player;
			CFrame = playerClass:GetCFrame();
		}

		strangerNpcClass.StatusComp:Apply("ImmobilizedFriend", {});
	end)
	
	return CutsceneSequence;
end;