--== Configuration;
local NotificationsLibrary = require(game.ReplicatedStorage.Library.NotificationsLibrary);
--== Variables;
local Chat = game:GetService("Chat")
local ReplicatedModules = Chat:WaitForChild("ClientChatModules")
local ChatSettings = require(ReplicatedModules:WaitForChild("ChatSettings"))

--== Script;
local function sendMessage(channel, speaker, messageData, retryCount)
	retryCount = retryCount or 5;
	
	if speaker then
		channel:SendSystemMessageToSpeaker(messageData.Message, speaker.Name, messageData.ExtraData);
	else
		if retryCount > 0 then
			delay(1, function()
				sendMessage(channel, speaker, messageData, retryCount-1);
			end)
		end
	end
end

local initNotifyBind = false;
local function Run(ChatService)
	local modProfile = require(game.ServerScriptService:WaitForChild("ServerLibrary"):WaitForChild("Profile"));
	
	local modRemotesManager = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("RemotesManager"));
	local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
	local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
	
	local remoteNotifyPlayer = modRemotesManager:Get("NotifyPlayer");
	
	if initNotifyBind then return end;
	initNotifyBind = true;
	
	local channelServer = ChatService:GetChannel(ChatSettings.GeneralChannelName);

	function shared.Notify(player, message, class, key, packet) -- Main Menu;
		if modBranchConfigs.WorldName ~= "MainMenu" then return end;
		channelServer = ChatService:GetChannel(ChatSettings.GeneralChannelName);
		if channelServer == nil then warn(script.Name..">>  No Server Channel."); return end;
		if type(player) == "table" then
			for a, p in pairs(player) do
				local chatSpeaker = ChatService:GetSpeaker(p.Name);
				local messageData = NotificationsLibrary[class] and NotificationsLibrary[class](message, player) or nil;


				local profile = modProfile:Find(p.Name);
				local notifyMode = modConfigurations.ForceNotifyStyle or (profile and profile.Settings and profile.Settings.Notifications);

				if notifyMode == 1 or (notifyMode == 2 and messageData.Imp == true) or modBranchConfigs.WorldName == "MainMenu" then
					sendMessage(channelServer, chatSpeaker, messageData or {Message=message;});

				elseif notifyMode == nil then
					remoteNotifyPlayer:FireClient(p, key, messageData or {Message=message;});

				end

			end

		elseif player:IsA("Player") then
			local chatSpeaker = ChatService:GetSpeaker(player.Name);
			local messageData = NotificationsLibrary[class] and NotificationsLibrary[class](message, player) or nil;

			local profile = modProfile:Find(player.Name);
			local notifyMode = modConfigurations.ForceNotifyStyle or (profile and profile.Settings and profile.Settings.Notifications);

			if notifyMode == 1 or (notifyMode == 2 and messageData.Imp == true) or modBranchConfigs.WorldName == "MainMenu" then
				sendMessage(channelServer, chatSpeaker, messageData or {Message=message;});

			elseif notifyMode == nil then
				remoteNotifyPlayer:FireClient(player, key, messageData or {Message=message;});

			end

		elseif player:IsA("Players") then
			local players = player:GetPlayers();
			for a, p in pairs(players) do
				local chatSpeaker = ChatService:GetSpeaker(p.Name);
				local messageData = NotificationsLibrary[class] and NotificationsLibrary[class](message, player) or nil;
				--sendMessage(channelServer, chatSpeaker, messageData or {Message=message;});

				local profile = modProfile:Find(p.Name);
				local notifyMode = modConfigurations.ForceNotifyStyle or (profile and profile.Settings and profile.Settings.Notifications);

				if notifyMode == 1 or (notifyMode == 2 and messageData.Imp == true) or modBranchConfigs.WorldName == "MainMenu" then
					sendMessage(channelServer, chatSpeaker, messageData or {Message=message;});

				elseif notifyMode == nil then
					remoteNotifyPlayer:FireClient(p, key, messageData or {Message=message;});

				end
			end

		else
			warn(script.Name..">>  Unknown player type");
		end
	end
end
 
return Run;