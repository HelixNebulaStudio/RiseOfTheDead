local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configurations;
local avatarString = "https://www.roblox.com/headshot-thumbnail/image?userId=$UserId&width=420&height=420&format=png";

--== Variables;
local TextService = game:GetService("TextService");
local RunService = game:GetService("RunService");
local modInterface = require(script.Parent.Parent.InterfaceModule);
local modSyncTime = require(game.ReplicatedStorage.Library:WaitForChild("SyncTime"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);

local submitButton = script.Parent:WaitForChild("Submit");
local submitText = submitButton:WaitForChild("buttonText");
local cancelButton = script.Parent:WaitForChild("Cancel");
local typeButton = script.Parent:WaitForChild("Type");
local typeText = typeButton:WaitForChild("buttonText");
local playerButton = script.Parent:WaitForChild("Player");
local playerText = playerButton:WaitForChild("buttonText");
local dropDownMenu = script.Parent:WaitForChild("DropDownMenu");
local dropDownListLayout = dropDownMenu:WaitForChild("UIListLayout");
local descTag = script.Parent:WaitForChild("descTag");
local chatRoomFrame = script.Parent:WaitForChild("ChatRoomFrame");

local templateClientChat = script:WaitForChild("ClientChatFrame");
local templateServerChat = script:WaitForChild("ServerChatFrame");

local messageBox = script.Parent:WaitForChild("MessageBox");
local quickButton = script.Parent.Parent.QuickButtons:WaitForChild("ReportMenu");
local quickButtonCounter = quickButton:WaitForChild("AmtFrame"):WaitForChild("AmtLabel");

local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
local remoteClientReport = remotes:WaitForChild("Interface"):WaitForChild("ClientReport");

local LocalPlayer = game.Players.LocalPlayer;
local modData = require(LocalPlayer:WaitForChild("DataModule"));

local defaultSize = Vector2.new(script.Parent.AbsoluteSize.X, script.Parent.AbsoluteSize.Y);

local ReportTypes = {Bug=0; Feedback=1; Exploit=2};
local CurrentType = ReportTypes.Bug;
local SelectedPlayer = nil;

local debounce = false;
local textboxOffset = 0;
local ChatRoomCache = {};
local ChatRoomMessages = modGlobalVars.Cache.Support;
local ClientSideMessage = nil;
local LastSubmission = 0;
--== Script;
function DropDownMenu(list, onClick)
	for _, c in pairs(dropDownMenu:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end;
	end
	local selected = false;
	local index = 0;
	for name, _ in pairs(list) do
		local new = typeButton:Clone();
		local textLabel = new:WaitForChild("buttonText");
		textLabel.Text = name;
		if CurrentType == ReportTypes[name] then
			dropDownMenu.Position = UDim2.new(0, 0, 0, 65-(index*35));
		elseif SelectedPlayer and SelectedPlayer.Name == name then
			dropDownMenu.Position = UDim2.new(1, -85, 0, 375-(index*35));
		end
		
		new.MouseButton1Click:Connect(function() if selected then return end; selected = true; modInterface:PlayButtonClick(); onClick(name) end)
		new.Parent = dropDownMenu;
		index = index +1;
	end
	RunService.Heartbeat:Wait();
	dropDownMenu.Size = UDim2.new(dropDownMenu.Size.X.Scale, dropDownMenu.Size.X.Offset, 0, dropDownListLayout.AbsoluteContentSize.Y);
	dropDownMenu.Visible = true;
end

function RefreshChatRoom()
--	if ChatRoomCache.Default == nil then
--		ChatRoomCache.Default = templateServerChat:Clone();
--		ChatRoomCache.Default.Parent = chatRoomFrame;
--	end
	local function refreshCanvasSize()
		chatRoomFrame.CanvasSize = UDim2.new(0, 0, 0, chatRoomFrame.UIListLayout.AbsoluteContentSize.Y+15);
		chatRoomFrame.CanvasPosition = chatRoomFrame.AbsoluteWindowSize;
	end
	local xBounds = chatRoomFrame.AbsoluteSize.X-90;
	
	local alertcount = 0;
	for a=1, #ChatRoomMessages do
		if ChatRoomMessages[a].Speaker ~= "helixnebuladev" then
			alertcount = alertcount+1;
		else
			break;
		end
	end
	if alertcount > 0 then
		quickButtonCounter.Text = alertcount;
	else
		quickButtonCounter.Text = "";
	end
	
	if ClientSideMessage then
		table.insert(ChatRoomMessages, ClientSideMessage);
	end
	for a=#ChatRoomMessages, 1, -1 do
		local message = ChatRoomMessages[a];
		if ChatRoomCache[message.Date] == nil then
			local new;
			
			if message.Speaker == "system" then
				new = templateServerChat:Clone();
				
				local nameTag = new:WaitForChild("nameTag")
				nameTag.Text = "System";
				
				local messageFrame = new:WaitForChild("MessageFrame")
				local messageTag = new:WaitForChild("MessageFrame"):WaitForChild("MessageTag");
				messageTag.Text = message.Text;
				new.Parent = chatRoomFrame;
				spawn(function()
					local textBounds = TextService:GetTextSize(messageTag.Text, messageTag.TextSize, messageTag.Font, Vector2.new(xBounds, 1000));
					messageFrame.Size = UDim2.new(0, math.clamp(textBounds.X+16, 0, xBounds), 0, textBounds.Y+15);
					new.Size = UDim2.new(1, 0, 0, messageFrame.Size.Y.Offset+35);
					refreshCanvasSize();
				end)
				
			elseif message.Speaker ~= "helixnebuladev" then -- Server
				new = templateServerChat:Clone();
				
				local nameTag = new:WaitForChild("nameTag")
				nameTag.Text = "MXKhronos (Developer)";
				local avatarLabel = new:WaitForChild("AvatarFrame"):WaitForChild("Avatar");
				avatarLabel.Image = avatarString:gsub("$UserId", 16170943);
				
				local messageFrame = new:WaitForChild("MessageFrame")
				local messageTag = new:WaitForChild("MessageFrame"):WaitForChild("MessageTag");
				messageTag.Text = message.Text;
				new.Parent = chatRoomFrame;
				spawn(function()
					local textBounds = TextService:GetTextSize(messageTag.Text, messageTag.TextSize, messageTag.Font, Vector2.new(xBounds, 1000));
					messageFrame.Size = UDim2.new(0, math.clamp(textBounds.X+16, 0, xBounds), 0, textBounds.Y+15);
					new.Size = UDim2.new(1, 0, 0, messageFrame.Size.Y.Offset+35);
					refreshCanvasSize();
				end)
				
			else
				new = templateClientChat:Clone();
				local nameTag = new:WaitForChild("nameTag")
				nameTag.Text = LocalPlayer.Name;
				local avatarLabel = new:WaitForChild("AvatarFrame"):WaitForChild("Avatar");
				avatarLabel.Image = avatarString:gsub("$UserId", LocalPlayer.UserId);
				local messageFrame = new:WaitForChild("MessageFrame")
				local messageTag = new:WaitForChild("MessageFrame"):WaitForChild("MessageTag");
				local messageType = message.Text:match("**Bug**") and "Bug"
								or message.Text:match("**Feedback**") and "Feedback"
								or message.Text:match("**Exploit**") and "Exploit" or "System";
				messageTag.Text = messageType == "Bug" and message.Text:sub(9, #message.Text)
								or messageType == "Feedback" and message.Text:sub(14, #message.Text)
								or messageType == "Exploit" and message.Text:sub(13, #message.Text)
								or messageType == "System" and message.Text;
				
				messageTag.Text = messageTag.Text:sub(1, 5) == "(Dev)" and messageTag.Text:sub(7, #message.Text)
								or messageTag.Text:sub(1, 5) == "(Live)" and messageTag.Text:sub(7, #message.Text) or messageTag.Text;
				new.Parent = chatRoomFrame;
				spawn(function()
					local textBounds = TextService:GetTextSize(messageTag.Text, messageTag.TextSize, messageTag.Font, Vector2.new(xBounds, 1000));
					messageFrame.Size = UDim2.new(0, math.clamp(textBounds.X+16, 0, xBounds), 0, textBounds.Y-30);
					new.Size = UDim2.new(1, 0, 0, messageFrame.Size.Y.Offset+35);
					refreshCanvasSize();
				end)
			end
			new.LayoutOrder = message.Speaker == "system" and 999 or (#ChatRoomMessages-a+1);
			ChatRoomCache[message.Date] = new;
			
		elseif message.Speaker == "system" then
			
			local new = ChatRoomCache[message.Date];
			local messageTag = new:WaitForChild("MessageFrame"):WaitForChild("MessageTag");
			messageTag.Text = message.Text;
			
		end
	end
	refreshCanvasSize();
end

local function SetPlayerVisible(visible)
	if visible then
		playerButton.Visible = true;
		messageBox.Size = UDim2.new(1, -240, 0, math.clamp(messageBox.Size.Y.Offset, 20, 200));
	else
		playerButton.Visible = false;
		messageBox.Size = UDim2.new(1, -100, 0, math.clamp(messageBox.Size.Y.Offset, 20, 200));
	end
end

typeButton.MouseButton1Click:Connect(function()
	if debounce then return end; debounce = true;
	modInterface:PlayButtonClick();
	dropDownMenu.Position = typeButton.Position;
	dropDownMenu.Size = typeButton.Size;
	dropDownMenu.AnchorPoint = Vector2.new(0, 0);
	DropDownMenu(ReportTypes, function(name)
		CurrentType = ReportTypes[name];
		dropDownMenu.Visible = false;
		typeText.Text = name;
		
		if name == "Exploit" then
			if #game.Players:GetPlayers() > 1 then
				SetPlayerVisible(true);
			end
		else
			SetPlayerVisible(false);
		end
	end);
	debounce = false;
end)

playerButton.MouseButton1Click:Connect(function()
	if debounce then return end; debounce = true;
	modInterface:PlayButtonClick();
	local players = game.Players:GetPlayers();
	local list = {};
	for _, p in pairs(players) do
		if p ~= game.Players.LocalPlayer then
			list[p.Name] = p;
		end
	end
	dropDownMenu.Position = playerButton.Position;
	dropDownMenu.Size = playerButton.Size;
	dropDownMenu.AnchorPoint = Vector2.new(1, 0);
	DropDownMenu(list, function(name)
		SelectedPlayer = list[name];
		dropDownMenu.Visible = false;
		playerText.Text = name;
	end);
	debounce = false;
end)

local function closeMenu()
	dropDownMenu.Visible = false;
	CurrentType = ReportTypes.Bug;
	typeText.Text = "Bug";
	SelectedPlayer = nil;
	playerText.Text = "None";
	submitText.Text = "Submit";
	messageBox.Text = "";
	script.Parent.Size = UDim2.new(0, defaultSize.X, 0, defaultSize.Y);
	playerButton.Visible = false;
	modInterface:CloseWindow("ReportMenu");
end

cancelButton.MouseButton1Click:Connect(function()
	if debounce then return end; debounce = true;
	modInterface:PlayButtonClick();
	closeMenu();
	debounce = false;
end)

local function clearSystemMsgs()
	ClientSideMessage = nil;
end

local cooldown = 60;--43200;
submitButton.MouseButton1Click:Connect(function()
	if #messageBox.Text <= 50 then return end;
	if debounce then return end; debounce = true;
	modInterface:PlayButtonClick();
	messageBox.TextEditable = false;
	
	local canSubmit = (modSyncTime.GetTime()-LastSubmission) > cooldown;
	Debugger:Log("Can post another:", canSubmit);
	
	if canSubmit then
		submitText.Text = "Submitted";
		
		local submissionMsg = messageBox.Text;
		if CurrentType == ReportTypes.Bug and #modData.ErrorLogs > 0 then
			local lastErrorMsg = modData.ErrorLogs[1];
			submissionMsg = submissionMsg.."\n\nLog: "..lastErrorMsg;
		end
		
		remoteClientReport:FireServer(CurrentType, submissionMsg:sub(1, 1024), SelectedPlayer);
		
		task.wait(1);
		RefreshChatRoom();
		messageBox.Text = "";
		
	else
		ClientSideMessage = {
			Date="System";
			Text="You cannot post another report yet, Cooldown: "..(modSyncTime.ToString( cooldown-(modSyncTime.GetTime()-LastSubmission) ));
			Speaker="system"
		};
		
		delay(60, clearSystemMsgs)
		
		submitText.Text = "Cooldown";
		RefreshChatRoom();
		
	end
	
	wait(2);
	submitText.Text = "Submit";
	messageBox.TextEditable = true;
	debounce = false;
end)

local requireInputLen = 21;
messageBox:GetPropertyChangedSignal("Text"):Connect(function()
	messageBox.Text = messageBox.Text:sub(1, 850);
	if not modConfigurations.CompactInterface then
		local textBounds = TextService:GetTextSize(messageBox.Text, messageBox.TextSize, messageBox.Font, Vector2.new(messageBox.AbsoluteSize.X, 1000));
		textboxOffset = math.floor((math.clamp(textBounds.Y, 20, 200)-6)/15)*15;
		messageBox.Size = UDim2.new(1, messageBox.Size.X.Offset, 0, 20+textboxOffset);
		script.Parent.Size = UDim2.new(0, defaultSize.X, 0, defaultSize.Y+textboxOffset);
		script.Parent.InputFrame.Size = UDim2.new(1, -85, 0, 30+textboxOffset);
	end
	
	submitButton.ImageColor3 = #messageBox.Text <= requireInputLen and Color3.fromRGB(72, 72, 72) or Color3.fromRGB(53, 72, 49);
	submitButton.AutoButtonColor = #messageBox.Text <= requireInputLen;
	
	submitText.Text = #messageBox.Text <= requireInputLen and "More Info Required" or "Submit";
end)

remoteClientReport.OnClientEvent:Connect(function(chatMessages, lastSubmission)
	modGlobalVars.Cache.Support = chatMessages or {};
	ChatRoomMessages = modGlobalVars.Cache.Support;
	LastSubmission = lastSubmission or 0;
	RefreshChatRoom();
end)

local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local menu = script.Parent;
if modConfigurations.CompactInterface then
	menu.Position = UDim2.new(0.5, 0, 0.5, 0);
	menu.Size = UDim2.new(1, 0, 1, 0);
	
	menu:WaitForChild("touchCloseButton").Visible = true;
	menu:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		modInterface:CloseWindow("ReportMenu");
	end)
end
local window = modInterface.NewWindow("ReportMenu", script.Parent);
window.CompactFullscreen = true;
window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1, 0));
window.OnWindowToggle:Connect(function(visible)
	if visible then
		RefreshChatRoom();
	end
end)
window:SetConfigKey("DisableReportMenu");

modKeyBindsHandler:SetDefaultKey("KeyWindowReportMenu", Enum.KeyCode.F3);
modInterface:ConnectQuickButton(quickButton, "KeyWindowReportMenu");

RefreshChatRoom();