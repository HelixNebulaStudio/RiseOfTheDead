--	// FileName: FriendJoinNotifer.lua
--	// Written by: TheGamer101
--	// Description: Module that adds a message to the chat whenever a friend joins the game.

local Chat = game:GetService("Chat")
local Players = game:GetService("Players")
local FriendService = game:GetService("FriendService")

local ReplicatedModules = Chat:WaitForChild("ClientChatModules")
local ChatSettings = require(ReplicatedModules:WaitForChild("ChatSettings"))
local ChatConstants = require(ReplicatedModules:WaitForChild("ChatConstants"))

local ChatLocalization = nil
pcall(function() ChatLocalization = require(game:GetService("Chat").ClientChatModules.ChatLocalization) end)
if ChatLocalization == nil then ChatLocalization = {} end
if not ChatLocalization.FormatMessageToSend or not ChatLocalization.LocalizeFormattedMessage then
	function ChatLocalization:FormatMessageToSend(key,default) return default end
end

local FriendMessageTextColor = Color3.fromRGB(255, 255, 255)
local FriendMessageExtraData = {ChatColor = FriendMessageTextColor}

local function Run(ChatService)

	local function ShowFriendJoinNotification()
		if ChatSettings.ShowFriendJoinNotification ~= nil then
			return ChatSettings.ShowFriendJoinNotification
		end
		return false
	end

	local function SendFriendJoinNotification(player, joinedFriend)
		pcall(function() 
		local msg = ChatLocalization:FormatMessageToSend("GameChat_FriendChatNotifier_JoinMessage",
			string.format("Your friend %s has joined the game.", joinedFriend.Name),
			"RBX_NAME",
			joinedFriend.Name);
			print("Social>> ",msg);
		end)
--		local speakerObj = ChatService:GetSpeaker(player.Name)
--		if speakerObj then
--			local msg = ChatLocalization:FormatMessageToSend("GameChat_FriendChatNotifier_JoinMessage",
--				string.format("Your friend %s has joined the game.", joinedFriend.Name),
--				"RBX_NAME",
--				joinedFriend.Name)
--			speakerObj:SendSystemMessage(msg, "System", FriendMessageExtraData)
--		end
	end

	local function TrySendFriendNotification(player, joinedPlayer)
		if player ~= joinedPlayer then
			task.spawn(function()
				local isFriend;
				pcall(function() 
					isFriend = player:IsFriendsWith(joinedPlayer.UserId)
				end)
				if isFriend then
					SendFriendJoinNotification(player, joinedPlayer)
				end
			end)
		end
	end

	if ShowFriendJoinNotification() then
		Players.PlayerAdded:connect(function(player)
			local possibleFriends = Players:GetPlayers()
			for i = 1, #possibleFriends do
				TrySendFriendNotification(possibleFriends[i], player)
			end
		end)
	end
end

return Run
