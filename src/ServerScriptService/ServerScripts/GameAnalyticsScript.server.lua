--Services
local LS = game:GetService("LogService")
local MKT = game:GetService("MarketplaceService")

-- Error Logger;
local initErrLog = "";
local tempErrHook = LS.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError then
		initErrLog = initErrLog.."/"..message;
	end
end)
--Variables
local ProductCache = {}

--Modules
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local GameAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--Init
if modGlobalVars.EngineMode == "RiseOfTheDead" then

	GameAnalytics:initServer("eaa8a5236aa03b5a484899865516b7da", "db07bcadfeba23a0df2f293028c9e73dae7cc44a");
	--deprecated GameAnalytics:Init("eaa8a5236aa03b5a484899865516b7da", "db07bcadfeba23a0df2f293028c9e73dae7cc44a");
	
else
	shared.depGameAnalytics = GameAnalytics;
	
	--local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
	--local moddedSelf = modModEngineService:GetServerModule("GameAnalytics");
	--if moddedSelf then
	--	moddedSelf:Init(GameAnalytics);
		
	--else
	--	warn("GameAnalytics disabled.");
	--	LS.MessageOut:Connect(function(message, messageType)
	--		--Validate
	--		if messageType ~= Enum.MessageType.MessageError then return end		
	--		if message:match("Failed to load sound") then return end;
	--		if message:match("LocalizationService HTTP error") then return end
	--		Debugger:WarnClient(game.Players:GetPlayers(), message);
	--	end)
		
	--	tempErrHook:Disconnect();
	--	return;
	--end
end

delay(120, function()
	if shared.MasterScriptInit ~= true and #initErrLog > 0 then
		local ver = modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild;
		GameAnalytics:ReportError("Loadup Error", initErrLog);
	end
	tempErrHook:Disconnect();
end)

spawn(function() for _, Player in pairs(game.Players:GetPlayers()) do GameAnalytics:PlayerJoined(Player); end end)
game.Players.PlayerAdded:Connect(function(Player)
	GameAnalytics:PlayerJoined(Player)
end)

--Players leaving
game.Players.PlayerRemoving:Connect(function(Player)
	GameAnalytics:PlayerRemoved(Player)
end)