local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");
local UserInputService = game:GetService("UserInputService");
local ChatService = game:GetService("Chat");
local StarterGui = game:GetService("StarterGui")

local chatInterface = script.Parent;
local inputFrame = chatInterface:WaitForChild("InputFrame");
local inputBox = inputFrame:WaitForChild("inputBar"):WaitForChild("inputBox");

local localPlayer = game.Players.LocalPlayer;
local playerGui = localPlayer:WaitForChild("PlayerGui");

local mainChatFrame = script.Parent:WaitForChild("ChatFrame");
local mainChannelsFrame = script.Parent:WaitForChild("ChannelsFrame");
local decorFrame = script.Parent:WaitForChild("DecorFrame");
local cmdFrame = inputFrame:WaitForChild("CmdFrame");
local toggleChatButton = inputFrame:WaitForChild("toggleChat");
local optionsFrame = script.Parent:WaitForChild("OptionsFrame");

local chatButton = chatInterface:WaitForChild("ChatButton");
local channelButton = chatInterface:WaitForChild("ChannelButton");
local activeChannelLabel = chatInterface:WaitForChild("activeChannelLabel");

local CommandsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("CommandsLibrary"));
local CommandHandler = require(game.ReplicatedStorage.Library:WaitForChild("CommandHandler"));
local ChatRoomInterface = require(script.Parent:WaitForChild("ChatRoomInterface"));
ChatRoomInterface.init();

local shiftKeyDown = false;

local library = game.ReplicatedStorage:WaitForChild("Library", 60);
local modRemotesManager = require(library:WaitForChild("RemotesManager", 60));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables", 60));
local modBranchConfigs = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));

local remoteSubmitMessage = modRemotesManager:Get("SubmitMessage");
local remoteChatService = modRemotesManager:Get("ChatService");

local templateLabel = script:WaitForChild("label");

local camera = workspace.CurrentCamera;

delay(1, function() 
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false);
end)

local bubbleSettings = {
	-- The amount of time, in seconds, to wait before a bubble fades out.
	BubbleDuration = 5,

	-- The amount of messages to be displayed, before old ones disappear
	-- immediately when a new message comes in.
	MaxBubbles = 2,

	-- Styling for the bubbles. These settings will change various visual aspects.
	BackgroundColor3 = Color3.fromRGB(250, 250, 250),
	TextColor3 = Color3.fromRGB(57, 59, 61),
	TextSize = 14,
	Font = Enum.Font.GothamSemibold,
	Transparency = .1,
	CornerRadius = UDim.new(0, 6),
	TailVisible = true,
	Padding = 8, -- in pixels
	MaxWidth = 300, --in pixels

	-- Extra space between the head and the billboard (useful if you want to
	-- leave some space for other character billboard UIs)
	VerticalStudsOffset = 0,

	-- Space in pixels between two bubbles
	BubblesSpacing = 6,

	-- The distance (from the camera) that bubbles turn into a single bubble
	-- with ellipses (...) to indicate chatter.
	MinimizeDistance = 40,
	-- The max distance (from the camera) that bubbles are shown at
	MaxDistance = 100,
}
pcall(function()
	ChatService:SetBubbleChatSettings(bubbleSettings);
end)
ChatService.BubbleChatEnabled = true;
--==
chatButton.Visible = UserInputService.TouchEnabled;

if camera.ViewportSize.X < 800 then
	mainChatFrame.Position = UDim2.new(0, 0, 1, 0);
	mainChatFrame.Size = UDim2.new(0, 300, 0, 100);
end

local function onChannelButtonsChange()
	local objs = mainChannelsFrame:GetChildren();
	local buttons = {};
	for a=1, #objs do
		if objs[a]:IsA("TextButton") then
			table.insert(buttons, objs[a]);
		end
	end
	
end

mainChannelsFrame.ChildAdded:Connect(onChannelButtonsChange);
mainChannelsFrame.ChildRemoved:Connect(onChannelButtonsChange)

local function tabChat()
	if shiftKeyDown then
		if ChatRoomInterface.ActiveChannel-1 < 1 then
			ChatRoomInterface.ActiveChannel = #ChatRoomInterface.Channels;
		else
			ChatRoomInterface.ActiveChannel = ChatRoomInterface.ActiveChannel-1;
		end
		
	else
		if ChatRoomInterface.ActiveChannel+1 > #ChatRoomInterface.Channels then
			ChatRoomInterface.ActiveChannel = 1;
		else
			ChatRoomInterface.ActiveChannel = ChatRoomInterface.ActiveChannel+1;
		end
		
	end

	local room = ChatRoomInterface.Channels[ChatRoomInterface.ActiveChannel];
	room:SetActive();
	room:SwitchWindow();
	
	activeChannelLabel.Text = tostring(room.Id);
	
	onChannelButtonsChange();
end

local charactersEnums = {
	[Enum.KeyCode.A]=true; [Enum.KeyCode.B]=true; [Enum.KeyCode.C]=true; [Enum.KeyCode.D]=true; [Enum.KeyCode.E]=true;
	[Enum.KeyCode.F]=true; [Enum.KeyCode.G]=true; [Enum.KeyCode.H]=true; [Enum.KeyCode.I]=true; [Enum.KeyCode.J]=true;
	[Enum.KeyCode.K]=true; [Enum.KeyCode.L]=true; [Enum.KeyCode.M]=true; [Enum.KeyCode.N]=true; [Enum.KeyCode.O]=true;
	[Enum.KeyCode.P]=true; [Enum.KeyCode.Q]=true; [Enum.KeyCode.R]=true; [Enum.KeyCode.S]=true; [Enum.KeyCode.T]=true;
	[Enum.KeyCode.U]=true; [Enum.KeyCode.V]=true; [Enum.KeyCode.W]=true; [Enum.KeyCode.X]=true; [Enum.KeyCode.Y]=true; [Enum.KeyCode.Z]=true;
	
	[Enum.KeyCode.One]=true; [Enum.KeyCode.Two]=true; [Enum.KeyCode.Three]=true; [Enum.KeyCode.Four]=true; [Enum.KeyCode.Five]=true;
	[Enum.KeyCode.Six]=true; [Enum.KeyCode.Seven]=true; [Enum.KeyCode.Eight]=true; [Enum.KeyCode.Nine]=true; [Enum.KeyCode.Zero]=true;
}

local cmdMatchs = {}; local matchIndexTab = nil; 
local lastInputTick = tick()-2;
local lastInput = "";

local oldChatCache = {};
local oldChatIndex = nil;

local function inputBoxChange()
	ChatRoomInterface.Channels[ChatRoomInterface.ActiveChannel]:SetActive();
	lastInputTick = tick();
	
	local maxInputSize = Vector2.new(490 + ((#ChatRoomInterface.Channels-4) * 110), 42)
	local textBounds = TextService:GetTextSize(inputBox.Text, inputBox.TextSize, inputBox.Font, Vector2.new(maxInputSize.X, 1000));

	if #inputBox.Text > #lastInput then
		local addedChar = inputBox.Text:sub(#inputBox.Text, #inputBox.Text);
		if string.byte(addedChar) == 13 then
			inputBox.Text = lastInput..string.char(10);
		elseif string.byte(addedChar) == 9 then
			inputBox.Text = lastInput;
		end
	end

	if #inputBox.Text >= 200 or textBounds.Y > maxInputSize.Y then
		inputBox.Text = lastInput;
	else
		lastInput = inputBox.Text;
	end
	textBounds = TextService:GetTextSize(inputBox.Text, inputBox.TextSize, inputBox.Font, Vector2.new(maxInputSize.X, 1000));

	local inputY = math.clamp(textBounds.Y, 14, maxInputSize.Y);
	inputFrame.Size = UDim2.new(0, maxInputSize.X+40, 0, inputY+20);
	decorFrame.Size = UDim2.new(0, maxInputSize.X+40, 0, inputY+20 + 40);
	mainChannelsFrame.Size = UDim2.new(0, maxInputSize.X+40, 0, UserInputService.TouchEnabled and 40 or 20);
	mainChannelsFrame.Position = UDim2.new(0, 0, 1, -inputY+20 - 40);

	delay(2, function()
		if tick()-lastInputTick < 2 then return end;
		if inputBox.Text:sub(1,1) ~= "/" and inputBox.Text ~= "" then
			local cacheText = inputBox.Text;
			local filtered = remoteSubmitMessage:InvokeServer(ChatRoomInterface.Channels[ChatRoomInterface.ActiveChannel].Id, cacheText, true);
			if inputBox.Text == cacheText then
				inputBox.Text = filtered;
			end
		end
	end)

	--Cmd suggest
	local message = inputBox.Text;
	
	if matchIndexTab == nil then
		cmdMatchs = {};
		if message:sub(1, 1) == "/" and #message >= 2 then
			
			
			local cmd, args = CommandHandler.ProcessMessage(message);
			if cmd == nil then return end;
			local cmdId = cmd:sub(2, #cmd):lower();

			local matches = CommandHandler.MatchStringFromDict(cmdId, CommandsLibrary.Library);
			if #matches > 0 then
				
				for _, obj in pairs(cmdFrame:GetChildren()) do
					if obj:IsA("GuiObject") then obj:Destroy() end;
				end
				for a=1, #matches do
					local lib = CommandsLibrary.Library[matches[a]];

					if CommandsLibrary.HasPermissions(game.Players.LocalPlayer, lib) then
						local new = templateLabel:Clone();

						local labelText = " /"..matches[a];
						if #matches == 1 then
							if lib.UsageInfo then
								labelText = " "..lib.UsageInfo;
							end
							
							labelText = "<b>".. labelText .."</b>";
							
							local desc = lib.Description;
							
							if desc then
								desc = string.gsub(desc, "(%<%[%>)", "[[");
								desc = string.gsub(desc, "(%<%]%>)", "]]");
							end
							
							labelText = labelText .."\n\nDescription:\n    ".. (desc or "n/a");
						end
						
						new.Text = labelText;
						
						new.Name = matches[a];
						table.insert(cmdMatchs, matches[a]);
						new.Parent = cmdFrame;
					end
				end
				
			end
		end
	end
	cmdFrame.Visible = #cmdMatchs > 0;

	onChannelButtonsChange();
end

local function toggleChat(force)
	if force == false or inputBox:IsFocused() then -- Close chat
		inputBox:ReleaseFocus(true);
		chatInterface.DisplayOrder = 0;
		inputFrame.Visible = false;
		mainChannelsFrame.Visible = false;
		decorFrame.Visible = false;
		optionsFrame.Visible = false;
		
		if localPlayer:GetAttribute("CinematicMode") == true then
			mainChatFrame.Visible = false;
		end
		
		
		channelButton.Visible = false;
		activeChannelLabel.Visible = false;

		
	else
		inputBox:CaptureFocus();
		chatInterface.DisplayOrder = 99;
		inputFrame.Visible = true;
		mainChannelsFrame.Visible = true;
		decorFrame.Visible = true;
		mainChatFrame.Visible = true;
		
		local room = ChatRoomInterface.Channels[ChatRoomInterface.ActiveChannel];
		room:SetActive();
		room:SwitchWindow();
		
		if UserInputService.TouchEnabled then
			channelButton.Visible = true;
			activeChannelLabel.Visible = true;
		end
	end
	
	if playerGui:FindFirstChild("MainInterface") and playerGui.MainInterface:FindFirstChild("InterfaceModule") then
		require(playerGui.MainInterface.InterfaceModule):RefreshVisibility();
	end
	inputBoxChange();
end

chatButton.MouseButton1Click:Connect(function()
	if mainChannelsFrame.Visible then
		toggleChat(false);
	else
		toggleChat(true);
	end
end)

channelButton.MouseButton1Click:Connect(function()
	tabChat();
end)



ChatRoomInterface.ToggleFocusChat = toggleChat;
toggleChatButton.MouseButton1Click:Connect(function()
	mainChatFrame.Visible = false;
	toggleChat(false);
end)

local function playEmote(id)
	local character = game.Players.LocalPlayer.Character;
	local remotePlayEmote = character and character:FindFirstChild("PlayEmote", true);
	if remotePlayEmote then
		remotePlayEmote:Invoke(id);
	end
end

local ClientCommands = {};
ClientCommands["ui"] = function(channelId, args)
	local room = ChatRoomInterface:GetRoom(channelId);
	
	local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
	local modInterface = modData:GetInterfaceModule();
	
	local inputName = args[1] or "";
	
	if modInterface.Windows[inputName] then
		modInterface:ToggleWindow(inputName);
		
	else
		local similarList = {};
		for name, _ in pairs(modInterface.Windows) do
			if string.lower(name):match(string.lower(inputName)) then
				table.insert(similarList, name);
			end
		end
		ChatRoomInterface:NewMessage(room, {
			Message = "Unknown interface called "..inputName..". Similar: "..table.concat(similarList, ", ");
			Presist = false;
			MessageColor=Color3.fromRGB(255, 69, 69);
		})
	end
	
end

ClientCommands["term"] = function(channelId, args)
	local room = ChatRoomInterface:GetRoom(channelId);

	local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();

	local termCmd = args[1] or "";
	
	if modInterface.Windows.TerminalWindow then
		modInterface:ToggleWindow("TerminalWindow", nil, termCmd);

	end

end

ClientCommands["report"] = function(channelId, args)
	local room = ChatRoomInterface:GetRoom(channelId);
	
	local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
	local modInterface = modData:GetInterfaceModule();
	
	modInterface:ToggleWindow("ReportMenu");
end

ClientCommands["vote"] = function(channelId, args)
	local room = ChatRoomInterface:GetRoom(channelId);
	
	local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
	local modInterface = modData:GetInterfaceModule();
	
	modInterface:ToggleWindow("VoteWindow");
end

ClientCommands["e"] = function(channelId, args)
	playEmote(args[1] or "dance");
end

ClientCommands["w"] = function(channelId, args)
	local playerName = #args > 0 and table.remove(args, 1) or nil;
	local msg = table.concat(args, " ");
	
	if playerName == nil then return end;
	local matches = CommandHandler.MatchName(playerName);
	local room = ChatRoomInterface:GetRoom(channelId);
	if #matches <= 0 then
		ChatRoomInterface:NewMessage(room, {
			Message = "Couldn't find "..playerName.." on this server.";
			Presist = false;
			MessageColor=Color3.fromRGB(255, 69, 69);
		})
		return;
	elseif #matches >= 2 then
		ChatRoomInterface:NewMessage(room, {
			Message = "Multiple matches for \""..playerName.."\": "..table.concat(matches, " ");
			Presist = false;
			MessageColor=Color3.fromRGB(255, 69, 69);
		})
		return;
	end
	local target = matches[1];
	local testText = msg:gsub(" ", "")
	testText = testText:gsub(string.byte(32), "")
	testText = testText:gsub("[\r\n]", "");
	
	if #testText > 0 and #msg < 200 then
		remoteSubmitMessage:InvokeServer(target.Name, msg);
		for a=1, 10 do
			local room = ChatRoomInterface:GetRoom(target.Name);
			if room then
				room:SetActive();
				room:SwitchWindow();
				break;
			end
			task.wait(0.1);
		end
	end;
end

ClientCommands["f"] = function(channelId, args)
	local msg = table.concat(args, " ");

	local speakerRoom = ChatRoomInterface:GetRoom(channelId);
	
	local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
	
	local factionProfile = modData.Profile.Faction;
	local channelId = factionProfile.ChannelId;
	if channelId == nil then
		ChatRoomInterface:NewMessage(speakerRoom, {
			Message = "You are not in a faction.";
			Presist = false;
			MessageColor=Color3.fromRGB(255, 69, 69);
		})
		return 
	end;
	
	local testText = msg:gsub(" ", "")
	testText = testText:gsub(string.byte(32), "")
	testText = testText:gsub("[\r\n]", "");
	if #testText > 0 and #msg < 200 then
		remoteSubmitMessage:InvokeServer(channelId, msg);
		for a=1, 10 do
			local room = ChatRoomInterface:GetRoom(channelId);
			if room then
				room:SetActive();
				room:SwitchWindow();
				break;
			end
			task.wait(0.1);
		end
	end;
end

ClientCommands["c"] = function(channelId)
	local room = ChatRoomInterface:GetRoom(channelId);
	for a=1, #ChatRoomInterface.Channels do
		if ChatRoomInterface.Channels[a].Id == channelId and a >= 4 then
			game.Debris:AddItem(ChatRoomInterface.Channels[a].Button, 0);
			game.Debris:AddItem(ChatRoomInterface.Channels[a].Frame, 0);
			table.remove(ChatRoomInterface.Channels, a);
			tabChat();
			break;
		else
			ChatRoomInterface:NewMessage(room, {
				Message = "You can't close this channel";
				Presist = false;
				MessageColor=Color3.fromRGB(255, 69, 69);
			})
		end
	end
end

ClientCommands["s"] = function(channelId, args)
	local targetChannel = args[1];
	if targetChannel == nil then return end;
	local speakerRoom = ChatRoomInterface:GetRoom(channelId);
	
	local room = ChatRoomInterface:GetRoom(targetChannel);
	if room then
		if room.Id == channelId then
			ChatRoomInterface:NewMessage(room, {
				Message = "You are already in channel "..channelId;
				Presist = false;
				MessageColor=Color3.fromRGB(255, 69, 69);
			});
		else
			room:SetActive();
			room:SwitchWindow();
		end
	else
		ChatRoomInterface:NewMessage(speakerRoom, {
			Message = "The channel "..targetChannel.." does not exist.";
			Presist = false;
			MessageColor=Color3.fromRGB(255, 69, 69);
		})
	end
end

--ClientCommands["config"] = function(channelId, args)
--	local room = ChatRoomInterface:GetRoom(channelId);
--	local configId = args[1];
--	local value = args[2];
	
--	local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
	
--	if configId and (modConfigurations[configId] ~= nil) then
--		if modBranchConfigs.CurrentBranch.Name == "Dev" then
--			modConfigurations.Set(configId, value)
--			ChatRoomInterface:NewMessage(room, {
--				Message = "[Client] Client config (".. configId ..")="..tostring(value)..".";
--				Presist = false;
--				MessageColor=Color3.fromRGB(99, 167, 255);
--			})
--		else
--			ChatRoomInterface:NewMessage(room, {
--				Message = "[Client] This is only available in development branch.";
--				Presist = false;
--				MessageColor=Color3.fromRGB(255, 69, 69);
--			})
--		end
--	else
--		ChatRoomInterface:NewMessage(room, {
--			Message = "[Client] configId (".. configId ..") does not exist.";
--			Presist = false;
--			MessageColor=Color3.fromRGB(255, 69, 69);
--		})
--	end
--end

ClientCommands["console"] = function(channelId, args)
	local success, developerConsoleVisible = pcall(function() return StarterGui:GetCore("DevConsoleVisible") end)
	if success then
		local success, err = pcall(function() StarterGui:SetCore("DevConsoleVisible", not developerConsoleVisible) end)
		if not success and err then
			print("Error making developer console visible: " ..err);
		end
	end
end

ClientCommands["printloadtimes"] = function(channelId, args)
	Debugger.PrintLoadTimes();
end


ClientCommands["reloadgui"] = function(channelId, args)
	Debugger:Warn("Reloading UserInterface");
	shared.ReloadGui();
end

ClientCommands["unixtime"] = function(channelId, args)
	args = {};
	table.insert(args, tostring(DateTime.now().UnixTimestampMillis));
	
	return args;
	--local speakerRoom = ChatRoomInterface:GetRoom(channelId);
	--ChatRoomInterface:NewMessage(speakerRoom, {
	--	Message = "Client Unix time: ".. DateTime.now().UnixTimestampMillis;
	--	Presist = false;
	--	MessageColor=Color3.fromRGB(90, 255, 208);
	--})
end

ClientCommands["dobug"] = function(channelId, args)
	spawn(function()
		print(a+0);
	end)
end

inputBox.FocusLost:Connect(function(enterPressed, inputThatCausedFocusLoss)
	if enterPressed then
		matchIndexTab = nil;
		oldChatIndex = nil;
		
		
		
		if shiftKeyDown then
			--inputBox.Text = inputBox.Text.."\n";
			toggleChat(true);
		else
			local submit = true;
			
			local text = modGlobalVars.CleanTextInput(inputBox.Text);
			
			local function addToChatCache()
				for a=#oldChatCache, 1, -1 do
					if oldChatCache[a] == text then
						table.remove(oldChatCache, a);
					end
				end
				table.insert(oldChatCache, text);
			end
			
			local activeChannel = ChatRoomInterface.Channels[ChatRoomInterface.ActiveChannel];
			if text:sub(1, 1) == "/" then

				local cmd, args = CommandHandler.ProcessMessage(text);
				local cmdKey = cmd:sub(2, #cmd);
				if ClientCommands[cmdKey] then
					args = ClientCommands[cmdKey](activeChannel.Id, args);
					if args and #args > 0 then
						text = cmd.." "..table.concat(args, " ");
						
					end
				end
			end
			inputBox.Text = "";
			
			if submit == true then
				local testText = text:gsub(" ", ""):gsub(string.byte(32), ""):gsub("[\r\n]", "");
				if #testText > 0 and #text < 200 then
					addToChatCache();
					
					task.spawn(function()
						local channelId = activeChannel.Id;

						local room = ChatRoomInterface:GetRoom(channelId);
						room:SwitchWindow();
						
						remoteSubmitMessage:InvokeServer(channelId, text, nil, {
							Dm=room.Dm;
						});
					end)
				end;
			end
			toggleChat(false);
		end
	end
end)


inputBox:GetPropertyChangedSignal("Text"):Connect(inputBoxChange)

UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
	if UserInputService.TouchEnabled then
		if inputObject.UserInputType == Enum.UserInputType.Touch and mainChannelsFrame.Visible and not gameProcessed then
			toggleChat(false);
		end
	end
	if inputObject.KeyCode == Enum.KeyCode.LeftShift then
		shiftKeyDown = true;
	end
	
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		if not gameProcessed then
			toggleChat(false);
		end
	end

	if inputObject.KeyCode == Enum.KeyCode.Escape then toggleChat(false) end;
	if inputBox:IsFocused() then
		
		if inputObject.KeyCode == Enum.KeyCode.Tab then
			if #cmdMatchs > 0 then
				RunService.Heartbeat:Wait();
				
				if matchIndexTab == nil then
					matchIndexTab = 1;
				end
				
				for _, obj in pairs(cmdFrame:GetChildren()) do
					if obj:IsA("TextLabel") then
						if obj.Name == cmdMatchs[matchIndexTab] then
							obj.TextColor3 = Color3.fromRGB(135, 167, 255);
						else
							obj.TextColor3 = Color3.fromRGB(255, 255, 255);
						end
					end
				end
				
				inputBox.Text = "/"..tostring(cmdMatchs[matchIndexTab]);
				inputBox.CursorPosition = #inputBox.Text+1
				matchIndexTab = matchIndexTab +1;
				if matchIndexTab > #cmdMatchs then
					matchIndexTab =1;
				end
				
			else
				inputBox.Text = lastInput;
				tabChat();
			end
			
		elseif inputObject.KeyCode == Enum.KeyCode.Up then
			if #oldChatCache > 0 then
				RunService.Heartbeat:Wait();
				
				if oldChatIndex == nil then
					oldChatIndex = #oldChatCache;
				end
				
				inputBox.Text = oldChatCache[oldChatIndex];
				inputBox.CursorPosition = #inputBox.Text+1
				oldChatIndex = oldChatIndex -1;
				if oldChatIndex <= 0 then
					oldChatIndex = #oldChatCache;
				end
			end
			
		elseif inputObject.KeyCode == Enum.KeyCode.Down then
			if #oldChatCache > 0 then
				RunService.Heartbeat:Wait();
				
				if oldChatIndex == nil then
					oldChatIndex = 1;
				end
				
				inputBox.Text = oldChatCache[oldChatIndex];
				inputBox.CursorPosition = #inputBox.Text+1
				oldChatIndex = oldChatIndex +1;
				if oldChatIndex > #oldChatCache then
					oldChatIndex =1;
				end
			end
			
		else
			if charactersEnums[inputObject.KeyCode] 
				or inputObject.KeyCode == Enum.KeyCode.Space
				or inputObject.KeyCode == Enum.KeyCode.Escape
				or inputObject.KeyCode == Enum.KeyCode.Backspace then
				matchIndexTab = nil;
				oldChatIndex = nil;
			end
		end
	else
		RunService.Heartbeat:Wait();
			
		if inputObject.KeyCode == Enum.KeyCode.Return 
			or inputObject.KeyCode == Enum.KeyCode.Slash 
			or inputObject.KeyCode == Enum.SpecialKey.ChatHotkey then
			
			if not gameProcessed then
				toggleChat();
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(inputObject, gameProcessed)
	if inputObject.KeyCode == Enum.KeyCode.LeftShift then
		shiftKeyDown = false;
	end
end)

onChannelButtonsChange();

shared.ChatRoomInterface = ChatRoomInterface;
shared.ClientCommands = ClientCommands;