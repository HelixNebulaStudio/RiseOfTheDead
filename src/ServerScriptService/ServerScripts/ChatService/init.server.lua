local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
repeat task.wait() until shared.MasterScriptInit == true;
--==
local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");
local TextChatService = game:GetService("TextChatService");
local MessagingService = game:GetService("MessagingService");
local HttpService = game:GetService("HttpService");
local Players = game:GetService("Players");

local modEngineCore = require(game.ReplicatedStorage.EngineCore);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modNotificationsLibrary = require(game.ReplicatedStorage.Library.NotificationsLibrary);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modCommandsLibrary = require(game.ReplicatedStorage.Library.CommandsLibrary);
local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modFactions = require(game.ServerScriptService.ServerLibrary.Factions);

local remoteChatServiceFunction = modRemotesManager:Get("ChatServiceFunction");
local remoteChatServiceEvent = modRemotesManager:Get("ChatServiceEvent");

local textChannelsFolder;
--==
local ChatService = {};
ChatService.__index = ChatService;
ChatService.Channels = {};
ChatService.GlobalChannels = {
	Global = {};
	LookingFor = {};
	Trade = {};
};
ChatService.MsgCache = {};

ChatService.ChatHistory = modDatabaseService:GetDatabase("ChatHistory");
ChatService.ChatHistory.ExpireTime = 60;
ChatService.ChatHistory.PublishTimer = 30;

if modBranchConfigs.CurrentBranch.Name == "Dev" then
	ChatService.GlobalChannels.LookingFor = nil;
	ChatService.GlobalChannels.Trade = nil;
	ChatService.GlobalChannels.Logs = {};
	ChatService.GlobalChannels.Bugs = {};
end

function ChatService.CacheMsg(data)
	if data == nil or data.ChannelId == nil then return end;
	local channelId = data.ChannelId;
	
	if ChatService.GlobalChannels[channelId] == nil then return end
	
	if ChatService.MsgCache[channelId] == nil then 
		ChatService.MsgCache[channelId] = {};
	end
	if #ChatService.MsgCache[channelId] > 16 then
		table.remove(ChatService.MsgCache[channelId], 1);
	end
	
	table.insert(ChatService.MsgCache[channelId], data);
end

ChatService.ChatHistory:OnUpdateRequest("addmsg", function(requestPacket)
	local oldHistory = requestPacket.RawData;
	local data = requestPacket.Values;
	
	local cacheMsgs = oldHistory and HttpService:JSONDecode(oldHistory) or {};

	if #cacheMsgs > 16 then
		table.remove(cacheMsgs, 1);
	end
	table.insert(cacheMsgs, data);

	return HttpService:JSONEncode(cacheMsgs);
end)

function ChatService.GlobalCacheMsg(data)
	if data == nil or data.ChannelId == nil then Debugger:Warn("Failed to cache global msg:", data); return end;

	ChatService.ChatHistory:UpdateRequest(data.ChannelId, "addmsg", data);
end

function ChatService.SendGlobalMessage(messagePacket)
	if modServerManager.ShadowBanned then return end;
	
	messagePacket.Text = messagePacket.Text:sub(1, 200);
	messagePacket.Timestamp = tostring(DateTime.now().UnixTimestampMillis);

	task.spawn(function()
		MessagingService:PublishAsync("ChatService", messagePacket);
		ChatService.GlobalCacheMsg(messagePacket);
	end)
end


local processCache = {};
function ChatService.OnServerMessage(senderPlayer: Player, txtChatMsg: TextChatMessage, txtSrc: TextSource)
	local currTick = tick();
	local msgId = txtChatMsg.MessageId;

	if processCache[msgId] then return end;
	processCache[msgId] = currTick;

	for mId, msgTick in pairs(processCache) do
		if (currTick-msgTick) > 60 then
			processCache[mId] = nil;
		end
	end

	local txtChannel = txtChatMsg.TextChannel;
	local txtMessage = txtChatMsg.Text;

	if shared.modProfile.IsBeingRecon(senderPlayer) then
		local modDiscordWebhook = require(game.ServerScriptService.ServerLibrary.DiscordWebhook);
		modDiscordWebhook.PostText(modDiscordWebhook.Hooks.ChatLogs, `{senderPlayer.Name}\`{senderPlayer.UserId}\`: [{txtChannel.Name}] {txtMessage}`);
	end

	if txtMessage:sub(1,1) == "/" then
		return;
	end

	local senderCanChat = false;
	pcall(function()
		senderCanChat = TextChatService:CanUserChatAsync(senderPlayer.UserId);
	end)
	if not senderCanChat then return end;

	local profile = shared.modProfile:Find(senderPlayer.Name);
	local factionProfile = profile.Faction;
	local factionTag = factionProfile and factionProfile.Tag;
	local factionRole = factionProfile and factionProfile.Role;

	local textChannel = ChatService.Channels[txtChannel.Name];
	if textChannel:GetAttribute("Global") then
		Debugger:Warn("Submit global msg", txtMessage);
		
		local filteredString = "";
		pcall(function()
			filteredString = game.Chat:FilterStringForBroadcast(txtMessage, senderPlayer);
		end)
		if #filteredString > 0 then
			local messageData = {
				SpeakerName = senderPlayer.Name;
				ChannelId = textChannel.Name;
				Text = filteredString;
			};
			if senderPlayer:GetAttribute("Premium") then
				messageData.Style = "Premium";
			elseif senderPlayer:GetAttribute("PlayerLevel") then
				messageData.Style = `Level{senderPlayer:GetAttribute("PlayerLevel")}`;
			end

			local channelFactionTag = textChannel:GetAttribute("Faction")
			if channelFactionTag then
				local roleKey = factionRole or "Member";
				messageData.Style = roleKey;
			
				local factionObject = modFactions.Get(factionTag);
				if factionObject == nil or factionObject:HasPermission(tostring(senderPlayer.UserId), "CanChat") == false then
					shared.Notify(senderPlayer, `You do not have permission to chat here.`, `Negative`, nil, {Persist=false;});
					return;
				end
			end

			ChatService.SendGlobalMessage(messageData);
		end
	end

	ChatService.CacheMsg({
		SpeakerName=senderPlayer.Name;
		ChannelId=textChannel.Name;
		Text=txtMessage;
	});
end

function ChatService.DefaultShouldDeliverCallback(txtChatMsg: TextChatMessage, txtSrc: TextSource)
	local txtChannel = txtChatMsg.TextChannel;
	local senderTxtSrc: TextSource = txtChatMsg.TextSource;
	local senderPlayer = game.Players:FindFirstChild(senderTxtSrc.Name);

	ChatService.OnServerMessage(senderPlayer, txtChatMsg, txtSrc);

	local txtMessage = txtChatMsg.Text;
	if txtMessage:sub(1,1) == "/" then
		return false;
	end

	if txtChannel:GetAttribute("Global") == true then
		return false;
	end

	local profile = shared.modProfile:Find(senderPlayer.Name);
	if profile.Punishment == modGlobalVars.Punishments.ChatDisablePenalty then
		return false;
	end;

	return true;
end

function ChatService.Notify(player, message, class, key, packet)
	local function processNotification(player, message, class, key, packet)
		if player == nil then return end;
		
		local messageData = modNotificationsLibrary[class] and modNotificationsLibrary[class](message, player) or nil;
		if messageData == nil then return end;
		
		local profile = shared.modProfile:Find(player.Name);
		local notifyMode = modConfigurations.ForceNotifyStyle or (profile and profile.Settings and profile.Settings.Notifications);
		
		if notifyMode == 1 or (notifyMode == 2 and messageData.Imp == true) then
			messageData.Chat = true;
			messageData.Style = class;
			messageData.Notify = true;
			remoteChatServiceEvent:FireClient(player, "notify", key, messageData or {Message=message; Packet=packet;});
		
		elseif notifyMode == nil then -- default;
			messageData.Packet = packet;
			remoteChatServiceEvent:FireClient(player, "notify", key, messageData or {Message=message; Packet=packet;});
			
		end
	end
	if type(player) == "table" then
		for a, p in pairs(player) do
			player = game.Players:FindFirstChild(p.Name);

			if player then
				processNotification(player, message, class, key, packet)
			end

		end

	elseif typeof(player) == "Instance" and player:IsA("Player") then
		processNotification(player, message, class, key, packet);

	elseif typeof(player) == "Instance" and player:IsA("Players") then
		local players = player:GetPlayers();
		for a, p in pairs(players) do
			processNotification(p, message, class, key, packet)
		end

	else
		warn(script.Name..">>  Unknown player type: ".. typeof(player) ..", "..tostring(player) .." message: ".. tostring(message) .. " " .. tostring(class));
	end
end

function ChatService.NewTextChannel(name)
	local textChannel = Instance.new("TextChannel");
	textChannel.Name = name;
	textChannel:SetAttribute("Global", true);
	textChannel.Parent = textChannelsFolder;
	ChatService.Channels[name] = textChannel;
	return textChannel;
end

local function QuickTextFilter(text)
	local filteredTxt;
	
	for _, player in (Players:GetPlayers()) do
		if filteredTxt == nil then
			pcall(function()
				filteredTxt = game.Chat:FilterStringForBroadcast(text, player);
			end)
		else
			break;
		end
	end

	return filteredTxt;
end

function ChatService.HandleCommand(message, speaker)
	local cmd, args = modCommandHandler.ProcessMessage(message);
	if cmd == nil then return true end;
	
	local cmdKey = (cmd:sub(2, #cmd):lower());
	local cmdLib = modCommandsLibrary.Library[cmdKey];

	if cmdLib == nil then
		if speaker then
			shared.Notify(speaker, `Unknown Command: {cmd}`, `Negative`);
		end
		return;
	end

	if speaker then
		Debugger:Warn(`Player ({speaker.Name}) issued command:/{cmdKey} Args:{Debugger.Stringify(args)}`);
		if not modCommandsLibrary.HasPermissions(speaker, cmdLib) then
			shared.Notify(speaker, `Insufficient permissions.`, `Negative`, nil, {Presist=false;});
			return;
		end;
	end
	
	if cmdLib.RequiredArgs and #args < cmdLib.RequiredArgs then
		local str = `Missing arguements..\n{(cmdLib.UsageInfo or "")}`;
		if speaker then
			shared.Notify(speaker, str, `Negative`, nil, {Presist=false;});
		else
			Debugger:Warn(str);
		end
		return;
	end;
	
	if speaker then
		if cmdLib.Cooldown and cmdLib.Debounce == nil then cmdLib.Debounce = {}; end
		if cmdLib.Debounce == nil or cmdLib.Debounce[speaker.Name] == nil or tick()-cmdLib.Debounce[speaker.Name] >= cmdLib.Cooldown then
			if cmdLib.Debounce then cmdLib.Debounce[speaker.Name] = tick(); end;
			if cmdLib.Function then
				cmdLib.Function(speaker, args);
			end
			if cmdLib.ClientFunction then
				cmdLib.ClientFunction(speaker, args);
			end
	
		else
			shared.Notify(speaker, `Command is on a cooldown..`, `Negative`, nil, {Presist=false;});
			return;
		end

	else
		-- Server call
		if cmdLib.Function then
			cmdLib.Function(nil, args);
		end

	end

	return;
end

function ChatService.Init()
	TextChatService:WaitForChild("BubbleChatConfiguration").Enabled = false;

	textChannelsFolder = Instance.new("Folder");
	textChannelsFolder.Name = "TextChannels";
	textChannelsFolder.Parent = TextChatService;
	
	textChannelsFolder.ChildAdded:Connect(function(txtChannel: TextChannel)
		if not txtChannel:IsA("TextChannel") then return end;

		txtChannel.ShouldDeliverCallback = ChatService.DefaultShouldDeliverCallback;
	end)
	
	local serverTextChannel = Instance.new("TextChannel");
	serverTextChannel.Name = "Server";
	serverTextChannel:SetAttribute("Public", true);
	serverTextChannel.Parent = textChannelsFolder;
	ChatService.Channels["Server"] = serverTextChannel;
	
	for k, _ in pairs(ChatService.GlobalChannels) do
		local textChannel = Instance.new("TextChannel");
		textChannel.Name = k;
		textChannel:SetAttribute("Public", true);
		textChannel:SetAttribute("Global", true);
		textChannel.Parent = textChannelsFolder;
		ChatService.Channels[k] = textChannel;
	end
	
	MessagingService:SubscribeAsync("ChatService", function(payload)
		local data = payload.Data;
		
		local channelId = data.ChannelId;
		local txtMessage = data.Text;

		if channelId == nil or txtMessage == nil then return end;
		
		local textChannel: TextChannel = ChatService.Channels[channelId];
		if textChannel == nil then return end;
		if not textChannel:GetAttribute("Global") then return end;

		ChatService.CacheMsg(data);
		Debugger:Warn("Global msg", data);

		task.spawn(function()
			local filteredTxt = QuickTextFilter(data.RawText or data.Text);
			if filteredTxt == nil then return end;
			if data.RawText == nil then data.RawText = data.Text; end
			data.Text = filteredTxt;
			
			remoteChatServiceEvent:FireAllClients("globalchat", data);
		end)
	end)

	remoteChatServiceEvent.OnServerEvent:Connect(function(player, action, ...)
		if action == "chatready" then
			local profile = shared.modProfile:Get(player);
			
			local factionProfile = profile and profile.Faction;
			local factionTag = factionProfile and factionProfile.Tag or nil;

			local textChannel = factionTag and ChatService.Channels[`[{factionTag}]`];
			if textChannel then
				remoteChatServiceEvent:FireClient(player, "globalchat", {
					Name="Game";
					ChannelId=textChannel.Name;
					Text="Loading messages...";
					Presist=false;
				});
			end

		elseif action == "cmd" then
			local cmdMsg = ...;
			ChatService.HandleCommand(cmdMsg, player);
			return;
		end

		if modBranchConfigs.IsWorld("MainMenu") then
			Debugger:Log("Disabled sync messages in main menu.");
			return;
		end

		if action == "syncchat" then
			local profile = shared.modProfile:Get(player);
			
			local factionProfile = profile and profile.Faction;
			local factionTag = factionProfile and factionProfile.Tag or nil;

			local channelId = ...;

			local txtChannel = ChatService.Channels[channelId];
			if txtChannel == nil then return end;

			local txtChannelFactionTag = txtChannel:GetAttribute("Faction");
			Debugger:StudioWarn("syncchat channelId",channelId,"txtChannelFactionTag", txtChannelFactionTag);

			if txtChannelFactionTag then
				if txtChannelFactionTag ~= factionTag then
					return;
				end
			end

			if txtChannelFactionTag then
				local cacheMsgJson = ChatService.ChatHistory:Get(channelId);
				local cacheMsg = cacheMsgJson and HttpService:JSONDecode(cacheMsgJson) or {};

				if cacheMsg then
					if profile.SyncFacChatInit == nil then
						profile.SyncFacChatInit = true;
						
						for a=1, #cacheMsg do
							local data = cacheMsg[a];
							Debugger:StudioLog("factionchat",factionTag, a, data);
							if data.Timestamp == nil then continue end;
			
							remoteChatServiceEvent:FireClient(player, "globalchat", data);
						end
					end
				end

			else
				if ChatService.MsgCache[channelId] == nil then
					local cacheMsgJson = ChatService.ChatHistory:Get(channelId);
					local cacheMsg = cacheMsgJson and HttpService:JSONDecode(cacheMsgJson) or {};
	
					for a=1, #cacheMsg do
						ChatService.CacheMsg(cacheMsg[a]);
					end
				end
				
				local msgList = ChatService.MsgCache[channelId];
				if msgList == nil then return end;
				
				for a=1, #msgList do
					local data = msgList[a];
					Debugger:StudioLog("globalchat", a, data);
					if data.Timestamp == nil then continue end;
	
					local filteredTxt = QuickTextFilter(data.RawText or data.Text);
					if filteredTxt == nil then continue end;
					if data.RawText == nil then data.RawText = data.Text; end
					data.Text = filteredTxt;

					remoteChatServiceEvent:FireClient(player, "globalchat", data);
				end

			end
		end
		
	end)
end

function OnPlayerConnect(player: Player)
	for channelId, textChannel: TextChannel in pairs(ChatService.Channels) do
		if textChannel:GetAttribute("Public") ~= true then continue end;
		textChannel:AddUserAsync(player.UserId);
	end
	
	if modBranchConfigs.GetWorld() == "MainMenu" then return end;
	local profile = shared.modProfile:WaitForProfile(player);
			
	local factionProfile = profile and profile.Faction;
	local factionTag = factionProfile and factionProfile.Tag or nil;

	if factionTag == nil then return end;

	local channelId = `[{factionTag}]`;
	local textChannel = ChatService.Channels[channelId];
	if textChannel == nil then
		textChannel = Instance.new("TextChannel");
		textChannel.Name = channelId;
		textChannel:SetAttribute("Global", true);
		textChannel:SetAttribute("Faction", factionTag);
		textChannel.Parent = textChannelsFolder;
		ChatService.Channels[channelId] = textChannel;
	end

	textChannel:AddUserAsync(player.UserId);
end

Players.PlayerRemoving:Connect(function(player)
	task.wait(1);
	for channelId, textChannel in pairs(ChatService.Channels) do
		if textChannel:GetAttribute("Faction") == nil then continue end;

		local exist = false;
		for _, txtSrc in pairs(textChannel:GetChildren()) do
			if Players:FindFirstChild(txtSrc.Name) then
				exist = true;
				break;
			end
		end

		if not exist then
			textChannel:Destroy();
			ChatService.Channels[channelId] = nil;
		end
	end
end)

shared.Notify = ChatService.Notify;
shared.modChatService = ChatService;
ChatService.Init();
modCommandsLibrary.init();
modEngineCore:ConnectOnPlayerAdded(script, OnPlayerConnect);

task.spawn(function()
	Debugger.AwaitShared("modProfile");

	shared.modProfile.OnPlayerPacketRecieved:Connect(function(profile, ...)
		local packet = ...;

		if packet and packet.Data and packet.Data.Request == "DirectMessage" then
			local data = packet.Data;
			
			
			local extra = data.Extra or {};
			extra.Name = data.SpeakerName;

			local channelId = data.ChannelId;
			local text = data.Text;
			local msgExtra = extra;

			local receiverPlayer = game.Players:FindFirstChild(data.ChannelId);
			if receiverPlayer == nil then return end;
			


			-- if not ChatService:IsMuted(receiverPlayer, data.SpeakerName) then
			-- 	msgExtra.Name = data.SpeakerName;
			-- 	ChatService:SendMessage(receiverPlayer, data.SpeakerName, text, msgExtra);

			-- 	shared.Notify(receiverPlayer, "New message from "..tostring(data.SpeakerName)..".", "Inform");
			-- end
				
		end
	end)
end)

task.spawn(function()
	Debugger.AwaitShared("modCommandsLibrary");

	shared.modCommandsLibrary:HookChatCommand("textchatservice", {
		Permission = shared.modCommandsLibrary.PermissionLevel.Admin;
		Description = "textchatservice.";
	
		RequiredArgs = 1;
		UsageInfo = "/textchatservice action";
		Function = function(speaker, args)
			
			local action = args[1];
			local userId = speaker.UserId;

			if action == "canchat" then
				Debugger:Warn("speaker can chat =", TextChatService:CanUserChatAsync(userId));

			elseif action == "notifycountdown" then
				for a=10, 1, -1 do
					shared.Notify(speaker, `Countdown: {a}`, `Inform`, `countdown`);
					task.wait(1);
				end
				shared.Notify(speaker, `Countdown: boom`, `Inform`, `countdown`);
			end
			
			return true;
		end;
	});

	shared.modCommandsLibrary:HookChatCommand("globalannounce", {
		Permission = shared.modCommandsLibrary.PermissionLevel.Admin;
		Description = "Global broadcast message.";
	
		RequiredArgs = 1;
		UsageInfo = "/globalannounce msg";
		Function = function(speaker, args)
			local msg = table.concat(args, " ");
			
			ChatService.SendGlobalMessage{
				SpeakerName="Game";
				ChannelId="Server";
				Text=msg;
				Style="Announce"
			};
			return true;
		end;
	});
end)



















if true then return end
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait() until shared.MasterScriptInit == true;
local ChannelConfig = {};

--== Variables;
local MessagingService = game:GetService("MessagingService");
local TextService = game:GetService("TextService");
local RunService = game:GetService("RunService");
local TextChatService = game:GetService("TextChatService");

local DataStoreService = game:GetService("DataStoreService");
local MemoryStoreService = game:GetService("MemoryStoreService");
local HttpService = game:GetService("HttpService");
local Players = game.Players;

local ChatPermissionDatastore = DataStoreService:GetDataStore("ChatService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);
local modFactions = require(game.ServerScriptService.ServerLibrary.Factions);

local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);

local remoteChatServiceFunction = modRemotesManager:Get("ChatServiceFunction");
local remoteChatServiceEvent = modRemotesManager:Get("ChatServiceEvent");

--local chatClientModule = script:WaitForChild("ChatClient");
local chatModules = script:WaitForChild("ChatModules");

local ChatService = {};
ChatService.__index = ChatService;
ChatService.ChatProcessors = {};
ChatService.PlayerCache = {};
ChatService.MsgCache = {};

ChatService.GlobalMsgRecieved = 20;
ChatService.GlobalChannels = {
	Global = {};
	LookingFor = {};
	Trade = {};
}

if modBranchConfigs.CurrentBranch.Name == "Dev" then
	ChatService.GlobalChannels.LookingFor = nil;
	ChatService.GlobalChannels.Trade = nil;
	ChatService.GlobalChannels.Logs = {};
	ChatService.GlobalChannels.Bugs = {};
end

ChatService.ReportLog = {};
ChatService.ReportsCache = {};
ChatService.ChatHistory = modDatabaseService:GetDatabase("ChatHistory");
ChatService.ChatHistory.ExpireTime = 60;
ChatService.ChatHistory.PublishTimer = 30;

shared.ChatService = ChatService;

local retrivedCacheMsgs = false;
--== Script;


spawn(function()
	while wait(60) do
		ChatService.GlobalMsgRecieved = 20;
		
		ChatService:ProcessReports();
		
		local reports = {};
		for name, c in pairs(ChatService.ReportsCache) do
			if ChatService.ReportsCache[name] > 0 then
				reports[name] = ChatService.ReportsCache[name];
			end
		end
		ChatService.ReportsCache = {};
		if next(reports) ~= nil then
			MessagingService:PublishAsync("ChatService", {Reports=reports});
		end
	end
end)

local function OnPlayerConnect(player: Player)
	local loadCacheMsgs = false;
	
	task.spawn(function()
		for _, textChannel: TextChannel in pairs(textChannelsFolder:GetChildren()) do
			if not textChannel:GetAttribute("Public") then continue end;

			textChannel:AddUserAsync(player.UserId);
		end
	end)

	local function onCharacterSpawn()
		if player:FindFirstChild("ChatClient") then return end;
		ChatService.PlayerCache[player.Name] = {};
		ChatService.ReportLog[player.Name] = 0;
		
		--local new = chatClientModule:Clone();
		--new.Parent = player;
		
		repeat wait(1) until (ChatService.PlayerCache[player.Name] and ChatService.PlayerCache[player.Name].MessagingReady) 
			or not player:IsDescendantOf(game.Players);
		
		if not player:IsDescendantOf(game.Players) then return end;
		
		task.spawn(function()
			ChatService:CheckGlobalMuted(player.Name);
		end)
	end
	
	onCharacterSpawn();
	player.CharacterAdded:Connect(onCharacterSpawn);
	
	for name, _ in pairs(ChatService.PlayerCache) do
		if game.Players:FindFirstChild(name) == nil then
			ChatService.PlayerCache[name] = nil;
		end
	end
end

function remoteChatService.OnServerInvoke(player, action, ...)
	local rPacket = {};
	if remoteChatService:Debounce(player) then rPacket.Debounce=true; return rPacket end;

	local profile = modProfile:Get(player);
	
	local factionProfile = profile and profile.Faction;
	local factionTag = factionProfile and factionProfile.Tag or nil;
	
	local playerCache = ChatService.PlayerCache[player.Name];
	if playerCache then
		playerCache.Faction = factionProfile;
	end
	
	if action == "syncfactionchat" then
		Debugger:Log("Sync faction chat ", player, factionTag);
		if factionTag then
			local cacheMsgJson = ChatService.ChatHistory:Get("["..factionTag.."]");
			local cacheMsg = cacheMsgJson and HttpService:JSONDecode(cacheMsgJson) or {};

			if cacheMsg then
				if profile.SyncFacChatInit == nil then
					profile.SyncFacChatInit = true;
					
					for a=1, #cacheMsg do
						local data = cacheMsg[a];
						if not ChatService:IsMuted(player, data.SpeakerName) then
							local filtered;
							local s, e = pcall(function()
								filtered = TextService:FilterStringAsync(data.Text, player.UserId, Enum.TextFilterContext.PublicChat):GetChatForUserAsync(player.UserId);
							end)

							if s and filtered then
								local extra = data.Extra or {};
								extra.Name = data.SpeakerName;

								ChatService:SendMessage(player, data.ChannelId, filtered, extra);
							end
						end
					end
				end
				rPacket.CacheMsg = cacheMsg;
			end
			return rPacket;
		end
		
	elseif action == "syncchat" then
		
		local channelId = ...;
		if ChatService.GlobalChannels[channelId] then
			if modBranchConfigs.IsWorld("MainMenu") then
				Debugger:Log("Disabled sync messages in main menu.");
				return;
			end
			
			if ChatService.MsgCache[channelId] == nil then
				local cacheMsgJson = ChatService.ChatHistory:Get(channelId);
				local cacheMsg = cacheMsgJson and HttpService:JSONDecode(cacheMsgJson) or {};

				Debugger:Log("Loaded ",channelId," cache msg", cacheMsg);
				for a=1, #cacheMsg do
					ChatService:CacheMsg(cacheMsg[a]);
				end
			end
			
			local msgList = ChatService.MsgCache[channelId]
			local channelConfig = ChatService.GlobalChannels[channelId];
			
			if msgList == nil then return end;
			
			for a=1, #msgList do
				local data = msgList[a];
				if not ChatService:IsMuted(player, data.SpeakerName) then
					local filtered;
					local s, e = pcall(function()
						filtered = TextService:FilterStringAsync(data.Text, player.UserId, Enum.TextFilterContext.PublicChat):GetChatForUserAsync(player.UserId);
					end)

					if s and filtered then
						local extra = data.Extra or {};
						extra.Name = data.SpeakerName;

						ChatService:SendMessage(player, data.ChannelId, filtered, extra);
					end
				end
			end
		end
	end
end

function remoteSubmitMessage.OnServerInvoke(player, channelId, text, filterTest, params)
	params = params or {};
	text = tostring(text);
	
	text = modGlobalVars.CleanTextInput(text);

	local testText = text:gsub(" ", "")
	testText = testText:gsub(string.char(32), "")
	testText = testText:gsub("[\r\n]", "");
	
	if #testText <= 0 or #text >= 200 then return text; end;
	
	local filteredText = shared.modAntiCheatService:Filter(text, player, false, true);
	if filterTest == true then return filteredText end;
	-- Passes clean up.

	if shared.modProfile.IsBeingRecon(player) then
		local modDiscordWebhook = require(game.ServerScriptService.ServerLibrary.DiscordWebhook);
		modDiscordWebhook.PostText(modDiscordWebhook.Hooks.ChatLogs, `{player.Name}\`{player.UserId}\`: [{channelId}] {text}`);
	end

	local playerCache = ChatService.PlayerCache[player.Name];
	
	-- Basic anti spam
	if playerCache.LastMsg
	and playerCache.MsgFreebie
	and tick()-playerCache.LastMsg <= 5 and playerCache.MsgFreebie <= 0 then
		ChatService:SendMessage(player, channelId, 
			"Woah there, please wait ".. 6-math.ceil(tick()-playerCache.LastMsg).." secs before sending another message.", 
			{Presist=false; MessageColor=Color3.fromRGB(255, 69, 69);}
		);
		return;
	end;
	
	local timeLapse = tick()-(playerCache.LastMsg or 0);
	
	if playerCache.MsgFreebie == nil
	or timeLapse >= 3
	or playerCache.MsgFreebie <= 0 then playerCache.MsgFreebie = 3; end
	playerCache.MsgFreebie = playerCache.MsgFreebie -1;
	
	playerCache.LastMsg = tick();
	
	
	-- ChatProcessors
	local skipReplicate = false;
	for id, func in pairs(ChatService.ChatProcessors) do
		skipReplicate = ChatService.ChatProcessors[id](player.Name, text, channelId);
	end
	if skipReplicate == true then playerCache.MsgFreebie = playerCache.MsgFreebie+1; return end;

	filteredText = modRichFormatter.SanitizeRichText(filteredText);
	
	-- Messaging
	local canUserChat = game.Chat:CanUserChatAsync(player.UserId);
	if canUserChat == false then
		ChatService:SendMessage(player, channelId, 
			"Your chat is disabled by Roblox.", 
			{Presist=false; MessageColor=Color3.fromRGB(255, 69, 69);}
		);
		return;
	end
	
	
	local profile = modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	
	local factionProfile = profile.Faction;
	local factionTag = factionProfile and factionProfile.Tag;
	local factionRole = factionProfile and factionProfile.Role;

	local playerCache = ChatService.PlayerCache[player.Name];
	playerCache.Faction = factionProfile;
	
	local isFactionChannel = (factionTag and channelId == "["..factionTag.."]");
	
	if profile.Punishment == modGlobalVars.Punishments.ChatDisablePenalty then return end;
	
	local msgExtra = {};
	msgExtra.Style = profile.Premium and "Premium" or "Level"..(activeSave and activeSave:GetStat("Level") or 0);
	
	if params.Dm == nil and channelId == "Server" then
		ChatService:ProccessChat(player, channelId, filteredText, msgExtra);

	elseif params.Dm == nil and game.Players:FindFirstChild(channelId) then -- whisper;
		local whisperRecieve = game.Players:FindFirstChild(channelId);
		
		msgExtra.Name = player.Name;
		ChatService:SendMessage(player, channelId, filteredText, msgExtra);
		
		if not ChatService:IsMuted(whisperRecieve, player.Name) then
			msgExtra.Name = player.Name;
			ChatService:SendMessage(whisperRecieve, player.Name, filteredText, msgExtra);
		end
		
	elseif params.Dm == nil and (ChatService.GlobalChannels[channelId] or isFactionChannel) then
		
		if ChatService.GlobalMsgRecieved <= 0 then
			ChatService:SendMessage(player, channelId, 
				"Please wait, cross-server messaging is busy.", 
				{Presist=false; MessageColor=Color3.fromRGB(255, 69, 69);}
			);
			return;
		end
		
		if playerCache.LastGlobalMsg and tick()-playerCache.LastGlobalMsg <= 5 then
			ChatService:SendMessage(player, channelId, 
				"Please wait, you are on cooldown for 5 seconds.", 
				{Presist=false; MessageColor=Color3.fromRGB(255, 69, 69);}
			);
			return;
		end
		playerCache.LastGlobalMsg = tick();
		
		if playerCache.GlobalChatMute then
			if os.time()-playerCache.GlobalChatMute < 0 then
				ChatService:SendMessage(player, channelId, 
					"You are on a chat cooldown from multiple reports.", 
					{Presist=false; MessageColor=Color3.fromRGB(255, 69, 69);}
				);
				return;
			else
				playerCache.GlobalChatMute = nil;
				local s, e = pcall(function()
					local userId = Players:GetUserIdFromNameAsync(player.Name);
					if userId then
						local key = tostring(userId);
						ChatPermissionDatastore:RemoveAsync(key);
					end
				end)
			end
		end;
		
		if isFactionChannel then
			local roleKey = factionRole or "Member";
			msgExtra.Style = roleKey;
			
			local factionPermissions = modGlobalVars.FactionPermissions;
			local factionObject = modFactions.Get(factionTag);
			if factionObject == nil or factionObject:HasPermission(tostring(player.UserId), "CanChat") == false then 
				ChatService:SendMessage(player, channelId, 
					"You do not have permission to chat here.", 
					{Presist=false; MessageColor=Color3.fromRGB(255, 69, 69);}
				);
				
				return;
			end
		end
		
		ChatService:ProccessGlobalChat(player.Name, channelId, filteredText, msgExtra);

	elseif params.Dm then -- Direct message;

		local dmData = params.Dm;
		local targetUserId = dmData.SenderUserId;
		local targetName = dmData.SpeakerName;

		local packet = {
			Request = "DirectMessage";

			SpeakerName = player.Name;
			SenderUserId = player.UserId;

			ReceiverUserId = targetUserId;
			ChannelId = targetName;

			Text = filteredText;
			Extra = {
				Dm={
					SenderUserId = player.UserId;
					SpeakerName = player.Name;
				};
				MsgTime = tostring(DateTime.now().UnixTimestampMillis);
				Style = msgExtra.Style;
			};
		};

		profile:SendMsg("Msg"..targetUserId, packet);
		ChatService:SendMessage(player, channelId, filteredText, {
			Dm={
				SenderUserId = targetUserId;
				SpeakerName = targetName;
			};
			Name = player.Name;
			MsgTime = tostring(DateTime.now().UnixTimestampMillis);
			Style = msgExtra.Style;
		});
		
	else
		ChatService:SendMessage(player, channelId, 
			"The channel ("..tostring(channelId)..") does not exist.", 
			{Presist=false; MessageColor=Color3.fromRGB(255, 69, 69);}
		);
		
	end

	return;
end

--== ChatService;
function ChatService:SendMessage(player, channelId, text, extra)
	local msgPacket = {Message=text;};
	
	for k, v in pairs(extra or {}) do
		msgPacket[k] = v;
	end
	if extra.MsgTime == nil then
		msgPacket.MsgTime = tostring(DateTime.now().UnixTimestampMillis);
	end
	
end

function ChatService:ProccessChat(player, channelId, text, extra)
	extra.MsgTime = tostring(DateTime.now().UnixTimestampMillis);
	
	ChatService:CacheMsg({
		SpeakerName=player.Name;
		Text=text;
		Extra=extra;
		ChannelId=channelId;
	});

end

function ChatService:ProccessGlobalChat(speakerName, channelId, text, extra)
	if modServerManager.ShadowBanned then return end;
	
	local data = {
		ChannelId = channelId;
		SpeakerName = speakerName;
		Text = text:sub(1, 200);
		Extra = extra;
	};
	
	data.Extra = data.Extra or {};
	data.Extra.MsgTime = tostring(DateTime.now().UnixTimestampMillis);
	
	task.spawn(function()
		MessagingService:PublishAsync("ChatService", data);
		ChatService:GlobalCacheMsg(data);
	end)
end

function ChatService:RegisterProcessCommandsFunction(id, func)
	ChatService.ChatProcessors[id] = func;
end

for _, module in pairs(chatModules:GetChildren()) do
	if module.ClassName == "ModuleScript" then
		require(module)(ChatService);
	end
end

function ChatService:SetMute(player, name, value)
	local playerCache = ChatService.PlayerCache[player.Name];
	if playerCache then
		if playerCache.Mutes == nil then playerCache.Mutes = {}; end;
		playerCache.Mutes[name] = value;
	end
end

function ChatService:IsMuted(player, name)
	local playerCache = ChatService.PlayerCache[player.Name];
	if playerCache and playerCache.Mutes and playerCache.Mutes[name] == true then
		return true;
	end
	return false;
end

function ChatService:ProcessReports()
	for name, reports in pairs(ChatService.ReportLog) do
		local playerCache = ChatService.PlayerCache[name];
		if reports >= 4 then
			local newMuteTime = os.time()+43200; -- 12 hours
			ChatService:SetGlobalMute(name, newMuteTime, true);
		end
	end
	ChatService.ReportLog = {};
end

function ChatService:NewReport(name)
	ChatService.ReportsCache[name] = (ChatService.ReportsCache[name] or 0)+1;
end

function ChatService:SetGlobalMute(name, newTime, isAutoMute)
	local playerCache = ChatService.PlayerCache[name];
	
	local s, e = pcall(function()
		local userId = Players:GetUserIdFromNameAsync(name);
		if userId then
			local key = tostring(userId);
			ChatPermissionDatastore:UpdateAsync(key, function(muteValue)
				if isAutoMute == true then
					if muteValue == nil then
						muteValue = newTime;
					elseif os.time()-muteValue < 0 then
						muteValue = newTime;
					end
				else
					muteValue = newTime;
				end
				if playerCache then
					playerCache.GlobalChatMute = muteValue;
				end
				return muteValue;
			end)
		end
	end)
end

function ChatService:CheckGlobalMuted(name)
	local playerCache = ChatService.PlayerCache[name];
	if playerCache and playerCache.GlobalChatMute then 
		return playerCache.GlobalChatMute;
	end;
	
	local muteTime;
	local s, e = pcall(function()
		local userId = Players:GetUserIdFromNameAsync(name);
		if userId then
			local key = tostring(userId);
			muteTime = ChatPermissionDatastore:GetAsync(key);
		end
	end)
	
	if playerCache then
		playerCache.GlobalChatMute = muteTime;
	end
	return muteTime;
end

function ChatService:CacheMsg(data)
	if data == nil or data.ChannelId == nil then return end;
	local channelId = data.ChannelId;
	
	if ChatService.GlobalChannels[channelId] == nil then return end
	
	if ChatService.MsgCache[channelId] == nil then 
		ChatService.MsgCache[channelId] = {};
	end
	if #ChatService.MsgCache[channelId] > 16 then
		table.remove(ChatService.MsgCache[channelId], 1);
	end
	
	table.insert(ChatService.MsgCache[channelId], data);
	
end

ChatService.ChatHistory:OnUpdateRequest("addmsg", function(requestPacket)
	local oldHistory = requestPacket.RawData;
	local data = requestPacket.Values;
	
	local cacheMsgs = oldHistory and HttpService:JSONDecode(oldHistory) or {};

	if #cacheMsgs > 16 then
		table.remove(cacheMsgs, 1);
	end
	table.insert(cacheMsgs, data);

	return HttpService:JSONEncode(cacheMsgs);
end)


function ChatService:GlobalCacheMsg(data)
	if data == nil or data.ChannelId == nil then Debugger:Warn("Failed to cache global msg:", data) return end;

	ChatService.ChatHistory:UpdateRequest(data.ChannelId, "addmsg", data);
end

remoteSubmitChatReport.OnServerEvent:Connect(function(player, name)
	if player.Name == name then return end;
	ChatService:SetMute(player, name, true);
	
	local profile = modProfile:Get(player);
	if profile and profile.Reports > 0 then
		profile.Reports = profile.Reports -1;
		Debugger:Log("Report submitted", player.Name, " Suspect:", name);
		ChatService:NewReport(name);
	end
end)

local modEngineCore = require(game.ReplicatedStorage.EngineCore);
modEngineCore:ConnectOnPlayerAdded(script, OnPlayerConnect)
--pcall(function()
--	for _, player in pairs(game.Players:GetPlayers()) do OnPlayerConnect(player); end
--end)
--Players.PlayerAdded:Connect(OnPlayerConnect)

Players.PlayerRemoving:Connect(function(player)
	wait(30);
	if game.Players:FindFirstChild(player.Name) then return end;
	ChatService.ReportLog[player.Name] = nil;
end)

MessagingService:SubscribeAsync("ChatService", function(payload)
	ChatService.GlobalMsgRecieved = ChatService.GlobalMsgRecieved -1;
	
	local data = payload.Data;
	
	if data.SpeakerName and data.ChannelId and data.Text then
		
		ChatService:CacheMsg(data);
		--
		for _, oPlayer in pairs(game.Players:GetPlayers()) do
			local profile = modProfile:Get(oPlayer);
			local factionProfile = profile.Faction;
			local factionTag = factionProfile.Tag;

			if ChatService:IsMuted(oPlayer, data.SpeakerName) then continue end;

			if ChatService.GlobalChannels[data.ChannelId] or (factionTag and data.ChannelId == "["..factionTag.."]") then
				local filteredResult = TextService:FilterStringAsync(data.Text, oPlayer.UserId, Enum.TextFilterContext.PublicChat);
				local filtered = filteredResult:GetChatForUserAsync(oPlayer.UserId);
				
				local extra = data.Extra or {};
				extra.Name = data.SpeakerName;

				if data.SpeakerName == "Game" then
					ChatService:SendMessage(oPlayer, data.ChannelId, data.Text, extra);
				else
					ChatService:SendMessage(oPlayer, data.ChannelId, filtered, extra);
				end
			end
		end
		
	elseif data.Reports then
		Debugger:Log("Received reports", data.Reports);
		for name, v in pairs(data.Reports) do
			if ChatService.ReportLog[name] and name ~= "MXKhronos" then
				ChatService.ReportLog[name] = ChatService.ReportLog[name] + v;
			end
		end
	end
end)

task.spawn(function()
	repeat task.wait() until shared.modProfile ~= nil;
	Debugger:Log("ChatService connected OnPlayerPacketRecieved.")

	shared.modProfile.OnPlayerPacketRecieved:Connect(function(profile, ...)
		local packet = ...;

		Debugger:Log(profile.Player," Received packet", packet);
		--Debugger:WarnClient(profile.Player, "Received packet, ", packet);

		if packet and packet.Data and packet.Data.Request == "DirectMessage" then
			local data = packet.Data;
			
			
			local extra = data.Extra or {};
			extra.Name = data.SpeakerName;

			local channelId = data.ChannelId;
			local text = data.Text;
			local msgExtra = extra;

			local receiverPlayer = game.Players:FindFirstChild(data.ChannelId);
			if receiverPlayer then
				if not ChatService:IsMuted(receiverPlayer, data.SpeakerName) then
					msgExtra.Name = data.SpeakerName;
					ChatService:SendMessage(receiverPlayer, data.SpeakerName, text, msgExtra);

					shared.Notify(receiverPlayer, "New message from "..tostring(data.SpeakerName)..".", "Inform");
				end
			end
		end
	end)
end)

--for channelId, _ in pairs(ChatService.GlobalChannels) do
--	local cacheMsgJson = ChatService.ChatHistory:Get(channelId); --ChatService.ChatHistory:GetAsync(channelId);
--	local cacheMsg = cacheMsgJson and HttpService:JSONDecode(cacheMsgJson) or {};
	
--	Debugger:Log("Loaded ",channelId," cache msg", cacheMsg);
--	for a=1, #cacheMsg do
--		ChatService:CacheMsg(cacheMsg[a]);
--	end
--end
retrivedCacheMsgs = true;