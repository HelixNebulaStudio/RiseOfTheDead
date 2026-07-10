local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local localPlayer = game.Players.LocalPlayer;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local ClientHandler = {};
--==

function ClientHandler.onRequire()
	local dataModule = localPlayer:WaitForChild("DataModule");
	local modData = shared.require(dataModule :: ModuleScript);

    modData.TravelRequests = {};

    local remoteMasterySync = modRemotesManager:Get("MasterySync");
	remoteMasterySync.OnClientEvent:Connect(function(name, value)
		if name == nil then return end;
		if modData.Players[name] == nil then
			modData.Players[name] = {
				Stats={
					Level=0;
				};
			};
		end;
		if modData.Players[name] and modData.Players[name].Stats then
			modData.Players[name].Stats.Level = value; 
		end
		task.wait(0.1);
        
		modClientGuis.fireEvent("UpdateSocialMenu");
	end)


	local remoteTravelRequest = modRemotesManager:Get("TravelRequest");
	remoteTravelRequest.OnClientEvent:Connect(function(userData)
		local exist = false;
		for a=1, #modData.TravelRequests do
			if modData.TravelRequests[a].UserName == userData.UserName then
				modData.TravelRequests[a] = userData;
				exist = true;
				break;
			end
		end
		if not exist then
			table.insert(modData.TravelRequests, userData);
		end
		
		modClientGuis.fireEvent("UpdateSocialMenu");
	end)

end

return ClientHandler;