local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ChatClient = {};
ChatClient.__ChatClient = ChatClient;

ChatClient.ChatCache = {};

ChatClient.ChatCache["Server"] = {
	NewMsgs = 0;
	Messages = {}
};

--==
function ChatClient.init()
	if ChatClient.Inited then return end;
	ChatClient.Inited = true;
	
	EventSignal = require(game.ReplicatedStorage.Library.EventSignal);
	RemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
	
	ChatClient.OnNewMessage = EventSignal.new("OnNewMessage");
	
	local remoteNewClientMessage = RemotesManager:Get("NewClientMessage");
	remoteNewClientMessage.OnClientEvent:Connect(function(channelId, messageData)
		if ChatClient.MsgReady == nil then
			ChatClient.MsgReady = true;
			remoteNewClientMessage:FireServer();
		end
		
		ChatClient:NewMessage(channelId, messageData);
	end)
	remoteNewClientMessage:FireServer();
end

function ChatClient:NewMessage(channelId, messageData)
	if ChatClient.ChatCache[channelId] == nil then
		ChatClient.ChatCache[channelId] = {
			NewMsgs = 0;
			Messages = {};
		};
	end
	
	if messageData.Name then
		table.insert(ChatClient.ChatCache[channelId].Messages, messageData);
		ChatClient.OnNewMessage:Fire(channelId, messageData);
		
	else
		local activeId = ChatClient.ActiveChannelId or "Server";
		ChatClient.OnNewMessage:Fire(activeId, messageData);
		
	end
end

return ChatClient;