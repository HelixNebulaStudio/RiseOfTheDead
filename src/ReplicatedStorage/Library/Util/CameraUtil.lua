local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;
--
local CameraUtil = {};


function CameraUtil.GetClosestPlayerToCamera(minRad, func)
	minRad = minRad or math.pi;
	
	local players = game.Players:GetPlayers();
	local closestPlayer, closestRadian = nil, math.huge;
	
	for _, player in pairs(players) do
		if player == localPlayer then continue end;

		local classPlayer = shared.modPlayers.Get(player);
		local playerCf = classPlayer:GetCFrame();

		local screenPoint, onScreen = camera:WorldToViewportPoint(playerCf.Position);
		if not onScreen then continue end;
		

		local lookVec = camera.CFrame.LookVector;
		local objVec = (playerCf.Position-camera.CFrame.Position).Unit

		local angle = lookVec:Angle(objVec);
		if angle > minRad then continue end;
		if angle >= closestRadian then continue end;
			
		if func ~= nil and func(classPlayer) == true then continue end;
		
		closestRadian = angle;
		closestPlayer = player;
		
	end
	
	return closestPlayer, closestRadian;
end

return CameraUtil;