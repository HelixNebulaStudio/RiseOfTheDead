--!strict

local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;

local currentCamera = workspace.CurrentCamera;

--==
local SpectateManager = {};
SpectateManager.__index = SpectateManager;

--==

function SpectateManager:SetSpectate()
	if RunService:IsClient() then
		
		local currentIndex = 0;

		local aliveHumanoids = {};
		for _, player in pairs(game.Players:GetPlayers()) do
			local humanoid = player.Character and player.Character:FindFirstChild("Humanoid") or nil;
			if humanoid == nil or humanoid.Health <= 0 then continue end;
			
			table.insert(aliveHumanoids, {Humanoid=humanoid; UserId=player.UserId});
		end
		
		table.sort(aliveHumanoids, function(a, b)
			return a.UserId > b.UserId;
		end)
		
		for a=1, #aliveHumanoids do
			if aliveHumanoids[a].Humanoid == currentCamera.CameraSubject then
				currentIndex = a;
				break;
			end
		end

		if #aliveHumanoids > 0 then
			local nextIndex = currentIndex +1;
			local alive = aliveHumanoids[nextIndex > #aliveHumanoids and 1 or nextIndex];
			
			currentCamera.CameraSubject = alive.Humanoid;
		end
	end
end

return SpectateManager;
