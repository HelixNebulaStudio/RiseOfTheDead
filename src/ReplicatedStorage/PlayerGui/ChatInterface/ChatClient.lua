local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ChatClient = {};
ChatClient.__ChatClient = ChatClient;

ChatClient.Inited = false;
ChatClient.MsgReady = false;
ChatClient.OnNewMessage = nil;
ChatClient.ActiveChannelId = nil;

ChatClient.ChatCache = {};
ChatClient.ChatCache["Server"] = {
	NewMsgs = 0;
	Messages = {}
};

--==
function ChatClient.init()
	if ChatClient.Inited then return end;
	ChatClient.Inited = true;
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