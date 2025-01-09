local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

--== Server Variables;
if RunService:IsServer() then
	
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("BioXResearch") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		
		Debugger:Warn("Play cutscene for ", players);

		CutsceneSequence:NextScene("PlayCamera");
	end)
	
	CutsceneSequence:NewScene("PlayCamera", function()
		local focusCf = CFrame.new(-104.409981, -14.1441832, -135.329193, 0.86163938, 0.0280792918, -0.50674361, 1.86264493e-09, 0.998468399, 0.0553263761, 0.507520914, -0.0476713851, 0.860319734);
		
		local cfA = CFrame.new(-149.570816, 2.37724638, -114.463188, 0.375645101, 0.333804518, -0.864560723, 7.45057971e-09, 0.932881594, 0.36018306, 0.926763535, -0.135301009, 0.350432426);
		local cfB = CFrame.new(-68.198082, 3.62026238, -105.040527, 0.59140867, -0.318891972, 0.740637362, -0, 0.918480992, 0.395465106, -0.806371927, -0.233881488, 0.543197632);
		
		local sTick;
		local duration = 6;
		local modCameraGraphics = require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);
		modCameraGraphics:Bind("CameraHijack", {
			RenderStepped=function(camera)
				camera.Focus = focusCf
				
				if sTick == nil then
					sTick = tick();
				end
				camera.CFrame = cfA:Lerp(cfB, math.clamp(tick()-sTick, 0, duration)/duration)
			end;
		}, 2, duration);
	end)
	
	return CutsceneSequence;
end;