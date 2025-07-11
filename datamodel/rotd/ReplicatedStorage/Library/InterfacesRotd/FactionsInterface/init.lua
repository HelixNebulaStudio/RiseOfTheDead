local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local TextService = game:GetService("TextService");
local UserInputService = game:GetService("UserInputService");

local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modLeaderboardService = shared.require(game.ReplicatedStorage.Library.LeaderboardService);
local modMissionLibrary = shared.require(game.ReplicatedStorage.Library.MissionLibrary);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local modSafehomesLibrary = shared.require(game.ReplicatedStorage.Library.SafehomesLibrary);

local modRadialImage = shared.require(game.ReplicatedStorage.Library.UI.RadialImage);
local modLeaderboardInterface = shared.require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);
local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modRichFormatter = shared.require(game.ReplicatedStorage.Library.UI.RichFormatter);
local modGuiObjectPlus = shared.require(game.ReplicatedStorage.Library.UI.GuiObjectPlus);
local modDropdownList = shared.require(game.ReplicatedStorage.Library.UI.DropdownList);


local RESOURCE_KEYS = {
	{Key="Food"; Value=0; Icon="rbxassetid://4466508636";};
	{Key="Ammo"; Value=0; Icon="rbxassetid://10577724784";};
	{Key="Material"; Value=0; Icon="rbxassetid://1551792125";};
	{Key="Power"; Value=0; Icon="rbxassetid://3592076927";};
	{Key="Comfort"; Value=0; Icon="rbxassetid://6734447412";};
}

local RESOURCE_RADIAL_CONFIG = '{"version":1,"size":128,"count":128,"columns":8,"rows":8,"images":["rbxassetid://10577973797","rbxassetid://10577974058"]}';
local TIMER_RADIAL_CONFIG = '{"version":1,"size":128,"count":128,"columns":8,"rows":8,"images":["rbxassetid://10606346824","rbxassetid://10606347195"]}';

local ONE_SEC_TWEENINFO = TweenInfo.new(1);

local BAR_COLORS = {
	Green=Color3.fromRGB(27, 106, 23);
	Yellow=Color3.fromRGB(163, 143, 27);
	Red=Color3.fromRGB(118, 54, 54);
}


local interfacePackage = {
    Type = "Player";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local chatRoomInterface = shared.require(localPlayer.PlayerGui:WaitForChild("ChatInterface"):WaitForChild("ChatRoomInterface"));

    local remoteFactionService = modRemotesManager:Get("FactionService");
    local remoteChatServiceEvent = modRemotesManager:Get("ChatServiceEvent");
    local remoteLeaderboardService = modRemotesManager:Get("LeaderboardService");

    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local branchColor = modBranchConfigs.BranchColor
	local colorPickerObj = interface.ColorPicker;
	
	local windowFrame = script:WaitForChild("FactionsMenu"):Clone();
	windowFrame.Parent = interface.ScreenGui;

	local window: InterfaceWindow = interface:NewWindow("FactionsMenu", windowFrame);
	window.CompactFullscreen = true;
    interface:BindConfigKey("DisableFactionsMenu", {window});
	
	if modConfigurations.CompactInterface then
		window:SetClosePosition(UDim2.new(0.5, 0, -1, 0), UDim2.new(0.5, 0, 0, 0));
	else
		window:SetClosePosition(UDim2.new(0.5, 0, -1, 0), UDim2.new(0.5, 0, 0.1, 0));
	end
	
	modKeyBindsHandler:SetDefaultKey("KeyWindowFactionsMenu", Enum.KeyCode.O);
	local quickButton = interface:NewQuickButton("FactionsMenu", "Factions", "rbxassetid://9890634236");
	quickButton.LayoutOrder = 4;
	interface:ConnectQuickButton(quickButton, "KeyWindowFactionsMenu");

    local binds = window.Binds;
	binds.ActivePage = "";
	binds.MembersData = {};


    local frame = windowFrame:WaitForChild("MainFrame");
	local windowTitleLabel = windowFrame:WaitForChild("Title");

	local bannerFrame = frame:WaitForChild("Banner");
	local bannerSizeConstraint = bannerFrame:WaitForChild("UISizeConstraint");
	local bannerTitleLabel = bannerFrame:WaitForChild("Title");
	local bannerDescLabel = bannerFrame:WaitForChild("DescLabel");
	local bannerNavFrame = bannerFrame:WaitForChild("NavBar");
	
	local bannerGoldStats = bannerFrame:WaitForChild("GoldStats");
	local bannerGoldLabel = bannerGoldStats:WaitForChild("goldLabel");

	local bannerNavMenuButton = bannerNavFrame:WaitForChild("Menu");
	local bannerNavSettingsButton = bannerNavFrame:WaitForChild("Settings");
	local bannerNavChatButton = bannerNavFrame:WaitForChild("Chat");
	local bannerNavLeaderboardsButton = bannerNavFrame:WaitForChild("Leaderboards");

	local memberFrame = frame:WaitForChild("Members");
	local memberSizeConstraint = memberFrame:WaitForChild("UISizeConstraint");
	local memberIconLabel = memberFrame:WaitForChild("IconLabel");
	local memberCountLabel = memberFrame:WaitForChild("MembersLabel");

	local centerFrame = frame:WaitForChild("Center");
	local profileFrame = centerFrame:WaitForChild("ProfileFrame");
	local profileNavBar = profileFrame:WaitForChild("ProfileNavBar");
	local profileScrollFrame = profileFrame:WaitForChild("ScrollFrame");

	local settingsFrame = centerFrame:WaitForChild("SettingsFrame");
	local settingsNav = settingsFrame:WaitForChild("SettingsNav");
	local settingsBodyFrame = settingsFrame:WaitForChild("SettingsBody");

	local factionChatFrame = centerFrame:WaitForChild("FactionChatFrame");

	local centerMenuFrame = centerFrame:WaitForChild("MenuFrame");
	local centerResourceFrame = centerMenuFrame:WaitForChild("ResourcesFrame");
	local centerMissionsFrame = centerMenuFrame:WaitForChild("MissionsFrame");
	
	local centerHeadquartersFrame = centerMenuFrame:WaitForChild("HeadquartersFrame");
	local travelToHqButton = centerHeadquartersFrame:WaitForChild("travelHqButton");
	local hqMapThumbnail = centerHeadquartersFrame:WaitForChild("MapThumbnail");
	
	local missionContentScrollList = centerMissionsFrame:WaitForChild("ExpandPanel"):WaitForChild("Content");
	local missionNavListScrollList = centerMissionsFrame:WaitForChild("ExpandPanel"):WaitForChild("NavList");
	
	local noFactionFrame = centerFrame:WaitForChild("JoinFactionFrame");
	local noFactionInput = noFactionFrame:WaitForChild("TextInput");
	local noFactionList = noFactionFrame:WaitForChild("factionsList");
	local searchingLabel = noFactionList:WaitForChild("searchingLabel");
	local createFactionButton = noFactionList:WaitForChild("createListing"):WaitForChild("createButton");

	local templateJoinListing = script:WaitForChild("joinListing");
	local templateFactionUserFrame = script:WaitForChild("factionUserFrame");
	local templateJoinRequestUser = script:WaitForChild("joinRequestUser");
	local templateMemberSettingsListing = script:WaitForChild("memberSettingsListing");
	local templateLogLabel = script:WaitForChild("logLabel");
	local templateMissionListing = script:WaitForChild("missionListing");
	local templateMissionInfo = script:WaitForChild("missionInfo");
	local templateMembersSelectionList = script:WaitForChild("membersSelectionList");
	local templateAppearanceListing = script:WaitForChild("AppearanceListing");

	local templateResourceStatLabel = script:WaitForChild("ResourceStatLabel");

	local auditLogs = shared.require(script:WaitForChild("AuditLogFormats"));

	local factionPermissions = modGlobalVars.FactionPermissions;

	local missionMenuPage = "";
	local updateMissionPage;
	local centerFrameState;
	local viewAvailableMissionFunc;
	
	local syncActivated = false;
	local lastSync = tick()-300;
	local firstsynced = false;
	local requestedFactionChat = false;
	
	local newLeaderboard, factionChatRoom = nil, nil;
	local setRoleDropdownList;
	local selectedUser = nil;

	local roleConfigActive = "__new";
	local roleConfigInput = {
		Perm=nil;
	};
	local permButtons = {};
	
	if modConfigurations.CompactInterface then
		windowFrame.Position = UDim2.new(0.5, 0, 0.5, 0);
		windowFrame.Size = UDim2.new(1, 0, 1, 0);
		windowFrame:WaitForChild("UICorner"):Destroy();

		bannerFrame.Size = UDim2.new(0.26, 0, 1, 0);
	end

	windowFrame:WaitForChild("Title"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		window:Close();
	end)

	local function colorBoolText(text)
		text = tostring(text);
		if text:lower() == "true" then
			return '<font color="rgb(0,128,255)">'..text..'</font>';
		elseif text:lower() == "false" then
			return '<font color="rgb(255,102,102)">'..text..'</font>';
		end
		return text;
	end


	local function updatePermButtons()
		local perm = roleConfigInput.Perm or 0;
		for a=1, #permButtons do
			local button = permButtons[a];
			local roleKey = button.Name;
			button.Text = factionPermissions.Names[roleKey]..": ".. colorBoolText(factionPermissions:Test(roleKey, perm));
		end
	end

	
	local agentToolTip = modItemInterface.newItemTooltip();
	agentToolTip.Frame.Parent = windowFrame;
	game.Debris:AddItem(agentToolTip.Frame:WaitForChild("UISizeConstraint"), 0);

	local agentTooltipFrame = script.agentTooltip:Clone();
	agentTooltipFrame.Parent = agentToolTip.Frame.custom;

	function agentToolTip:SetPosition(guiObject)

		local targetPos = guiObject.AbsolutePosition;
		local targetSize = guiObject.AbsoluteSize;

		local frameSize = self.Frame.AbsoluteSize;

		local parentPos = windowFrame.AbsolutePosition;

		self.Frame.Position = UDim2.new(0, targetPos.X+(targetSize.X/2)-(frameSize.X/2)-parentPos.X, 0, targetPos.Y-frameSize.Y-parentPos.Y);
	end

	local function clearMissionPage()
		for _, obj in pairs(missionContentScrollList:GetChildren()) do
			if obj:IsA("GuiObject") then
				obj.Visible = false;
				game.Debris:AddItem(obj, 0);

			end
		end
	end

	local function shrinkMissionFrame()
		centerMissionsFrame.ExpandPanel.Visible = false;
		centerMissionsFrame.Size = UDim2.new(1, 0, 0.333, 0);

		centerMissionsFrame.PublicMissions.Size = UDim2.new(1, 0, 1, -30);
		centerHeadquartersFrame.Visible = true;
		centerResourceFrame.Visible = true;
		centerFrameState = nil;

		updateMissionPage();
	end
	
	local function sync(returnFactionObj, onComplete)
		task.spawn(function()
			local factionObj = returnFactionObj;

			if factionObj == nil then
				local syncReturn = remoteFactionService:InvokeServer("sync");
				firstsynced = true;

				if syncReturn == nil or syncReturn.Debounce then
					factionObj = modData.FactionData;
				else
					factionObj = syncReturn.FactionObj;
				end
			end

			Debugger:StudioLog("FactionData sync:", factionObj);
			modData.FactionData = factionObj;
			lastSync = tick();

			local factionData = modData.FactionData;
			if factionData then
				local memberCount = 0;
				for userId, memberData in pairs(factionData.Members) do
					memberCount = memberCount+1;
					factionData.Roles[memberData.Role or "Member"].Size = (factionData.Roles[memberData.Role or "Member"].Size or 0) +1;
				end

				factionData.MemberCount = memberCount;
				
				if factionData.Color then
					local colorHue, colorSat = Color3.fromHex(factionData.Color):ToHSV();
					local factionColor = Color3.fromHSV(colorHue, colorSat, 0.196);
					local frameColor = Color3.fromRGB(20, 20, 20);
					
					windowFrame:WaitForChild("UIGradient").Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, factionColor);
						ColorSequenceKeypoint.new(0.0999, factionColor);
						ColorSequenceKeypoint.new(0.1, frameColor);
						ColorSequenceKeypoint.new(1, frameColor);
					})
				end
				
				if requestedFactionChat == false then
					requestedFactionChat = true;
					remoteChatServiceEvent:FireServer("syncchat", `[{factionObj.Tag}]`);
				end
			end

			window:Update();
			if onComplete then
				onComplete(factionObj);
			end
		end)
	end
	
	local function setSelectedUser(userId)
		userId = tostring(userId);
		local factionData = modData.FactionData;
		if factionData == nil then return end;
		selectedUser = factionData.Members[userId];
	end

	local function clearDropdownList()
		if setRoleDropdownList then
			setRoleDropdownList:Destroy();
			setRoleDropdownList = nil;
		end
	end
	
    --MARK: OnToggle
	window.OnToggle:Connect(function(visible)
		if visible then
			binds.ActivePage = "MenuFrame";
			missionMenuPage = "";
			clearMissionPage();
			shrinkMissionFrame();

			local mission58Complete = false;
			local missionData = modData:GetMission(58);
			if missionData and missionData.Type == 3 then
				mission58Complete = true;
			end
			
			if not mission58Complete then
				binds.ActivePage = "MissionRequirementFrame";
				
			else
				task.spawn(function()
					if syncActivated then return end;
					syncActivated = true;

					while true do
						task.wait(300);
						if tick()-lastSync >= 300 then
							sync();
						end
						if not localPlayer:IsAncestorOf(windowFrame) then
							break
						end
						
					end
				end)
			end

			remoteLeaderboardService:FireServer("request", {StatKey=modLeaderboardService.FactionBoardKey});

			if newLeaderboard == nil then
				newLeaderboard = modLeaderboardInterface.new({
					StatName="Faction Score";
					SeasonlyTableKey="Seasonly".. modLeaderboardService.FactionBoardKey;
					MonthlyTableKey="Monthly".. modLeaderboardService.FactionBoardKey;
					WeeklyTableKey="Weekly".. modLeaderboardService.FactionBoardKey;
				});
				newLeaderboard.Frame.BackgroundTransparency = 1;
				newLeaderboard.Frame.Parent = centerFrame;
			end

			interface:HideAll{[window.Name]=true;};
			window:Update();

			sync();
			setSelectedUser(localPlayer.UserId);

		else

			binds.refreshPublicMissions = nil;
			binds.refreshActiveMissionInfo = nil;

			clearDropdownList();
			if factionChatRoom then
				factionChatRoom.Frame.Parent = factionChatRoom.MainChatFrame
				factionChatRoom.Frame.UIListLayout.Padding = UDim.new(0, 2);
			end


			local serverChatRoom = chatRoomInterface:GetRoom("Server");
			serverChatRoom:SetActive();
		end
	end)
	
	
	local function loadMissionDesc(descLabel, missionLib)
		local factionData = modData.FactionData or {};
		
		local descStr = missionLib.Description.."\n";
		
		local costStr;

		local factionCosts = missionLib.FactionCosts;
		for a=1, #factionCosts do
			local reqInfo = factionCosts[a];

			if costStr == nil then costStr = "\n" end;
			costStr = costStr.."    -".. (reqInfo.Value) .."% ".. (reqInfo.Id) .. " per ".. reqInfo.Per .. "\n";
		end
		
		descStr = descStr.."\n<b>Mission Costs:</b>"..costStr;

		local rewardsStr;

		local missionRewards = missionLib.FactionRewards;
		for a=1, #missionRewards do
			local rewardInfo = missionRewards[a];

			if rewardsStr == nil then rewardsStr = "\n" end;

			if rewardInfo.Type == "Resource" then
				rewardsStr = rewardsStr.."    " .. (math.sign(rewardInfo.Value) >= 0 and "+" or "-") .. (rewardInfo.Value) .."% ".. (rewardInfo.Id) .. "\n";

			elseif rewardInfo.Type == "Score" then
				rewardsStr = rewardsStr.."    + " .. (rewardInfo.Value) .." Score".. "\n";

			elseif rewardInfo.Type == "Gold" and factionData.TestGoldReward == true then
				rewardsStr = rewardsStr.."    + " .. (rewardInfo.Value) ..modRichFormatter.GoldText(" Gold").. "\n";

			end
		end

		descStr = descStr.."\n<b>Mission Rewards:</b>"..rewardsStr;
		
		if missionLib.FactionSuccessCriteria then
			descStr = descStr.."\n<b>Success Criteria:</b>";
			local steps = 0;
			if missionLib.FactionSuccessCriteria.SuccessfulAgents then
				steps = steps+1;
				descStr = descStr.."\n<b>"..steps..".</b> At least "..missionLib.FactionSuccessCriteria.SuccessfulAgents.." successful agents.";
			end
		end

		descLabel.Text = descStr;
	end
	
	updateMissionPage = function()
		local unixTime = workspace:GetServerTimeNow();

		local factionData = modData.FactionData;
		if factionData == nil then return end;

		local missionData = factionData.Missions;
		clearMissionPage();

		if missionMenuPage == "ActiveMission1" or missionMenuPage == "ActiveMission2" or missionMenuPage == "ActiveMission3" then
			local missionIndex = missionMenuPage == "ActiveMission1" and 1 or missionMenuPage == "ActiveMission2" and 2 or missionMenuPage == "ActiveMission3" and 3

			local missionInfo = missionData.Active[missionIndex];
			if missionInfo then
				local missionLib = modMissionLibrary.Get(missionInfo.Id);

				local new = templateMissionInfo:Clone();

				local titleLabel = new:WaitForChild("Title");
				titleLabel.Text = missionLib.Name;
				
				local descLabel = new:WaitForChild("Desc");
				loadMissionDesc(descLabel, missionLib);

				local activePanel = new:WaitForChild("ActivePanel");
				local completePanel = new:WaitForChild("CompletePanel");

				local function refreshPlayerListing(playersPanel, userId, listingFrameTemplate)
					local playerMissionData = missionInfo.Players[userId];
					local playerListing = playersPanel:FindFirstChild(userId);

					if playerListing == nil then
						playerListing = listingFrameTemplate:Clone();

						agentToolTip:BindHoverOver(playerListing, function()
							if not agentToolTip.Frame.Visible then return end;

							agentToolTip.CustomUpdate = function(self)
								missionData = factionData.Missions;
								missionInfo = missionData.Active[missionIndex];

								if missionInfo == nil then
									binds.refreshActiveMissionInfo = nil;
									return;
								end

								playerMissionData = missionInfo.Players[userId];

								self.Frame.Size = UDim2.new(0, 240, 0, 240);
								self.Frame.custom.Visible = true;

								local nameTag = self.Frame:WaitForChild("NameTag");
								nameTag.Text = playerListing.PlayerNameLabel.Text;

								local iconLabel = agentTooltipFrame:WaitForChild("Icon");
								iconLabel.Image = playerListing.PlayerIconLabel.Image;

								local descLabel = agentTooltipFrame.descLabel;
								local descText = "Mission Status: ";

								if playerMissionData.MissionStatus == 3 then
									descText = descText .."Complete"

								elseif playerMissionData.MissionStatus == 4 then
									descText = descText .."Failed"

								else
									descText = descText .."Active"

								end

								descLabel.Text = descText;
							end;

							agentToolTip:Update();
							agentToolTip:SetPosition(playerListing);
						end)

					end

					playerListing.Parent = playersPanel;
					playerListing.Size = UDim2.new(0, 40, 0, 40);

					local playerIcon = playerListing:WaitForChild("PlayerIconLabel");
					playerIcon.Position = UDim2.new(0, 0, 0.5, 0);

					if playerMissionData.MissionStatus == 3 then
						playerListing.LayoutOrder = 1;
						playerIcon.BackgroundColor3 = Color3.fromRGB(122, 200, 122);

					elseif playerMissionData.MissionStatus == 4 then
						playerListing.LayoutOrder = 2;
						playerIcon.BackgroundColor3 = Color3.fromRGB(200, 122, 122);

					else
						playerListing.LayoutOrder = 0;
						playerIcon.BackgroundColor3 = Color3.fromRGB(100, 100, 100);

					end

					local playerNameLabel = playerListing:WaitForChild("PlayerNameLabel");
					playerNameLabel.Visible = false;

				end

				if missionInfo.Completed or unixTime >= missionInfo.CompletionTick then
					completePanel.Visible = true;

					local claimButton = completePanel:WaitForChild("claimButton");
					claimButton.MouseButton1Click:Connect(function()
						interface:PlayButtonClick();
						claimButton.Text = "Closing Mission..";

						local packet = {
							ActiveIndex=missionIndex;
						}
						local rPacket = remoteFactionService:InvokeServer("claimfactionmission", packet);
						claimButton.Text = "Complete";

						if rPacket and rPacket.FactionObj then
							sync(rPacket.FactionObj, function(factionObj)
								missionMenuPage = "";
								updateMissionPage();
							end);
						end
					end)

					local playersPanel = completePanel:WaitForChild("PlayersPanel");

					local playersCount = 0;
					local successCount, failCount = 0, 0;
					for userId, playerMissionData in pairs(missionInfo.Players) do
						playersCount = playersCount+1;

						if playerMissionData.MissionStatus == 3 then
							successCount = successCount +1;
						end

						local listingFrameTemplate = binds.MembersData[userId] and binds.MembersData[userId].ListingFrame;
						if listingFrameTemplate == nil then continue end;
						playerMissionData.Name = binds.MembersData[userId] and binds.MembersData[userId].Name;

						refreshPlayerListing(playersPanel, userId, listingFrameTemplate);
					end
					failCount = playersCount-successCount;

					local successCriteria = missionLib.FactionSuccessCriteria;
					local reportLabel = completePanel:WaitForChild("reportLabel");
					local reportText = "";

					reportText = reportText.."<b>Status: </b>";

					local missionSuccess = false;
					if successCriteria then
						local missionResult;
						if successCriteria.SuccessfulAgents and successCount < successCriteria.SuccessfulAgents then
							missionResult = "At least ".. successCriteria.SuccessfulAgents .." agents are required to successfully completed the mission.";
						end

						if missionResult ~= nil then
							reportText = reportText.. modRichFormatter.FailText("Failed");
							reportText = reportText.."\n    • "..(missionResult or "Aborted");
						else
							reportText = reportText.. modRichFormatter.SuccessText("Successful");
							missionSuccess = true;
						end
					else
						reportText = reportText.. modRichFormatter.SuccessText("Successful");
						missionSuccess = true;
					end

					reportText = reportText.."\n\n<b>Agents: </b>".. playersCount;
					reportText = reportText.."\n    • <b>Sucessful: </b>".. successCount;
					reportText = reportText.."\n    • <b>Failed: </b>".. failCount;

					reportText = reportText.."\n\n<b>Total Costs: </b>";

					local costs = missionLib.FactionCosts;
					for a=1, #costs do
						local costType = costs[a].Type;
						local costId = costs[a].Id;
						local costValue = costs[a].Value;

						if costType == "Resource" then
							local value = -(costValue * playersCount);
							reportText = reportText.."\n    • "..costId..": ".. math.ceil(value*100)/100 .."%";
						end
					end

					reportText = reportText.."\n\n<b>Final Rewards: </b>";
					if missionSuccess then
						local rewards = missionLib.FactionRewards;
						for a=1, #rewards do
							local rewardType = rewards[a].Type;
							local rewardId = rewards[a].Id;
							local rewardValue = rewards[a].Value;

							if rewardType == "Resource" then
								reportText = reportText.."\n    • "..rewardId..": ".. rewardValue .."%";

							elseif rewardType == "Score" then
								reportText = reportText.."\n    + ".. rewardValue .." Score";

							elseif rewardType == "Gold" and factionData.TestGoldReward == true then
								reportText = reportText.."\n    + ".. rewardValue .. modRichFormatter.GoldText(" Gold");

							end
						end
					else
						reportText = reportText.."\n    • None"

					end

					if missionLib.PrintNote then
						local noteText = missionLib.PrintNote(missionInfo);
						if #noteText > 0 then
							reportText = reportText.."\n\n<b>Note: </b>".. noteText;
						end
					end

					reportLabel.Text = reportText;

				else
					activePanel.Visible = true;

					local timerLabel = activePanel:WaitForChild("TimerLabel");
					local joinMissionButton = activePanel:WaitForChild("joinButton");
					local quotaLabel = activePanel:WaitForChild("QuotaLabel");
					local playersPanel = activePanel:WaitForChild("PlayersPanel");
					local accessLabel = activePanel:WaitForChild("AccessLabel");

					joinMissionButton.MouseButton1Click:Connect(function()
						interface:PlayButtonClick();
						joinMissionButton.Text = "Joining..";

						unixTime = workspace:GetServerTimeNow();
						missionData = factionData.Missions;
						
						missionInfo = missionData.Active[missionIndex];
						Debugger:Warn("missionInfo", missionInfo);
						
						local packet = {
							ActiveIndex=missionIndex;
						}
						local rPacket = remoteFactionService:InvokeServer("joinfactionmission", packet);
						joinMissionButton.Text = "Join Mission";
						if rPacket and rPacket.FactionObj then
							sync(rPacket.FactionObj, function(factionObj)
								updateMissionPage();
							end);
						end
					end)


					binds.refreshActiveMissionInfo = function()
						local factionData = modData.FactionData;
						if factionData == nil then return end;

						unixTime = workspace:GetServerTimeNow();
						missionData = factionData.Missions;
						missionInfo = missionData.Active[missionIndex];

						if missionInfo == nil then
							binds.refreshActiveMissionInfo = nil;
							return;
						end

						local playersCount = 0;
						for userId, playerMissionData in pairs(missionInfo.Players) do
							playersCount = playersCount+1;

							if tostring(userId) == tostring(localPlayer.UserId) then
								joinMissionButton.Visible = false;
							else
								joinMissionButton.Visible = true;
							end

							local listingFrameTemplate = binds.MembersData[userId] and binds.MembersData[userId].ListingFrame;
							if listingFrameTemplate == nil then continue end;

							refreshPlayerListing(playersPanel, userId, listingFrameTemplate);
						end

						for _, obj in pairs(playersPanel:GetChildren()) do
							if obj:IsA("GuiObject") and missionInfo.Players[obj.Name] == nil then
								game.Debris:AddItem(obj, 0);
							end
						end

						timerLabel.Text = "Complete In: ".. modSyncTime.ToString(math.max(missionInfo.CompletionTick-unixTime, 0));
						quotaLabel.Text = "Quota: ".. playersCount .."/".. (missionInfo.QuotaLimit >= 99 and "Max" or missionInfo.QuotaLimit);
						
						accessLabel.Text = "Access: [".. missionInfo.AccessType .."] "..table.concat(missionInfo.AccessValue, ", ")
					end
					binds.refreshActiveMissionInfo();

				end

				new.Parent = missionContentScrollList;
				missionContentScrollList.CanvasPosition = Vector2.new();

			else
				Debugger:StudioLog("Missing ",missionMenuPage, " missionData", missionData);

				missionMenuPage = "";
				updateMissionPage();

			end

		elseif missionMenuPage == "ViewAvailableMission" then
			if viewAvailableMissionFunc then
				viewAvailableMissionFunc();

			else
				missionMenuPage = "";
				updateMissionPage();

			end

		else
			--Show available missions;
			if #missionData.Available <= 0 then
				local new = templateMissionListing:Clone();
				local viewButton = new:WaitForChild("viewAvailButton");
				viewButton.Visible = false;

				local titleLabel = new:WaitForChild("Title");
				titleLabel.Text = "No available missions, come back later..";
				titleLabel.TextXAlignment = Enum.TextXAlignment.Center;
				titleLabel.TextSize = 16;

				new.Parent = missionContentScrollList;
			end

			for a=1, #missionData.Available do
				local availableData = missionData.Available[a];
				
				local new = templateMissionListing:Clone();
				local missionLib = modMissionLibrary.Get(missionData.Available[a].Id);
				
				
				local titleLabel = new:WaitForChild("Title");
				titleLabel.Text = missionLib.Name

				local timeRemaining = shared.Const.OneDaySecs-(unixTime-availableData.RollTime);
				
				local radialBarLabel = new:WaitForChild("radialBar");
				local radialBar = modRadialImage.new(TIMER_RADIAL_CONFIG, radialBarLabel);
				local timeLeftRatio = timeRemaining/shared.Const.OneDaySecs;
				
				radialBar:UpdateLabel(timeLeftRatio);
				if timeRemaining <= 3600 then
					radialBarLabel.ImageColor3 = BAR_COLORS.Yellow;
				elseif timeRemaining <= 600 then
					radialBarLabel.ImageColor3 = BAR_COLORS.Red;
				else
					radialBarLabel.ImageColor3 = BAR_COLORS.Green;
				end
				
				local viewButton = new:WaitForChild("viewAvailButton");

				local factionCosts = missionLib.FactionCosts;
				if factionCosts == nil then
					viewButton.Visible = false;
				end

				viewButton.MouseButton1Click:Connect(function()
					if factionCosts == nil then return end;

					interface:PlayButtonClick();
					missionMenuPage = "ViewAvailableMission";

					local selectionListFrame;
					local accessType = "Everyone";

					viewAvailableMissionFunc = function()
						clearMissionPage();

						local new = templateMissionInfo:Clone();

						local titleLabel = new:WaitForChild("Title");
						titleLabel.Text = "Start "..missionLib.Name;

						local descLabel = new:WaitForChild("Desc");
						loadMissionDesc(descLabel, missionLib);
						
						local availPanel = new:WaitForChild("AvailPanel");
						availPanel.Visible = true;

						local timeLeftLabel = availPanel:WaitForChild("TimeLeftLabel");
						local function tickUpdateLabel()
							unixTime = workspace:GetServerTimeNow();
							timeRemaining = shared.Const.OneDaySecs-(unixTime-availableData.RollTime);
							timeLeftLabel.Text = "Available For: ".. modSyncTime.ToString(timeRemaining);
						end
						tickUpdateLabel();
						task.spawn(function()
							while true do
								task.wait(1);
								if not missionContentScrollList:IsAncestorOf(new) then break; end
								tickUpdateLabel();
							end
						end)
						

						local accessButton = availPanel:WaitForChild("accessButton");
						accessButton.MouseButton1Click:Connect(function()
							interface:PlayButtonClick();

							if selectionListFrame == nil then
								selectionListFrame = templateMembersSelectionList:Clone();
							end

							for _, obj in pairs(selectionListFrame.contentList:GetChildren()) do
								if obj:IsA("GuiObject") then
									game.Debris:AddItem(obj, 0);
								end
							end

							if accessType == "Everyone" then
								accessType = "Roles";
								selectionListFrame.Visible = true;

								for roleKey, roleConfig in pairs(factionData.Roles) do
									local newCheckbox = interface.newTemplate("Checkbox");
									newCheckbox.LayoutOrder = roleConfig.Rank;

									local roleColor = Color3.fromHex(roleConfig.Color) or Color3.fromRGB(255, 255, 255);

									newCheckbox.Name = "CheckboxOption";
									newCheckbox:SetAttribute("CheckedId", roleConfig.Title);
									local checkboxLabel = newCheckbox:WaitForChild("TextLabel");
									checkboxLabel.Text = roleConfig.Title;
									checkboxLabel.TextColor3 = roleColor;


									newCheckbox.Parent = selectionListFrame.contentList;
								end

							elseif accessType == "Roles" then
								accessType = "Members";
								selectionListFrame.Visible = true;

								for userId, memberData in pairs(factionData.Members) do
									local newCheckbox = interface.newTemplate("Checkbox");

									newCheckbox.Name = "CheckboxOption";
									newCheckbox:SetAttribute("CheckedId", memberData.Name);
									local checkboxLabel = newCheckbox:WaitForChild("TextLabel");
									checkboxLabel.Text = memberData.Name;

									newCheckbox.Parent = selectionListFrame.contentList;
								end

							elseif accessType == "Members" then
								accessType = "Everyone";
								selectionListFrame.Visible = false;

							end

							accessButton.Text = "Access: "..accessType;

							selectionListFrame.LayoutOrder = 11;
							selectionListFrame.Parent = availPanel;
						end)

						local quotaInputBox = availPanel:WaitForChild("QuotaLabel"):WaitForChild("quotaInputBox");
						local function updateQuotaInput()
							local num = tonumber(quotaInputBox.Text);
							if num == nil then return end;
							
							local maxMissionQuota = missionLib.QuotaLimit or 99;
							quotaInputBox.Text = math.clamp(num, 1, maxMissionQuota);
						end
						quotaInputBox.Text = missionLib.QuotaLimit or 50;
						quotaInputBox:GetPropertyChangedSignal("Text"):Connect(updateQuotaInput);
						updateQuotaInput();

						local startButton = availPanel:WaitForChild("startButton");
						local defStartText = startButton.Text;

						local startDebounce = false;
						startButton.MouseButton1Click:Connect(function()
							if startDebounce then return end;
							startDebounce = true;
							interface:PlayButtonClick();

							local checkedOptions = {};

							if selectionListFrame then
								for _, obj in pairs(selectionListFrame.contentList:GetChildren()) do
									if obj.Name == "CheckboxOption" and obj:GetAttribute("Checked") == true then
										table.insert(checkedOptions, obj:GetAttribute("CheckedId"))
									end
								end
							end

							local packet = {
								AccessType=accessType;
								AccessValue=checkedOptions;
								QuotaLimit=quotaInputBox.Text;
								MissionId=missionData.Available[a].Id;
							}

							startButton.Text = "Starting Mission..";
							local rPacket = remoteFactionService:InvokeServer("startfactionmission", packet);

							if rPacket and rPacket.Success then
								if rPacket.FactionObj then
									sync(rPacket.FactionObj, function(factionObj)
										if rPacket.VacantIndex then
											missionMenuPage = "ActiveMission"..rPacket.VacantIndex;

										else
											missionMenuPage = "";

										end
										updateMissionPage();
									end);
								end
							end

							startButton.Text = defStartText;

						end)

						new.Parent = missionContentScrollList;

					end

					updateMissionPage();
				end)

				new.Parent = missionContentScrollList;
			end

		end
	end
	
	local membersFrameExpandTween = TweenService:Create(memberSizeConstraint, TweenInfo.new(0.2), {MaxSize=Vector2.new(200, math.huge)});
	local membersFrameShrinkTween = TweenService:Create(memberSizeConstraint, TweenInfo.new(0.2), {MaxSize=Vector2.new(60, math.huge)});
	local mouseOnMemberFrame = false;
	function binds.MemberFrameLayout()
		local factionData = modData.FactionData;

		if factionData then
			if modConfigurations.CompactInterface then
				mouseOnMemberFrame = false;
			end
			if mouseOnMemberFrame then
				memberCountLabel.Text = "Members: "..factionData.MemberCount;
				memberCountLabel.TextXAlignment = Enum.TextXAlignment.Left;
				memberCountLabel.UIPadding.PaddingLeft = UDim.new(0, 10);
				membersFrameExpandTween:Play();
				memberFrame.ScrollBarThickness = 5;
				
			else
				memberCountLabel.Text = factionData.MemberCount.."/50";
				memberCountLabel.TextXAlignment = Enum.TextXAlignment.Center;
				memberCountLabel.UIPadding.PaddingLeft = UDim.new(0, 0);
				membersFrameShrinkTween:Play();
				memberFrame.ScrollBarThickness = 0;
				
			end
		else
			memberSizeConstraint.MaxSize = Vector2.new(0, math.huge);
		end
	end
	
	function binds.HasPermission(key)
		local factionData = modData.FactionData;
		if factionData == nil then return false; end;
		local memberData = factionData.Members[tostring(localPlayer.UserId)];
		if memberData == nil then return false end;

		local roleConfig = factionData.Roles[memberData.Role or "Member"];

		if tostring(localPlayer.UserId) == factionData.Owner then
			Debugger:StudioLog("Has owner permissions.");
			return true;
		end

		local r= factionPermissions:Test(key, (roleConfig and roleConfig.Perm or 0));
		if r == false then
			Debugger:StudioLog("Insufficient permissions.");
		end
		if localPlayer:GetAttribute("FactionBypass") == true then
			Debugger:StudioLog("FactionBypass permissions.");
			return true;
		end
		return r;
	end

	function binds.UpdateProfileFrame()
		if selectedUser == nil then setSelectedUser(localPlayer.UserId); end
		if selectedUser == nil then return end;

		local factionData = modData.FactionData;
		selectedUser = factionData.Members[selectedUser.UserId];

		local isLocalPlayer = selectedUser.Name == localPlayer.Name;
		local userId = selectedUser.UserId;

		profileFrame.Title.Text = selectedUser.Name;
		profileFrame.AvatarLabel.Image = "rbxthumb://type=AvatarHeadShot&id="..userId.."&w=420&h=420";

		local rolesConfig = factionData.Roles or {};
		local userRoleConfig = rolesConfig[selectedUser.Role] or {Rank=99; Title="Member"; Color="ffffff"};
		local roleColor = Color3.fromHex(userRoleConfig.Color);

		profileFrame.BackgroundColor3 = roleColor;
		profileFrame.AvatarLabel.BackgroundColor3 = roleColor;
		profileFrame.roleLabel.Text = userRoleConfig.Title;
		profileFrame.roleLabel.TextColor3 = roleColor;

		-- Buttons
		local setRoleButton = profileFrame.roleLabel.setRoleButton
		setRoleButton.Visible = binds.HasPermission("AssignRole");
		if isLocalPlayer or selectedUser.UserId == factionData.Owner then
			setRoleButton.Visible = false;
		end
		if localPlayer:GetAttribute("FactionBypass") == true then
			setRoleButton.Visible = true;
		end

		profileNavBar.leaveButton.Visible = isLocalPlayer;
		
		Debugger:Warn("selectedUser", selectedUser);
		local statsFrame = profileScrollFrame.Stats;
		local statsLabel: TextLabel = statsFrame.StatsLabel;
		
		local statsStr = "";
		
		local successCard = selectedUser.SuccessfulMissions or {This=0; Total=0};
		local scoreCard = selectedUser.ScoreContribution or {This=0; Total=0};
		
		statsStr = statsStr.."<b>Successful missions</b>: "
			..modFormatNumber.Beautify(successCard.This) .."  (Total: "..modFormatNumber.Beautify(successCard.Total)..")";
		statsStr = statsStr.."\n<b>Score contribution</b>: "
			..modFormatNumber.Beautify(scoreCard.This) .."  (Total: "..modFormatNumber.Beautify(scoreCard.Total)..")";
		statsStr = statsStr.."\n";
		statsStr = statsStr.."\n<b>Top Successful Missions:</b>";
		
		local topMissions = selectedUser.TopMissions or {};
		table.sort(topMissions, function(a, b) return a.Score > b.Score; end);
		for a=1, math.min(#topMissions, 3) do
			local missionInfo = topMissions[a];
			local missionLib = modMissionLibrary.Get(missionInfo.Id);
			statsStr = statsStr.."\n<b>"..a..".</b> "..missionLib.Name.."  (Total Score: ".. missionInfo.Score ..")";
		end
		
		statsLabel.Text = statsStr;
	end

	function binds.RefreshMemberSettingsFrame()
		local memberSettingsFrame = settingsBodyFrame.MemberSettingsFrame;
		if not memberSettingsFrame.Visible then return end;
		local factionData = modData.FactionData;
		if factionData == nil then return end;

		if modConfigurations.CompactInterface then
			memberSettingsFrame.JoinRequestsList.Size = UDim2.new(1, 0, 0, 100);
			memberSettingsFrame.MembersList.Size = UDim2.new(1, 0, 0, 100);
		end
		
		for _, obj in pairs(memberSettingsFrame.MembersList:GetChildren()) do
			if obj:IsA("GuiObject") and obj.Name ~= "buffer" then
				game.Debris:AddItem(obj, 0);
			end
		end

		local rolesConfig = factionData.Roles;
		-- Members Settings;
		for userId, memberData in pairs(factionData.Members) do
			local new = templateMemberSettingsListing:Clone();
			new.LayoutOrder = 99;

			local nameLabel = new:WaitForChild("memberNameLabel");
			nameLabel.Text = (userId == factionData.Owner and "★ " or "").. memberData.Name;

			local kickButton = new:WaitForChild("kickButton");
			kickButton.MouseButton1Click:Connect(function()
				if not binds.HasPermission("KickUser") then return end;
				interface:PlayButtonClick();

				game.Debris:AddItem(new, 0);
				local rPacket = remoteFactionService:InvokeServer("kickuser", userId);
				if rPacket and rPacket.Success then
					if rPacket.FactionObj then
						sync(rPacket.FactionObj, binds.RefreshMemberSettingsFrame);
					end
				end
			end)

			local userButton = new:WaitForChild("userButton");
			userButton.MouseButton1Click:Connect(function()
				interface:PlayButtonClick();
				setSelectedUser(userId);

				binds.ActivePage = "ProfileFrame";
				window:Update();
			end)

			local userRoleConfig = rolesConfig[memberData.Role];
			if userRoleConfig then
				new.LayoutOrder = userRoleConfig.Rank;

				local roleColor = Color3.fromHex(userRoleConfig.Color);
				nameLabel.TextColor3 = roleColor;
			end

			new.Parent = memberSettingsFrame.MembersList;
		end

		for _, obj in pairs(memberSettingsFrame.JoinRequestsList:GetChildren()) do
			if obj:IsA("GuiObject") and obj.Name ~= "buffer" then
				game.Debris:AddItem(obj, 0);
			end
		end

		local countJoinRequests = 0;
		for userId, userData in pairs(factionData.JoinRequests) do
			local _lastTime = userData.LastSent or 0;
			local userName = userData.Name or "n/a";
			
			countJoinRequests = countJoinRequests +1;
			local new = templateJoinRequestUser:Clone();
			new:WaitForChild("JoinRequestTitle").Text = tostring(userName);

			new:WaitForChild("joinAcceptButton").MouseButton1Click:Connect(function()
				if not binds.HasPermission("HandleJoinRequests") then return end;
				interface:PlayButtonClick();
				game.Debris:AddItem(new, 0);

				local rPacket = remoteFactionService:InvokeServer("handlejoinrequest", userId, true);
				if rPacket and rPacket.Success then
					if rPacket.FactionObj then
						sync(rPacket.FactionObj, binds.RefreshMemberSettingsFrame);
					end
				end
			end)
			new:WaitForChild("joinIgnoreButton").MouseButton1Click:Connect(function()
				if not binds.HasPermission("HandleJoinRequests") then return end;
				interface:PlayButtonClick();
				game.Debris:AddItem(new, 0);

				local rPacket = remoteFactionService:InvokeServer("handlejoinrequest", userId, false);
				if rPacket and rPacket.Success then
					if rPacket.FactionObj then
						sync(rPacket.FactionObj, binds.RefreshMemberSettingsFrame);
					end
				end
			end)

			new.Parent = memberSettingsFrame.JoinRequestsList;
		end
		
		memberSettingsFrame.JoinRequestTitle.Text = "Join Requests (".. countJoinRequests.."/16)";
	end
	
	local tagInputTick = tick();
	interface.Garbage:Tag(noFactionInput:GetPropertyChangedSignal("Text"):Connect(function()
		tagInputTick = tick();

		noFactionInput.Text = string.lower(string.sub(noFactionInput.Text, 1, 10));
		task.delay(0.5, function()
			if tick()-tagInputTick >= 0.45 and #noFactionInput.Text > 3 then
				searchingLabel.Visible = true;
				local searchResults = remoteFactionService:InvokeServer("search", string.sub(noFactionInput.Text, 1, 10));
				searchingLabel.Visible = false;

				if searchResults == nil or searchResults.Debounce then return end;
				Debugger:StudioLog("searchResults", searchResults);

				for _, obj in pairs(noFactionList:GetChildren()) do
					if obj:IsA("GuiObject") and obj.Name ~= "createListing" and obj.Name ~= "searchingLabel" then
						game.Debris:AddItem(obj, 0);
					end
				end

				for k, v in pairs(searchResults) do
					local newJoinFrame = templateJoinListing:Clone();

					local titleLabel = newJoinFrame:WaitForChild("Title");
					local tagLabel = newJoinFrame:WaitForChild("Tags");
					local iconLabel = newJoinFrame:WaitForChild("IconLabel");
					local joinButton = newJoinFrame:WaitForChild("joinButton")

					if v.Title then
						titleLabel.Text = v.Title;
					end
					if v.Tag then
						tagLabel.Text = "["..v.Tag.."]";
					end
					if v.Icon then
						iconLabel.Image = "rbxassetid://"..v.Icon;
						
						if v.Icon == "9890634236" then
							iconLabel.ImageColor3 = Color3.fromHex(v.Color or "ffffff");
						else
							iconLabel.ImageColor3 = Color3.fromRGB(255, 255, 255);
						end
					end

					joinButton.MouseButton1Click:Connect(function()
						interface:PlayButtonClick();
						joinButton.buttonText.Text = "Requesting...";
						local rPacket = remoteFactionService:InvokeServer("sendjoinrequest", v.Tag);
						joinButton.buttonText.Text = "Request Sent";

						if rPacket and rPacket.Success and rPacket.FactionObj then
							sync(rPacket.FactionObj, binds.RefreshMemberSettingsFrame);
						end
						
						if rPacket and rPacket.FailMsg then
							Debugger:Warn("Fail to send join request:", rPacket.FailMsg);
						end
					end)

					newJoinFrame.Parent = noFactionList;
				end
			end
		end)
	end));

    
	local function getFailResponse(r)
		if r == nil then
			return "Something went wrong, please try again.";
		end

		if r.Filtered then
			noFactionInput.Text = r.Tag;
			return "Sorry, faction tag got filter.";

		elseif r.TooShort then
			return  "Sorry, faction tag too short. Tags should be more than 3 and less than 10 characters.";

		elseif r.TooLong then
			return "Sorry, faction tag too long. Tags should be more than 3 and less than 10 characters.";

		elseif r.Taken then
			return "Sorry, this faction tag has been taken.";

		elseif r.AlreadyInFaction then
			return "You are already in a faction.";

		elseif r.NotInFaction then
			return "You are not in a faction.";

		elseif r.NoPermissions then
			return "You do not have permissions to do that.";

		elseif r.TooManyRoles then
			return "Too many roles.";

		elseif r.Mission58 then
			return "Requires mission \"Double Cross\".";

		elseif r.InsufficientGold then
			return "Requires 5'000 Gold.";

		end

        Debugger:StudioLog("Error", r);
        return "Something went wrong, please try again.";
	end

	interface.Garbage:Tag(createFactionButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();

		createFactionButton.buttonText.Text = "Create a Faction..";
		local testCreateReturn = remoteFactionService:InvokeServer("create", string.sub(noFactionInput.Text, 1, 10), true);
		createFactionButton.buttonText.Text = "Create a Faction";

		if testCreateReturn == nil or testCreateReturn.Success ~= true then
			modClientGuis.promptWarning( getFailResponse(testCreateReturn) );
            return;
		end
        
        modClientGuis.promptDialogBox({
            Title = `Create Faction?`;
            Desc = `Creating faction with tag <b>{testCreateReturn.Tag}</b> for <b><font color='rgb(170, 120, 0)'>5'000 Gold</font></b>?`;
            Icon = `rbxassetid://9890634236`;
            Buttons={
                {
                    Text="Create";
                    Style="Confirm";
                    OnPrimaryClick=function(dialogWindow)
                        local statusLabel = dialogWindow.Binds.StatusLabel;
                        statusLabel.Text = "Creating Faction<...>";

                        local createReturn = remoteFactionService:InvokeServer(
                            "create", 
                            string.sub(noFactionInput.Text, 1, 10)
                        );
                        if createReturn.Success then
                            statusLabel.Text = "Faction Created!";
                            sync(createReturn.FactionObj, function(factionObj)
                                window:Update();
                            end);
                        else
                            statusLabel.Text = getFailResponse(createReturn);
                        end

                        task.wait(2);
                    end;
                };
                {
                    Text="Cancel";
                    Style="Cancel";
                };
            }
        });
	end))

	--== Profile frame
	profileNavBar.leaveButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		if selectedUser.UserId ~= tostring(localPlayer.UserId)  then
			Debugger:StudioLog("setRoleButton failed, not self")
			return
		end

		modData.FactionData = nil;
		window:Update();

		local rPacket = remoteFactionService:InvokeServer("leavefaction");
		if rPacket and rPacket.Success then
			modData.FactionData = nil;
			sync();
		end
	end)

	local setRoleButton = profileFrame.roleLabel.setRoleButton;
	local function updateSetRole()
		if not binds.HasPermission("AssignRole") then return end;
		
		local isMouseHover = modGuiObjectPlus.IsMouseOver(setRoleButton);

		setRoleButton.BackgroundTransparency = isMouseHover and 0 or 1;
		setRoleButton.TextTransparency = isMouseHover and 0 or 1;
	end
	setRoleButton.MouseEnter:Connect(updateSetRole);
	setRoleButton.MouseLeave:Connect(updateSetRole);
	
	setRoleButton.MouseButton1Click:Connect(function()
		if not binds.HasPermission("AssignRole") then return end;
		interface:PlayButtonClick();

		local factionData = modData.FactionData;
		if factionData == nil then return end;

		local memberData = factionData.Members[tostring(localPlayer.UserId)];
		if memberData == nil then return end;

		local setterRoleConfig = factionData.Roles[memberData.Role or "Member"];
		
		local maxLengthSize = setRoleButton.Size.X.Offset;
		local rolesList = {};
		for roleKey, roleConfig in pairs(factionData.Roles) do
			if roleKey == "Owner" then continue end;
			if roleConfig.Rank <= setterRoleConfig.Rank then continue end;
			
			local roleStr = roleConfig.Title.." ("..roleConfig.Rank..")";
			table.insert(rolesList, {
				Id=roleKey; 
				Text=roleStr; 
				LayoutOrder=roleConfig.Rank;
				TextColor3=Color3.fromHex(roleConfig.Color);
				BackgroundColor3=Color3.fromRGB(48, 50, 71);
			});
			
			local txtSize = TextService:GetTextSize(roleStr, 16, Enum.Font.Arial, Vector2.new(200, 16));
			if txtSize.X > maxLengthSize then
				maxLengthSize = txtSize.X;
			end
		end
		table.insert(rolesList, {
			Id="__close"; 
			Text="Cancel"; 
			LayoutOrder=100;
		});
		for a=1, #rolesList do
			rolesList[a].Size = UDim2.new(0, maxLengthSize+20, 0, 25);
		end

		setRoleDropdownList = interface.newDropdownList(rolesList);
		setRoleDropdownList.ScrollFrame.Parent = windowFrame;
		setRoleDropdownList:SetPosition(setRoleButton.AbsolutePosition);
		setRoleDropdownList:OnOptionClick(function(roleKey)
			interface:PlayButtonClick();
			if roleKey ~= "__close" then
				task.spawn(function()
					task.spawn(function()
						local targetData = factionData.Members[tostring(selectedUser.UserId)];
						if targetData then
							targetData.Role = roleKey;
						end
						window:Update();

					end)
					local rPacket = remoteFactionService:InvokeServer("setrole", selectedUser.UserId, roleKey);
					if rPacket and rPacket.Success then
						if rPacket.FactionObj then
							sync(rPacket.FactionObj);
						end
					end
				end)
			end
			clearDropdownList();
		end)
	end)
	
	
	local function expandMissionFrame()
		centerHeadquartersFrame.Visible = false;
		centerResourceFrame.Visible = false;
		centerMissionsFrame:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true);
		centerMissionsFrame.PublicMissions.Size = UDim2.new(1, 0, 0, 140);
		centerMissionsFrame.ExpandPanel.Visible = true;

	end
	
	local function onActiveMissionSelect(index)
		task.spawn(function()
			remoteFactionService:InvokeServer("select", {Index=index;});
		end)
	end
	
	interface.Garbage:Tag(centerMissionsFrame.PublicMissions.Content1.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			interface:PlayButtonClick();
			missionMenuPage = "ActiveMission1";
			updateMissionPage();
			onActiveMissionSelect(1);

		end
	end))
	interface.Garbage:Tag(centerMissionsFrame.PublicMissions.Content2.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			interface:PlayButtonClick();
			missionMenuPage = "ActiveMission2";
			updateMissionPage();
			onActiveMissionSelect(2);

		end
	end))
	interface.Garbage:Tag(centerMissionsFrame.PublicMissions.Content3.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			interface:PlayButtonClick();
			missionMenuPage = "ActiveMission3";
			updateMissionPage();
			onActiveMissionSelect(3);

		end
	end))

	interface.Garbage:Tag(centerMissionsFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if centerFrameState ~= centerMissionsFrame.Name then
				centerFrameState = centerMissionsFrame.Name;

				interface:PlayButtonClick();

				expandMissionFrame();
				updateMissionPage();
			end
		end
	end))

	interface.Garbage:Tag(missionNavListScrollList.availableButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		missionMenuPage = "";
		updateMissionPage();
		Debugger:StudioLog("Available mission");
	end))

	interface.Garbage:Tag(missionNavListScrollList.backButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();

		centerMissionsFrame.ExpandPanel.Visible = false;
		centerMissionsFrame:TweenSize(UDim2.new(1, 0, 0.333, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true, shrinkMissionFrame);
	end))
	
    
	interface.Garbage:Tag(travelToHqButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		
        modClientGuis.promptDialogBox({
            Title = `Travel to Headquarters?`;
            Desc = `You're about to leave this world`;
            Buttons={
                {
                    Text="Travel";
                    Style="Confirm";
                    OnPrimaryClick=function(dialogWindow)
                        local statusLabel = dialogWindow.Binds.StatusLabel;
                        statusLabel.Text = "Traveling<...>";

                        local _travelReturn = remoteFactionService:InvokeServer("travelhq");
                        interface:ToggleGameBlinds(false, 3);
                        task.wait(5);
                    end;
                };
                {
                    Text="Cancel";
                    Style="Cancel";
                };
            }
        });
	end));
	

	--== Settings
	local activeSettingsPage = "InfoSettingsFrame";
	local function updateSettingsPage()
		clearDropdownList();
		for _, obj in pairs(settingsBodyFrame:GetChildren()) do
			if obj:IsA("GuiObject") then
				obj.Visible = obj.Name == activeSettingsPage;
			end
		end
	end

	interface.Garbage:Tag(settingsNav.infoButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		activeSettingsPage = "InfoSettingsFrame";
		updateSettingsPage()
	end))
	interface.Garbage:Tag(settingsNav.hqButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		activeSettingsPage = "HeadquartersFrame";
		updateSettingsPage()
	end))
	interface.Garbage:Tag(settingsNav.membersButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		activeSettingsPage = "MemberSettingsFrame";
		updateSettingsPage()
	end))
	interface.Garbage:Tag(settingsNav.rolesButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		activeSettingsPage = "RoleSettingsFrame";
		updateSettingsPage()
	end))
	interface.Garbage:Tag(settingsNav.logsButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		activeSettingsPage = "AuditLogsFrame";
		updateSettingsPage()
	end))

	local auditLogFrame = settingsBodyFrame.AuditLogsFrame;
	interface.Garbage:Tag(auditLogFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not auditLogFrame.Visible then return end;

		local factionData = modData.FactionData;
		if factionData == nil then return end;

		local factionLogs = factionData.Logs;
		local listFrame = auditLogFrame.LogsList;

		for _, obj in pairs(listFrame:GetChildren()) do
			if obj:IsA("GuiObject") and obj.Name ~= "buffer" then
				game.Debris:AddItem(obj, 0);
			end
		end

		for a=1, #factionLogs do
			local logData = factionLogs[a];
			local new = templateLogLabel:Clone();
			if auditLogs[logData.Type] then
				new.Text = "<b>["..DateTime.fromUnixTimestamp(logData.Tick):ToIsoDate().."]</b>  "..auditLogs[logData.Type].GetText(factionData, logData.Values);
			end
			new.Parent = listFrame;
		end
	end))

	
	--======================= InfoSettingsFrame
	local infoSettingsFrame = settingsBodyFrame.InfoSettingsFrame;
	interface.Garbage:Tag(infoSettingsFrame.TitleInput:GetPropertyChangedSignal("Text"):Connect(function()
		infoSettingsFrame.TitleInput.Text = infoSettingsFrame.TitleInput.Text:sub(1,40);
	end))
	interface.Garbage:Tag(infoSettingsFrame.DescInput:GetPropertyChangedSignal("Text"):Connect(function()
		infoSettingsFrame.DescInput.Text = infoSettingsFrame.DescInput.Text:sub(1,500);
	end))

	interface.Garbage:Tag(infoSettingsFrame.saveButton.MouseButton1Click:Connect(function()
		if not binds.HasPermission("EditInfo") then return end;
		local factionData = modData.FactionData;
		if factionData == nil then return end;

		interface:PlayButtonClick();

		local titleInput, descInput, iconInput, colorInput;

		if infoSettingsFrame.TitleInput.Text ~= factionData.Title then
			titleInput = infoSettingsFrame.TitleInput.Text;
		end
		if infoSettingsFrame.DescInput.Text ~= factionData.Description then
			descInput = infoSettingsFrame.DescInput.Text;
		end
		if infoSettingsFrame.IconInput.Text ~= factionData.Title then
			iconInput = infoSettingsFrame.IconInput.Text;
		end
		if infoSettingsFrame.ColorInput.Text ~= factionData.Color then
			colorInput = infoSettingsFrame.ColorInput.Text;
		end
		
		
		local settingsPacket = {
			TitleInput=titleInput;
			DescInput=descInput;
			IconInput=iconInput;
			ColorInput=colorInput;
		};
		
		infoSettingsFrame.saveButton.buttonText.Text = "Saving Settings...";
		local settingsReturn = remoteFactionService:InvokeServer("settings", settingsPacket);
		infoSettingsFrame.saveButton.buttonText.Text = "Save Settings";

		if settingsReturn then
			if settingsReturn.TitleFail then
				infoSettingsFrame.TitleInput.BackgroundColor3 = Color3.fromRGB(100, 43, 43);
				TweenService:Create(infoSettingsFrame.TitleInput, ONE_SEC_TWEENINFO, {BackgroundColor3=Color3.fromRGB(0,0,0)}):Play();
			end
			if settingsReturn.DescFail then
				infoSettingsFrame.DescInput.BackgroundColor3 = Color3.fromRGB(100, 43, 43);
				TweenService:Create(infoSettingsFrame.DescInput, ONE_SEC_TWEENINFO, {BackgroundColor3=Color3.fromRGB(0,0,0)}):Play();
			end

			if settingsReturn.FactionObj then
				sync(settingsReturn.FactionObj);
			end
		else
			getFailResponse(settingsReturn);

		end
	end))
	interface.Garbage:Tag(infoSettingsFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if infoSettingsFrame.Visible then
			local factionData = modData.FactionData;
			if factionData == nil then return end;

			infoSettingsFrame.TitleInput.Text = factionData.Title;
			infoSettingsFrame.DescInput.Text = factionData.Description;
			infoSettingsFrame.IconInput.Text = factionData.Icon;
			infoSettingsFrame.ColorInput.Text = factionData.Color;
			
		end
	end))
	interface.Garbage:Tag(infoSettingsFrame.ColorInput:GetPropertyChangedSignal("Text"):Connect(function()
		pcall(function()
			infoSettingsFrame.ColorInput.ColorSample.BackgroundColor3 = Color3.fromHex(infoSettingsFrame.ColorInput.Text);
		end)
	end))
	
	interface.Garbage:Tag(infoSettingsFrame.ColorInput:WaitForChild("ColorSample").MouseButton1Click:Connect(function()
		interface:PlayButtonClick();

		interface.setPositionWithPadding(colorPickerObj.Frame);
		colorPickerObj.Frame.Visible = true;

		function colorPickerObj:OnColorSelect(selectColor)
			interface:PlayButtonClick();
			infoSettingsFrame.ColorInput.ColorSample.BackgroundColor3 = selectColor;
			infoSettingsFrame.ColorInput.Text = selectColor:ToHex();
			colorPickerObj.Frame.Visible = false;
			
		end
	end))
	--======================= InfoSettingsFrame
	
	

	--======================= HeadquartersFrame
	local hqFrame = settingsBodyFrame.HeadquartersFrame;
	
	local function loadHqCustomizations()
		for _, obj in pairs(hqFrame:GetChildren()) do
			if obj:IsA("Frame") then
				game.Debris:AddItem(obj, 0);
			end
		end

		local factionData = modData.FactionData;
		if factionData == nil then return end;
		
		local safehomeCustomizableFolder = workspace.Environment:FindFirstChild("Customizable");
		if safehomeCustomizableFolder then
			hqFrame.HqCustomizationHint.Visible = false;
			
			local customizationData = factionData.SafehomeCustomizations;
			local aIndex = 0;
			for _, obj in pairs(safehomeCustomizableFolder:GetChildren()) do
				local groupId = obj.Name;
				local groupName = obj:GetAttribute("Name");
				local defaultColor = obj:GetAttribute("DefaultColor");

				if groupName and defaultColor then
					aIndex = aIndex +1;
					local groupData = customizationData and customizationData[groupId]
					local savedColor = groupData and groupData.Color and Color3.fromHex(groupData.Color) or nil;

					local new = templateAppearanceListing:Clone();
					new.LayoutOrder = 100 + aIndex;
					local titleLabel = new:WaitForChild("Title");
					local colorButton = new:WaitForChild("ColorButton");
					local textureLabel = colorButton:WaitForChild("TextureLabel");

					titleLabel.Text = groupName;
					textureLabel.BackgroundColor3 = savedColor or defaultColor;

					colorButton.MouseButton1Click:Connect(function()
						interface:PlayButtonClick();
						interface.setPositionWithPadding(colorPickerObj.Frame);
						colorPickerObj.Frame.Visible = true;

						if modConfigurations.CompactInterface then
							colorPickerObj.Frame.Size = UDim2.new(1,0,1,0);
						else
							colorPickerObj.Frame.Size = UDim2.new(0,300,0,300);
						end

						function colorPickerObj:OnColorSelect(selectColor)
							interface:PlayButtonClick();
							textureLabel.BackgroundColor3 = selectColor;
							colorPickerObj.Frame.Visible = false;

							local rPacket = remoteFactionService:InvokeServer("customizeHq", {
								GroupId=groupId;
								NewColor=selectColor;
							});
							
							if rPacket and rPacket.Success then
								textureLabel.BackgroundColor3 = selectColor;
								if rPacket.FactionObj then
									sync(rPacket.FactionObj);
								end
							end

						end
					end)

					local function resetColor()
						interface:PlayButtonClick();
						textureLabel.BackgroundColor3 = defaultColor;

						local rPacket = remoteFactionService:InvokeServer("customizeHq", {
							GroupId=groupId;
							NewColor=defaultColor;
						});
						if rPacket and rPacket.Success then
							textureLabel.BackgroundColor3 = defaultColor;
							
							if rPacket.FactionObj then
								sync(rPacket.FactionObj);
							end
						end

					end

					colorButton.TouchLongPress:Connect(resetColor)
					colorButton.MouseButton2Click:Connect(resetColor)

					new.Parent = hqFrame;
				end
			end
			
		else
			hqFrame.HqCustomizationHint.Visible = true;
			
		end
	end

	if modBranchConfigs.IsWorld("Safehome") then
		interface.Garbage:Tag(workspace:GetAttributeChangedSignal("SafehomeMap"):Connect(loadHqCustomizations))
	end
	
	interface.Garbage:Tag(hqFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if hqFrame.Visible then
			local factionData = modData.FactionData;
			if factionData == nil then return end;

			local hqSafehomeLib = modSafehomesLibrary:Find(factionData.SafehomeId or "default");
			
			hqFrame.HqHostTitle.Text = "Location: ".. hqSafehomeLib.Name;
			hqFrame.HqHostInput.Text = factionData.HqHost;
			
			loadHqCustomizations();
		end
	end))
	
	local dropdownListObj = modDropdownList.new();
    dropdownListObj.Parent = interface.ScreenGui;

	interface.Garbage:Tag(hqFrame.HqHostInput.setButton.MouseButton1Click:Connect(function()
		if not binds.HasPermission("CustomizeHq") then return end;
		
		interface:PlayButtonClick();

		local factionData = modData.FactionData;
		if factionData == nil then return end;
		
		local membersList = {};
		for userId, memberData in pairs(factionData.Members) do
			table.insert(membersList, memberData.Name);
		end
		
		dropdownListObj:LoadOptions(membersList);
		
		interface.setPositionWithPadding(dropdownListObj.Frame);
		dropdownListObj.Frame.Visible = true;

		function dropdownListObj:OnOptionSelect(selectIndex, optionButton)
			interface:PlayButtonClick();

			local selectName = optionButton.Name;

			hqFrame.HqHostInput.Text = selectName;
			dropdownListObj.Frame.Visible = false;
			task.spawn(function()
				local returnPacket = remoteFactionService:InvokeServer("sethqhost", selectName);
				hqFrame.HqHostInput.Text = returnPacket.SelectName;
			end)
		end
	end))
	
	--templateAppearanceListing
	
	
	--======================= HeadquartersFrame
	
	
	interface.Garbage:Tag(settingsBodyFrame.MemberSettingsFrame:GetPropertyChangedSignal("Visible"):Connect(binds.RefreshMemberSettingsFrame))

	local roleSettingsFrame = settingsBodyFrame.RoleSettingsFrame;
	local rolesNavFrame = roleSettingsFrame.rolesNavFrame;
	local roleConfigFrame = roleSettingsFrame.roleConfigFrame;

	if modConfigurations.CompactInterface then
		rolesNavFrame.Size = UDim2.new(0, 120, 1, 0);
		roleConfigFrame.Size = UDim2.new(1, -120, 1, 0);
	end
	
	for key, v in pairs(factionPermissions.Flags) do
		local newButton = interface.newTemplate("BasicButton");
		newButton.Size = UDim2.new(1, 0, 0, 30);
		newButton.RichText = true;
		newButton.LayoutOrder = math.log(v, 2)+10;
		newButton.Text = factionPermissions.Names[key]..": ".. colorBoolText(false);
		newButton.Name = key;
		newButton.BackgroundColor3=Color3.fromRGB(50, 53, 62);
		newButton.Parent = roleConfigFrame;

		newButton.MouseButton1Click:Connect(function()
			if roleConfigActive ~= "Owner" then
				interface:PlayButtonClick();

				local perm = roleConfigInput.Perm;
				local flagValue = not factionPermissions:Test(key, perm);
				roleConfigInput.Perm = factionPermissions:Set(perm, key, flagValue)
			end
			updatePermButtons();
		end)

		table.insert(permButtons, newButton);
	end

	local function refreshRoleSettings()
		if not roleSettingsFrame.Visible then return end;
		local factionData = modData.FactionData;
		if factionData == nil then return end;

		for _, obj in pairs(rolesNavFrame:GetChildren()) do
			if obj:IsA("GuiObject") then
				game.Debris:AddItem(obj, 0);
			end
		end

		-- Members Settings;
		for roleKey, roleConfig in pairs(factionData.Roles) do
			local newButton = interface.newTemplate("BasicButton");
			newButton.Font = Enum.Font.Arial;
			newButton.Size = UDim2.new(1, 0, 0, 30);
			newButton.RichText = true;
			newButton.LayoutOrder = roleConfig.Rank;
			newButton.Text = roleConfig.Title;
			newButton.TextColor3 = Color3.fromHex(roleConfig.Color);
			newButton.Name = roleKey;
			newButton.BackgroundColor3=Color3.fromRGB(50, 53, 62);

			local function roleButtonClick()
				roleConfigActive = roleKey;

				roleConfigFrame.TitleInput.Text = roleConfig.Title;
				roleConfigFrame.ColorInput.Text = roleConfig.Color;
				roleConfigFrame.membersInRoleCountLabel.Visible = true;
				roleConfigFrame.membersInRoleCountLabel.Text = "Members: "..(roleConfig.Size or 0);

				roleConfigFrame.RankInput.Text = roleConfig.Rank;
				roleConfigFrame.RankInput.TextEditable = roleConfig.Rank ~= 0 and roleConfig.Rank ~= 99;
				roleConfigFrame.deleteButton.Visible = roleConfigFrame.RankInput.TextEditable;

				roleConfigInput.Perm = roleConfig.Perm or 0;
				if roleKey == "Owner" then
					roleConfigInput.Perm = factionPermissions.Size;
					roleConfig.Perm = roleConfigInput.Perm;
				end
				updatePermButtons();
			end

			newButton.MouseButton1Click:Connect(function()
				interface:PlayButtonClick();
				roleButtonClick();
			end)
			if roleConfigActive == roleKey then
				roleButtonClick();
			end

			newButton.Parent = rolesNavFrame;
		end

		local addButton = interface.newTemplate("BasicButton");
		addButton.Font = Enum.Font.Arial;
		addButton.Size = UDim2.new(1, 0, 0, 30);
		addButton.LayoutOrder = 100;
		addButton.Text = "+";
		addButton.BackgroundColor3=Color3.fromRGB(50, 53, 62);
		addButton.MouseButton1Click:Connect(function()
			interface:PlayButtonClick();
			roleConfigActive = "__new";

			roleConfigFrame.TitleInput.Text = "Unnamed";
			roleConfigFrame.ColorInput.Text = "ffffff";
			roleConfigFrame.RankInput.Text = "98";
			roleConfigFrame.membersInRoleCountLabel.Visible = false;

			roleConfigFrame.RankInput.TextEditable = true;
			roleConfigFrame.deleteButton.Visible = false;

			roleConfigInput.Perm = 0;
			updatePermButtons();
		end)

		addButton.Parent = rolesNavFrame;
	end	

	roleConfigInput.Perm = 0;
	updatePermButtons();

	interface.Garbage:Tag(roleSettingsFrame:GetPropertyChangedSignal("Visible"):Connect(refreshRoleSettings))
	roleConfigFrame.saveButton.MouseButton1Click:Connect(function()
		if not binds.HasPermission("ConfigRole") then return end;
		interface:PlayButtonClick();

		roleConfigInput.Title = roleConfigFrame.TitleInput.Text;
		roleConfigInput.Color = roleConfigFrame.ColorInput.ColorSample.BackgroundColor3:ToHex();
		roleConfigInput.Rank = tonumber(roleConfigFrame.RankInput.Text) or 98;

		local rPacket = remoteFactionService:InvokeServer("configrole", roleConfigActive, roleConfigInput);
		if rPacket and rPacket.Success then
			if rPacket.FactionObj then
				sync(rPacket.FactionObj, refreshRoleSettings);
			end
		end
	end)
	roleConfigFrame.deleteButton.MouseButton1Click:Connect(function()
		if not binds.HasPermission("ConfigRole") then return end;
		interface:PlayButtonClick();

		game.Debris:AddItem(rolesNavFrame:FindFirstChild(roleConfigActive), 0);
		local rPacket = remoteFactionService:InvokeServer("deleterole", roleConfigActive);
		if rPacket and rPacket.Success then
			if rPacket.FactionObj then
				sync(rPacket.FactionObj, refreshRoleSettings);
			end
		end

		roleConfigActive = "Member";
		refreshRoleSettings();
	end)

	roleConfigFrame.TitleInput:GetPropertyChangedSignal("Text"):Connect(function()
		roleConfigFrame.TitleInput.Text = roleConfigFrame.TitleInput.Text:sub(1, 40);
	end)
	roleConfigFrame.ColorInput:GetPropertyChangedSignal("Text"):Connect(function()
		pcall(function()
			roleConfigFrame.ColorInput.ColorSample.BackgroundColor3 = Color3.fromHex(roleConfigFrame.ColorInput.Text);
		end)
	end)
	roleConfigFrame.RankInput:GetPropertyChangedSignal("Text"):Connect(function()
		if not roleConfigFrame.RankInput.TextEditable then return end;

		local rankNum = tonumber(roleConfigFrame.RankInput.Text) or 98;
		roleConfigFrame.RankInput.Text = math.clamp(rankNum, 0, 100);
	end)
	
	roleConfigFrame.ColorInput:WaitForChild("ColorSample").MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		
		interface.setPositionWithPadding(colorPickerObj.Frame);
		colorPickerObj.Frame.Visible = true;
		
		function colorPickerObj:OnColorSelect(selectColor)
			interface:PlayButtonClick();
			roleConfigFrame.ColorInput.ColorSample.BackgroundColor3 = selectColor;
			roleConfigFrame.ColorInput.Text = selectColor:ToHex();
			colorPickerObj.Frame.Visible = false;
		end
	end)

	--== Navbar
	local mouseEventForButtons = {bannerNavMenuButton; bannerNavChatButton; bannerNavLeaderboardsButton; bannerNavSettingsButton;};
	for a=1, #mouseEventForButtons do
		local imageButton = mouseEventForButtons[a];
		imageButton.MouseEnter:Connect(function()
			imageButton.ImageColor3 = branchColor;
		end)
		imageButton.MouseLeave:Connect(function()
			imageButton.ImageColor3 = Color3.fromRGB(255,255,255);
		end)
	end

	interface.Garbage:Tag(bannerNavMenuButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		binds.ActivePage = "MenuFrame";
		window:Update();
	end))
	interface.Garbage:Tag(bannerNavChatButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		binds.ActivePage = "FactionChatFrame";
		window:Update();
	end))
	interface.Garbage:Tag(bannerNavLeaderboardsButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		binds.ActivePage = "LeaderboardFrame";
		window:Update();
	end))
	interface.Garbage:Tag(bannerNavSettingsButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();

		if binds.HasPermission("CanViewSettings") then 
			binds.ActivePage = "SettingsFrame";
		else
			selectedUser = nil;
			binds.ActivePage = "ProfileFrame";
		end;

		window:Update();
		updateSettingsPage();
	end))

    interface.Scheduler.OnStepped:Connect(function(tickData: TickData)
        if tickData.ms1000 ~= true then return end;
        
        if binds.refreshPublicMissions then
			binds.refreshPublicMissions();
		end
		if binds.refreshActiveMissionInfo then
			binds.refreshActiveMissionInfo();
		end
    end);

	local function memberFrameMouseEnter() mouseOnMemberFrame = true; binds.MemberFrameLayout() end
	local function memberFrameMouseLeave() mouseOnMemberFrame = false; binds.MemberFrameLayout() end
	memberFrame.MouseEnter:Connect(memberFrameMouseEnter)
	memberFrame.MouseMoved:Connect(memberFrameMouseEnter)
	memberFrame.MouseLeave:Connect(memberFrameMouseLeave);

	remoteFactionService.OnClientInvoke = function(action, ...)
		if action == "sync" then
			local packet = ...;
			if packet.FactionObj then
				Debugger:Warn("Faction interface synced");
				sync(packet.FactionObj);
			end
		end
	end
	
    window.OnUpdate:Connect(function()
		local unixTime = workspace:GetServerTimeNow();
		clearDropdownList();

		if binds.ActivePage == "MissionRequirementFrame" then
			for _, obj in pairs(centerFrame:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj.Visible = obj.Name == binds.ActivePage;
				end
			end
			return;
		end

		if not firstsynced then
			binds.ActivePage = "LoadingFrame";

			for _, obj in pairs(centerFrame:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj.Visible = obj.Name == binds.ActivePage;
				end
			end
			return;
		end

		local factionData = modData.FactionData;

		if not windowFrame.Visible then return end;

		local updatedMember = {};

		if factionData == nil then
			binds.ActivePage = "JoinFactionFrame";
			bannerSizeConstraint.MaxSize = Vector2.new(0, math.huge);
			windowTitleLabel.Text = "Factions";

		else
			if binds.ActivePage == "FactionChatFrame" then
				local factionChatChannelId = "["..modData.FactionData.Tag.."]";
				factionChatRoom = chatRoomInterface:GetRoom(factionChatChannelId);

				if factionChatRoom == nil then
					factionChatRoom = chatRoomInterface:newRoom(factionChatChannelId);
				end

				chatRoomInterface.SwitchChannelFunc[factionChatChannelId] = function()
					binds.ActivePage = "FactionChatFrame";
					window:Update();
				end

				if factionChatRoom then
					factionChatRoom:SetActive();
					factionChatRoom.Frame.Parent = factionChatFrame;
					factionChatRoom.Frame.Visible = true;
					factionChatRoom.Frame.UIListLayout.Padding = UDim.new(0, 5);
				end

			else
				if factionChatRoom then
					factionChatRoom.Frame.Parent = factionChatRoom.MainChatFrame
					factionChatRoom.Frame.UIListLayout.Padding = UDim.new(0, 2);
				end

				local serverChatRoom = chatRoomInterface:GetRoom("Server");
				serverChatRoom:SetActive();

			end

			if binds.ActivePage == "JoinFactionFrame" or binds.ActivePage == "LoadingFrame" then
				binds.ActivePage = "MenuFrame";

			elseif binds.ActivePage == "ProfileFrame" then
				binds.UpdateProfileFrame();

			elseif binds.ActivePage == "SettingsFrame" then
				binds.RefreshMemberSettingsFrame();
			end
			bannerSizeConstraint.MaxSize = Vector2.new(280, math.huge);

			bannerTitleLabel.Text = factionData.Title;
			bannerDescLabel.Text = factionData.Description;
			memberIconLabel.Image = "rbxassetid://"..factionData.Icon;
			windowTitleLabel.Text = factionData.Title;

			if factionData.Icon == "9890634236" then
				memberIconLabel.ImageColor3 = Color3.fromHex(factionData.Color or "ffffff");
			end
			
			bannerGoldStats.Visible = factionData.TestGoldReward == true;
			bannerGoldLabel.Text = modRichFormatter.GoldText(modFormatNumber.Beautify(factionData.Gold or 0));
			
			local rolesConfig = factionData.Roles;
			-- members list;
			for userId, memberData in pairs(factionData.Members) do
				if binds.MembersData[userId] == nil then
					binds.MembersData[userId] = {};
				end

				local data = binds.MembersData[userId];

				local userListing = data.ListingFrame;
				if userListing == nil then
					userListing = templateFactionUserFrame:Clone();
					userListing.MouseButton1Click:Connect(function()
						interface:PlayButtonClick();

						setSelectedUser(userId);
						binds.ActivePage = "ProfileFrame";
						window:Update();
					end)
				end

				userListing.Name = userId;
				data.ListingFrame = userListing;
				userListing.LayoutOrder = 99;
				userListing.Parent = memberFrame;

				local nameLabel = userListing:WaitForChild("PlayerNameLabel");
				local iconLabel = userListing:WaitForChild("PlayerIconLabel");

				nameLabel.Text = memberData.Name;
				data.Name = memberData.Name;
				iconLabel.Image = "rbxthumb://type=AvatarHeadShot&id="..userId.."&w=420&h=420";


				local statusIcon = iconLabel:WaitForChild("StatusIconLabel");
				if game.Players:FindFirstChild(memberData.Name) or (unixTime-(memberData.LastActive or 0)) <= 180 then
					statusIcon.Visible = true;
					statusIcon.ImageColor3 = Color3.fromRGB(73, 189, 96);
				else
					statusIcon.Visible = false;
				end

				local userRoleConfig = rolesConfig[memberData.Role or "Member"];
				if userRoleConfig then
					userListing.LayoutOrder = userRoleConfig.Rank;

					local roleColor = Color3.fromHex(userRoleConfig.Color);
					nameLabel.TextColor3 = roleColor;
					iconLabel.BackgroundColor3 = roleColor;
				end

				updatedMember[userId] = true;
			end

		end

		for userId, memberData in pairs(binds.MembersData) do
			if updatedMember[userId] == nil then
				game.Debris:AddItem(memberData.ListingFrame, 0);
				binds.MembersData[userId] = nil;
			end
		end

		binds.MemberFrameLayout()
		--======


		if binds.ActivePage == "MenuFrame" then
			for _, obj in pairs(centerResourceFrame.Content:GetChildren()) do
				if obj:IsA("GuiObject") then
					game.Debris:AddItem(obj, 0);

				end
			end

			local resourceData = factionData.Resources;

			for a=1, #RESOURCE_KEYS do
				local statInfo = RESOURCE_KEYS[a];

				local newStat = templateResourceStatLabel:Clone();
				local statLabel = newStat:WaitForChild("StatLabel");
				local iconLabel = newStat:WaitForChild("IconLabel");

				iconLabel.Image = statInfo.Icon;

				local radialBarLabel: ImageLabel = newStat:WaitForChild("radialBar")
				local radialBar = modRadialImage.new(RESOURCE_RADIAL_CONFIG, radialBarLabel);

				local statVal = resourceData[statInfo.Key]/100;
				radialBar:UpdateLabel(statVal);
				statLabel.Text = string.format("%.1f%%", statVal*100);
				
				if statVal <= 0.2 then
					radialBarLabel.ImageColor3 = BAR_COLORS.Yellow;
				elseif statVal <= 0.1 then
					radialBarLabel.ImageColor3 = BAR_COLORS.Red;
				else
					radialBarLabel.ImageColor3 = BAR_COLORS.Green;
				end
					
				if UserInputService.TouchEnabled then
					statLabel.Visible = true;
				else
					radialBarLabel.MouseEnter:Connect(function()
						statLabel.Visible = true;
					end)
					radialBarLabel.MouseLeave:Connect(function()
						statLabel.Visible = false;
					end)
				end
			
				newStat.Position = UDim2.new(0.1 + (a-1)*(0.2), 0, 0.5, 0);
				newStat.Parent = centerResourceFrame.Content;
			end
			
			local hqSafehomeLib = modSafehomesLibrary:Find(factionData.SafehomeId or "default");
			hqMapThumbnail.Image = hqSafehomeLib.Image;
			
			local function refreshPublicMissions()
				local missionData = factionData.Missions;
				unixTime = workspace:GetServerTimeNow();
				
				for _, frame in pairs(centerMissionsFrame.PublicMissions:GetChildren()) do
					if frame.Name:find("Content") and frame.LayoutOrder > 0 then
						local activeIndex = frame.LayoutOrder;

						local activeFrame = frame.ActiveFrame;
						local plusFrame = frame.Plus;
						
						local activeMission = missionData.Active[activeIndex];
						if activeMission then
							local missionLib = modMissionLibrary.Get(activeMission.Id);
							
							
							local radialBar = modRadialImage.new(TIMER_RADIAL_CONFIG, activeFrame.radialBar);
							local timeLeft = activeMission.CompletionTick - unixTime;
							local ratio = 1- math.clamp(timeLeft/missionLib.ExpireTime, 0, 1);

							if activeMission.Completed then
								radialBar:UpdateLabel(1);
							else
								radialBar:UpdateLabel(math.clamp(ratio, 0.01, 0.99));
							end

							if timeLeft > -5 and timeLeft <= 0 and activeMission.Completed ~= true then
								if activeMission.Syncing ~= true then
									activeMission.Syncing = true;

									sync(nil, function(factionObj)
										Debugger:StudioLog("mission complete sync completed", factionObj);
										missionMenuPage = "";
										if updateMissionPage then
											updateMissionPage();
										end
									end);
								end
							end

							activeFrame.Title.Text = missionLib.Name;
							activeFrame.Visible = true;
							plusFrame.Visible = false;

						else
							activeFrame.Visible = false;
							plusFrame.Visible = true;

						end
					end
				end

			end

			refreshPublicMissions();
			binds.refreshPublicMissions = refreshPublicMissions;
		end

		for _, obj in pairs(centerFrame:GetChildren()) do
			if obj:IsA("GuiObject") then
				obj.Visible = obj.Name == binds.ActivePage;

			end
		end
	end)
    
end

return interfacePackage;

