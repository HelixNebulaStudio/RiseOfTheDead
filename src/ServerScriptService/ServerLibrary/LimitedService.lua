local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local LimitedService = {}
LimitedService.__index = LimitedService;

local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modSerializer = require(game.ReplicatedStorage.Library.Serializer);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);

local remoteLimitedService = modRemotesManager:Get("LimitedService");

local limitedServiceMem = modDatabaseService:GetDatabase("LimitedData");
local limitedSerializer = modSerializer.new();

local defaultKey = "main";
local oneDaySec = 86400;
local oneMonthSec = 2592000;

--== LimitedData;
local LimitedData = {};
LimitedData.__index = LimitedData;
LimitedData.ClassType = "LimitedData";

function LimitedData.new()
	local meta = {};
	meta.__index = meta;

	local self = {
		List={};
	};
	
	setmetatable(self, meta);
	setmetatable(meta, LimitedData);
	return self;
end

limitedSerializer:AddClass(LimitedData.ClassType, LimitedData.new);	--For saving and loading classes.
--==
limitedServiceMem:OnUpdateRequest("setstock", function(requestPacket)
	local limitedData = limitedSerializer:Deserialize(requestPacket.RawData);
	if limitedData == nil then 
		limitedData = LimitedData.new(); 
	end
	local limitedId = requestPacket.Values.Id;

	limitedData.List[limitedId] = requestPacket.Values.Amount;

	return limitedSerializer:Serialize(limitedData);
end);

limitedServiceMem:OnUpdateRequest("subtractstock", function(requestPacket)
	local limitedData = limitedSerializer:Deserialize(requestPacket.RawData);
	if limitedData == nil then
		requestPacket.FailMsg = "Data does not exist";
		return;
	end
	local limitedId = requestPacket.Values.Id;

	if limitedData.List[limitedId] and limitedData.List[limitedId] > 0 then
		limitedData.List[limitedId] = limitedData.List[limitedId] -1;
		
	else
		requestPacket.FailMsg = "Out of stock";
		return;
	end

	return limitedSerializer:Serialize(limitedData);
end);

function LimitedService:GetPlayerClaim(player, id)
	local profile = shared.modProfile:Get(player);
	if profile == nil then return end;
	
end

function LimitedService:SubtractStock(id)
	local requestPacket = limitedServiceMem:UpdateRequest(defaultKey, "subtractstock", {Id=id;});
	Debugger:Log("SubtractStock requestPacket", requestPacket);
	return requestPacket.Success;
end

function LimitedService:SetStock(id, amount)
	local requestPacket = limitedServiceMem:UpdateRequest(defaultKey, "setstock", {Id=id; Amount=amount});
	Debugger:Log("SetStock requestPacket", requestPacket);
end

function remoteLimitedService.OnServerInvoke(player, action)
	if action == "fetch" then
		local rawData = limitedServiceMem:Get(defaultKey);
		local limitedData = limitedSerializer:Deserialize(rawData);
		
		local list = limitedData and limitedData.List or nil;
		
		if list then
			for k, v in pairs(list) do
				list[k] = math.min(list[k], 100);
			end
		end
		
		return list;
	end
end

task.spawn(function()
	local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

	Debugger.AwaitShared("modCommandsLibrary");
	shared.modCommandsLibrary:HookChatCommand("limited", {
		Permission = shared.modCommandsLibrary.PermissionLevel.Admin;
		Description = "LimitedService cmds\n/limited get\n/limited set key amt\n/limited sub key";

		RequiredArgs = 0;
		UsageInfo = "/limited action";
		Function = function(player, args)
			local profile = shared.modProfile:Get(player);

			local action = args[1];
			local id = args[2];

			if action == "set" and args[3] then
				LimitedService:SetStock(id, tonumber(args[3]) or 0);
				
			elseif action == "get" then
				Debugger:Warn(limitedServiceMem:Get(defaultKey));

			elseif action == "sub" then
				LimitedService:SubtractStock(id);
				
			end
			
			Debugger:Warn("/limited",table.concat(args, " "));
			return true;
		end;
	});
end)

return LimitedService;
