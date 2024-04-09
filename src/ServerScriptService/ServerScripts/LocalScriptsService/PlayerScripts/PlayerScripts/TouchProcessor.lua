local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
return function()
	local localplayer = game.Players.LocalPlayer;
	
	local RunService = game:GetService("RunService");
	local UserInputService = game:GetService("UserInputService");
	
	
	local modRemotesManager = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("RemotesManager"));
	local modData = require(localplayer:WaitForChild("DataModule"));

	local raycastParams = RaycastParams.new();
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist;
	raycastParams.IgnoreWater = true;
	raycastParams.CollisionGroup = "Raycast";
	
	local TouchProcessor = {};
	TouchProcessor.__index = TouchProcessor;
	
	UserInputService.InputBegan:Connect(function(inputObj, gameProcessed)
		if inputObj.UserInputType ~= Enum.UserInputType.Touch then return end;
		local camera = workspace.CurrentCamera;
		local touchPosition = inputObj.Position;

		local pointRay = camera:ScreenPointToRay(touchPosition.X, touchPosition.Y);
		
		local rayWhitelist = {workspace.Environment; workspace.Entity; workspace.Terrain; workspace.Interactables; workspace:FindFirstChild("Characters")};

		raycastParams.FilterDescendantsInstances = rayWhitelist;
		local raycastResult = workspace:Raycast(pointRay.Origin, pointRay.Direction*32, raycastParams)
		local rayHit, rayPoint, rayNormal, distance;

		if raycastResult then
			rayHit, rayPoint, rayNormal = raycastResult.Instance, raycastResult.Position, raycastResult.Normal;
			
			if RunService:IsStudio() then
				Debugger:Log("rayHit", rayHit);
			end
		end
	end)
	
	
	return TouchProcessor;
end