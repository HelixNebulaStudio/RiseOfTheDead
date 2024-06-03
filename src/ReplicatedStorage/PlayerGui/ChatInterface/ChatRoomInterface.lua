local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local parent = script.Parent;

local ChatRoomInterface = {};
ChatRoomInterface.__index = ChatRoomInterface;

ChatRoomInterface.ActiveChannel = 1;
ChatRoomInterface.Channels = {};

ChatRoomInterface.SwitchChannelFunc = {};

local localPlayer = game.Players.LocalPlayer;

local TextService = game:GetService("TextService");
local UserInputService = game:GetService("UserInputService");
local ChatService = game:GetService("Chat");

local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
local modNotificationsLibrary = require(game.ReplicatedStorage.Library.NotificationsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);

local remoteChatService = modRemotesManager:Get("ChatService");

local chatClientModule = localPlayer:FindFirstChild("ChatClient");
if chatClientModule == nil then
	chatClientModule = script.Parent.ChatClient:Clone();
	chatClientModule.Parent = localPlayer;
end
--local chatClientModule = localPlayer:WaitForChild("ChatClient", 5);

local ChatClient = require(chatClientModule);
ChatClient.init();

local mainChatFrame = parent:WaitForChild("ChatFrame");
local mainChannelsFrame = parent:WaitForChild("ChannelsFrame");
local mainInputFrame = parent:WaitForChild("InputFrame");
local optionsFrame = parent:WaitForChild("OptionsFrame");

local templateChannelButton = script:WaitForChild("channelButton");
local templateChannelFrame = script:WaitForChild("channelFrame");

local templateMessageFrame = script:WaitForChild("newMessageFrame");
local templateNameTag = script:WaitForChild("messageNameTag");
local templateMessageLabel = script:WaitForChild("messageLabel");

local initTime = DateTime.now().UnixTimestampMillis;
--==
function ChatRoomInterface.ToggleChat(v)
	if v == nil then v = true; end
	mainChatFrame.Visible = v;
end

local Room = {};
Room.__index = Room;
Room.MainChatFrame = mainChatFrame;

function Room.new(id)
	local self = {
		Id=id;
	};
	
	
	self.Button = templateChannelButton:Clone();
	self.Button.Parent = mainChannelsFrame;
	self.Button.Text = id;
	
	setmetatable(self, Room);
	
	self.Button.MouseButton1Click:Connect(function()
		
		if UserInputService.TouchEnabled then
			ChatRoomInterface.ToggleFocusChat(true);
		end
		self:SetActive();
	end)
	
	self.Frame = templateChannelFrame:Clone();
	self.Frame.Name = id;
	self.Frame.Parent = mainChatFrame;
	self.Frame.Visible = false;
	self.Frame.CanvasPosition = Vector2.new(0, 99999);
	
	self.Frame:GetPropertyChangedSignal("Parent"):Connect(function()
		local parent = self.Frame.Parent;
		
		if parent ~= nil then
			self:UpdateVisible();
		end
	end)
	
	local frameListLayout = self.Frame:WaitForChild("UIListLayout");
	frameListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local msgs = self.Frame:GetChildren();
		table.sort(msgs, function(A, B)
			return (tonumber(A.Name) or 0) > (tonumber(B.Name) or 0);
		end)
		for a=#msgs, 30, -1 do
			if msgs[a]:IsA("GuiObject") then
				msgs[a]:Destroy();
			end
		end
		
		local stickToBottom = self.Frame.CanvasSize.Y.Offset-self.Frame.AbsoluteWindowSize.Y;
		
		self.Frame.CanvasSize = UDim2.new(0, 0, 0, frameListLayout.AbsoluteContentSize.Y);
		if stickToBottom < 0 or stickToBottom < self.Frame.CanvasPosition.Y+16 then
			self.Frame.CanvasPosition = Vector2.new(0, frameListLayout.AbsoluteContentSize.Y);
		end
	end)
	
	return self;
end

function Room:UpdateVisible()
	for _, obj in pairs(self.Frame:GetChildren()) do
		if obj:IsA("GuiObject") then
			if self.Frame.Parent ~= mainChatFrame then
				obj.Visible = true;
				
			elseif mainInputFrame.Visible and self.Active then
				obj.Visible = true;
				if obj:GetAttribute("Visible") ~= nil then
					obj:SetAttribute("Visible", true);
				end
				
			else
				if obj:GetAttribute("Visible") ~= nil then
					obj:SetAttribute("Visible", false);
				else
					obj.Visible = false;
				end
				
			end
			
			obj.Active = mainInputFrame.Visible;
		end
	end
end


function Room:SwitchWindow()
	if ChatRoomInterface.SwitchChannelFunc[self.Id] then
		task.spawn(ChatRoomInterface.SwitchChannelFunc[self.Id]);
	end
end


function Room:SetActive()
	for index, room in pairs(ChatRoomInterface.Channels) do
		local id = room.Id;
		
		if id == self.Id then
			ChatRoomInterface.ActiveChannel = index;
			ChatClient.ActiveChannelId = id;
			
			self.Button.BackgroundColor3 = Color3.fromRGB(63, 71, 80);
			self.Active = true;
			
			if self.Frame.Parent == mainChatFrame then
				self.Frame.Visible = true;
				
			end
			
			if ChatClient.ChatCache[id] then
				ChatClient.ChatCache[id].NewMsgs = 0;
				room.Button.Text = id;
			end
		else
			if room.Button then
				room.Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40);
			end
			room.Active = false;
			
			if room.Frame.Parent == mainChatFrame then
				room.Frame.Visible = false;
				
			end
		end
	end
	
	if self.Sync ~= true then
		self.Sync = true;
		task.spawn(function() 
			remoteChatService:InvokeServer("syncchat", self.Id);
		end)
	end
	
	ChatRoomInterface:RefreshVisibility();
end
--==
function ChatRoomInterface:GetRoom(channelId)
	for a=1, #ChatRoomInterface.Channels do
		local room = ChatRoomInterface.Channels[a];
		local id = room.Id;
		if id == channelId then
			return room;
		end
	end
end

local reportButtonConn;
function ChatRoomInterface:NewMessage(room, messageData)
	messageData.RoomId = room.Id;
	
	local function processMessage(messageData)
		local roomId = messageData.RoomId;
		local nameString = messageData.Name;
		local msgString = messageData.Message;
		
		msgString = string.gsub(msgString,"&","&amp;");
		msgString = string.gsub(msgString,"<","&lt;");
		msgString = string.gsub(msgString,">","&gt;");
		msgString = string.gsub(msgString,'"',"&quot;");
		msgString = string.gsub(msgString,"'","&apos;");

		--chatkeywords Chat Keywords
		local colonStart, colonEnd = 0, 0;
		for a=1, 10 do
			colonStart, colonEnd = string.find(msgString, ";", colonEnd);
			
			if colonEnd == nil or colonEnd == 0 then
				break;
			end
			colonEnd = colonEnd+1;
			
			local wildCard = "(%w+)";
			local cutoffStart, cutoffEnd, cutOffStr = string.find(msgString, wildCard.." ", colonEnd);
			if cutOffStr == nil then
				cutoffStart, cutoffEnd, cutOffStr = string.find(msgString, wildCard.."%.", colonEnd);
			end
			if cutOffStr == nil then
				cutoffStart, cutoffEnd, cutOffStr = string.find(msgString, wildCard..",", colonEnd);
			end
			if cutOffStr == nil then
				cutoffStart, cutoffEnd, cutOffStr = string.find(msgString, wildCard.."!", colonEnd);
			end
			if cutOffStr == nil then
				cutoffStart, cutoffEnd, cutOffStr = string.find(msgString, wildCard.."?", colonEnd);
			end
			if cutOffStr == nil then
				cutoffStart, cutoffEnd, cutOffStr = string.find(msgString, wildCard..":", colonEnd);
			end
			if cutOffStr == nil then
				cutoffStart, cutoffEnd, cutOffStr = colonEnd, #msgString, string.sub(msgString, colonEnd, #msgString);
			end
			
			local keyword = cutOffStr;
			--Debugger:Warn("keyword", keyword);
			local isValidKeyword = false;
			
			if string.find(string.lower(keyword), "(%d+g)") or string.find(string.lower(keyword), "(%d+gold)") then
				
				local goldVal = string.match(keyword, "(%d+)");
				local newGStr = string.gsub(keyword, goldVal, modFormatNumber.Beautify(tonumber(goldVal)));
				msgString = string.gsub(msgString, keyword, modRichFormatter.GoldText(newGStr));
				
				isValidKeyword = true;
				
			elseif modItemsLibrary:Find(string.lower(keyword)) then
				local itemLib = modItemsLibrary:Find(string.lower(keyword));
				
				msgString = string.gsub(msgString, keyword, "<b>"..itemLib.Name.."</b>");
				
				isValidKeyword = true;
				
			elseif string.lower(keyword) == "roll" then
				
				msgString = string.gsub(msgString, keyword, `<font color="#4fdab0">{math.random(0, 100)}</font>`);
				isValidKeyword = true;
				
			--elseif string.find(text, "(%[%#(%a+)%]%(.+%))") then -- Hello [#abcdef](This will be colored) World

			end
			
			if isValidKeyword then
				msgString = msgString:sub(1, colonStart-1)..msgString:sub(colonStart+1, #msgString);
			end
			colonEnd = cutoffEnd;
		end
		
		messageData.Message = msgString;
	end
	processMessage(messageData);

	local msgString = messageData.Message;
	local nameString = messageData.Name;
	
	if nameString == "Game" then nameString = nil end;
	
	messageData.MsgTime = messageData.MsgTime or DateTime.now().UnixTimestampMillis;
	
	local msgTime = tonumber(messageData.MsgTime);
	local msgTimelapsed = msgTime-initTime;
	
	local notificationLib;
	
	if nameString then
		if messageData.Bubble == nil and initTime-msgTime <= 5000 then
			local speaker = game.Players:FindFirstChild(messageData.Name);

			local chatBubblePoint = speaker and speaker.Character and speaker.Character:FindFirstChild("Head");
			if chatBubblePoint and chatBubblePoint:IsDescendantOf(workspace) then
				pcall(function()
					local disableHud = game.Players.LocalPlayer:GetAttribute("DisableHud") == true;
					if disableHud then return end;

					ChatService:Chat(chatBubblePoint, messageData.Message, Enum.ChatColor.White);
				end)
			end
			messageData.Bubble = true;
		end
	else
		if messageData.Style then
			notificationLib = modNotificationsLibrary[messageData.Style];

			if notificationLib then
				local newMsgData = notificationLib(msgString);

				messageData.MessageColor = newMsgData.ExtraData.ChatColor;
				messageData.Font = newMsgData.ExtraData.Font;
				msgString = messageData.Message;
			end
		end
	end

	local richMsgString = msgString;
	
	local msgAlreadyExist = room.Frame:FindFirstChild(msgTime);
	if msgAlreadyExist then return end;
	
	local msgFrame = templateMessageFrame:Clone();
	msgFrame.Name = msgTime;
	local msgSize = Vector2.new(0, 16);

	local msgLabel = templateMessageLabel:Clone();
	local msgTimeLabel = msgLabel:WaitForChild("msgTimeLabel");

	msgFrame.LayoutOrder = msgTimelapsed/100;
	
	if not UserInputService.TouchEnabled then
		
		msgFrame.Active = false;
		msgFrame.MouseMoved:Connect(function()
			if not mainInputFrame.Visible then return end;
			msgFrame.BackgroundTransparency = 0.5;
			msgTimeLabel.Size = UDim2.new(1, 0, 0, 9);
			msgTimeLabel.Visible = true;
		end)
		msgFrame.MouseLeave:Connect(function()
			msgFrame.BackgroundTransparency = 1;
			msgTimeLabel.Visible = false;
			msgTimeLabel.Size = UDim2.new(1, 0, 0, 0);
		end)
		msgFrame.InputBegan:Connect(function(inputObject)
			if not mainInputFrame.Visible then return end;
			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 and messageData.Name ~= nil then
				local mousePosition = UserInputService:GetMouseLocation();

				optionsFrame.Visible = true;
				optionsFrame.Position = UDim2.new(0, mousePosition.X, 0, mousePosition.Y);
				if reportButtonConn then reportButtonConn:Disconnect() end;
				reportButtonConn = optionsFrame.reportButton.MouseButton1Click:Connect(function()
					if remoteSubmitChatReport then
						remoteSubmitChatReport:FireServer(messageData.Name);
					end
					for a=1, #ChatRoomInterface.Channels do
						local room = ChatRoomInterface.Channels[a];
						for _, obj in pairs(room.Frame:GetChildren()) do
							if obj:FindFirstChild(messageData.Name) then
								game.Debris:AddItem(obj, 0);
							end
						end
					end
					optionsFrame.Visible = false;
				end)
			end
		end)
	end
	
	msgTimeLabel.Text = DateTime.fromUnixTimestampMillis(msgTime):ToIsoDate();
	
	
	if messageData.MessageColor then
		msgLabel.TextColor3 = messageData.MessageColor;
	end
	if messageData.Font then
		pcall(function() msgLabel.Font = messageData.Font; end)
	end
	
	local richNameString = nameString;
	if messageData.Style then
		if nameString then
			local factionTag = modData.FactionData and modData.FactionData.Tag or "";
			local isFactionChat = room.Id == "["..factionTag.."]";
			
			if isFactionChat then
				local roleConfig = modData.FactionData.Roles[messageData.Style or "Member"];
				if roleConfig then
					richNameString = [[<font color="#]]..roleConfig.Color..[[">]]..nameString..[[  </font>]];
				end
				
			elseif messageData.Style == "Premium" then
				richNameString = [[<font face="ArialBold" color="rgb(255, 162, 0)">]]..nameString..[[  </font>]];
				
			elseif messageData.Style:sub(1, 5) == "Level" then
				local lvl = math.fmod(tonumber(messageData.Style:sub(6, #messageData.Style)) or 0, 100);
				if lvl < 10 then
					richNameString = [[<font color="rgb(206, 206, 206)">]]..nameString..[[  </font>]];
				elseif lvl < 20 then
					richNameString = [[<font color="rgb(156, 200, 130)">]]..nameString..[[  </font>]];
				elseif lvl < 30 then
					richNameString = [[<font color="rgb(112, 182, 113)">]]..nameString..[[  </font>]];
				elseif lvl < 40 then
					richNameString = [[<font color="rgb(135, 196, 209)">]]..nameString..[[  </font>]];
				elseif lvl < 50 then
					richNameString = [[<font color="rgb(123, 165, 255)">]]..nameString..[[  </font>]];
				elseif lvl < 60 then
					richNameString = [[<font color="rgb(173, 165, 255)">]]..nameString..[[  </font>]];
				elseif lvl < 80 then
					richNameString = [[<font color="rgb(255, 164, 246)">]]..nameString..[[  </font>]];
				elseif lvl < 100 then
					richNameString = [[<font color="rgb(234, 122, 122)">]]..nameString..[[  </font>]];
				end
				
			end
		end
	end
	if richNameString then
		if messageData.Style == "Announce" then
			msgLabel.Text = [[<font face="ArialBold" size="22" color="rgb(255, 170, 0)">]]..msgString..[[  </font>]];
		else
			msgLabel.Text = tostring(richNameString)..tostring(msgString);
		end
	else
		msgLabel.Text = richMsgString;
	end
	
	if messageData.Notify then
		local systemHighlight = msgLabel:WaitForChild("systemHighlight");
		systemHighlight.BackgroundColor3 = messageData.MessageColor;
		systemHighlight.Visible = true;
		local uiPadding = Instance.new("UIPadding");
		uiPadding.PaddingLeft = UDim.new(0, 6);
		uiPadding.Parent = msgLabel;
	end

	msgLabel.Parent = msgFrame;
	msgFrame.Parent = room.Frame;
	
	msgFrame.Visible = true;
	msgFrame:SetAttribute("Visible", mainInputFrame.Visible);

	local packet = messageData.Packet or {};
	if packet.SndId then
		modAudio.Play(packet.SndId, room.Frame);
	end
	
	task.delay(10, function()
		if room.Frame.Parent ~= mainChatFrame then return end
		if mainInputFrame.Visible == false then
			msgFrame.Visible = false;
		end
		msgFrame:SetAttribute("Visible", nil);
		if messageData.Presist == false then
			msgFrame:Destroy();
		end
	end)
end

function ChatRoomInterface:RefreshVisibility()
	for a=1, #ChatRoomInterface.Channels do
		local room = ChatRoomInterface.Channels[a];
		room:UpdateVisible()
	end
end

function ChatRoomInterface:newRoom(channelId)
	local room = Room.new(channelId);
	table.insert(ChatRoomInterface.Channels, room);
	return room;
end

function ChatRoomInterface.init()
	local library = game.ReplicatedStorage:WaitForChild("Library", 60);
	local modRemotesManager = require(library:WaitForChild("RemotesManager", 60));
	
	table.insert(ChatRoomInterface.Channels, Room.new("Server"));
	table.insert(ChatRoomInterface.Channels, Room.new("Global"));

	if modBranchConfigs.CurrentBranch.Name == "Dev" then
		table.insert(ChatRoomInterface.Channels, Room.new("Logs"));
		table.insert(ChatRoomInterface.Channels, Room.new("Bugs"));
	else
		table.insert(ChatRoomInterface.Channels, Room.new("LookingFor"));
		table.insert(ChatRoomInterface.Channels, Room.new("Trade"));
	end
	
	for channelId, cache in pairs(ChatClient.ChatCache) do
		local exist = false;
		for a=1, #ChatRoomInterface.Channels do
			if ChatRoomInterface.Channels[a].Id == channelId then
				exist = true;
				break;
			end
		end
		if not exist then
			table.insert(ChatRoomInterface.Channels, Room.new(channelId));
		end
	end
	
	for channelId, cache in pairs(ChatClient.ChatCache) do
		local messages = cache.Messages;
		if #messages > 0 then
			local room = ChatRoomInterface:GetRoom(channelId);
			local startIndex = math.max(#messages-5, 1);
			for a=startIndex, #messages do
				ChatRoomInterface:NewMessage(room, messages[a]);
			end
		end
	end
	
	local onNewMessage
	onNewMessage = function(channelId, newMsg)
		if not script:IsDescendantOf(game.Players.LocalPlayer) then
			ChatClient.OnNewMessage:Disconnect(onNewMessage);
			return; 
		end;
		
		local room = ChatRoomInterface:GetRoom(channelId);
		if room == nil then
			Debugger:Warn("Missing chat channel:", channelId); 
			room = ChatRoomInterface:newRoom(channelId);
			
			if newMsg.Dm then
				room.Dm = newMsg.Dm;
			end
		end;
		
		if room.Active then
			ChatClient.ChatCache[channelId].NewMsgs = 0;
			room.Button.Text = channelId;
		else
			ChatClient.ChatCache[channelId].NewMsgs = ChatClient.ChatCache[channelId].NewMsgs +1;
			room.Button.Text = channelId.." ("..ChatClient.ChatCache[channelId].NewMsgs..")";
		end
		
		ChatRoomInterface:NewMessage(room, newMsg);
	end
	
	ChatClient.OnNewMessage:Connect(onNewMessage);
	
	mainInputFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		ChatRoomInterface:RefreshVisibility();
		
		for index, room in pairs(ChatRoomInterface.Channels) do
			room.Frame.ScrollingEnabled = mainInputFrame.Visible;
		end
	end)
	
	ChatRoomInterface.Channels[1]:SetActive();
	
	remoteSubmitChatReport = modRemotesManager:Get("SubmitChatReport");
end


return ChatRoomInterface;