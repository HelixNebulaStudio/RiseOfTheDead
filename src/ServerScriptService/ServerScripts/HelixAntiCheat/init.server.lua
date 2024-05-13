local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait() until shared.MasterScriptInit == true;

--== Variables;
local Players = game.Players;
local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");
local MarketplaceService = game:GetService("MarketplaceService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modGameLogService = require(game.ReplicatedStorage.Library.GameLogService);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

local modHashLib = require(game.ReplicatedStorage.Library.Util.HashLib);

local templateClientAntiCheat = script:WaitForChild("ClientHelixAntiCheat");
local clientAntiCheatCore = templateClientAntiCheat:WaitForChild("AntiCheatCore");

local coreLibraries = {};
for _, obj in pairs(clientAntiCheatCore:GetChildren()) do
	if obj:IsA("ModuleScript") then
		coreLibraries[obj.Name] = obj;
	end
end


local remotes = game.ReplicatedStorage.Remotes;
local remoteTinker = Instance.new("RemoteFunction"); remoteTinker.Name = "Tinker"; remoteTinker.Parent = remotes;

local HOURINSECS = 3600;
local DAYINSECS = 86400;


local function IsAuthorized(player)
	if modGlobalVars.IsCreator(player) then
		return true;
	end
	return false;
end

local function LogToAdminConsole(target, msg)
	modGameLogService:Log(target.UserId.." ("..target.Name.."): ".. msg, script.Name);
end

local function LogToAnalytics(msg)
	task.spawn(function()
		modAnalytics:ReportError("Security Alert", msg, modBranchConfigs.CurrentBranch.Name == "Dev" and "debug" or "critical");
	end)
end

--=== Case Class
local Case = {};
Case.__index = Case;
Case.List = {};

function Case.Get(playerName)
	playerName = tostring(playerName);
	return Case.List[playerName];
end

function Case.new(name)
	local seed = math.random(111111111, 999999999);
	local self = {
		Name = name;
		CastInitTick = tick();

		Seed = seed;
		KeyGen = Random.new(seed);
		TamperingCount = 0;
		
		Debounce = false;
		LastInvoke = tick();
		
		CFrameLog = {};
		LastIllegalMovement = tick();
		IllegalCount = 0;
		
		TotalIllegalCount = 0;
		TotalTamperingCount = 0;
		TotalFailedResponse = 0;
	};
	
	setmetatable(self, Case);
	Case.List[name] = self;
	
	return self;
end

function Case:Destroy()
	self.Destroyed = true;
	Case.List[self.Name] = nil;
end

function Case:TestKeys(keys)
	if keys == nil then return false end;
	keys = typeof(keys) ~= "table" and {keys} or keys;

	local keyGen = self.KeyGen;
	local tempCloneKeyGen = keyGen:Clone();
	
	local keyBuffer = {
		modHashLib.md5(tostring(tempCloneKeyGen:NextInteger(1111111111, 9999999999)));
		modHashLib.md5(tostring(tempCloneKeyGen:NextInteger(1111111111, 9999999999)));
	};
	
	local keyMatchFound = false;
	local keyGenUpdates = 2;
	
	for a=1, #keys do
		local findIndex = table.find(keyBuffer, keys[a]);
		if findIndex ~= nil then
			keyMatchFound = true;

			if findIndex ~= a then
				if a > findIndex then
					Debugger:Warn("Client lacking", findIndex, a);
					LogToAnalytics("Client lacking on key match.");
					keyGenUpdates = 1;

				elseif findIndex > a then
					Debugger:Warn("Server lacking", findIndex, a)
					LogToAnalytics("Server lacking on key match.");
					keyGenUpdates = 3;
					
				end
			end
			break;
		end
	end
	
	for a=1, keyGenUpdates do
		keyGen:NextNumber();
	end
	
	--Debugger:Warn("Test ", keyMatchFound, " keys", keys, "keyBuffer", keyBuffer);
	return keyMatchFound;
end

--===
local AntiCheatService = {};
AntiCheatService.__index = AntiCheatService;

local function TinkerInvokeClient(player, action, ...)
	local case = Case.Get(player.Name);
	if case == nil then Debugger:Warn("Missing player case", player); return {}; end;
	Debugger:Log("TinkerInvokeClient", player, action);
	
	case.LastInvoke = tick();
	
	local paramPacket = {...};
	local rPacket;
	
	local invokeValid = false;

	if case.ClientIgnited ~= true then
		LogToAnalytics("Client failed to ignite.");
		return {};
	end
	local s, e;
	task.spawn(function()
		s, e = pcall(function()
			if not game.Players:IsAncestorOf(player) then 
				s = false;
				e = "disconnected";
				return;
			end;
			
			rPacket = remoteTinker:InvokeClient(player, action, unpack(paramPacket));
			invokeValid = case:TestKeys(rPacket and rPacket.Key or nil);

			if not invokeValid then
				case.TamperingCount = case.TamperingCount +1;
				Debugger:Warn("Invalid clientInvoke key, tampering detected?");

				if case.TamperingCount >= 3 then
					LogToAnalytics("Server Remote tempering.");
					LogToAdminConsole(player, "Remote return tampering count: "..case.TamperingCount);
				end
			end
		end)
	end)
	
	for a=0, 60*5 do
		if s ~= nil then
			break;
		else
			task.wait(1/60);
		end
	end
	
	if s == nil then
		s = false;
		e = "Failed to receive response in time.";
		Debugger:Warn("Failed to receive response in time.", player);
		case.TotalFailedResponse = case.TotalFailedResponse +1;

		if case.TotalFailedResponse >= 3 then
			LogToAnalytics("Failed to receive response in time.");
			--LogToAdminConsole(player, "Failed to receive response in time.: "..case.TotalFailedResponse);
		end
	end
	
	if not s then
		if string.match(e, "disconnected during remote call") then
		end
		Debugger:Warn("Failed to retrieve client anticheat response:", e);
	end

	if typeof(rPacket) ~= "table" then
		rPacket = {};
	end

	rPacket.Success = invokeValid;

	if rPacket.Success then 
		--Debugger:Warn("Successful response", action);

	else
		Debugger:Warn("Invalid invokeClient key", player, rPacket);

	end;

	return rPacket;
end
AntiCheatService.InvokeClient = TinkerInvokeClient;

function AntiCheatService:GetAverageDistance(player, targetPos)
	if player == nil then return -1 end;
	
	local case = Case.Get(player.Name);
	if case == nil then return -2; end;
	
	local cframeLog = case.CFrameLog;
	if cframeLog == nil then return -3; end;
	
	local avgDistance;
	local logsCount = math.min(#cframeLog, 30);
	local rangeMax, rangeMin = #cframeLog, #cframeLog-logsCount
	
	for a=rangeMax, rangeMin, -1 do
		if cframeLog[a] == nil then continue end;
		local pos = cframeLog[a].p;
		local distance = (pos-targetPos).Magnitude;
		
		if avgDistance == nil then
			avgDistance = distance;
			
		else
			avgDistance = (avgDistance + distance)/2;
			
		end
	end
	
	if avgDistance == nil then return 0 end;
	return avgDistance;
end

function AntiCheatService:GetLastTeleport(player)
	if player == nil then return 4 end;
	
	local case = Case.Get(player.Name);
	if case == nil then Debugger:Warn("Missing player case", player); return 5; end;
	
	if case.LastIllegalMovement == nil then return 6; end;
	
	return (tick()-case.LastIllegalMovement);
end

function AntiCheatService.saferequire(player, moduleScript)
	if player and player:IsA("ModuleScript") then
		Debugger:Warn("Missing player param.");
		return;
	end
	if typeof(moduleScript) == "Instance" and moduleScript:IsA("ModuleScript") then
		
		--Debugger:Log("Player (",player.Name,") requiring: ",moduleScript);
		return require(moduleScript);
	end
	
	if typeof(moduleScript) == "number" then
		LogToAnalytics("Player attempt to inject module id ("..tostring(moduleScript)..") to saferequire.")
		LogToAdminConsole(player, player.UserId.." ("..player.Name.."Attempt to inject module id ("..tostring(moduleScript)..") to saferequire.");
	end

	return;
end

local censorNames = {
	"Roblox";
	"Khronos";
	"Admin";
	"Moderator";
	"Helix Nebula";
	"Developer";
	"Creator";
	"Rise Of The Dead";
	"RiseOfTheDead";
	"ROTDDev";
	"ROTD Dev";
	"Kronos";
	"ROTD";
	"Khr0n0s";
	"Kr0n0s";
	"Khron0s";
	"Kron0s";
};

function AntiCheatService:GetStrRandomness(str, checkNum, checkSpecial) -- > 0.3 is clean;
	if str == nil or #str <= 0 then return 0 end;
	local strL = string.lower(str);
	local strU = string.upper(str);

	local lChar, uChar, nChar, sChar = 0, 0, 0, 0;
	for i=1, #str do
		local sI = string.sub(str, i, i);
		local strByte = string.byte(sI);

		if strByte < 65 or strByte > 122 then
			if checkNum and tonumber(sI) then
				nChar = nChar +1;
			elseif checkSpecial then
				sChar = sChar +1;
			end
		else
			if sI == string.sub(strL, i, i) then
				lChar = lChar +1;
			elseif sI == string.sub(strU, i, i) then
				uChar = uChar +1;
			end
		end
	end

	local l = #str;
	local r = 1;
	if lChar ~= 0 and uChar ~= 0 then
		r = (lChar-uChar)/l
	end

	if checkNum then
		r = r - (nChar/l);
	end
	if checkSpecial then
		r = r - (sChar/l);
	end
	
	return r;
end

local bannedWords = {"urinate";};
function AntiCheatService:Filter(value, player, filterNames, filterGibberish)
	if value == nil then return ""; end;
	
	local failedResult = string.rep("#", #value);
	
	local userId = player and player.UserId;
	if player == nil then
		userId = 1;
	end;
	
	local resultValue;
	local filterS, filterE = pcall(function()
		resultValue = TextService:FilterStringAsync(value, userId, Enum.TextFilterContext.PublicChat);
		resultValue = resultValue:GetChatForUserAsync(userId);
		
		for a=1, #bannedWords do
			local word = bannedWords[a];

			resultValue = string.gsub(resultValue, word, string.rep("#", #word));
		end
	end)
	if not filterS then Debugger:Warn("Filter",value,"Error:",filterE); return failedResult end;
	if type(resultValue) ~= "string" then return failedResult end;
	if value ~= resultValue then return failedResult end;
	value = resultValue;
	
	if filterNames ~= false then
		if player and not IsAuthorized(player) then
			for _, oPlayer in pairs(game.Players:GetPlayers()) do
				if player == oPlayer then continue end;
				if oPlayer.Name:lower() == value:lower() then
					return failedResult;
				end
			end
			for a=1, #censorNames do
				if value:lower():find(censorNames[a]:lower()) then
					return failedResult;
				end
			end
		end
	end
	
	if filterGibberish ~= false then
		if #value > 6 then
			local wordsList = string.split(value, " ");
			for a=1, #wordsList do
				local word = wordsList[a];
				if #word > 6 and #word < 14 then
					local r = shared.modAntiCheatService:GetStrRandomness(word, true, true);
					if r < 0 then
						local s, _ = pcall(function()
							local v = value;
							v = v:gsub("%(", ""):gsub("%)", "");
							value = string.gsub(v, word, string.rep("#", #word));
						end)
						if not s then
							value = string.rep("#", #value);
						end
					end
				end
			end
		end
	end
	
	return value;
end


function AntiCheatService:FilterNonChatStringForBroadcast(value, player)
	if value == nil then return ""; end;

	local failedResult = string.rep("#", #value);
	
	if player == nil then
		player = game.Players:FindFirstChildWhichIsA("Player");
	end
	
	if player == nil then
		return failedResult;
	end
	
	local resultValue;
	local filterS, filterE = pcall(function()
		resultValue = TextService:FilterStringAsync(value, player.UserId, Enum.TextFilterContext.PublicChat);
		resultValue = resultValue:GetChatForUserAsync(player.UserId);

		for a=1, #bannedWords do
			local word = bannedWords[a];

			resultValue = string.gsub(resultValue, word, string.rep("#", #word));
		end
	end)
	if not filterS then Debugger:Warn("Filter",value,"Error:",filterE); return failedResult end;
	if type(resultValue) ~= "string" then return failedResult end;
	if value ~= resultValue then return failedResult end;
	value = resultValue;
	
	return value;
end


function AntiCheatService:SafeProductInfo(assetId, infoType, player)
	assetId = tonumber(assetId);
	if assetId == nil then return {}; end;
	
	local marketProductInfo;
	pcall(function()
		marketProductInfo = MarketplaceService:GetProductInfo(assetId, infoType);
	end)
	
	if marketProductInfo == nil then return end;

	if marketProductInfo.AssetTypeId == 13 then
		if marketProductInfo.IsPublicDomain == true then
			if player then
				shared.Notify(player, "Attempting to convert decal id to asset id..", "Info");
			end

			local s, e = pcall(function()
				local asset = game:GetService("InsertService"):LoadAsset(assetId);
				local objects = asset and asset:GetChildren();
				game.Debris:AddItem(asset, 5);

				if objects[1] then
					assetId = string.gsub(string.gsub("http://www.roblox.com/asset/?id=13192700114", "http://www.roblox.com/asset/", ""),"?id=", "");
					Debugger:Warn("imageId", assetId);
				end
			end)

			if not s then
				if player then
					shared.Notify(player, "Failed to convert decal id to asset id, Please use Roblox Studio to convert that id into asset id using a decal. Error: ".. tostring(e), "Negative");
				end
				return;
			end

			pcall(function()
				marketProductInfo = MarketplaceService:GetProductInfo(assetId, infoType);
			end)
			
		else
			if player then
				shared.Notify(player, "Failed to get asset id because decal id is not public.", "Negative");
			end
			
		end
	end
	
	local productInfoMeta = {};
	productInfoMeta.__index = function(_, k)
		if rawget(productInfoMeta, k) then
			return productInfoMeta[k];
		end
		return marketProductInfo[k];
	end;
	
	
	productInfoMeta.Placeholder = "rbxasset://textures/ui/GuiImagePlaceholder.png";
	
	local productInfo = setmetatable({}, productInfoMeta);
	productInfo.Updated = marketProductInfo.Updated;
	productInfo.Creator = marketProductInfo.Creator;
	productInfo.AssetTypeId = marketProductInfo.AssetTypeId;
	productInfo.ProductId = marketProductInfo.ProductId;
	
	local assetDateTime = DateTime.fromIsoDate(productInfo.Updated);
	local assetOwnerUserId = productInfo.Creator.CreatorTargetId
	
	local releaseTime = assetDateTime.UnixTimestamp;
	if player then
		local profile = shared.modProfile:Get(player);
		local trustLevel = profile.TrustLevel;
		
		local buffer = (30-math.clamp(trustLevel, 0, 30)) * HOURINSECS;
		local isCreator = player.UserId == assetOwnerUserId;
		
		if not isCreator then
			buffer = buffer+DAYINSECS;
		end
		
		releaseTime = releaseTime+buffer
		if releaseTime > os.time() then
			productInfo.Verifying = true;
			productInfo.TimeLeft = (releaseTime-os.time());
		end
	end
	
	releaseTime = releaseTime+DAYINSECS;
	if releaseTime > os.time() then
		productInfo.Verifying = true;
		productInfo.TimeLeft = (releaseTime-os.time());
	end
	
	
	return productInfo;
end


shared.modAntiCheatService = AntiCheatService;
shared.saferequire = AntiCheatService.saferequire;
shared.IsAuthorized = IsAuthorized;
--== Script;

function Kick(player, reasonId)
	local reasonList = {
		"Violated character movement limits too many times!";
	};
	local reasonStr = "Prohibited action from client!";
	if reasonList[reasonId] then reasonStr = reasonList[reasonId]; end
	
	Debugger:Warn(player.Name, reasonStr);
	
	if IsAuthorized(player) then return end;
	player:Kick(reasonStr);
end

function AntiCheatService:Teleport(player, cframe)
	local position = cframe.Position;
	
	if workspace.StreamingEnabled then
		for a=1, 3 do
			local requestStreamS, requestStreamE = pcall(function()
				player:RequestStreamAroundAsync(position);
			end)
			if requestStreamS then break; else Debugger:Warn("RequestStreamAroundAsync failed:", requestStreamE); end;
		end
	end

	local playerCase = Case.Get(player.Name);
	if playerCase == nil then return end;

	while playerCase.CFrameLog == nil do
		if not game.Players:IsAncestorOf(player) then
			break;
		end
		task.wait();
	end
	if not game.Players:IsAncestorOf(player) then return end;


	local classPlayer = shared.modPlayers.Get(player);
	local humanoid = classPlayer.Humanoid;

	if humanoid == nil then return end;
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false);
	for a=1, 3 do
		local unsitS, unsitE = pcall(function()
			--local humanoid = player and player.Character and player.Character:FindFirstChild("Humanoid");
			if humanoid and humanoid.SeatPart and humanoid.SeatPart:FindFirstChild("SeatWeld") then 
				humanoid.SeatPart.SeatWeld:Destroy();
			end
		end)
		if unsitS then break; else Debugger:Warn("Unsitting failed:", unsitE); end;
	end
	
	for statusKey, statusTable in pairs(classPlayer.Properties) do
		if typeof(statusTable) ~= "table" then continue end;
		
		if statusTable.OnTeleport then
			pcall(function()
				statusTable.OnTeleport(classPlayer, statusTable, cframe);
			end)
		end
	end
	
	for a=1, 60 do
		if workspace:IsAncestorOf(classPlayer.RootPart) then
			break;
		else
			task.wait();
		end
	end
	local rootPart = classPlayer.RootPart;
	
	table.insert(playerCase.CFrameLog, cframe);

	playerCase.TeleportCframeBuffer = cframe;
	playerCase.LastTeleport = tick();
	
	rootPart.CFrame = cframe;
	
	task.delay(0.1, function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true);
	end)
end

function OnPlayerAdded(player)
	if Case.Get(player.Name) then return end;
	Debugger:Log("Initialized on",player.Name);
	
	--== Local Helix Protector;
	local newCase = Case.new(player.Name);
	
	local localProtector = templateClientAntiCheat:Clone();
	localProtector:SetAttribute("Oracle", newCase.Seed);
	localProtector.Name = tick();
	localProtector.Parent = player:WaitForChild("PlayerGui");
	localProtector.Disabled = false;
	
	local function onCharacterAdded(character)
		local rootPart = character:WaitForChild("HumanoidRootPart");
		
		for a=1, 60 do
			if workspace:IsAncestorOf(rootPart) then
				break;
			else
				task.wait(1/60);
			end
		end
		Debugger:Log("Initialized on character "..player.Name);
		
		local _classPlayer = shared.modPlayers.Get(player);
		
		table.clear(newCase.CFrameLog);
		local cframeLog = newCase.CFrameLog;
		
		local tenSecTick = tick();
		local loggedIllegalExceed = false;
		
		rootPart:GetPropertyChangedSignal("CFrame"):Connect(function()
			table.insert(cframeLog, rootPart.CFrame);
			Debugger:StudioLog("Teleported", rootPart.CFrame)
		end)
		
		while workspace:IsAncestorOf(rootPart) do
			RunService.Stepped:Wait();
			
			if tick()-tenSecTick >= 10 then
				tenSecTick = tick();
				
				newCase.TotalIllegalCount = newCase.TotalIllegalCount + newCase.IllegalCount;
				if newCase.IllegalCount >= 10 then
					task.spawn(function()
						if loggedIllegalExceed == false then
							loggedIllegalExceed = true;
							LogToAdminConsole(player, "Exceed illegal counts. (".. newCase.TotalIllegalCount ..")")
							shared.modAntiCheatService.InvokeClient(player, "setactive", "Terrorblade", true);
						end
						LogToAnalytics("Player exceeded illegal limits.");
					end)
					
				end
				newCase.IllegalCount = 0;
				
				newCase.TotalTamperingCount = newCase.TotalTamperingCount + newCase.TamperingCount;
				newCase.TamperingCount = 0;
			end
		end
	end
	
	-- Character hook:
	local conCharacterAdded;
	conCharacterAdded = player.CharacterAdded:Connect(onCharacterAdded);
	if player.Character then
		task.spawn(onCharacterAdded, player.Character);
	end
	
	player.Destroying:Connect(function()
		newCase:Destroy();
		conCharacterAdded:Disconnect();
	end)
	
	task.delay(0.1, function()
		for a=1, 200 do
			if newCase.ClientIgnited == true then
				break;
			else
				task.wait(0.1);
			end
		end
		
		player:SetAttribute("Ignited", true);
		
		task.spawn(function()
			while game.Players:IsAncestorOf(player) do
				task.wait(10);

				if not game.Players:IsAncestorOf(player) then return; end;

				if tick()-newCase.LastInvoke < 30 then continue end;

				local rPacket = TinkerInvokeClient(player);
				if rPacket.Success then continue; end;
			end
		end)

		Debugger:Warn("Client ignited", player);
		
		if not game.Players:IsAncestorOf(player) then return end;
		Debugger.AwaitShared("modProfile");
		local liveProfile = shared.modProfile:GetLiveProfile(player.UserId);
		if liveProfile == nil then return end;

		local hacModules = liveProfile.HacModules;

		for moduleId, moduleData in pairs(hacModules) do
			if moduleData.Active == true then
				
				newCase.IllegalCount = 9;
				Debugger:Warn("Strict Terrorblade Threshold (".. player.Name ..")");
				
				--local rPacket = shared.modAntiCheatService.InvokeClient(player, "setactive", moduleId, true);
				--if rPacket.Active == true then
				--	Debugger:Warn("Activated (".. moduleId ..") for (".. player.Name ..")");
				--end
			end
		end

		--if modBranchConfigs.CurrentBranch.Name == "Dev" then
		--	TinkerInvokeClient(player, "setactive", "Terrorblade", true);
		--end
	end)
end

local modEngineCore = require(game.ReplicatedStorage.EngineCore);
modEngineCore:ConnectOnPlayerAdded(script, OnPlayerAdded, 1)

Players.PlayerRemoving:Connect(function()
	task.wait();
	for playerName, case in pairs(Case.List) do
		local player = game.Players:FindFirstChild(playerName);
		if player == nil or not game.Players:IsAncestorOf(player) then
			case:Destroy();
		end
	end
end)

function remoteTinker.OnServerInvoke(player, keys, action, packet)
	local case = Case.Get(player.Name);
	if case == nil then Debugger:Warn("Missing player case", player); return false end;
	
	local validInvoke = case:TestKeys(keys);
	
	if validInvoke == false then
		Debugger:Warn("Invalid serverInvoke key, tampering detected?");
		
		case.TamperingCount = case.TamperingCount +1;
		if case.TamperingCount >= 3 then
			LogToAnalytics("Client Remote tempering.");
			LogToAdminConsole(player, "Remote receive tampering count: "..case.TamperingCount);
		end
		
		return false;
	end;
	
	
	if action == "bane" then
		Kick(player);
		LogToAnalytics("Client bane triggered.");
		LogToAdminConsole(player, "Triggered bane.");
		
	elseif action == "sniper" then
		local ability = packet.Ability;
		
		if ability == "Ignite" then
			--Debugger:Warn("Client request ignite", player);
			case.ClientIgnited = true;
			return true;
		end
		
		local hacAbilityModule = script.HacAbilities:FindFirstChild(ability);
		hacAbilityModule = hacAbilityModule and require(hacAbilityModule) or nil;
		if hacAbilityModule then
			hacAbilityModule.LogToAnalytics = LogToAnalytics;
			return hacAbilityModule:OnSniper(player, case, packet);
			
		else
			return false;
			
		end
		
	end
	return;
end

task.spawn(function()
	Debugger.AwaitShared("modProfile");
	
	local liveProfileDatabase = shared.modProfile.LiveProfileDatabase;

	liveProfileDatabase:OnUpdateRequest("updateHacModuleData", function(requestPacket)
		local liveProfile = requestPacket.Data;
		local values = requestPacket.Values;
		
		local action = values.Action;
		
		if action == "toggleModule" then
			local moduleId = values.ModuleId;
			
			if liveProfile.HacModules[moduleId] == nil then
				liveProfile.HacModules[moduleId] = {};
			end
			local moduleData = liveProfile.HacModules[moduleId];
			
			moduleData.Active = values.SetActive;
		end
		
		return liveProfile;
	end)

	local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

	Debugger.AwaitShared("modCommandsLibrary");
	shared.modCommandsLibrary:HookChatCommand("hac", {
		Permission = shared.modCommandsLibrary.PermissionLevel.Admin;
		Description = [[Helix Anit-Cheat
			/hac "setactive" "module" userId boolean
			/hac "getactive" userId
			/hac "listmods"
		]];

		RequiredArgs = 1;
		Function = function(speaker, args)
			local player = speaker;
			
			local action = args[1];
			
			if action == "setactive" then
				local moduleId = args[2];
				local userId = args[3];
				local setActive = args[4] == true;

				if userId == nil then
					userId = speaker.UserId;
				end
				
				if coreLibraries[moduleId] == nil then
					shared.Notify(player, "Module does not exist: ".. moduleId, "Inform");
					return;
				end
				
				local targetPlayer = game.Players:GetPlayerByUserId(userId);
				if targetPlayer then
					local rPacket = TinkerInvokeClient(targetPlayer, "setactive", moduleId, setActive == true);
					shared.Notify(player, "Tinker Invoked to (".. targetPlayer.Name .."), Success: ".. tostring(rPacket.Active), "Inform");
				end

				local databasePacket = liveProfileDatabase:UpdateRequest(tostring(userId), "updateHacModuleData", {
					Action="toggleModule";
					ModuleId=moduleId;
					SetActive=setActive;
				});
				if databasePacket.Success then
					Debugger:Warn("setactive returnPacket.Data", databasePacket.Data);
				end
				
				return;

			elseif action == "getactive" then
				local userId = args[2];
				
				if userId == nil then
					userId = speaker.UserId;
				end

				local targetPlayer = game.Players:GetPlayerByUserId(userId);
				if targetPlayer == nil then
					shared.Notify(player, "Players does not exist in this server: ".. userId, "Inform");
					return 
				end
				
				local rPacket = TinkerInvokeClient(targetPlayer, "getactive");
				
				if rPacket.Success then
					local concatList = #rPacket.List > 0 and table.concat(rPacket.List, ",\n") or "Empty list";
					shared.Notify(player, "Player module list:\n"..concatList, "Inform");
					
				else
					shared.Notify(player, "Failed to acquire client modules list.", "Inform");
					Debugger:Warn("Failed rPacket", rPacket);
					
				end

			elseif action == "listmods" then

				shared.Notify(player, "Modules List:", "Inform");
				
				local a = 1;
				for moduleId, _ in pairs(coreLibraries) do
					shared.Notify(player, a..": ".. moduleId, "Inform");
					a = a +1;
				end

			elseif action == "lackserver" then

				local case = Case.Get(player.Name);
				case.KeyGen:NextNumber();

			--elseif action == "lackclient" then
			--	TinkerInvokeClient(speaker, "lackclient")
				
			elseif action == "trigger" then
				local moduleId = args[2];
				local userId = args[3];

				local param = {};
				for a=4, #args do
					table.insert(param, args[a]);
				end

				if userId == nil then
					userId = speaker.UserId;
				end
				
				if coreLibraries[moduleId] == nil then
					shared.Notify(player, "Module does not exist: ".. moduleId, "Inform");
					return;
				end
				
				local targetPlayer = game.Players:GetPlayerByUserId(userId);
				if targetPlayer then
					local rPacket = TinkerInvokeClient(targetPlayer, "trigger", moduleId, unpack(param));
					shared.Notify(player, "Tinker Invoked to (".. targetPlayer.Name .."), Success: ".. tostring(rPacket.Active), "Inform");
				end

				
				return;

			end

			return;
		end;
	});
	
	shared.modCommandsLibrary:HookChatCommand("getuserid", {
		Permission = shared.modCommandsLibrary.PermissionLevel.Admin;
		Description = [[Gets userid of a player.]];

		RequiredArgs = 0;
		Function = function(speaker, args)
			local player = speaker;

			local playerName = args[1];
			if playerName then
				local matches = modCommandHandler.MatchName(playerName);
				if #matches == 1 then
					player = matches[1];

				elseif #matches > 1 then
					shared.Notify(speaker, "Got multiple matches for: ".. tostring(playerName), "Inform");
					return;

				elseif #matches < 1 then
					player = nil;
				end
			end
			
			if player then
				shared.Notify(speaker, "User id for (".. player.Name ..") = ".. player.UserId, "Inform");
			else
				shared.Notify(speaker, "Failed to find playerName (".. playerName ..").", "Negative");
			end

			return;
		end;
	});

	shared.modCommandsLibrary:HookChatCommand("faketeleport", {
		Permission = shared.modCommandsLibrary.PermissionLevel.Admin;
		Description = [[Teleport with fake info]];

		RequiredArgs = 0;
		Function = function(speaker, args)
			local player = speaker;

			local case = Case.Get(player.Name);
			local classPlayer = shared.modPlayers.Get(player);
			
			case.TeleportCframeBuffer = CFrame.new();
			case.LastTeleport = tick();
			Debugger:Warn("Fake TeleportCframeBuffer", case.Position);

			classPlayer.RootPart.CFrame = CFrame.new(-152, -14, 015);

			return;
		end;
	});
	
	
end)