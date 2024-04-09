--== Configuration;
local streetviewCFrame = CFrame.new(420.549286, 64.1897659, 203.84285, 0.516148329, 0.0607130677, 0.854344785, -0, 0.997484565, -0.0708851367, -0.856499255, 0.0365872458, 0.514849961);
local streetviewFocus = CFrame.new(418.840607, 64.3315353, 202.813156, 1, 0, 0, 0, 1, 0, 0, 0, 1);

local roomviewCFrame = CFrame.new(448.777557, 61.4614372, 279.636963, -0.57750994, -0.2146402, 0.787662268, 7.4505806e-09, 0.964818716, 0.26291585, -0.81638366, 0.151836514, -0.557192445);
local roomviewFocus = CFrame.new(447.202209, 60.9355965, 280.751373, 1, 0, 0, 0, 1, 0, 0, 0, 1);
				
local blurMax = 12;
local blurMin = 10;

local MenuButtons = {
	MainCampaign={Order=2; Enabled=true};
	MainFriends={Order=1; Enabled=true};
	MainUpdates={Order=3; Enabled=true};
	MainCredits={Order=25; Enabled=true};
	MainAppearance={Order=10; Enabled=false};
	MainSettings={Order=99; Enabled=false};
};
--== Variables;
local HttpService = game:GetService("HttpService");
local RunService = game:GetService("RunService");
local SoundService = game:GetService("SoundService");
local ContentProvider = game:GetService("ContentProvider");
local TweenService = game:GetService("TweenService");
local TeleportService = game:GetService('TeleportService');
local ReplicatedFirst = game.ReplicatedFirst;
local StarterGui = game.StarterGui;

local modAudio;
local modBranchConfigs = require(game.ReplicatedStorage:WaitForChild("Library", 60):WaitForChild("BranchConfigurations", 60));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables", 60));
local branchColor = modBranchConfigs.BranchColor
if not modBranchConfigs.IsWorld("MainMenu") then return end;

local player = game.Players.LocalPlayer;
local playerGui = player:WaitForChild("PlayerGui");
local modData = require(player:WaitForChild("DataModule"));

local camera = workspace.CurrentCamera;
local camCFrame = CFrame.new(); --streetviewCFrame;
local camFocus = CFrame.new();--streetviewFocus;

local remotes;
local loadLabelConnection;

local cameraBlur;
local blurRate = 0.44;
local blurSize = blurMin;
local blurTick = tick();

local random = Random.new();

local menuInterfaceTemplate = script:WaitForChild("MenuInterface"); menuInterfaceTemplate.Enabled = true;
local menuIndex=0;
local modGuiTween;
	
local menuTheme = script:WaitForChild("MenuTheme");
local resetBindCallback;

local localCharacterClone;
local characterClone;

local buttonDebounce = false;
local connections = {};
local playerScripts = player.PlayerScripts;

--== Script;
for _, c in pairs(menuInterfaceTemplate:GetDescendants()) do c.Parent:WaitForChild(c.Name); end;
ReplicatedFirst:RemoveDefaultLoadingScreen();
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false);
playerGui:SetTopbarTransparency(1);

spawn(function()
	local s, e = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true);
		local chatFrame = playerGui:WaitForChild("Chat", 600):WaitForChild("Frame");
		local chatInterfaceScreenGui = game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("ChatInterface");
		local modChatInterface = require(chatInterfaceScreenGui);
		modChatInterface.Initialize(chatFrame);
	end);
	if not s then warn("ClientMainMenu>>  ", e) end;
end);

function ResetMenu() -- max reentry logged
	warn("ClientMainMenu>>  ", "ResetMenu()");
	RunService:UnbindFromRenderStep("FirstRun");
	if script.Parent.Name == "PlayerGui" then script.Parent = game.ReplicatedFirst end;
	local uiChildren = playerGui:GetChildren();
	for a=1, #uiChildren do
		if uiChildren[a].Name ~= "Chat" and not uiChildren[a]:IsA("LocalScript") then 
			uiChildren[a]:Destroy();
		end
	end
	initialize();
end

function SetCamera(cframe, focus)
	camCFrame = cframe;
	camFocus = focus;
end

function playerClickSound()
	if modAudio == nil then modAudio = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("Audio")); end
	if modAudio then
		modAudio.Play("ButtonSound", nil, nil, false);
	end
end

function menu(menuInterface)
	local thisMenuIndex = menuIndex;
	local mainFrame = menuInterface:WaitForChild("MenuFrame");
	if mainFrame == nil then warn("Menu>> Mainframe does not exist.") return end;
	
	local mainDescendants = mainFrame:GetDescendants(); --MainFrame
	
	local squadInterface = menuInterface:WaitForChild("SquadMenu");
	modGuiTween.FadeTween(squadInterface, modGuiTween.FadeDirection.Out, TweenInfo.new(0.1));
	modGuiTween.FadeTween(menuInterface.AlertFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.1));
	
	for a=1, #connections do
		if connections[a].Connected then
			connections[a]:Disconnect();
		end
	end
	connections = {};
	
	local warningCloseButton = menuInterface:WaitForChild("WarningFrame"):WaitForChild("WarningCloseButton");
	warningCloseButton.MouseButton1Click:Connect(function()
		menuInterface.WarningFrame.Visible = false;
		playerClickSound();
	end);
	
	local remotePromptWarning = remotes.Interface.PromptWarning;
	remotePromptWarning.OnClientEvent:Connect(function(message, fadeMenuIn)
		warningCloseButton.Parent.Label.Text = message;
		menuInterface.WarningFrame.Visible = true;
		
		if fadeMenuIn == true then
			menuInterface.MenuFrame.MainFrame.Visible = true;
			modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
		end
	end)
	
	local friendsButtonTemplate = script:WaitForChild("friendButton");
	local joinFriendsFrame = menuInterface:WaitForChild("JoinFriendFrame");
	local soloButton = joinFriendsFrame:WaitForChild("soloButton");
	local enteredCampaign = false;
	local inGameFriends = {};
	local function updateJoinFriendsMenu()
		--print(game:GetService("HttpService"):JSONEncode(inGameFriends))
		for a=1, #inGameFriends do
			local friendData = inGameFriends[a];
			local button = joinFriendsFrame.listFrame.list:FindFirstChild(friendData.Name);
			if button == nil then
				button = friendsButtonTemplate:Clone();
				button.Name = friendData.Name;
				button.Parent = joinFriendsFrame.listFrame.list;
				button.Visible = true;
				button.MouseButton1Click:Connect(function()
					playerClickSound();
					menuInterface.LoadLabel.Text = "Joining "..friendData.Name.."...";
					remotes.MainMenu.EnterCampaign:FireServer(friendData.Name);
					joinFriendsFrame.Visible = false;
				end)
			end
			local avatarLabel = button:WaitForChild("AvatarLabel");
			local nameLabel = button:WaitForChild("nameLabel");
			local worldLabel = button:WaitForChild("worldLabel");
			avatarLabel.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..friendData.UserId.."&width=420&height=420&format=png";
			nameLabel.Text = friendData.Name;
			worldLabel.Text = modBranchConfigs.GetWorldDisplayName(friendData.WorldName) or friendData.WorldName;
			
			joinFriendsFrame.listFrame.list.CanvasSize = UDim2.new(0, 0, 0, joinFriendsFrame.listFrame.list.UIListLayout.AbsoluteContentSize.Y);
		end
	end
	soloButton.MouseButton1Click:Connect(function()
		playerClickSound();
		menuInterface.LoadLabel.Text = "Resuming last session...";
		joinFriendsFrame.Visible = false;
		remotes.MainMenu.EnterCampaign:FireServer("/solo");
	end)
--	remotes.MainMenu.EnterCampaign.OnClientEvent:Connect(function(friends)
--		if menuInterface.Parent == nil then return end;
--		inGameFriends = friends;
--		updateJoinFriendsMenu();
--		if #inGameFriends > 0 and enteredCampaign then
--			joinFriendsFrame.Visible = true;
--			menuInterface.LoadLabel.Text = "";
--		else
--			joinFriendsFrame.Visible = false;
--		end
--	end)
	
	table.insert(connections, TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
		warningCloseButton.Parent.Visible = true;
		warningCloseButton.Parent.Label.Text = "Error: "..errorMessage;
		modGuiTween.FadeTween(menuInterface.LoadLabel, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
		wait(0.5);
		menuInterface.MenuFrame.MainFrame.Visible = true;
		modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
		buttonDebounce = false;
	end));
	
	for a=1, #mainDescendants do
		if mainDescendants[a]:IsA("ImageLabel") or mainDescendants[a]:IsA("ImageButton") then
			mainDescendants[a].ImageTransparency = 1;
		elseif mainDescendants[a]:IsA("TextLabel") then
			mainDescendants[a].TextTransparency = 1;
			mainDescendants[a].TextStrokeTransparency = 1;
		elseif mainDescendants[a]:FindFirstChild("AvatarLabel") then
			mainDescendants[a].BackgroundTransparency = 0;
		end
	end
--	spawn(function()
--		repeat until menuInterface.SquadReady.Value or not wait(0.1);
--		--squadInterface.Visible = true;
--		--modGuiTween.FadeTween(squadInterface, modGuiTween.FadeDirection.In, TweenInfo.new(1));
--	end)
	menuInterface.MenuFrame.Visible = true;
	menuInterface:WaitForChild("FadeFrame");
	
	local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
	
	local allImageLabelButtons = {};
	for a=1, #mainDescendants do
		
		if mainDescendants[a]:IsA("ImageLabel") or mainDescendants[a]:IsA("ImageButton") then
			if mainDescendants[a].Name ~= "FriendFrame" then
				TweenService:Create(mainDescendants[a], TweenInfo.new(2), {ImageTransparency=0;}):Play();
			end
		elseif mainDescendants[a]:IsA("TextLabel") then
			TweenService:Create(mainDescendants[a], TweenInfo.new(2), {TextTransparency=0; TextStrokeTransparency=0.7}):Play();
		elseif mainDescendants[a]:FindFirstChild("AvatarLabel") then
			TweenService:Create(mainDescendants[a], TweenInfo.new(2), {BackgroundTransparency=0.4}):Play();
		end
		
		if mainDescendants[a].Name == "gameVersionLabel" then
			mainDescendants[a].Text = "Version: "..modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild;
		end
		
		if mainDescendants[a]:IsA("ImageButton") and mainDescendants[a].Name ~= "FriendFrame" then
			local defaultColor = mainDescendants[a].ImageColor3;
			mainDescendants[a].MouseEnter:Connect(function()
				for b=1, #allImageLabelButtons do
					if allImageLabelButtons[b].Button ~= nil then
						allImageLabelButtons[b].ResetColor();
					end
				end
				mainDescendants[a].ImageColor3 = Color3.new(branchColor.r*0.75, branchColor.g*0.75, branchColor.b*0.75);
			end)
			mainDescendants[a].MouseLeave:Connect(function()
				mainDescendants[a].ImageColor3 = defaultColor;
			end)
			local scopeButton = mainDescendants[a];
			table.insert(allImageLabelButtons, {Button=mainDescendants[a]; ResetColor=function() scopeButton.ImageColor3 = defaultColor; end});
			
			local function resetButtons()
				for a=1, #mainDescendants do
					if mainDescendants[a]:IsA("ImageButton") then
						mainDescendants[a].ImageColor3 = defaultColor;
					end
				end
			end
			
			local buttonName = mainDescendants[a].Name;
			if MenuButtons[buttonName] then
				mainDescendants[a].LayoutOrder = MenuButtons[buttonName].Order;
				mainDescendants[a].Visible = MenuButtons[buttonName].Enabled;
			end
			if buttonName == "MainCampaign" then
				local function onIsGameOnlineUpdate()
					pcall(function()
						mainDescendants[a]:WaitForChild("MaintenanceLabel").Visible = workspace:GetAttribute("IsGameOnline") == false;
					end)
				end
				workspace:GetAttributeChangedSignal("IsGameOnline"):Connect(onIsGameOnlineUpdate);
				onIsGameOnlineUpdate();
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					menuInterface.LoadLabel.Text = "Searching for server...";
					wait(0.5);
					modGuiTween.FadeTween(menuInterface.LoadLabel, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					
					local isUpdatingTag = game.ReplicatedStorage:FindFirstChild("ServerIsUpdating");
					
					if isUpdatingTag == nil or isUpdatingTag.Value == false then
						remotes.MainMenu.EnterCampaign:FireServer("/solo");
						enteredCampaign = true;
					else
						-- Servers updating warning
						warningCloseButton.Parent.Visible = true;
						warningCloseButton.Parent.Label.Text = "Sorry, our servers are currently updating, please wait a few minutes..";
						modGuiTween.FadeTween(menuInterface.LoadLabel, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
						wait(0.5);
						menuInterface.MenuFrame.MainFrame.Visible = true;
						modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
						buttonDebounce = false;
						--
					end
					
					buttonDebounce = false;
					resetButtons();
				end);
			elseif buttonName == "MainPlay" then
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					menuInterface.LoadLabel.Text = "Loading...";
					wait(0.5);
					modGuiTween.FadeTween(menuInterface.LoadLabel, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					remotes.MainMenu.EnterCampaign:FireServer();
					menuInterface.MenuFrame.MainFrame.Visible = false;
					menuInterface.MenuFrame.PlayFrame.Visible = true;
					modGuiTween.FadeTween(menuInterface.MenuFrame.PlayFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					wait(0.1);
					buttonDebounce = false;
					resetButtons();
				end);
			elseif buttonName == "MainAppearance" then
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					spawn(loadAvatar);
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					menuInterface.FadeFrame.Visible = true;
					modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					modGuiTween.FadeTween(menuInterface.FadeFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48), {BackgroundTransparency=0;});
					modGuiTween.FadeTween(menuInterface.SquadMenu, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					wait(0.5);
					menuInterface.MenuFrame.MainFrame.Visible = false;
					menuInterface.SquadMenu.Visible = false;
					SetCamera(roomviewCFrame, roomviewFocus);
					cameraBlur.Enabled = false;
					menuInterface.MenuFrame.AppearanceFrame.Visible = true;
					modGuiTween.FadeTween(menuInterface.MenuFrame.AppearanceFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					modGuiTween.FadeTween(menuInterface.FadeFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					wait(0.1);
					buttonDebounce = false;
					resetButtons();
				end);
			elseif buttonName == "MainFriends" then
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					
					--local saves = modData.Profile and modData.Profile.Saves and #modData.Profile.Saves or 0;
					local mission1 = modData:GetMission(1);
					if mission1 == nil or mission1.Type ~= 3 then
						warningCloseButton.Parent.Visible = true;
						warningCloseButton.Parent.Label.Text = "Sorry, you can't join a friend until you started campaign.";
		
					else
						modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
						wait(0.5);
						menuInterface.MenuFrame.MainFrame.Visible = false;
						menuInterface.MenuFrame.FriendsFrame.Visible = true;
						modGuiTween.FadeTween(menuInterface.MenuFrame.FriendsFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
						wait(0.1);
						
					end
					buttonDebounce = false;
					resetButtons();
				end);
			elseif buttonName == "MainUpdates" then
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					--modGuiTween.FadeTween(menuInterface.SquadMenu, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					wait(0.5);
					menuInterface.MenuFrame.MainFrame.Visible = false;
					menuInterface.MenuFrame.UpdatesFrame.Visible = true;
					menuInterface.SquadMenu.Visible = false;
					modGuiTween.FadeTween(menuInterface.MenuFrame.UpdatesFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					wait(0.1);
					buttonDebounce = false;
					resetButtons();
				end);
			elseif buttonName == "MainSettings" then
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					modGuiTween.FadeTween(menuInterface.SquadMenu, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					wait(0.5);
					menuInterface.MenuFrame.MainFrame.Visible = false;
					menuInterface.SquadMenu.Visible = false;
					menuInterface.MenuFrame.SettingsFrame.Visible = true;
					modGuiTween.FadeTween(menuInterface.MenuFrame.SettingsFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					wait(0.1);
					buttonDebounce = false;
					resetButtons();
				end);
			elseif buttonName == "MainCredits" then
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					modGuiTween.FadeTween(menuInterface.SquadMenu, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					wait(0.5);
					menuInterface.MenuFrame.MainFrame.Visible = false;
					menuInterface.SquadMenu.Visible = false;
					menuInterface.MenuFrame.CreditsFrame.Visible = true;
					modGuiTween.FadeTween(menuInterface.MenuFrame.CreditsFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					wait(0.1);
					buttonDebounce = false;
					resetButtons();
				end);
			elseif buttonName == "PlayBack" then
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					modGuiTween.FadeTween(menuInterface.MenuFrame.PlayFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					wait(0.5);
					menuInterface.MenuFrame.PlayFrame.Visible = false;
					menuInterface.MenuFrame.MainFrame.Visible = true;
					modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					wait(0.1);
					buttonDebounce = false;
					resetButtons();
				end);
			elseif buttonName == "AppearanceBack" then
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					modGuiTween.FadeTween(menuInterface.MenuFrame.AppearanceFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					modGuiTween.FadeTween(menuInterface.FadeFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					wait(0.5);
					menuInterface.MenuFrame.AppearanceFrame.Visible = false;
					SetCamera(streetviewCFrame, streetviewFocus);
					cameraBlur.Enabled = true;
					menuInterface.MenuFrame.MainFrame.Visible = true;
					menuInterface.SquadMenu.Visible = true;
					modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					modGuiTween.FadeTween(menuInterface.FadeFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					modGuiTween.FadeTween(menuInterface.SquadMenu, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					wait(0.1);
					buttonDebounce = false;
					resetButtons();
				end);
			elseif buttonName == "FriendsBack" then
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					modGuiTween.FadeTween(menuInterface.MenuFrame.FriendsFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					wait(0.5);
					menuInterface.MenuFrame.FriendsFrame.Visible = false;
					menuInterface.MenuFrame.MainFrame.Visible = true;
					modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					wait(0.1);
					buttonDebounce = false;
					resetButtons();
				end);
			elseif buttonName == "UpdatesBack" then
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					modGuiTween.FadeTween(menuInterface.MenuFrame.UpdatesFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					wait(0.5);
					--menuInterface.MenuFrame.UpdatesFrame.UpdatesScreen.slotsBackground.LogsFrame.Visible = false;
					--menuInterface.MenuFrame.UpdatesFrame.UpdatesScreen.slotsBackground.List.Visible = true;
					menuInterface.MenuFrame.UpdatesFrame.Visible = false;
					menuInterface.MenuFrame.MainFrame.Visible = true;
					--menuInterface.SquadMenu.Visible = true;
					modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					--modGuiTween.FadeTween(menuInterface.SquadMenu, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					wait(0.1);
					buttonDebounce = false;
					resetButtons();
				end);
			elseif buttonName == "SettingsBack" then
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					modGuiTween.FadeTween(menuInterface.MenuFrame.SettingsFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					wait(0.5);
					menuInterface.MenuFrame.SettingsFrame.Visible = false;
					menuInterface.MenuFrame.MainFrame.Visible = true;
					menuInterface.SquadMenu.Visible = true;
					modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					modGuiTween.FadeTween(menuInterface.SquadMenu, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					wait(0.1);
					buttonDebounce = false;
					resetButtons();
				end);
			elseif buttonName == "CreditsBack" then
				mainDescendants[a].MouseButton1Click:Connect(function()
					if buttonDebounce then return end;
					buttonDebounce = true;
					playerClickSound();
					mainDescendants[a].ImageColor3 = branchColor;
					modGuiTween.FadeTween(menuInterface.MenuFrame.CreditsFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					wait(0.5);
					menuInterface.MenuFrame.CreditsFrame.Visible = false;
					menuInterface.MenuFrame.MainFrame.Visible = true;
					menuInterface.SquadMenu.Visible = true;
					modGuiTween.FadeTween(menuInterface.MenuFrame.MainFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					modGuiTween.FadeTween(menuInterface.SquadMenu, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					wait(0.1);
					buttonDebounce = false;
					resetButtons();
				end);
			end
		end
	end
end

function loadAvatar()
	local modCustomizeAppearance = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("CustomizeAppearance"));
	local waitPlayerAppearanceTick = tick();
	local playerAppearance;
	repeat
		playerAppearance = player:FindFirstChild("Appearance");
		if tick()-waitPlayerAppearanceTick >= 5 then
			waitPlayerAppearanceTick = tick();
			warn("LoadAvatar>>  Waiting for appearance...");
		end;
	until playerAppearance ~= nil or not wait(0.1); 
	local characterApperance = playerAppearance:GetChildren();
	
	if characterClone ~= nil then
		characterClone:Destroy();
	end
	characterClone = localCharacterClone:Clone();
	local avatarHumanoid = characterClone:WaitForChild("Humanoid");
	local avatarAnimationsDir = script:WaitForChild("Animations");
	
	avatarHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
	
	for a=1, #characterApperance do
		local clonedAppearance = characterApperance[a]:Clone();
		if clonedAppearance.Name == "face" then
			clonedAppearance.Parent = characterClone:WaitForChild("Head");
		else
			if clonedAppearance:IsA("Accessory") or clonedAppearance:IsA("Folder") then
				modCustomizeAppearance.AttachAccessory(characterClone, characterApperance[a]:Clone());
			else
				clonedAppearance.Parent = characterClone;
			end
		end
	end
	characterClone.Parent = workspace;
	
	local avatarAnimations = avatarAnimationsDir:GetChildren();
	local animations = {};
	for a=1, #avatarAnimations do
		animations[avatarAnimations[a].Name] = avatarHumanoid:LoadAnimation(avatarAnimations[a]);
	end
	animations.Idle:Play();
	spawn(function()
		local random = Random.new();
		while wait(random:NextNumber(20, 40)) do
			if random:NextInteger(1, 10) == 1 then
				animations.Wave.Looped = false;
				animations.Wave:Play();
			else
				animations.Idle2.Looped = false;
				animations.Idle2:Play();
			end
		end
	end)
end

-- !outline: function initialize()
function initialize()
	local isLoading = true;
	local preloadTable = {menuTheme};
	local menuInterface = menuInterfaceTemplate:Clone();
	menuInterface.Parent = playerGui;
	
	remotes = game.ReplicatedStorage:WaitForChild("Remotes");
	local bindReset = script:WaitForChild("ResetCallback");
	
	repeat until pcall(function() StarterGui:SetCore("ResetButtonCallback", bindReset) end) or not RunService.Heartbeat:Wait();
	if resetBindCallback == nil then
		resetBindCallback = bindReset.Event:Connect(ResetMenu)
	end;
	if menuInterface.Parent == nil then return end;
	delay(15, function() if isLoading then ResetMenu() return end; end);
	
	local sceneModel = workspace:WaitForChild("Environment"):WaitForChild("Scene");
	
	local focusPart;
	local spinTick = tick()+3;
	local lastBlur = 20;
	RunService:BindToRenderStep("FirstRun", Enum.RenderPriority.Camera.Value-1, function()
		if sceneModel.PrimaryPart == nil then return end;
		
		local camDistance = sceneModel:GetAttribute("CameraDistance") or 50;
		local camAngle = sceneModel:GetAttribute("CameraAngle") or -15;
		
		if focusPart == nil then
			focusPart = sceneModel:FindFirstChild("FocusPart");
		end
		
		camera.FieldOfView = sceneModel:GetAttribute("CustomFov") or 45;
		local spin = tick()-spinTick;
		camera.CFrame = ((focusPart and focusPart.CFrame) or CFrame.new(0, 6, 0)) * CFrame.Angles(0, spin > 0 and spin/8 or 0, 0) 
			* CFrame.Angles(math.rad(camAngle), 0, 0) * CFrame.new(0, 0, camDistance);
		camera.Focus = camera.CFrame;
		
		cameraBlur = camera:FindFirstChild("Blur");
		if cameraBlur == nil then
			cameraBlur = Instance.new("BlurEffect");
		end
		cameraBlur.Parent = camera;
		cameraBlur.Size = 4;--lastBlur*(1-0.1) + (1-math.clamp(menuTheme.PlaybackLoudness/400, 0, 1))*10 *0.1;
		lastBlur = cameraBlur.Size;
	end)
	
	menuIndex = menuIndex +1;
	
	modGuiTween = require(game.StarterGui:WaitForChild("GuiObjectTween"));
	
	local menuDescendants = menuInterface:GetDescendants();
	for a=1, #menuDescendants do
		menuDescendants[a].Parent:WaitForChild(menuDescendants[a].Name);
		if menuDescendants[a]:IsA("ImageLabel") and menuDescendants[a].Name == "MenuTitleLogo" then
			menuDescendants[a].ImageColor3 = branchColor;
			table.insert(preloadTable, menuDescendants[a]);
		elseif menuDescendants[a]:IsA("TextLabel") and menuDescendants[a].Name == "LoadLabel" then
			menuDescendants[a].TextColor3 = branchColor;
			table.insert(preloadTable, menuDescendants[a]);
		elseif menuDescendants[a]:IsA("LocalScript") then
			menuDescendants[a].Disabled = false;
		end
	end
	
	menuInterface:WaitForChild("FadeFrame").BackgroundTransparency = 1;
	menuInterface.FadeFrame.Visible = true;
	menuInterface:WaitForChild("MenuFrame").Visible = false;
	modGuiTween.FadeTween(menuInterface:WaitForChild("FadeFrame"), modGuiTween.FadeDirection.Out, TweenInfo.new(2));
	
	for _, c in pairs(camera:GetChildren()) do
		if c.Name == menuTheme.Name then
			c:Destroy();
		end
	end
	local newMenuTheme = menuTheme:Clone();
	newMenuTheme.Parent = camera;
	--spawn(function() ContentProvider:PreloadAsync(preloadTable); end);
	--SetCamera(streetviewCFrame, streetviewFocus);
	
	newMenuTheme.Volume = 0;
	newMenuTheme:Play();
	
	TweenService:Create(newMenuTheme, TweenInfo.new(5), {Volume=0.75;}):Play();
	local sceneInterface;
	if sceneInterface == nil then
		sceneInterface = script:WaitForChild("SceneInterface"):Clone();
		sceneInterface.Parent = playerGui
	end;
	local blindsFrame = sceneInterface:WaitForChild("GameBlinds");
	TweenService:Create(blindsFrame, TweenInfo.new(3), {BackgroundTransparency = 1;}):Play();
	
	local loadingBarFrame = menuInterface:WaitForChild("LoadingBar");
	local loadingBar = loadingBarFrame:WaitForChild("Bar");
	local titleLogoImage = menuInterface:WaitForChild("TitleLogo");
	local titleGradient = titleLogoImage:WaitForChild("UIGradient");
	local loadingLabel = menuInterface:WaitForChild("LoadLabel");
	local loadSize = ContentProvider.RequestQueueSize;
	--loadingBarFrame.Visible = true;
	titleLogoImage.Visible = true;
	loadingLabel.Visible = true;
	
	local modHints = require(script:WaitForChild("GameHints"));
	local currentLoadString = "Loading";
	local timeout=tick(); local pickStringTick = tick()-4; local updateLogTick = tick()-0.5;
	
	--loadingBar.ImageColor3 = branchColor;
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, branchColor);
		ColorSequenceKeypoint.new(1/600, Color3.new(1, 1, 1));
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1));
	})
	local rate, lastRate = 0, 0;
	
	--repeat
	--	if loadSize > 0 then
	--		local queueSize = ContentProvider.RequestQueueSize;
	--		if queueSize >= loadSize then loadSize = queueSize end;
	--		local loadrate = (queueSize/loadSize);
	--		--local opacity = titleLogoImage.ImageTransparency * (0.95) + (loadrate*0.05);
	--		titleLogoImage.ImageTransparency = 0;
	--		local timeoutRate = math.clamp(tick()-timeout, 0, 10)/10;
	--		rate = math.ceil((1-loadrate)*100);
	--		rate = timeoutRate > rate and timeoutRate or rate;
	--		if rate < lastRate then rate = lastRate end;
	--		TweenService:Create(titleGradient, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Offset=Vector2.new(math.clamp(1*rate, 0, 1), 0)}):Play();
	--		--loadingBar:TweenSize(UDim2.new(math.clamp(1*rate, 0, 1), 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true);
	--		if tick()-pickStringTick >= 5 then
	--			pickStringTick = tick();
	--			currentLoadString = modHints.Get();
	--		end
	--		if tick()-updateLogTick > 1 then
	--			updateLogTick = tick();
	--			print("Client>> Game loading "..(loadSize-queueSize).."/"..loadSize.."("..rate.."%)...");
	--		end
	--		lastRate = rate;
	--		loadingLabel.Text = currentLoadString;
	--	else
	--		loadingLabel.Text = currentLoadString;
	--	end
	--	RunService.RenderStepped:Wait();
	--until loadSize <= 0 or tick()-timeout > 10;
	--loadingBar:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
	
	local loadtime = 2.6;

	titleLogoImage.ImageTransparency = 0;
	loadingLabel.Position = UDim2.new(0.5, 0, 0.8, 0);
	TweenService:Create(titleGradient, TweenInfo.new(loadtime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Offset=Vector2.new(math.clamp(1*rate, 0, 1), 0)}):Play();
	
	loadingLabel.Text = modHints.Get();
	TweenService:Create(titleGradient, TweenInfo.new(loadtime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Offset=Vector2.new(1, 0)}):Play();
	task.wait(loadtime);
	loadingLabel.Position = UDim2.new(0.5, 0, 0.5, 0);
	titleLogoImage.ImageTransparency = 0;
	loadingLabel.Text = "";
	isLoading = false;
	
	localCharacterClone = game.StarterPlayer:WaitForChild("StarterCharacter", 20);
	spawn(loadAvatar);
	print("Client>> Game successfully loaded.");
	wait(0.5);
	modGuiTween.FadeTween(loadingBarFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(1));
	modGuiTween.FadeTween(titleLogoImage, modGuiTween.FadeDirection.Out, TweenInfo.new(1));
	modGuiTween.FadeTween(loadingLabel, modGuiTween.FadeDirection.Out, TweenInfo.new(1));
	wait(1);
	menu(menuInterface);
	
	local remoteSetLoadLabel = remotes.MainMenu.SetLoadLabel;
	if loadLabelConnection then loadLabelConnection:Disconnect() end;
	loadLabelConnection = remoteSetLoadLabel.OnClientEvent:Connect(function(text)
		print("Client>>",text);
		loadingLabel.Text = text;
	end)
end

player.Chatted:Connect(function(message)
	if  message == "/settings" then
		MenuButtons.MainSettings.Enabled = not MenuButtons.MainSettings.Enabled;
	end
end)

game.Lighting.FogEnd = 250;
game.Lighting.FogStart = 0;
ResetMenu();
print("ClientMenu>>  Client interface initialized.");