local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");
local BadgeService = game:GetService("BadgeService");
local TweenService = game:GetService("TweenService");


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
}
local THUMBNAIL_TYPE = Enum.ThumbnailType.HeadShot;
local THUMBNAIL_SIZE = Enum.ThumbnailSize.Size420x420;

local interfacePackage = {
    Type = "Player";
};
--==

function interfacePackage.onRequire()
	modKeyBindsHandler:SetDefaultKey("KeyWindowSocialMenu", Enum.KeyCode.G);
end

function interfacePackage.newInstance(interface: InterfaceInstance)
    local remotes = game.ReplicatedStorage.Remotes;
    local remoteWorldTravelRequest = remotes.Interactable.WorldTravelRequest;
    local remoteRequestPublicProfile = modRemotesManager:Get("RequestPublicProfile");
    local remoteProgressMission = modRemotesManager:Get("ProgressMission");
    local remoteSetPlayerTitle = modRemotesManager:Get("SetPlayerTitle");
    local remoteDuelRequest = modRemotesManager:Get("DuelRequest");
    local remoteTradeRequest = modRemotesManager:Get("TradeRequest");
    local remotePlayerSearch = modRemotesManager:Get("PlayerSearch");
    local remoteTeamsManager = modRemotesManager:Get("TeamsManager");
    
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local branchColor = modBranchConfigurations.BranchColor

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

    local invitationsList = {};
    local inviteDebounce = {};


    local playerSelection = localPlayer.Name;
    local selectionWorldName = "TheWarehouse";
    modGlobalVars.AvatarCache = {};

    local titlePinIcon = nil;
    local achievementIndexList = modAchievementLibrary:GetIndexList();
    local badgeButtons = {};
    local searchedPlayer = {};

    local barTemplate = script:WaitForChild("barTemplate");
    local templatebadgeButton = script:WaitForChild("badgeButton");
    local templatePinIcon = script:WaitForChild("PinIcon");

    local templateOptionFrame = script:WaitForChild("Options");
    local templateOptionButton = script:WaitForChild("templateButton");
    local activeOptionsFrame;

    local highlightText = menuFrame:WaitForChild("HighlightText");


    --MARK: Window
	local window: InterfaceWindow = interface:NewWindow("SocialMenu", menuFrame);
    window.BoolStringWhenActive = {String="!Hotbar"; Priority=2;};
	window.CompactFullscreen = true;
    window.CloseWithInteract = true;

	if modConfigurations.CompactInterface then
		window:SetClosePosition(UDim2.new(0.5, 0, -1, 0), UDim2.new(0.5, 0, 0.5, 0));
	else
		window:SetClosePosition(UDim2.new(0.5, 0, -1, 0), UDim2.new(0.5, 0, 0.5, 0));
	end
    
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
        
        menuFrame:WaitForChild("touchCloseButton").Visible = true;
        menuFrame:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
            interface:PlayButtonClick();
            window:Close();
        end)
    end

    local function UpdateApplicableFriends()
        local friends = {};
        local s,e = pcall(function() friends = localPlayer.UserId > 0 and localPlayer:GetFriendsOnline() or {}; end)
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
        
        local IdList = {};
        for a=1, #friends do
            local inUniverse = false;
            if friends[a].LocationType == 1 or friends[a].LocationType == 4 then
                inUniverse = modBranchConfigurations.IsPlaceIdThisGame(friends[a].PlaceId);

            end
            
            local thumbnail = shared.modPlayers.getAvatar(friends[a].VisitorId);
            if binds.FriendsList == nil then return end;

            friends[a].Avatar = thumbnail;
            friends[a].InUniverse = inUniverse;
            table.insert(IdList, friends[a].VisitorId);
            binds.FriendsList[friends[a].UserName] = friends[a];
        end
        
        
        if localPlayer.UserId == -1 then
            local friend = {};
            friend.VisitorId = modGlobalVars.UseRandomId();
            local _thumbnail;
            friend.UserName = "Random1";
            friend.Avatar = "";
            friend.InUniverse = true;
            binds.FriendsList[friend.UserName] = friend;
            
            local friend2 = {};
            friend2.VisitorId = modGlobalVars.UseRandomId();
            local thumbnail2 = shared.modPlayers.getAvatar(friend2.VisitorId);
            friend2.UserName = "Random2";
            friend2.Avatar = thumbnail2;
            friend2.InUniverse = true;
            binds.FriendsList[friend2.UserName] = friend2;
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

    local function CacheAvatar(name, userId)
        if modGlobalVars.AvatarCache[name] then return modGlobalVars.AvatarCache[name]; end;
        if userId then
            if type(userId) == "number" then
                task.spawn(function()
                    pcall(function()
                        modGlobalVars.AvatarCache[name] = game.Players:GetUserThumbnailAsync(userId > 0 
                            and userId or modGlobalVars.UseRandomId(), THUMBNAIL_TYPE, THUMBNAIL_SIZE);
                    end)	
                end)
            else
                modGlobalVars.AvatarCache[name] = userId;
            end
        end
        return modGlobalVars.AvatarCache[name]
    end


    --MARK: Render social profile;
    function binds.SelectPlayer(playerName, refresh)
        playerSelection = playerName;
        profileNameTag.Text = playerName;
        profileAvatarLabel.Image = CacheAvatar(playerName) or "";
        
        if modData.Players[playerName] == nil or refresh then 
            modData.Players[playerName] = remoteRequestPublicProfile:InvokeServer(playerName);
        end;
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
                if playerData.Stats.Level then
                    modLevelBadge:Update(profileLevelLabel, playerData.Stats.Level);
                else
                    modLevelBadge:Update(profileLevelLabel, 0);
                end
                
                local statSort = {
                    Level={Name="Mastery Level"; Index=1; MaxKey="MaxLevels"};
                    Kills={Name="Kills"; Index=3};
                    ZombieKills={Name="Zombie Kills"; Index=31};
                    HumanKills={Name="Human Kills"; Index=32};
                    Death={Name="Death"; Index=40};
                    TweakPoints={Name="Tweak Points"; Index=49};
                    Perks={Name="Perks"; Index=50};
                    Money={Name="Money"; Index=60};
                    MissionsCompleted={Name="Missions Completed"; Index=70};
                    FotlStats={Name="Fall of the Living"; Index=75;};
                    ColorPacks={Name="Color Packs"; Index=80};
                    SkinsPacks={Name="Skin Packs"; Index=90};
                    --TraderRep={Name="Trader Reputation"; Index=100};
                };
                local _enemySort = {
                    ["Zombie"]=1;
                    ["Leaper Zombie"]=2;
                    ["Leaper"]=2;
                    ["Ticks Zombie"]=3;
                    ["Ticks"]=3;
                    ["Heavy Zombie"]=4;
                    ["Heavy"]=4;
                    
                    ["Bandit"]=1;
                    
                    ["The Prisoner"]=10;
                    ["Tanker"]=11;
                    ["Fumes"]=12;
                    ["Corrosive"]=13;
                    ["Zpider"]=14;
                    ["Shadow"]=15;
                    ["Zomborg"]=16;
                    ["Karl"]=18;
                    ["Kylde"]=19;
                    ["Hector Shot"]=20;
                    ["Zricera"]=21;
                    ["Vexeron"]=22;
                }
                
                local statStringTable = {};
                local statCache = {};
                
                if RunService:IsStudio() then
                    table.insert(statCache, {Index=99; String=`<b>Gameplay Points</b>: <font size="12">{interface.beautifyNumber(playerData.PlayPoints)}</font>`});
                end

                if playerData.Punishment and playerData.Punishment > 0 then
                    table.insert(statCache, {Index=-5; String=`<b>Punished</b>: <font size="12"> {modGlobalVars.Punishments[playerData.Punishment]}</font>`});
                end
                
                for k, v in pairs(playerData.Stats) do
                    local lib = statSort[k];
                    
                    local statKey = tostring(lib and lib.Name or k) or "";
                    local statValue = tostring(v) or "";


                    if k == "FotlStats" then
                        Debugger:StudioLog(`FotlStats`, v);
                    end
                    if typeof(v) == "number" then
                        statValue = interface.beautifyNumber(v);

                        local maxVal = modGlobalVars[lib and lib.MaxKey or `Max{k}`];
                        if maxVal and v >= maxVal then
                            statValue = `{statValue} <font size="9"><b>(Maxed)</b></font>`;
                        end
                    end
                    
                    local s = `<b>{statKey}</b>: <font size="12">{statValue}</font>`;

                    if lib then
                        table.insert(statCache, {Index=(lib and lib.Index or 999); String=s});
                    end
                end
                table.sort(statCache, function(A, B) return A.Index < B.Index; end)
                for a=1, #statCache do
                    table.insert(statStringTable, statCache[a].String);
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
            
            if playerData.Stats.FocusLevel and playerData.Stats.Level then
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
                    totalKills = totalKills + killsNeeded;
                    label.Text = ("L$focusLevel: $killsNeeded"):gsub("$focusLevel",tostring(lvl)):gsub("$killsNeeded", killsNeeded);
                    
                    table.insert(barFrames, {Bar=barFrame; Amount=killsNeeded});
                    table.insert(levelSort, {Bar=barFrame; Level=lvl;});
                end
                table.sort(barFrames, function(A, B) return A.Amount < B.Amount end)
                table.sort(levelSort, function(A, B) return A.Level > B.Level end)

                
                for a=1, #barFrames do
                    local barFrame = barFrames[a].Bar;
                    
                    barFrame.LayoutOrder = a;
                    barFrame.Size = UDim2.new(math.clamp(barFrames[a].Amount/totalKills, 0, 1) , 0, 1, 0);
                    
                    barFrame.Visible = true;
                end
                for a=1, #levelSort do
                    local barFrame = barFrames[a].Bar;
                    if a == 1 then
                        barFrame.BackgroundColor3 = Color3.fromRGB(89, 89, 89);
                    elseif a == 2 then
                        barFrame.BackgroundColor3 = Color3.fromRGB(51, 102, 204);
                    elseif a == 3 then
                        barFrame.BackgroundColor3 = Color3.fromRGB(101, 59, 169);
                    elseif a == 4 then
                        barFrame.BackgroundColor3 = Color3.fromRGB(165, 59, 168);
                    end
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
                profileDisplayList.collectionProfile.label.Text = ("Collectibles doesn't have any affect on gameplay. ($f/$t)"):gsub("$f", noOfFound):gsub("$t", total);
                profileDisplayList.collectionProfile.foundLabel.Text = "Found:\n".. table.concat(found, "\n");
                profileDisplayList.collectionProfile.notfoundLabel.Text = ":Not Found\n".. table.concat(notFound, "\n");
                local txtBoundFound = TextService:GetTextSize(profileDisplayList.collectionProfile.foundLabel.Text,
                                                                profileDisplayList.collectionProfile.foundLabel.TextSize,
                                                                profileDisplayList.collectionProfile.foundLabel.Font,
                                                                Vector2.new(250, 1000))
                local txtBoundUnfound = TextService:GetTextSize(profileDisplayList.collectionProfile.notfoundLabel.Text,
                                                                profileDisplayList.collectionProfile.notfoundLabel.TextSize,
                                                                profileDisplayList.collectionProfile.notfoundLabel.Font,
                                                                Vector2.new(250, 1000))
                local ySize = txtBoundFound.Y > txtBoundUnfound.Y and txtBoundFound.Y or txtBoundUnfound.Y;
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
                    
                    local new = badgeButtons[lib.Id] or templatebadgeButton:Clone();
                    
                    if lib.Id == playerData.TitleId then
                        if titlePinIcon == nil or titlePinIcon.Parent == nil then
                            titlePinIcon = templatePinIcon:Clone();
                        end
                        
                        titlePinIcon.Parent = new;
                        titlePinIcon.Visible = true;
                    end
                    
                    if badgeButtons[lib.Id] == nil and new then
                        new.MouseMoved:Connect(function()
                            if lib.BadgeInfo == nil then return end;
                            
                            local position = new.AbsolutePosition-menuFrame.AbsolutePosition;
                            highlightText.Position = UDim2.new(0, position.X+40, 0, position.Y+65);
                            
                            if lib.Tier == modAchievementLibrary.Tiers.Bronze then
                                highlightText.ImageColor3 = HIGHLIGHT_COLORS.Bronze;
                            elseif lib.Tier == modAchievementLibrary.Tiers.Silver then
                                highlightText.ImageColor3 = HIGHLIGHT_COLORS.Silver;
                            elseif lib.Tier == modAchievementLibrary.Tiers.Gold then
                                highlightText.ImageColor3 = HIGHLIGHT_COLORS.Gold;
                            elseif lib.Tier == modAchievementLibrary.Tiers.Diamond then
                                highlightText.ImageColor3 = HIGHLIGHT_COLORS.Diamond;
                            else
                                highlightText.ImageColor3 = HIGHLIGHT_COLORS.Black;
                            end
                            
                            highlightText.titleTag.Text = lib.BadgeInfo.Name;
                            highlightText.descTag.Text = lib.BadgeInfo.Description
                            
                            if lib.Tier and lib.Tier.Perks then
                                highlightText.descTag.Text = highlightText.descTag.Text.."\nReward: +"..lib.Tier.Perks.." Perks";
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
                                    game:GetService("GroupService"):PromptJoinAsync(4573862);
                                end

                                return
                            end;
                            
                            if equipTitleDebounce then return end
                            equipTitleDebounce = true;
                            setTitleClick();
                            equipTitleDebounce = false;
                        end)
                        
                        if (RunService:IsStudio()) then
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
                    new.ImageColor3 = owned and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25);
                    

                    if lib.Hidden and owned == nil then
                        new.Visible = false;
                    else
                        new.Visible = true;
                    end

                    
                    new.Parent = profileDisplayList.achievements.ScrollingFrame;
                end
                pcall(function()
                    task.spawn(function()
                        profileDisplayList.achievements.Size = UDim2.new(
                            1, 
                            0, 
                            0, 
                            profileDisplayList.achievements.ScrollingFrame.UIGridLayout.AbsoluteContentSize.Y+130
                        );
                    end)
                end)
            else
                profileDisplayList.achievements.Visible = false;
            end
            
            if playerData.Statistics and next(playerData.Statistics) ~= nil then
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
        
        selectionWorldName = shared.WorldName;

        local squadTeam = modTeamsManager.getTeamByPlayer(localPlayer, "Squad");
        if squadTeam and squadTeam.Members[playerName] then
            selectionWorldName = (squadTeam.Members[playerName].Values.WorldName or "Unknown");
        elseif binds.FriendsList and binds.FriendsList[playerName] and binds.FriendsList[playerName].InUniverse then
            selectionWorldName = (modBranchConfigurations.GetWorldName(binds.FriendsList[playerName].PlaceId) or "Unknown");
        end
        profileLocationLabel.Text = (selectionWorldName and modBranchConfigurations.GetWorldDisplayName(selectionWorldName) or "Unknown");
        
    end


    local function UpdateListing(data)
        local curPlayerName = data.Name;
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
                        and getInvitationFrom("TradeInvite", curPlayerName),
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
                            
                            local rPacket = remoteTeamsManager:InvokeServer("invitetosquad", curPlayerName);
                    end)
                    newOptionButton(
                        curPlayerName == localPlayer.Name and squadTeam,
                        "Leave Squad",
                        function(button)
                            local rPacket = remoteTeamsManager:InvokeServer("leavesquad");
                    end)
                    newOptionButton(
                        getInvitationFrom("SquadInvite", curPlayerName) ~= nil,
                        "Join Squad",
                        function()
                            local squadInvitePacket = getInvitationFrom("SquadInvite", curPlayerName);
                            if squadInvitePacket then
                                squadInvitePacket._hide = squadInvitePacket.AddTime;
                                local teamGuid = squadInvitePacket.Id;
                                local rPacket = remoteTeamsManager:InvokeServer("joinsquadguid", teamGuid);
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
                    
                    
                    if squadTeam and squadTeam.Members[curPlayerName] then
                        selectionWorldName = (squadTeam.Members[curPlayerName].Values.WorldName or "Unknown");
                    elseif binds.FriendsList and binds.FriendsList[curPlayerName] and binds.FriendsList[curPlayerName].InUniverse then
                        selectionWorldName = (modBranchConfigurations.GetWorldName(binds.FriendsList[curPlayerName].PlaceId) or "Unknown");
                    end
                    
                    local travelDisabled = false;
                    if selectionWorldName ~= modBranchConfigurations.WorldName or game.Players:FindFirstChild(curPlayerName) == nil then
                        local worldInfo = modBranchConfigurations.Worlds[selectionWorldName];
                        if worldInfo and worldInfo.CanTravelTo and binds.FriendsList[curPlayerName] then
                            if binds.FriendsList[curPlayerName].SearchedPlayer then
                                newOptionButton(
                                    curPlayerName ~= localPlayer.Name,
                                    "Request to Travel",
                                    function()
                                        if mission1Data == nil or mission1Data.Type ~= 3 then
                                            modClientGuis.promptWarning("Please complete the first mission.");
                                            return;
                                        end
                                        remoteWorldTravelRequest:InvokeServer("TravelRequest", curPlayerName)
                                    end
                                )
                                
                            elseif binds.FriendsList[curPlayerName].TravelRequest then
                                newOptionButton(
                                    curPlayerName ~= localPlayer.Name,
                                    "Accept Travel Request",
                                    function()
                                        if mission1Data == nil or mission1Data.Type ~= 3 then
                                            modClientGuis.promptWarning("Please complete the first mission.");
                                            return;
                                        end
                                        remoteWorldTravelRequest:InvokeServer("AcceptTravel", curPlayerName)
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
                                        if travelDisabled then return end;
                                        interface:PlayButtonClick();
                                        if mission1Data == nil or mission1Data.Type ~= 3 then
                                            modClientGuis.promptWarning("Please complete the first mission.");
                                            return;
                                        end
                                        
                                        local promptWindow = modClientGuis.promptQuestion("You are about to leave this world",
                                            "Are you sure you want to travel to ".. modBranchConfigurations.GetWorldDisplayName(selectionWorldName) .."?");
                                        local YesClickedSignal, NoClickedSignal;
                                        
                                        YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
                                            interface:PlayButtonClick();
                                            promptWindow:Close();
                                            if remoteWorldTravelRequest:InvokeServer("Social", curPlayerName) == true then
                                                travelDisabled = true;
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
                                end)
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
        local healthBarFrame = listing:WaitForChild("HealthBar");
        local healthBar = healthBarFrame:WaitForChild("Bar");
        
        local alertsFrame = avatarLabel:WaitForChild("playerAlerts");
        local tradeRequestIcon = alertsFrame:WaitForChild("tradeRequestIcon");
        local squadRequestIcon = alertsFrame:WaitForChild("squadRequestIcon");
        local duelRequestIcon = alertsFrame:WaitForChild("duelRequestIcon");
        
        if getInvitationFrom("TradeInvite", curPlayerName) then
            tradeRequestIcon.Visible = true;
        else
            tradeRequestIcon.Visible = false;
        end
        
        if getInvitationFrom("SquadInvite", curPlayerName) then
            squadRequestIcon.Visible = true;
        else
            squadRequestIcon.Visible = false;
        end
        
        if getInvitationFrom("DuelInvite", curPlayerName) then
            duelRequestIcon.Visible = true;
        else
            duelRequestIcon.Visible = false;
        end
        
        local function update()
            local playerData = modData.Players[curPlayerName];
            
            nameLabel.Text = curPlayerName;
            avatarLabel.Image = data.Avatar or "";
            
            local thatPlayer = game.Players:FindFirstChild(curPlayerName);
            if thatPlayer then
                --healthBarFrame.Visible = true;
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
                        if titleLib.TitleStyle.TextColor3 then
                            titleLabel.TextColor3 = titleLib.TitleStyle.TextColor3;
                        end
                        if titleLib.TitleStyle.TextStrokeColor3 then
                            titleLabel.TextStrokeColor3 = titleLib.TitleStyle.TextStrokeColor3;
                        end
                    end
                else
                    titleLabel.Text = "No Title"
                end
            else
                --healthBarFrame.Visible = false;
                locationLabel.Visible = true;
                titleLabel.Visible = false;
                local worldName = data.PlaceId and modBranchConfigurations.GetWorldName(data.PlaceId) or data.WorldName;
                locationLabel.Text = modBranchConfigurations.GetWorldDisplayName(worldName) or "Unknown";
            end
            if modData.Players[curPlayerName] then
                if playerData.Role then
                    if playerData.Role == "Founder" then
                        nameLabel.TextColor3 = Color3.fromRGB(231,186,115);
                        
                    elseif playerData.GroupRank >= 200 then
                        nameLabel.TextColor3 = Color3.fromRGB(206,107,225);
                        
                    end
                else
                    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
                end
                modData.Players[curPlayerName].Avatar = data.Avatar;
                
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
        if debounce then return end;
        debounce = true;
        if list.Parent == nil then return end;
        
        local players = game.Players:GetPlayers();
        local totalFriends = 0;
        local onlineFriends = 0;
        
        local updated = {};
        
        for userName, friendData in pairs(binds.FriendsList) do
            totalFriends = totalFriends+1;
            if friendData.InUniverse then onlineFriends = onlineFriends +1; end
        end
        
        local serverTab = list:FindFirstChild("ServerTab");
        if serverTab == nil then
            local new = friendsTabTemplate:Clone();
            new.Name = "ServerTab";
            new.LayoutOrder = onlineFriends+3;
            new.Parent = list;
            serverTab = new;
        end
        local serverTabLabel = serverTab.Labeltag;
        
        --== Players;
        local playersOrder = onlineFriends+3;
        for _,player in pairs(players) do
            if binds.FriendsList[player.Name] == nil or not binds.FriendsList[player.Name].InUniverse then
                playersOrder = playersOrder +1;
                
                local listing = UpdateListing{
                    Name=player.Name;
                    Avatar=CacheAvatar(player.Name, player.UserId);
                };
                if player.Name == localPlayer.Name then
                    listing.LayoutOrder = 1;
                else
                    listing.LayoutOrder = playersOrder+1;
                end
                updated[player.Name] = true;
            end
        end
        serverTabLabel.Text = "Players Online ("..#players.."/".. game.Players.MaxPlayers ..")";
        
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
            if friendData.InUniverse then 
                friendIndex = friendIndex +1;
                local listing = UpdateListing{
                    Name=userName;
                    Avatar=CacheAvatar(userName, friendData.Avatar);
                    PlaceId=friendData.PlaceId;
                };
                listing.LayoutOrder = friendIndex;
                updated[userName] = true;
            end
        end
        serverTab.LayoutOrder = friendIndex+1;
        local friendsTabLabel = friendsTab.Labeltag; -- inf yield
        friendsTabLabel.Text = "Friends Online ("..onlineFriends.."/"..totalFriends..")";
        if onlineFriends > 0 then
            friendsTab.Visible = true;
        else
            friendsTab.Visible = false;
        end
        
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
            local socialTabLabel = squadTab.Labeltag;
            local mCount = 0;
            for mName, mData in pairs(squadTeam.Members) do
                mCount += 1;
                
                local listing = UpdateListing{
                    Name = mName;
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
            
            socialTabLabel.Text = `Squad ({mCount}/6)`;
        else
            for _, obj in pairs(list:GetChildren()) do
                if obj:IsA("GuiObject") and obj.Name == "SquadTab" then
                    game.Debris:AddItem(obj, 0);
                end
            end
        end
        
        local showServerTab = false;
        for _, obj in pairs(list:GetChildren()) do
            if obj:IsA("GuiObject") then
                if obj.LayoutOrder > serverTab.LayoutOrder then
                    serverTab.Visible = true;
                    showServerTab = true;
                end
            end
        end
        if not showServerTab then serverTab.Visible = false; end;
        
        for name, listing in pairs(binds.ActivePlayerListing) do
            if updated[name] == nil then
                binds.ActivePlayerListing[name] = nil;
                game.Debris:AddItem(listing, 0);
            end
        end
        
        debounce = false;
        task.spawn(function() binds.SelectPlayer(playerSelection, false); end);
    end)


    listUIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local showScrollBars = modData.Settings and modData.Settings.ShowScrollbars == 1 or false;
        
        if showScrollBars then
            list.ScrollBarThickness = 5;
        else
            list.ScrollBarThickness = 0;
        end
        list.CanvasSize = UDim2.new(0, 0, 0, listUIListLayout.AbsoluteContentSize.Y+5);
    end)

    profileDisplayLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local showScrollBars = modData.Settings and modData.Settings.ShowScrollbars == 1 or false;
        
        if showScrollBars then
            profileDisplayList.UIPadding.PaddingRight = profileDisplayLayout.AbsoluteContentSize.Y >= profileDisplayList.AbsoluteSize.Y and UDim.new(0, 15) or UDim.new(0, 0);
            profileDisplayList.ScrollBarThickness = 5;
        else
            profileDisplayList.UIPadding.PaddingRight = UDim.new(0, 0);
            profileDisplayList.ScrollBarThickness = 0;
        end
        profileDisplayList.CanvasSize = UDim2.new(0, 0, 0, profileDisplayLayout.AbsoluteContentSize.Y);
    end)

    profileFrame.BottomBorder:GetPropertyChangedSignal("Visible"):Connect(function()
        profileDisplayList.Size = UDim2.new(1, -10, 1, profileFrame.BottomBorder.Visible and -125 or -55)
    end)

    searchBar:GetPropertyChangedSignal("Text"):Connect(function()
        if #searchBar.Text > 0 then
            for name, listing in pairs(binds.ActivePlayerListing) do
                listing.Visible = name:lower():match(searchBar.Text:lower()) ~= nil;
            end
        else
            for name, listing in pairs(binds.ActivePlayerListing) do
                listing.Visible = true;
            end
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
    local navBar = menuFrame:WaitForChild("Nav");
    
    local mailBoxButton = navBar:WaitForChild("Mailbox");
    mailBoxButton.MouseButton1Click:Connect(function()
        interface:ToggleWindow("Mailbox", true);
    end)
    window.OnToggle:Connect(function()
        local amtFrame = mailBoxButton:WaitForChild("AmtFrame");
        local amtLabel = amtFrame:WaitForChild("AmtLabel");
        amtLabel.Text = #modData.GameSave.Mailbox > 0 and #modData.GameSave.Mailbox or "";
        amtFrame.Visible = #modData.GameSave.Mailbox > 0;
    end)

end

return interfacePackage;

