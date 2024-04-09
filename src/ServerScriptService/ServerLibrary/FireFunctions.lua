local FireFunctions = {};
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configurations;
local webApiUrl = "https://rise-of-the-dead.firebaseapp.com/api/v1/"; -- Requires https://

--== Services;
local HttpService = game:GetService("HttpService");

--== Dependencies;
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

--== Script;
local function expressParams(params)
	local r = "";
	for a=1, #params do
		r = r.."/"..params[a];
	end
	return r;
end

function FireFunctions:Call(funcName, params, body)
	params = expressParams(params);
	local res;
	local tries = 0;
	
	local req = {
		Url=webApiUrl..HttpService:UrlEncode(funcName..params).."/",
		Method="GET",
		Headers={
			["Cache-Control"]="no-cache";
			["Pragma"]="no-cache";
			["Expires"]="5";
			["Content-Type"] = "application/json";
		};
		Body=body;
	};
	repeat
		tries = tries +1;
		local s, e = pcall(function()
			if #game.Players:GetPlayers() > 0 then
				--modAnalytics.RecordResource(game.Players:GetPlayers()[1], 1, "Source", "ServerRequest", "Called", funcName);
			end
			res = HttpService:RequestAsync(req);
		end)
		if s and res.Success then
			Debugger:Warn(funcName, "Success");
			return res.Body and #res.Body > 0 and res.Body or nil;
		end
	until s or tries > 2;
	Debugger:Warn(funcName,"Failed", res.StatusMessage);
end

--local function comment()
--local HttpService = game:GetService("HttpService");
--local req = {
--	Url="https://rise-of-the-dead.firebaseapp.com/api/v1/findPlayerServer/DevServers/",
--	Method="GET"
--};
--local res = HttpService:RequestAsync(req);
--print(res.Status, res.Body);
--
--local HttpService = game:GetService("HttpService");
--local packet = {
--	WorldName = "TheUnderground";
--	Version = 5343674960;
--	MaxPlayers = 8;
--	Tick = 1576943044;
--}
--local req = {
--	Url="https://rise-of-the-dead.firebaseapp.com/api/v1/findSuitableWorldServer/DevServers/"..HttpService:UrlEncode(HttpService:JSONEncode(packet)),
--	Method="GET"
--};
--local res = HttpService:RequestAsync(req);
--print(res.Status, res.Body);
--
--end

return FireFunctions;