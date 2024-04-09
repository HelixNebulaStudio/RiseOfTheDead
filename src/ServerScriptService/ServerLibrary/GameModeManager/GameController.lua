local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modMarkers = require(game.ReplicatedStorage.Library.Markers);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);


local remoteGameModeHud = modRemotesManager:Get("GameModeHud");



local GameController = {};
GameController.__index = GameController;
--==

function GameController:SetMarker(target, label, markType)
	if target == nil then
		remoteGameModeHud:FireAllClients({
			Action="SetMarker";
			ClearMarker=true;
		})
		
	else
		remoteGameModeHud:FireAllClients({
			Action="SetMarker";
			Marker={
				Target=target;
				Label=label;
				MarkType=markType;
			};
		})
	end
end


function GameController.new(gameId, stageId)
	local self = {
		GameId=gameId;
		StageId=stageId;
	};
	
	setmetatable(self, GameController);
	return self;
end

return GameController;
