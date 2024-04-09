local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local NotificationsLibrary = require(game.ReplicatedStorage.Library.NotificationsLibrary);

local modProfile = require(game.ServerScriptService:WaitForChild("ServerLibrary"):WaitForChild("Profile"));
local modRemotesManager = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("RemotesManager"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));

local remoteNotifyPlayer = modRemotesManager:Get("NotifyPlayer");

local addDelay = 0;
local function Run(ChatService)

	local function processNotification(player, message, class, key, packet)
		local messageData = NotificationsLibrary[class] and NotificationsLibrary[class](message, player) or nil;
		if messageData == nil then return end;
		
		local profile = modProfile:Find(player.Name);
		local notifyMode = modConfigurations.ForceNotifyStyle or (profile and profile.Settings and profile.Settings.Notifications);
		
		if notifyMode == 1 or (notifyMode == 2 and messageData.Imp == true) then
			addDelay = (addDelay > 30 and 0 or addDelay) +1;
			ChatService:SendMessage(player, "Server", messageData.Message, {
				MsgTime = tostring(DateTime.now().UnixTimestampMillis+addDelay);
				MessageColor = messageData.ExtraData and messageData.ExtraData.ChatColor or nil;
				Font = messageData.ExtraData and messageData.ExtraData.Font or nil;
				Presist = messageData.Presist;
				Packet=packet;
			});
			
		
		elseif notifyMode == nil then -- default;
			messageData.Packet = packet;
			remoteNotifyPlayer:FireClient(player, key, messageData or {Message=message; Packet=packet;});
			
		end
	end
	
	
	-- !outline: function    shared.Notify(...)
	function shared.Notify(player, message, class, key, packet) -- In-Game
		if modBranchConfigs.WorldName == "MainMenu" then return end;
		if type(player) == "table" then
			for a, p in pairs(player) do
				local player = game.Players:FindFirstChild(p.Name);

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
end
 
return Run;