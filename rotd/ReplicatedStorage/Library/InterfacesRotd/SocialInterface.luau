local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");
local BadgeService = game:GetService("BadgeService");
local GroupService = game:GetService("GroupService");


local localPlayer = game.Players.LocalPlayer;


local modBranchConfigurations = shared.require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));
local modRemotesManager = shared.require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("RemotesManager"));
local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modLevelBadge = shared.require(game.ReplicatedStorage.Library.LevelBadge);
local modAchievementLibrary = shared.require(game.ReplicatedStorage.Library.AchievementLibrary);
local modCollectiblesLibrary = shared.require(game.ReplicatedStorage.Library.CollectiblesLibrary);
local modPlayerTitlesLibrary = shared.require(game.ReplicatedStorage.Library.PlayerTitlesLibrary);
local modConfigurations = shared.require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modTeamsManager = shared.require(game.ReplicatedStorage.Library.TeamsManager);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);


local HIGHLIGHT_COLORS = {
	Black = Color3.fromRGB(25, 25, 25);
	Bronze = Color3.fromRGB(80, 47, 20);
	Silver = Color3.fromRGB(116, 116, 116);
	Gold = Color3.fromRGB(116, 96, 24);
	Diamond = Color3.fromRGB(77, 142, 143);
};

local FOCUS_LEVEL_COLORS = {
	Color3.fromRGB(89, 89, 89);
	Color3.fromRGB(51, 102, 204);
	Color3.fromRGB(101, 59, 169);
	Color3.fromRGB(165, 59, 168);
};

local STAT_SORT = {
	Level={Name="Mastery Level"; Index=1; MaxKey="MaxLevels";};
	Kills={Name="Kills"; Index=3;};
	ZombieKills={Name="Zombie Kills"; Index=31;};
	HumanKills={Name="Human Kills"; Index=32;};
	Death={Name="Death"; Index=40;};
	TweakPoints={Name="Tweak Points"; Index=49;};
	Perks={Name="Perks"; Index=50;};
	Money={Name="Money"; Index=60;};
	MissionsCompleted={Name="Missions Completed"; Index=70;};
	FotlStats={Name="Fall of the Living"; Index=75;};
	ColorPacks={Name="Color Packs"; Index=80;};
	SkinsPacks={Name="Skin Packs"; Index=90;};
	--TraderRep={Name="Trader Reputation"; Index=100;};
};

local function getHighlightColor(tier)
	if tier == modAchievementLibrary.Tiers.Bronze then
		return HIGHLIGHT_COLORS.Bronze;
	elseif tier == modAchievementLibrary.Tiers.Silver then
		return HIGHLIGHT_COLORS.Silver;
	elseif tier == modAchievementLibrary.Tiers.Gold then
		return HIGHLIGHT_COLORS.Gold;
	elseif tier == modAchievementLibrary.Tiers.Diamond then
		return HIGHLIGHT_COLORS.Diamond;
	end

	return HIGHLIGHT_COLORS.Black;
end

local interfacePackage = {
    Type = "Player";
};
--==

function interfacePackage.onRequire()
	modKeyBindsHandler:SetDefaultKey("KeyWindowSocialMenu", Enum.KeyCode.G);
end

function interfacePackage.newInstance(interface: InterfaceInstance)
    local remoteWorldTravelRequest = game.ReplicatedStorage.Remotes.Interactable.WorldTravelRequest;
    local remoteRequestPublicProfile = modRemotesManager:Get("RequestPublicProfile");
    local remoteProgressMission = modRemotesManager:Get("ProgressMission");
    local remoteSetPlayerTitle = modRemotesManager:Get("SetPlayerTitle");
    local remoteDuelRequest = modRemotesManager:Get("DuelRequest");
    local remoteTradeRequest = modRemotesManager:Get("TradeRequest");
    local remotePlayerSearch = modRemotesManager:Get("PlayerSearch");
    local remoteTeamsManager = modRemotesManager:Get("TeamsManager");
    
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local friendsTabTemplate = script:WaitForChild("FriendsTab");
    local playerListingTemplate = script:WaitForChild("PlayerListing");

    local menuFrame = script:WaitForChild("SocialMenu"):Clone();
    menuFrame.Parent = interface.ScreenGui;
        
    local list = menuFrame:WaitForChild("LeftBackground"):WaitForChild("List");
    local listUIListLayout = list:WaitForChild("UIListLayout");

    local profileFrame = menuFrame:WaitForChild("RightBackground");
    local profileNameTag = profileFrame:WaitForChild("NameTag");
    local profileTitleTag = profileFrame:WaitForChild("TitleTag");

    local profileAvatarLabel = profileFrame:WaitForChild("Avatar");
    local profileLevelLabel = profileFrame:WaitForChild("LevelIcon");
    local profileDisplayList = profileFrame:WaitForChild("ProfileFrame");
    local profileDisplayLayout = profileDisplayList:WaitForChild("UIListLayout");
    local profileLocationLabel = profileFrame:WaitForChild("LocationTag");

    local searchBar = menuFrame:WaitForChild("SearchBar"):WaitForChild("nameInput");

    local inviteDebounce = {};


    local playerSelection = localPlayer.Name;
    local selectionWorldName = "TheWarehouse";

    local titlePinIcon = nil;
    local achievementIndexList = modAchievementLibrary:GetIndexList();
    local badgeButtons = {};
    local searchedPlayer = {};

    local barTemplate = script:WaitForChild("barTemplate");
    local templateBadgeButton = script:WaitForChild("badgeButton");
    local templatePinIcon = script:WaitForChild("PinIcon");

    local templateOptionFrame = script:WaitForChild("Options");
    local templateOptionButton = script:WaitForChild("templateButton");
    local activeOptionsFrame;

    local highlightText = menuFrame:WaitForChild("HighlightText");


    --MARK: Window
	local window: InterfaceWindow = interface:NewWindow("SocialMenu", menuFrame);
    window.BoolStringWhenActive = {String="!HotbarsHud"; Priority=2;};
	window.CompactFullscreen = true;
    window.CloseWithInteract = true;

	window:SetClosePosition(UDim2.new(0.5, 0, -1, 0), UDim2.new(0.5, 0, 0.5, 0));
    
	local quickButton = interface:NewQuickButton("SocialMenu", "Social", "rbxassetid://3256270238");
	quickButton.LayoutOrder = 100;
	interface:ConnectQuickButton(quickButton, "KeyWindowSocialMenu");
    interface:BindConfigKey("DisableSocialMenu", {window});

    local binds = window.Binds;
    binds.FriendsList = {};
    binds.ActivePlayerListing = {};

    local function updateRequest()
        window:Update();
    end

	interface.Garbage:Tag(game.Players.PlayerAdded:Connect(updateRequest));
	interface.Garbage:Tag(game.Players.PlayerRemoving:Connect(updateRequest));

    
    local mission1Data;
    local function hasCompletedFirstMission()
        if mission1Data ~= nil and mission1Data.Type == 3 then
            return true;
        end

        modClientGuis.promptWarning("Please complete the first mission.");
        return false;
    end

    --MARK: OnToggle
	window.OnToggle:Connect(function(visible)
		if visible then
            mission1Data = modData:GetMission(1);

			interface:HideAll{[window.Name]=true;};
			binds.SelectPlayer(localPlayer.Name, true);
			window:Update();
			
			if modData and modData.GameSave and modData.GameSave.Missions then
				local missionsList = modData.GameSave.Missions;
				for a=1, #missionsList do
					local missionData = missionsList[a];
					if missionData.Id == 27 then
						if missionData.Type == 1 and missionData.ProgressionPoint == 1 then
							remoteProgressMission:FireServer(27, 1);
						end
						break;
					end
				end
			end
		else
			if activeOptionsFrame then
				activeOptionsFrame:Destroy();
				activeOptionsFrame = nil;
			end
			highlightText.Visible = false;
		end
	end)

	   if modConfigurations.CompactInterface then
	       menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0);
	       menuFrame.Size = UDim2.new(1, 0, 1, 0);
	       menuFrame:WaitForChild("UICorner"):Destroy();

	       local touchCloseButton = menuFrame:WaitForChild("touchCloseButton");
	       touchCloseButton.Visible = true;
	       touchCloseButton:WaitForChild("closeButton").MouseButton1Click:Connect(function()
	           interface:PlayButtonClick();
	           window:Close();
	       end)
	   end

    local function UpdateApplicableFriends()
        local friends = {};
        local s,e = pcall(function()
            friends = localPlayer.UserId > 0 and localPlayer:GetFriendsOnlineAsync() or {};
        end)
        if not s then warn(e) end;

        binds.FriendsList = {};

        for a=1, #searchedPlayer do
            searchedPlayer[a].LocationType = 1;
            searchedPlayer[a].SearchedPlayer = true;
            table.insert(friends, searchedPlayer[a]);
        end

        for a=1, #modData.TravelRequests do
            modData.TravelRequests[a].LocationType = 1;
            modData.TravelRequests[a].TravelRequest = true;
            table.insert(friends, modData.TravelRequests[a]);
        end

        for a=1, #friends do
            local inUniverse = false;
            if friends[a].PlaceId or friends[a].LocationType == 1 or friends[a].LocationType == 4 then
                inUniverse = modBranchConfigurations.IsPlaceIdThisGame(friends[a].PlaceId);
            end

            friends[a].Avatar = shared.modPlayers.getAvatar(friends[a].VisitorId);
            friends[a].InUniverse = inUniverse;

            if binds.FriendsList then
                binds.FriendsList[friends[a].UserName] = friends[a];
            end
        end

        if localPlayer.UserId == -1 then
            local random1Id = modGlobalVars.UseRandomId();
            binds.FriendsList.Random1 = {
                VisitorId = random1Id;
                UserName = "Random1";
                Avatar = shared.modPlayers.getAvatar(random1Id);
                InUniverse = true;
            };

            local random2Id = modGlobalVars.UseRandomId();
            binds.FriendsList.Random2 = {
                VisitorId = random2Id;
                UserName = "Random2";
                Avatar = shared.modPlayers.getAvatar(random2Id);
                InUniverse = true;
            };
        end
    end

    local function getInvitations(typeName)
        local r = {};

        for _, packet in pairs(modData.ToastPackets.List) do
            if typeName and packet.Type ~= typeName then continue end;
            if typeName == nil and string.match(packet.Type, "Invite") == nil then continue end;
            if packet._hide == packet.AddTime then continue end;

            table.insert(r, packet);
        end

        return r;
    end
    local function getInvitationFrom(typeName, name)
        for _, packet in pairs(modData.ToastPackets.List) do
            if packet.Type ~= typeName then continue end;
            if packet._hide == packet.AddTime then continue end;

            if packet.SenderName == name then
                return packet;
            end
        end
        return;
    end

    interface.OnInterfaceEvent:Connect(function(action, toastPackets)
        if action ~= "UpdateToast" then return end;

        Debugger:StudioWarn("OnUpdateToast", toastPackets);
    end)

    local function CacheAvatar(playerName, userId)
        if userId == nil then
            userId = shared.modPlayers.getUserId(playerName);
        end
        if userId == nil then return "" end;
        return shared.modPlayers.getAvatar(userId);
    end


    local function getPlayerWorldName(playerName, fallbackWorldName)
        local squadTeam = modTeamsManager.getTeamByPlayer(localPlayer, "Squad");
        if squadTeam and squadTeam.Members[playerName] then
            return squadTeam.Members[playerName].Values.WorldName or "Unknown";
        end

        local friendData = binds.FriendsList and binds.FriendsList[playerName];
        if friendData and friendData.InUniverse then
            return modBranchConfigurations.GetWorldName(friendData.PlaceId) or "Unknown";
        end

        return fallbackWorldName;
    end

    --MARK: Render social profile;
    function binds.SelectPlayer(playerName, refresh)
        playerSelection = playerName;
        profileNameTag.Text = playerName;
        profileAvatarLabel.Image = CacheAvatar(playerName) or "";
        
        if modData.Players[playerName] == nil or refresh then
            modData.Players[playerName] = remoteRequestPublicProfile:InvokeServer(playerName);
        end
        if modData.Players[playerName] then
            local playerData = modData.Players[playerName];
            
            if playerData.TitleId ~= "" then
                local titleLib = modPlayerTitlesLibrary:Find(playerData.TitleId);
                if titleLib then
                    profileTitleTag.Text = titleLib.Title;
                    
                    if titleLib.TitleStyle then
                        if titleLib.TitleStyle.TextColor3 then
                            profileTitleTag.TextColor3 = titleLib.TitleStyle.TextColor3;
                        end
                        if titleLib.TitleStyle.TextStrokeColor3 then
                            profileTitleTag.TextStrokeColor3 = titleLib.TitleStyle.TextStrokeColor3;
                        end
                    end
                end
            else
                profileTitleTag.Text = "";
                profileTitleTag.TextStrokeColor3 = Color3.fromRGB(0, 0, 0);
                if titlePinIcon then
                    titlePinIcon:Destroy();
                    titlePinIcon = nil;
                end
            end
            
            if playerData.Stats then
                modLevelBadge:Update(profileLevelLabel, playerData.Stats.Level or 0);

                local statCache = {};
                
                if RunService:IsStudio() then
                    local playPoints = interface.beautifyNumber(playerData.PlayPoints or 0);
                    table.insert(statCache, {Index=99; String=`<b>Gameplay Points</b>: <font size="12">{playPoints}</font>`});
                end

                if playerData.Punishment and playerData.Punishment > 0 then
                    table.insert(statCache, {Index=-5; String=`<b>Punished</b>: <font size="12"> {modGlobalVars.Punishments[playerData.Punishment]}</font>`});
                end
                
                for k, v in pairs(playerData.Stats) do
                    local lib = STAT_SORT[k];

                    local statKey = lib and lib.Name or k;
                    local statValue = tostring(v);

                    if typeof(v) == "number" then
                        statValue = interface.beautifyNumber(v);

                        local maxVal = modGlobalVars[lib and lib.MaxKey or `Max{k}`];
                        if maxVal and v >= maxVal then
                            statValue = `{statValue} <font size="9"><b>(Maxed)</b></font>`;
                        end
                    end

                    if lib then
                        table.insert(statCache, {Index=lib.Index; String=`<b>{statKey}</b>: <font size="12">{statValue}</font>`});
                    end
                end
                table.sort(statCache, function(A, B) return A.Index < B.Index; end)

                local statStringTable = table.create(#statCache);
                for a=1, #statCache do
                    statStringTable[a] = statCache[a].String;
                end
                
                profileDisplayList.statsProfile.label.Text = table.concat(statStringTable, "\n");
                local textSize = TextService:GetTextSize(profileDisplayList.statsProfile.label.Text, 
                                                        profileDisplayList.statsProfile.label.TextSize,
                                                        profileDisplayList.statsProfile.label.Font,
                                                        Vector2.new(415, 2000));
                profileDisplayList.statsProfile.Size = UDim2.new(1, 0, 0, textSize.Y+100);
            else
                modLevelBadge:Update(profileLevelLabel, 0);
            end
            profileDisplayList.statsProfile.Visible = true;
            profileLevelLabel.Visible = true;
            
            if playerData.Stats and playerData.Stats.FocusLevel and playerData.Stats.Level then
                profileDisplayList.focusLevels.Visible = true;
                local focusLevelFrame = profileDisplayList.focusLevels.Frame;
                local playerLevel = playerData.Stats.Level;
                local focusLevel = playerData.Stats.FocusLevel;
                
                for _, obj in pairs(focusLevelFrame:GetChildren()) do
                    if obj:IsA("GuiObject") then
                        obj:Destroy();
                    end
                end
                
                local barFrames = {};
                local levelSort = {};
                local totalKills = 0;
                for lvl=math.clamp(focusLevel-3, 1, math.huge), focusLevel do
                    local levelKills = (playerData.Stats["LevelKills-"..lvl] or 0);
                    local focusAmount = modGlobalVars.GetFocusLevel(playerLevel, lvl);

                    local barFrame = barTemplate:Clone();
                    local label = barFrame:WaitForChild("amountLabel");
                    barFrame.Parent = focusLevelFrame;

                    local sizeConstraint = Instance.new("UISizeConstraint");
                    sizeConstraint.MinSize = Vector2.new(40, 0);
                    sizeConstraint.Parent = barFrame;

                    local killsNeeded = focusAmount-math.fmod(levelKills, focusAmount);
                    totalKills += killsNeeded;
                    label.Text = `L{lvl}: {killsNeeded}`;

                    table.insert(barFrames, {Bar=barFrame; Amount=killsNeeded;});
                    table.insert(levelSort, {Bar=barFrame; Level=lvl;});
                end
                table.sort(barFrames, function(A, B) return A.Amount < B.Amount end);
                table.sort(levelSort, function(A, B) return A.Level > B.Level end);

                for a=1, #barFrames do
                    local barFrame = barFrames[a].Bar;

                    barFrame.LayoutOrder = a;
                    barFrame.Size = UDim2.new(math.clamp(barFrames[a].Amount/totalKills, 0, 1), 0, 1, 0);
                    barFrame.Visible = true;
                end
                for a=1, #levelSort do
                    levelSort[a].Bar.BackgroundColor3 = FOCUS_LEVEL_COLORS[a] or FOCUS_LEVEL_COLORS[#FOCUS_LEVEL_COLORS];
                end
            else
                profileDisplayList.focusLevels.Visible = false;
            end
            
            if playerData.Collectibles then
                profileDisplayList.collectionProfile.Visible = true;
                
                local found = {};
                local notFound = {};
                for id, info in pairs(modCollectiblesLibrary:GetAll()) do
                    if playerData.Collectibles[id] then
                        table.insert(found, info.Name);
                    else
                        table.insert(notFound, info.Name);
                    end
                end
                local total = #found+#notFound;
                local noOfFound = #found;
                profileDisplayList.collectionProfile.Frame.Bar.Size = UDim2.new(math.clamp(#found/total, 0, 1), 0, 1, 0);
                profileDisplayList.collectionProfile.label.Text = `Collectibles doesn't have any affect on gameplay. ({noOfFound}/{total})`;
                profileDisplayList.collectionProfile.foundLabel.Text = "Found:\n".. table.concat(found, "\n");
                profileDisplayList.collectionProfile.notfoundLabel.Text = ":Not Found\n".. table.concat(notFound, "\n");
                local txtBoundFound = TextService:GetTextSize(profileDisplayList.collectionProfile.foundLabel.Text,
                                                                profileDisplayList.collectionProfile.foundLabel.TextSize,
                                                                profileDisplayList.collectionProfile.foundLabel.Font,
                                                                Vector2.new(250, 1000));
                local txtBoundUnfound = TextService:GetTextSize(profileDisplayList.collectionProfile.notfoundLabel.Text,
                                                                profileDisplayList.collectionProfile.notfoundLabel.TextSize,
                                                                profileDisplayList.collectionProfile.notfoundLabel.Font,
                                                                Vector2.new(250, 1000));
                local ySize = math.max(txtBoundFound.Y, txtBoundUnfound.Y);
                profileDisplayList.collectionProfile.Size = UDim2.new(1, 0, 0, ySize+130);
            else
                profileDisplayList.collectionProfile.Visible = false;
            end
            
            if playerData.Achievements then
                profileDisplayList.achievements.Visible = true;

                local equipTitleDebounce = false;
                local order = 1000;
                for a=1, #achievementIndexList do
                    local lib = achievementIndexList[a];
                    local owned = playerData.Achievements[lib.Id];

                    local new = badgeButtons[lib.Id] or templateBadgeButton:Clone();

                    if lib.Id == playerData.TitleId then
                        if titlePinIcon == nil or titlePinIcon.Parent == nil then
                            titlePinIcon = templatePinIcon:Clone();
                        end

                        titlePinIcon.Parent = new;
                        titlePinIcon.Visible = true;
                    end

                    if badgeButtons[lib.Id] == nil then
                        new.MouseMoved:Connect(function()
                            if lib.BadgeInfo == nil then return end;

                            local position = new.AbsolutePosition-menuFrame.AbsolutePosition;
                            highlightText.Position = UDim2.new(0, position.X+40, 0, position.Y+65);

                            highlightText.ImageColor3 = getHighlightColor(lib.Tier);

                            highlightText.titleTag.Text = lib.BadgeInfo.Name;
                            highlightText.descTag.Text = lib.BadgeInfo.Description;

                            if lib.Tier and lib.Tier.Perks then
                                highlightText.descTag.Text ..= `\nReward: +{lib.Tier.Perks} Perks`;
                            end

                            local textBounds = TextService:GetTextSize(
                                highlightText.descTag.Text,
                                highlightText.descTag.TextSize,
                                highlightText.descTag.Font,
                                Vector2.new(340, 1000));

                            highlightText.Size = UDim2.new(0, 350, 0, 40+math.clamp(textBounds.Y, 0, 1000));

                            highlightText.Visible = true;
                        end)
                        new.MouseLeave:Connect(function()
                            highlightText.Visible = false;
                        end)

                        local function setTitleClick()
                            interface:PlayButtonClick();

                            local newTitleId = remoteSetPlayerTitle:InvokeServer(lib.Id);

                            if modData.Profile then
                                modData.Profile.TitleId = newTitleId;
                            end
                            if titlePinIcon then
                                titlePinIcon:Destroy();
                                titlePinIcon = nil;
                            end
                            binds.SelectPlayer(playerSelection, true);
                            window:Update();
                        end
                        new.MouseButton1Click:Connect(function()
                            if playerName ~= localPlayer.Name then return end;
                            if playerData.Achievements[lib.Id] == nil then
                                if lib.Id == "gromem" then
                                    GroupService:PromptJoinAsync(4573862);
                                end

                                return
                            end;

                            if equipTitleDebounce then return end
                            equipTitleDebounce = true;
                            setTitleClick();
                            equipTitleDebounce = false;
                        end)

                        if RunService:IsStudio() then
                            new.MouseButton2Click:Connect(setTitleClick);
                        end
                    end

                    badgeButtons[lib.Id] = new;
                    new.LayoutOrder = owned or order+a;

                    task.spawn(function()
                        if lib.BadgeInfo == nil then
                            pcall(function()
                                lib.BadgeInfo = BadgeService:GetBadgeInfoAsync(lib.BadgeId);
                            end)
                        end
                        if lib.BadgeInfo then
                            new.Image = lib.BadgeInfo.IconImageId and "rbxassetid://"..lib.BadgeInfo.IconImageId or "rbxasset://textures/ui/GuiImagePlaceholder.png";
                        end
                    end)
                    new.ImageColor3 = owned and Color3.fromRGB(255, 255, 255) or HIGHLIGHT_COLORS.Black;
                    new.Visible = not (lib.Hidden and owned == nil);

                    new.Parent = profileDisplayList.achievements.ScrollingFrame;
                end

                task.spawn(function()
                    profileDisplayList.achievements.Size = UDim2.new(
                        1,
                        0,
                        0,
                        profileDisplayList.achievements.ScrollingFrame.UIGridLayout.AbsoluteContentSize.Y+130
                    );
                end)
            else
                profileDisplayList.achievements.Visible = false;
            end
            
            if playerData.Statistics and next(playerData.Statistics) then
                profileDisplayList.gameStatistics.Visible = true;
                
                local strTable = {
                    "This is just for your own reference. Some of the data shown are newly added, there for it can not count data before it was added.\n"
                };
                for category, statsTable in pairs(playerData.Statistics) do
                    table.insert(strTable, category..":")
                    for statType, statCount in pairs(statsTable) do
                        statType = statType:gsub("-", " - ");
                        statType = statType:gsub("Kills", " Kills");
                        table.insert(strTable, "    "..statType..":  "..statCount);
                    end
                    table.insert(strTable, "\n")
                end
                
                profileDisplayList.gameStatistics.label.Text = table.concat(strTable, "\n");
                local textSize = TextService:GetTextSize(profileDisplayList.gameStatistics.label.Text, 
                                                        profileDisplayList.gameStatistics.label.TextSize,
                                                        profileDisplayList.gameStatistics.label.Font,
                                                        Vector2.new(415, 10000));
                profileDisplayList.gameStatistics.Size = UDim2.new(1, 0, 0, textSize.Y+100);
            else
                profileDisplayList.gameStatistics.Visible = false;
            end
        else
            modLevelBadge:Update(profileLevelLabel, 0);
            profileLevelLabel.Visible = false;
            profileNameTag.TextColor3 = Color3.fromRGB(255, 255, 255);
            profileDisplayList.statsProfile.Visible = false;
            profileDisplayList.focusLevels.Visible = false;
        end
        
        selectionWorldName = getPlayerWorldName(playerName, shared.WorldName);
        profileLocationLabel.Text = selectionWorldName and modBranchConfigurations.GetWorldDisplayName(selectionWorldName) or "Unknown";
    end


    local function UpdateListing(listingData)
        local curPlayerName = listingData.Name;

        local listing = binds.ActivePlayerListing[curPlayerName];
        if listing == nil then
            listing = playerListingTemplate:Clone();
            listing.Parent = list;
            binds.ActivePlayerListing[curPlayerName] = listing;
            
            listing.MouseButton1Down:Connect(function()
                interface:PlayButtonClick();
                
                if playerSelection == curPlayerName and activeOptionsFrame then
                    activeOptionsFrame:Destroy();
                    activeOptionsFrame = nil;
                else
                    if activeOptionsFrame == nil then
                        activeOptionsFrame = templateOptionFrame:Clone();
                        activeOptionsFrame.Parent = listing.Parent;
                    end
                    local listLayout = activeOptionsFrame:WaitForChild("UIListLayout");
                    
                    activeOptionsFrame.Size = UDim2.new(1, 0, 0, 0);
                    activeOptionsFrame.LayoutOrder = listing.LayoutOrder > 0 and listing.LayoutOrder or listing.LayoutOrder+1;
                    for _, obj in pairs(activeOptionsFrame:GetChildren()) do
                        if obj:IsA("GuiObject") then
                            obj:Destroy();
                        end
                    end
                    
                    local optionsCount = 0;
                    local function newOptionButton(create, label, onClick)
                        if not create then return end;
                        optionsCount = optionsCount +1;
                        
                        local new = templateOptionButton:Clone();
                        local buttonText = new:WaitForChild("buttonText");
                        buttonText.Text = label;
                        new.Parent = activeOptionsFrame;
                        
                        new.MouseButton1Click:Connect(function()
                            interface:PlayButtonClick();
                            if onClick then
                                onClick(new);
                            end
                            if activeOptionsFrame then
                                activeOptionsFrame:Destroy();
                            end
                            activeOptionsFrame = nil;
                        end)
                    end
                    
                    local isInGame = game.Players:FindFirstChild(curPlayerName) ~= nil;
                    
                    newOptionButton(
                        curPlayerName ~= localPlayer.Name and isInGame,
                        "Invite to Trade",
                        function()
                            remoteTradeRequest:FireServer("request", curPlayerName);
                    end)
                    newOptionButton(
                        curPlayerName ~= localPlayer.Name and isInGame
                        and getInvitationFrom("TradeInvite", curPlayerName) ~= nil,
                        "Accept Trade Request",
                        function()
                            local tradeInvitePacket = getInvitationFrom("TradeInvite", curPlayerName);
                            tradeInvitePacket._hide = tradeInvitePacket.AddTime;
                            remoteTradeRequest:FireServer("request", curPlayerName);
                    end)

                    -- Duel options
                    newOptionButton(
                        curPlayerName ~= localPlayer.Name and isInGame,
                        "Invite to Duel",
                        function()
                            remoteDuelRequest:FireServer("request", curPlayerName);
                    end)
                    newOptionButton(
                        curPlayerName ~= localPlayer.Name and isInGame 
                        and getInvitationFrom("DuelInvite", curPlayerName) ~= nil,
                        "Accept Duel Request",
                        function()
                            local duelInvitePacket = getInvitationFrom("DuelInvite", curPlayerName);
                            duelInvitePacket._hide = duelInvitePacket.AddTime;
                            remoteDuelRequest:FireServer("request", curPlayerName);
                    end)

                    --MARK: Squad Options
                    local squadTeam = modTeamsManager.getTeamByPlayer(localPlayer, "Squad");
                    newOptionButton(
                        curPlayerName ~= localPlayer.Name and (squadTeam == nil or squadTeam:GetMember(curPlayerName) == nil),
                        "Invite to Squad",
                        function()
                            if inviteDebounce[curPlayerName] then return end;
                            inviteDebounce[curPlayerName] = true;
                            task.delay(5, function() inviteDebounce[curPlayerName] = nil; end);

                            remoteTeamsManager:InvokeServer("invitetosquad", curPlayerName);
                    end)
                    newOptionButton(
                        curPlayerName == localPlayer.Name and squadTeam,
                        "Leave Squad",
                        function()
                            remoteTeamsManager:InvokeServer("leavesquad");
                    end)
                    newOptionButton(
                        getInvitationFrom("SquadInvite", curPlayerName) ~= nil,
                        "Join Squad",
                        function()
                            local squadInvitePacket = getInvitationFrom("SquadInvite", curPlayerName);
                            if squadInvitePacket then
                                squadInvitePacket._hide = squadInvitePacket.AddTime;
                                remoteTeamsManager:InvokeServer("joinsquadguid", squadInvitePacket.Id);
                            end
                        end)

                    newOptionButton(
                        curPlayerName ~= localPlayer.Name and modData.MutePlayerNoise[curPlayerName] == nil,
                        "Mute Noise",
                        function()
                            modData.MutePlayerNoise[curPlayerName] = true;
                            modData.RefreshPlayerNoise(curPlayerName);
                        end)
                    newOptionButton(
                        curPlayerName ~= localPlayer.Name and modData.MutePlayerNoise[curPlayerName] ~= nil,
                        "Unmute Noises",
                        function()
                            modData.MutePlayerNoise[curPlayerName] = nil;
                            modData.RefreshPlayerNoise(curPlayerName);
                        end)

                    selectionWorldName = getPlayerWorldName(curPlayerName, selectionWorldName);

                    local travelDisabled;
                    if selectionWorldName ~= shared.WorldName or game.Players:FindFirstChild(curPlayerName) == nil then
                        local worldInfo = modBranchConfigurations.Worlds[selectionWorldName];
                        
                        if worldInfo and worldInfo.CanTravelTo and binds.FriendsList[curPlayerName] then
                            if binds.FriendsList[curPlayerName].SearchedPlayer then
                                newOptionButton(
                                    curPlayerName ~= localPlayer.Name,
                                    "Request to Travel",
                                    function()
                                        if not hasCompletedFirstMission() then return end;
                                        remoteWorldTravelRequest:InvokeServer("TravelRequest", curPlayerName);
                                    end
                                )
                            end
                            
                            if binds.FriendsList[curPlayerName].TravelRequest then
                                newOptionButton(
                                    curPlayerName ~= localPlayer.Name,
                                    "Accept Travel Request",
                                    function()
                                        if not hasCompletedFirstMission() then return end;
                                        remoteWorldTravelRequest:InvokeServer("AcceptTravel", curPlayerName);
                                        binds.FriendsList[curPlayerName] = nil;
                                end)
                                newOptionButton(
                                    curPlayerName ~= localPlayer.Name,
                                    "Deny Travel Request",
                                    function()
                                        for a=#modData.TravelRequests, 1, -1 do
                                            if modData.TravelRequests[a].UserName == curPlayerName then
                                                table.remove(modData.TravelRequests, a);
                                            end
                                        end
                                        binds.FriendsList[curPlayerName] = nil;
                                        window:Update();
                                end)
                                
                            else
                                newOptionButton(
                                    curPlayerName ~= localPlayer.Name and game.Players:FindFirstChild(curPlayerName) == nil,
                                    "Travel to Player",
                                    function()
                                        if travelDisabled and tick()-travelDisabled <= 10 then return end;
                                        interface:PlayButtonClick();

                                        if not hasCompletedFirstMission() then return end;

                                        local promptWindow = modClientGuis.promptQuestion(
                                            "You are about to leave this world",
                                            `Are you sure you want to travel to {modBranchConfigurations.GetWorldDisplayName(selectionWorldName)}?`
                                        );
                                        local YesClickedSignal, NoClickedSignal;
                                        
                                        YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
                                            interface:PlayButtonClick();
                                            promptWindow:Close();
                                            if remoteWorldTravelRequest:InvokeServer("Social", curPlayerName) == true then
                                                travelDisabled = tick();
                                            end
                                            YesClickedSignal:Disconnect();
                                            NoClickedSignal:Disconnect();
                                        end);
                                        NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
                                            interface:PlayButtonClick();
                                            promptWindow:Close();
                                            YesClickedSignal:Disconnect();
                                            NoClickedSignal:Disconnect();
                                        end);
                                    end
                                )
                            end
                        end
                    end
                    
                    if optionsCount > 0 then
                        activeOptionsFrame:TweenSize(UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y+10), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25);
                    else
                        activeOptionsFrame.Size = UDim2.new(1, 0, 0, 0);
                    end
                end
                binds.SelectPlayer(curPlayerName, true);
            end)
        end
        local avatarLabel = listing:WaitForChild("Avatar");
        local nameLabel = listing:WaitForChild("NameTag");
        local levelIcon = listing:WaitForChild("LevelIcon");
        local locationLabel = listing:WaitForChild("LocationTag");
        local titleLabel = listing:WaitForChild("TitleTag");
        local healthBar = listing:WaitForChild("HealthBar"):WaitForChild("Bar");

        local alertsFrame = avatarLabel:WaitForChild("playerAlerts");
        local tradeRequestIcon = alertsFrame:WaitForChild("tradeRequestIcon");
        local squadRequestIcon = alertsFrame:WaitForChild("squadRequestIcon");
        local duelRequestIcon = alertsFrame:WaitForChild("duelRequestIcon");

        tradeRequestIcon.Visible = getInvitationFrom("TradeInvite", curPlayerName) ~= nil;
        squadRequestIcon.Visible = getInvitationFrom("SquadInvite", curPlayerName) ~= nil;
        duelRequestIcon.Visible = getInvitationFrom("DuelInvite", curPlayerName) ~= nil;

        local function update()
            local playerData = modData.Players[curPlayerName];
            
            nameLabel.Text = curPlayerName;
            avatarLabel.Image = playerData and playerData.Avatar or "";
            
            local thatPlayer = game.Players:FindFirstChild(curPlayerName);
            if thatPlayer then
                locationLabel.Visible = false;
                titleLabel.Visible = true;

                local playerTitleTag = thatPlayer:FindFirstChild("PlayerTitleTag");
                if playerTitleTag and playerData then
                    playerData.TitleId = playerTitleTag.Value;
                end

                local titleLib = modPlayerTitlesLibrary:Find(playerData and playerData.TitleId or "");
                if titleLib then
                    titleLabel.Text = titleLib.Title;

                    if titleLib.TitleStyle then
                        titleLabel.TextColor3 = titleLib.TitleStyle.TextColor3 or titleLabel.TextColor3;
                        titleLabel.TextStrokeColor3 = titleLib.TitleStyle.TextStrokeColor3 or titleLabel.TextStrokeColor3;
                    end
                else
                    titleLabel.Text = "No Title";
                end
            else
                -- not ingame
                locationLabel.Visible = true;
                titleLabel.Visible = false;

                local worldName = listingData.WorldId
                    or (listingData.PlaceId and modBranchConfigurations.GetWorldName(listingData.PlaceId))
                    or (playerData and (playerData.PlaceId and modBranchConfigurations.GetWorldName(playerData.PlaceId)
                                        or playerData.WorldName));

                local worldDisplayName = modBranchConfigurations.GetWorldDisplayName(worldName);
                if worldDisplayName == "Unknown World" then
                    binds.ActivePlayerListing[curPlayerName] = nil;
                    game.Debris:AddItem(listing, 0);
                else
                    locationLabel.Text = worldDisplayName;
                end
            end

            if playerData then
                if playerData.Role == "Founder" then
                    nameLabel.TextColor3 = Color3.fromRGB(231,186,115);
                elseif playerData.GroupRank and playerData.GroupRank >= 200 then
                    nameLabel.TextColor3 = Color3.fromRGB(206,107,225);
                else
                    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
                end

                if playerData.Stats and playerData.Stats.Level then
                    levelIcon.Visible = true;
                    modLevelBadge:Update(levelIcon, playerData.Stats.Level);
                end
                if playerData.Health and playerData.MaxHealth then
                    healthBar.Size = UDim2.new(1, 0, math.clamp(playerData.Health/playerData.MaxHealth, 0, 1), 0);
                end
            else
                levelIcon.Visible = false;
            end
        end

        update();

        return listing;
    end

    local debounce = false;
    -- MARK: OnUpdate
    window.OnUpdate:Connect(function()
        if debounce or list.Parent == nil then return end;
        debounce = true;

        local serverPlayers = game.Players:GetPlayers();
        local totalFriends = 0;
        local onlineFriends = 0;
        
        local updated = {};
        
        for _, friendData in pairs(binds.FriendsList) do
            totalFriends += 1;
            if friendData.InUniverse then
                onlineFriends += 1;
            end
        end
        
        local serverTab = list:FindFirstChild("ServerTab");
        if serverTab == nil then
            local new = friendsTabTemplate:Clone();
            new.Name = "ServerTab";
            new.Parent = list;
            serverTab = new;
        end
        local serverTabLabel = serverTab.Labeltag;
        
        --== Players;
        local playersOrder = onlineFriends+3;
        for _, player in pairs(serverPlayers) do
            if binds.FriendsList[player.Name] == nil or not binds.FriendsList[player.Name].InUniverse then
                playersOrder = playersOrder +1;
                
                local listing = UpdateListing{
                    Name = player.Name;
                    UserId = player.UserId;
                    Avatar = CacheAvatar(player.Name, player.UserId);
                };
                if player.Name == localPlayer.Name then
                    listing.LayoutOrder = 1;
                else
                    listing.LayoutOrder = playersOrder+1;
                end
                updated[player.Name] = true;
            end
        end
        serverTabLabel.Text = `Players Online ({#serverPlayers}/{game.Players.MaxPlayers})`;
        
        --== Friends;
        local friendsTab = list:FindFirstChild("FriendsTab");
        if friendsTab == nil then
            local new = friendsTabTemplate:Clone();
            new.LayoutOrder = 2;
            new.Parent = list;
            friendsTab = new;
        end

        local friendIndex = 2;
        for userName, friendData in pairs(binds.FriendsList) do
            if not friendData.InUniverse then continue end;

            friendIndex += 1;

            local listing = UpdateListing{
                Name = userName;
                Avatar = friendData.Avatar or CacheAvatar(userName);
                PlaceId = friendData.PlaceId;
            };
            listing.LayoutOrder = friendIndex;

            updated[userName] = true;
        end

        serverTab.LayoutOrder = friendIndex+1;
        local friendsTabLabel = friendsTab.Labeltag; -- inf yield
        friendsTabLabel.Text = `Friends Online ({onlineFriends}/{totalFriends})`;
        friendsTab.Visible = onlineFriends > 0;
        
        --== Squads;
        local squadTeam = modTeamsManager.getTeamByPlayer(localPlayer, "Squad");
        if squadTeam then
            local squadTab = list:FindFirstChild("SquadTab");
            if squadTab == nil then
                local new = friendsTabTemplate:Clone();
                new.Name = "SquadTab";
                new.LayoutOrder = -10;
                new.Parent = list;
                squadTab = new;
            end
            local squadTabLabel = squadTab.Labeltag;
            local mCount = 0;
            for mName, mData in pairs(squadTeam.Members) do
                mCount += 1;
                
                local listing = UpdateListing{
                    Name = mName;
                    UserId = mData.UserId;
                    Avatar = CacheAvatar(mName, mData.UserId);
                    WorldId = mData.Values.WorldName;
                };
                if mName == localPlayer.Name then
                    listing.LayoutOrder = -9;
                else
                    listing.LayoutOrder = -7;
                end
                updated[mName] = true;
            end
            
            squadTabLabel.Text = `Squad ({mCount}/6)`;
        else
            for _, obj in pairs(list:GetChildren()) do
                if obj:IsA("GuiObject") and obj.Name == "SquadTab" then
                    game.Debris:AddItem(obj, 0);
                end
            end
        end
        
        local showServerTab = false;
        for _, obj in pairs(list:GetChildren()) do
            if obj:IsA("GuiObject") and obj.LayoutOrder > serverTab.LayoutOrder then
                showServerTab = true;
                break;
            end
        end
        serverTab.Visible = showServerTab;

        for name, listing in pairs(binds.ActivePlayerListing) do
            if updated[name] == nil then
                binds.ActivePlayerListing[name] = nil;
                game.Debris:AddItem(listing, 0);
            end
        end
        
        debounce = false;
        
        if not window.Visible then return end;
        task.spawn(function() binds.SelectPlayer(playerSelection, false); end);
    end)

    local function showScrollBars()
        return modData.Settings ~= nil and modData.Settings.ShowScrollbars == 1;
    end

    listUIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.ScrollBarThickness = showScrollBars() and 5 or 0;
        list.CanvasSize = UDim2.new(0, 0, 0, listUIListLayout.AbsoluteContentSize.Y+5);
    end)

    profileDisplayLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local contentOverflows = profileDisplayLayout.AbsoluteContentSize.Y >= profileDisplayList.AbsoluteSize.Y;
        profileDisplayList.UIPadding.PaddingRight = (showScrollBars() and contentOverflows) and UDim.new(0, 15) or UDim.new(0, 0);
        profileDisplayList.ScrollBarThickness = showScrollBars() and 5 or 0;
        profileDisplayList.CanvasSize = UDim2.new(0, 0, 0, profileDisplayLayout.AbsoluteContentSize.Y);
    end)

    profileFrame.BottomBorder:GetPropertyChangedSignal("Visible"):Connect(function()
        profileDisplayList.Size = UDim2.new(1, -10, 1, profileFrame.BottomBorder.Visible and -125 or -55);
    end)

    searchBar:GetPropertyChangedSignal("Text"):Connect(function()
        local filter = searchBar.Text:lower();
        for name, listing in pairs(binds.ActivePlayerListing) do
            listing.Visible = filter == "" or name:lower():match(filter) ~= nil;
        end
    end)

    searchBar.FocusLost:Connect(function(enterPressed)
        if enterPressed and #searchBar.Text > 0 then
            local found = remotePlayerSearch:InvokeServer(searchBar.Text);
            if found then
                table.insert(searchedPlayer, found);
            end
            UpdateApplicableFriends();
            window:Update();
        end
    end)

    local amtFrame = quickButton:WaitForChild("AmtFrame");
    local amtLabel = amtFrame:WaitForChild("AmtLabel");
    interface.Scheduler.OnStepped:Connect(function(tickData: TickData)
        if tickData.ms1000 ~= true then return end;

        if menuFrame.Visible and tickData.s5 then
            UpdateApplicableFriends();
            window:Update();
        end

        local invCount = #getInvitations();
        amtLabel.Text = invCount;
        amtFrame.Visible = invCount > 0;
    end)

    task.spawn(UpdateApplicableFriends);

    interface:BindEvent("UpdateSocialMenu", function()
        if not window.Visible then return end;
        window:Update();
    end)

    --MARK: Mailbox
    local mailBoxButton = menuFrame:WaitForChild("Nav"):WaitForChild("Mailbox");
    mailBoxButton.MouseButton1Click:Connect(function()
        interface:ToggleWindow("Mailbox", true);
    end)

    local mailBoxAmtFrame = mailBoxButton:WaitForChild("AmtFrame");
    local mailBoxAmtLabel = mailBoxAmtFrame:WaitForChild("AmtLabel");
    window.OnToggle:Connect(function()
        local mailCount = #modData.GameSave.Mailbox;
        mailBoxAmtLabel.Text = mailCount > 0 and mailCount or "";
        mailBoxAmtFrame.Visible = mailCount > 0;
    end)
end

return interfacePackage;
