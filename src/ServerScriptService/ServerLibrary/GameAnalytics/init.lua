local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local depGameAnalytics = require(game.ReplicatedStorage.Dependencies:WaitForChild("GameAnalytics")); --dependency
local depStore = require(game.ReplicatedStorage.Dependencies.GameAnalytics:WaitForChild("GameAnalytics"):WaitForChild("Store")); --dependency

--
local engVersion = modGlobalVars.EngineVersion;
depGameAnalytics:configureBuild(engVersion:sub(3, #engVersion));

function depGameAnalytics:initServer(gameKey, secretKey)
	depGameAnalytics:initialize({
		gameKey = gameKey;
		secretKey = secretKey;

		enableDebugLog = false;
	})

	depGameAnalytics:configureAvailableResourceCurrencies({"Gold"; "Money"; "Perks"; "TweakPoints"; "Time"})
	depGameAnalytics:configureAvailableResourceItemTypes({"Gameplay"; "Usage"; "Purchase"; "Trade"; "Faction"; "Sold"; "Npc"});
	depGameAnalytics:configureAvailableGamepasses({
		2649294; --passPremium
		2517190; --passWorkbench
		18321499; --passVIPTraveler
		932647; --passDonation

		--== ThirdParty;
		88723146; --helixdev test pass;
		88822531; --communitywaysidemap;
		134914087; --communityfissionbaymap;
		244342317; --communityrooftopmap;
	})
end

function depGameAnalytics:ReportError(errId, message, severity, playerId)
	
	severity = severity or "warning";
	
	if severity == "critical" 
		or severity == "debug"
		or severity == "info"
		or severity == "warning"
		or severity == "error" then
		
	else
		message = message.." (severity: "..severity..")"
		severity = "debug"
	end
	
	message = "["..errId.."] "..message;

	if RunService:IsStudio() then
		Debugger:Warn("ReportError>>",message);
		return 
	end;
	depGameAnalytics:addErrorEvent(playerId, {
		["severity"]=severity;
		["message"]=message;
	})
end

function depGameAnalytics.RecordResource(userId, Amount, FlowType, Currency, ItemType, ItemId)
	if modBranchConfigs.CurrentBranch.Name == "Dev" or RunService:IsStudio() then
		Debugger:Log("addResourceEvent", userId, Amount, FlowType, Currency, ItemType, ItemId);
		return 
	end;
	
	depGameAnalytics:addResourceEvent(userId, {
		["amount"]=Amount;
		["flowType"]=FlowType;
		["currency"]=Currency;
		["itemType"]=ItemType;
		["itemId"]=ItemId;
	});
end

function depGameAnalytics.RecordProgression(userId, progressionStatus, eventId, attempts, score)
	if modBranchConfigs.CurrentBranch.Name == "Dev" then 
		Debugger:Log("addProgressionEvent", userId, progressionStatus, eventId, attempts, score); 
		return 
	end;
	
	local p = string.split(eventId, ":");
	depGameAnalytics:addProgressionEvent(userId, {
		["progressionStatus"]=progressionStatus;
		["progression01"]=p[1];
		["progression02"]=p[2];
		["progression03"]=p[3];
		["score"] = score;
	})
end

function depGameAnalytics.RecordDesign(userId, eventId, value)
	if modBranchConfigs.CurrentBranch.Name == "Dev" then 
		Debugger:Log("addDesignEvent", userId, eventId, value); 
		return 
	end;
	
	depGameAnalytics:addDesignEvent(userId, {
		["eventId"]=eventId;
		["value"]=value;
	})
end

function depGameAnalytics:GetRemoteConfig(playerId, key)
	return depGameAnalytics:getRemoteConfigsValueAsString(playerId, {key=key;});
end

function depGameAnalytics:SyncRemoteConfigs(player)
	local module = player:FindFirstChild("RemoteConfigs");
	if module == nil then
		module = script.RemoteConfigs:Clone();
		module.Parent = player;
	end
	
	if modBranchConfigs.CurrentBranch.Name == "Dev" or RunService:IsStudio() then
		if module and depGameAnalytics.RemoteConfigJson then
			module:SetAttribute("Configurations", depGameAnalytics.RemoteConfigJson);
			
		end
		return 
	end;
	
	if module then
		local PlayerData = depStore:GetPlayerDataFromCache(player.UserId)
		if PlayerData == nil then return end;
		
		if depGameAnalytics:isRemoteConfigsReady(player.UserId) then
			local json = depGameAnalytics:getRemoteConfigsContentAsString(player.UserId);
			module:SetAttribute("Configurations", json);
			
		end
	end
end

game.ReplicatedStorage:WaitForChild("OnPlayerReadyEvent").Event:Connect(function(player)
	depGameAnalytics:SyncRemoteConfigs(player);
	task.wait(5);
	depGameAnalytics:SyncRemoteConfigs(player);
end)

return depGameAnalytics;
