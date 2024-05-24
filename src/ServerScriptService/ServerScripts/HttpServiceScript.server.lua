local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local ApiKey = {
	Trello = "?key=0cfba9570609f0b9c0b680bf0e7e37c9&token=179b65a153514b2dd90169699fdcfe170aa6e518e6c69fce13fd9d7e3e45357b";
	RotdMainDatastore = "HTmIC+5XY0a6XzAjYO9vqXcN1+y8oTmSrNcR7fV0wvBgnl+B";
};

--== Variables;
local HttpService = game:GetService("HttpService");

local DataStoreService = game:GetService("DataStoreService");
local creditsDatabase = DataStoreService:GetDataStore("Credits");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modDate = require(game.ReplicatedStorage.Library.Date);
local modApiRequestLibrary = require(game.ServerScriptService.ServerLibrary.ApiRequestLibrary);

local remoteApiRequest = modRemotesManager:Get("ApiRequest");

local ApiService = {};
ApiService.__index = ApiService;

shared.modApiService = ApiService;
--==

function ApiService:FetchMainBranchSave(userId)
	local baseUrl = "https://apis.roproxy.com/datastores/v1/universes/65708455";
	local rUrl = baseUrl.."/standard-datastores/datastore/entries/entry?datastoreName=Profiles&entryKey="..userId;
	local headers = {
		["x-api-key"]=ApiKey.RotdMainDatastore;
	};
	
	local response;
	local s, e = pcall(function()
		response = HttpService:RequestAsync({
			Url=rUrl;
			Method="GET";
			Headers=headers;
		})
	end)
	
	if not s then  return nil; end;
	if s and response.StatusCode == 200 then
		local raw;
		local js, je = pcall(function()
			raw = HttpService:JSONDecode(HttpService:JSONDecode(response.Body));
			if typeof(raw) == "table" then
				raw.LastOnline = os.time();
			end
		end)
		if js then
			return raw;
		end
		Debugger:Warn("Failed Decode: ",je)
	end
	Debugger:Warn("Failed Fetch: ", e, "Response:",response)
	return nil;
end

if modBranchConfigs.GetWorld() == "MainMenu" then
	local credits;
	
	repeat
		pcall(function()
			credits = creditsDatabase:GetAsync("Credits");
		end)
		
		if credits == nil then
			task.wait(10);
		end
	until credits ~= nil;
	
	workspace:SetAttribute("CreditsJson", credits);
end

function remoteApiRequest.OnServerInvoke(player, requestId)
	if requestId == nil then return end;
	
	local requestInfo = modApiRequestLibrary:Find(requestId);
	if requestInfo == nil then return end;
	
	if requestInfo.Api == "Trello" then
		local fetchCooldown = 60;
		if game:GetService("RunService"):IsStudio() then
			fetchCooldown = 1;
		end
		if requestInfo.LastFetch == nil or tick()-requestInfo.LastFetch >= fetchCooldown then
			pcall(function()
				requestInfo.RawData = HttpService:GetAsync(requestInfo.Url..ApiKey.Trello);
			end)
			
			requestInfo.LastFetch = tick();
		end
		
		if requestInfo.RawData then
			local blogTable;
			pcall(function()
				blogTable = HttpService:JSONDecode(requestInfo.RawData);
				local t = modDate:FromISOString(blogTable.dateLastActivity);
				local date = modDate.new(t);
				blogTable.lastUpdate = date:ToString();
			end)
			
			return blogTable;
		end

	elseif requestInfo.Api == "Github" then
		local fetchCooldown = 60;
		if game:GetService("RunService"):IsStudio() then
			fetchCooldown = 1;
		end
		if requestInfo.LastFetch == nil or tick()-requestInfo.LastFetch >= fetchCooldown then
			pcall(function()
				requestInfo.RawData = HttpService:GetAsync(requestInfo.Url);
			end)
			
			requestInfo.LastFetch = tick();
		end
		
		return requestInfo.RawData;
	end

	return;
end