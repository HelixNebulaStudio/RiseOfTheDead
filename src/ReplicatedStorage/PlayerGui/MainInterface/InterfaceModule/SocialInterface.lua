local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};
Interface.__index = Interface;
Interface.FriendsList = {};
Interface.ActivePlayerListing = {};

local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");
local BadgeService = game:GetService("BadgeService");

local localplayer = game.Players.LocalPlayer;

local menu = script.Parent.Parent:WaitForChild("SocialMenu");

local highlightColors = {
	Black = Color3.fromRGB(25, 25, 25);
	Bronze = Color3.fromRGB(80, 47, 20);
	Silver = Color3.fromRGB(116, 116, 116);
	Gold = Color3.fromRGB(116, 96, 24);
	Diamond = Color3.fromRGB(77, 142, 143);
}

local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));
local modRemotesManager = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modLevelBadge = require(game.ReplicatedStorage.Library.LevelBadge);
local modAchievementLibrary = require(game.ReplicatedStorage.Library.AchievementLibrary);
local modCollectiblesLibrary = require(game.ReplicatedStorage.Library.CollectiblesLibrary);
local modPlayerTitlesLibrary = require(game.ReplicatedStorage.Library.PlayerTitlesLibrary);
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local branchColor = modBranchConfigs.BranchColor

if modConfigurations.CompactInterface then
	menu.Position = UDim2.new(0.5, 0, 0.5, 0);
	menu.Size = UDim2.new(1, 0, 1, 0);
	menu:WaitForChild("UICorner"):Destroy();
	
	menu:WaitForChild("touchCloseButton").Visible = true;
	menu:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("SocialMenu");
	end)
end

local friendsTabTemplate = script:WaitForChild("FriendsTab");
local emptyTabTemplate = script:WaitForChild("EmptyTab");
local playerListingTemplate = script:WaitForChild("PlayerListing");

local list = menu:WaitForChild("LeftBackground"):WaitForChild("List");
local listUIListLayout = list:WaitForChild("UIListLayout");

local profileFrame = menu:WaitForChild("RightBackground");
local profileNameTag = profileFrame:WaitForChild("NameTag");
local profileTitleTag = profileFrame:WaitForChild("TitleTag");

local squadOptionsFrame = profileFrame:WaitForChild("SquadOptions");
local squadInviteButton = squadOptionsFrame:WaitForChild("InviteButton");
local squadJoinButton = squadOptionsFrame:WaitForChild("JoinButton");
local squadLeaveButton = squadOptionsFrame:WaitForChild("LeaveButton");
local squadTitleLabel = profileFrame:WaitForChild("SquadLabel");
local profileAvatarLabel = profileFrame:WaitForChild("Avatar");
local profileLevelLabel = profileFrame:WaitForChild("LevelIcon");
local profileTravelButton = profileFrame:WaitForChild("TravelButton");
local profileDisplayList = profileFrame:WaitForChild("ProfileFrame");
local profileDisplayLayout = profileDisplayList:WaitForChild("UIListLayout");
local profileLocationLabel = profileFrame:WaitForChild("LocationTag");

local searchBar = menu:WaitForChild("SearchBar"):WaitForChild("nameInput");

local remotes = game.ReplicatedStorage.Remotes;
local remoteWorldTravelRequest = remotes.Interactable.WorldTravelRequest;
local remoteSquadService = modRemotesManager:Get("SquadService");
local remoteOnInvitationsUpdate = modRemotesManager:Get("OnInvitationsUpdate");
local remoteRequestPublicProfile = modRemotesManager:Get("RequestPublicProfile");
local remoteProgressMission = modRemotesManager:Get("ProgressMission");
local remoteSetPlayerTitle = modRemotesManager:Get("SetPlayerTitle");
local remoteDuelRequest = modRemotesManager:Get("DuelRequest");
local remoteTradeRequest = modRemotesManager:Get("TradeRequest");
local remotePlayerSearch = modRemotesManager:Get("PlayerSearch");

local invitationsList = {};
local inviteDebounce = {};
local defaultButtonColor = Color3.fromRGB(255, 255, 255);

local thumbnailType = Enum.ThumbnailType.HeadShot;
local thumbnailSize = Enum.ThumbnailSize.Size420x420;

local barTemplate = script:WaitForChild("barTemplate");
local templatebadgeButton = script:WaitForChild("badgeButton");
local templatePinIcon = script:WaitForChild("PinIcon");

local templateOptionFrame = script:WaitForChild("Options");
local templateOptionButton = script:WaitForChild("templateButton");
local activeOptionsFrame;

local highlightText = menu:WaitForChild("HighlightText");

local playerSelection = localplayer.Name;
local selectionWorldName = "TheWarehouse";
modGlobalVars.AvatarCache = {};

local titlePinIcon = nil;
local achievementIndexList = modAchievementLibrary:GetIndexList();
local badgeButtons = {};
local searchedPlayer = {};
--== Script;

function UpdateApplicableFriends()
	local friends = {};
	local s,e = pcall(function() friends = localplayer.UserId > 0 and localplayer:GetFriendsOnline() or {}; end)
	if not s then warn(e) end;
	
	Interface.FriendsList = {};
	
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
			for worldName, worldId in pairs(modBranchConfigs.CurrentBranch.Worlds) do
				if worldId == friends[a].PlaceId then
					inUniverse = true;
					break;
				end
			end
		end
		local thumbnail, loaded;
		pcall(function() thumbnail, loaded = game.Players:GetUserThumbnailAsync(friends[a].VisitorId, thumbnailType, thumbnailSize); end)
		friends[a].Avatar = thumbnail;
		friends[a].InUniverse = inUniverse;
		table.insert(IdList, friends[a].VisitorId);
		Interface.FriendsList[friends[a].UserName] = friends[a];
	end
	
	
	if localplayer.UserId == -1 then
		local friend = {};
		friend.VisitorId = modGlobalVars.UseRandomId();
		local thumbnail, loaded;
		friend.UserName = "Random1";
		friend.Avatar = "";
		friend.InUniverse = true;
		Interface.FriendsList[friend.UserName] = friend;
		
		local friend = {};
		friend.VisitorId = modGlobalVars.UseRandomId();
		local thumbnail, loaded = game.Players:GetUserThumbnailAsync(friend.VisitorId, thumbnailType, thumbnailSize);
		friend.UserName = "Random2";
		friend.Avatar = thumbnail;
		friend.InUniverse = true;
		Interface.FriendsList[friend.UserName] = friend;
	end
end

local function getInvitationFrom(name)
	for a=1, #invitationsList do
		local invitation = invitationsList[a];
		if invitation.Name == name and invitation.Type == "Squad" then
			return invitation;
		end
	end
end

local invRemoteConn = remoteOnInvitationsUpdate.OnClientEvent:Connect(function(invitations)
	invitationsList = invitations or {};
	for a=1, #invitationsList do
		modData.SquadRequests[invitationsList[a].Name] = tick();
	end
end)

local function CacheAvatar(name, userId)
	if modGlobalVars.AvatarCache[name] then return modGlobalVars.AvatarCache[name]; end;
	if userId then
		if type(userId) == "number" then
			spawn(function()
				pcall(function()
					modGlobalVars.AvatarCache[name] = game.Players:GetUserThumbnailAsync(userId > 0 
						and userId or modGlobalVars.UseRandomId(), thumbnailType, thumbnailSize);
				end)	
			end)
		else
			modGlobalVars.AvatarCache[name] = userId;
		end
	end
	return modGlobalVars.AvatarCache[name]
end

local function SelectPlayer(playerName, refresh)
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
				Level={Name="Mastery Level"; Index=1};
				Kills={Name="Kills"; Index=3};
				ZombieKills={Name="Zombie Kills"; Index=31};
				HumanKills={Name="Human Kills"; Index=32};
				Death={Name="Death"; Index=40};
				Perks={Name="Perks"; Index=50};
				Money={Name="Money"; Index=60};
				MissionsCompleted={Name="Missions Completed"; Index=70};
				ColorPacks={Name="Color Packs"; Index=80};
				SkinsPacks={Name="Skin Packs"; Index=90};
				TraderRep={Name="Trader Reputation"; Index=100};
			};
			local enemySort = {
				["Zombie"]=1;
				["Leaper Zombie"]=2;
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
			
			local enemyTypes = {};
			local statStringTable = {};
			local statCache = {};
			
			if playerData.Punishment and playerData.Punishment > 0 then
				table.insert(statCache, {Index=-5; String="Punished: "..modGlobalVars.Punishments[playerData.Punishment]});
			end
			
			for k, v in pairs(playerData.Stats) do
				local lib = statSort[k];
				
				local statKey = tostring(lib and lib.Name or k) or "";
				local statValue = tostring(v) or "";
				
				local s = statKey..": "..statValue;
				--(("$Stat: $Value"):gsub("$Stat", statKey):gsub("$Value", statValue)); -- invalid use of '%' in replacement string

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
			profileDisplayList.statsProfile.Size = UDim2.new(1, 0, 0, textSize.Y+55);
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
				
				local killsNeeded = focusAmount-math.fmod(levelKills, focusAmount);
				totalKills = totalKills + killsNeeded;
				label.Text = ("L$focusLevel: $killsNeeded"):gsub("$focusLevel",lvl):gsub("$killsNeeded", killsNeeded);
				
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
			profileDisplayList.collectionProfile.Frame.Bar.Size = UDim2.new(math.clamp(#found/total, 0, 1), 0, 1, 0);
			profileDisplayList.collectionProfile.label.Text = ("Collectibles doesn't have any affect on gameplay. ($f/$t)"):gsub("$f", #found):gsub("$t", total);
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
			profileDisplayList.collectionProfile.Size = UDim2.new(1, 0, 0, ySize+95);
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
						
						local position = new.AbsolutePosition-menu.AbsolutePosition;
						highlightText.Position = UDim2.new(0, position.X+40, 0, position.Y+65);
						
						if lib.Tier == modAchievementLibrary.Tiers.Bronze then
							highlightText.ImageColor3 = highlightColors.Bronze;
						elseif lib.Tier == modAchievementLibrary.Tiers.Silver then
							highlightText.ImageColor3 = highlightColors.Silver;
						elseif lib.Tier == modAchievementLibrary.Tiers.Gold then
							highlightText.ImageColor3 = highlightColors.Gold;
						elseif lib.Tier == modAchievementLibrary.Tiers.Diamond then
							highlightText.ImageColor3 = highlightColors.Diamond;
						else
							highlightText.ImageColor3 = highlightColors.Black;
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
						Interface:PlayButtonClick();

						local newTitleId = remoteSetPlayerTitle:InvokeServer(lib.Id);

						if modData.Profile then
							modData.Profile.TitleId = newTitleId;
						end
						if titlePinIcon then
							titlePinIcon:Destroy();
							titlePinIcon = nil;
						end
						SelectPlayer(playerSelection, true);
						Interface.Update();
					end
					new.MouseButton1Click:Connect(function()
						if playerName ~= localplayer.Name then return end;
						if playerData.Achievements[lib.Id] == nil then return end;
						if equipTitleDebounce then return end equipTitleDebounce = true;
						setTitleClick();
						equipTitleDebounce = false;
					end)
					
					if (RunService:IsStudio()) then
						new.MouseButton2Click:Connect(setTitleClick);
					end
				end
				
				badgeButtons[lib.Id] = new;
				new.LayoutOrder = owned or order+a;
				
				spawn(function()
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
				spawn(function()
					profileDisplayList.achievements.Size = UDim2.new(1, 0, 0, profileDisplayList.achievements.ScrollingFrame.UIGridLayout.AbsoluteContentSize.Y+80);
--				if profileDisplayList.achievements.ScrollingFrame.UIGridLayout.AbsoluteContentSize.Y > 79 then
--					profileDisplayList.achievements.Size = UDim2.new(1, 0, 0, 240);
--				else
--					profileDisplayList.achievements.Size = UDim2.new(1, 0, 0, 160);
--				end
--				profileDisplayList.achievements.ScrollingFrame.CanvasSize = UDim2.new(0, 
--					0, 0, profileDisplayList.achievements.ScrollingFrame.UIGridLayout.AbsoluteContentSize.Y+5)
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
			profileDisplayList.gameStatistics.Size = UDim2.new(1, 0, 0, textSize.Y+55);
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
	
	selectionWorldName = modBranchConfigs.GetWorld();
	if modData.Squad and modData.Squad.Members and modData.Squad.Members[playerName] then
		selectionWorldName = (modData.Squad.Members[playerName].World or "Unknown");
	elseif Interface.FriendsList and Interface.FriendsList[playerName] and Interface.FriendsList[playerName].InUniverse then
		selectionWorldName = (modBranchConfigs.GetWorldName(Interface.FriendsList[playerName].PlaceId) or "Unknown");
	end
	profileLocationLabel.Text = (selectionWorldName and modBranchConfigs.GetWorldDisplayName(selectionWorldName) or "Unknown");
	
	if selectionWorldName ~= modBranchConfigs.GetWorld() or game.Players:FindFirstChild(playerSelection) == nil then
		local worldLib = modBranchConfigs.WorldLibrary[selectionWorldName];
		--profileTravelButton.Visible = worldLib and worldLib.CanTravelTo or false;
	else
		--profileTravelButton.Visible = false;
	end
	
end

local function UpdateListing(data)
	local listing = Interface.ActivePlayerListing[data.Name];
	if listing == nil then
		listing = playerListingTemplate:Clone();
		listing.Parent = list;
		Interface.ActivePlayerListing[data.Name] = listing;
		
		listing.MouseButton1Down:Connect(function()
			Interface:PlayButtonClick();
			
			if playerSelection == data.Name and activeOptionsFrame then
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
						Interface:PlayButtonClick();
						if onClick then
							onClick();
						end
						if activeOptionsFrame then
							activeOptionsFrame:Destroy();
						end
						activeOptionsFrame = nil;
					end)
				end
				
				local targetName = data.Name;
				local isInGame = game.Players:FindFirstChild(targetName) ~= nil;
				
				newOptionButton(
					targetName ~= localplayer.Name and isInGame,
					"Invite to Trade",
					function()
						remoteTradeRequest:FireServer("request", targetName);
				end)
				newOptionButton(
					targetName ~= localplayer.Name and isInGame and modData.TradeRequests[targetName] and tick()-modData.TradeRequests[targetName] <= 30,
					"Accept Trade Request",
					function()
						remoteTradeRequest:FireServer("request", targetName);
				end)
				newOptionButton(
					targetName ~= localplayer.Name and isInGame,
					"Invite to Duel",
					function()
						remoteDuelRequest:FireServer("request", targetName);
				end)
				newOptionButton(
					targetName ~= localplayer.Name and isInGame and modData.DuelRequests[targetName] and tick()-modData.DuelRequests[targetName] <= 30,
					"Accept Duel Request",
					function()
						remoteDuelRequest:FireServer("request", targetName);
				end)
				newOptionButton(
					targetName ~= localplayer.Name and (modData.Squad == nil or modData.Squad:FindMember(targetName) == nil),
					"Invite to Squad",
					function()
						if inviteDebounce[targetName] then return end;
						inviteDebounce[targetName] = true;
						delay(5, function() inviteDebounce[targetName] = nil; end);
						remoteSquadService:FireServer("invite",targetName);
				end)
				newOptionButton(
					targetName == localplayer.Name and modData.Squad ~= nil,
					"Leave Squad",
					function()
						remoteSquadService:FireServer("leave");
				end)
				newOptionButton(
					getInvitationFrom(targetName) ~= nil,
					"Join Squad",
					function()
						local invitation = getInvitationFrom(targetName);
						if invitation then
							for a=#invitationsList, 1, -1 do
								local invitation = invitationsList[a];
								if invitation.Name == targetName and invitation.Type == "Squad" then
									table.remove(invitationsList, a);
								end
							end
							remoteSquadService:FireServer("join", targetName);
						end
					end)
				newOptionButton(
					targetName ~= localplayer.Name and modData.PlayerNoise[targetName] == nil,
					"Mute Noise",
					function()
						modData.PlayerNoise[targetName] = true;
						modData.RefreshPlayerNoise(targetName);
					end)
				newOptionButton(
					targetName ~= localplayer.Name and modData.PlayerNoise[targetName] ~= nil,
					"Unmute Noises",
					function()
						modData.PlayerNoise[targetName] = nil;
						modData.RefreshPlayerNoise(targetName);
					end)
				--newOptionButton(
				--	targetName ~= localplayer.Name and modData.BoomboxMutes[targetName] == nil,
				--	"Mute Noise",
				--	function()
				--		modData.BoomboxMutes[targetName] = true;
				--		modData.RefreshBoomboxMutes();
				--end)
				--newOptionButton(
				--	targetName ~= localplayer.Name and modData.BoomboxMutes[targetName] ~= nil,
				--	"Unmute Noises",
				--	function()
				--		modData.BoomboxMutes[targetName] = nil;
				--		modData.RefreshBoomboxMutes();
				--end)
				
				
				local targetWorldName = modBranchConfigs.GetWorld();
				if modData.Squad and modData.Squad.Members and modData.Squad.Members[targetName] then
					selectionWorldName = (modData.Squad.Members[targetName].World or "Unknown");
				elseif Interface.FriendsList and Interface.FriendsList[targetName] and Interface.FriendsList[targetName].InUniverse then
					selectionWorldName = (modBranchConfigs.GetWorldName(Interface.FriendsList[targetName].PlaceId) or "Unknown");
				end
				
				local travelDisabled = false;
				if selectionWorldName ~= modBranchConfigs.GetWorld() or game.Players:FindFirstChild(targetName) == nil then
					local worldLib = modBranchConfigs.WorldLibrary[selectionWorldName];
					if worldLib and worldLib.CanTravelTo and Interface.FriendsList[targetName] then
						if Interface.FriendsList[targetName].SearchedPlayer then
							newOptionButton(
								targetName ~= localplayer.Name,
								"Request to Travel",
								function()
									remoteWorldTravelRequest:InvokeServer("TravelRequest", targetName)
							end)
							
						elseif Interface.FriendsList[targetName].TravelRequest then
							newOptionButton(
								targetName ~= localplayer.Name,
								"Accept Travel Request",
								function()
									remoteWorldTravelRequest:InvokeServer("AcceptTravel", targetName)
									Interface.FriendsList[targetName] = nil;
							end)
							newOptionButton(
								targetName ~= localplayer.Name,
								"Deny Travel Request",
								function()
									for a=#modData.TravelRequests, 1, -1 do
										if modData.TravelRequests[a].UserName == targetName then
											table.remove(modData.TravelRequests, a);
										end
									end
									Interface.FriendsList[targetName] = nil;
									Interface.Update();
							end)
							
						else
							newOptionButton(
								targetName ~= localplayer.Name,
								"Travel to Player",
								function()
									if travelDisabled then return end;
									Interface:PlayButtonClick();	
									local promptWindow = Interface:PromptQuestion("You are about to leave this world",
										"Are you sure you want to travel to ".. modBranchConfigs.GetWorldDisplayName(selectionWorldName) .."?");
									local YesClickedSignal, NoClickedSignal;
									
									YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
										Interface:PlayButtonClick();
										promptWindow:Close();
										if remoteWorldTravelRequest:InvokeServer("Social", targetName) == true then
											travelDisabled = true;
										end
										YesClickedSignal:Disconnect();
										NoClickedSignal:Disconnect();
									end);
									NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
										Interface:PlayButtonClick();
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
			SelectPlayer(data.Name, true);
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
	
	if modData.TradeRequests[data.Name] and tick()-modData.TradeRequests[data.Name] <= 30 then
		tradeRequestIcon.Visible = true;
	else
		tradeRequestIcon.Visible = false;
	end
	
	if modData.SquadRequests[data.Name] and tick()-modData.SquadRequests[data.Name] <= 20 then
		squadRequestIcon.Visible = true;
	else
		squadRequestIcon.Visible = false;
	end
	
	if modData.DuelRequests[data.Name] and tick()-modData.DuelRequests[data.Name] <= 60 then
		duelRequestIcon.Visible = true;
	else
		duelRequestIcon.Visible = false;
	end
	
	local function update()
		local playerData = modData.Players[data.Name];
		
		nameLabel.Text = data.Name;
		avatarLabel.Image = data.Avatar or "";
		
		local thatPlayer = game.Players:FindFirstChild(data.Name);
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
			local worldId = data.PlaceId and modBranchConfigs.GetWorldName(data.PlaceId) or data.WorldId;
			locationLabel.Text = modBranchConfigs.GetWorldDisplayName(worldId) or "Unknown";
		end
		if modData.Players[data.Name] then
			local playerData = modData.Players[data.Name];
			
			if playerData.Role then
				if playerData.Role == "Founder" then
					nameLabel.TextColor3 = Color3.fromRGB(231,186,115);
					
				elseif playerData.GroupRank >= 200 then
					nameLabel.TextColor3 = Color3.fromRGB(206,107,225);
					
				end
			else
				nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
			end
			modData.Players[data.Name].Avatar = data.Avatar;
			
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
function Interface.Update()
	if debounce then return end;
	debounce = true;
	if list.Parent == nil then return end;
	
	local players = game.Players:GetPlayers();
	local totalFriends = 0;
	local onlineFriends = 0;
	local totalPlayers = #players;
	
	local updated = {};
	
	for userName, friendData in pairs(Interface.FriendsList) do
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
		if Interface.FriendsList[player.Name] == nil or not Interface.FriendsList[player.Name].InUniverse then
			playersOrder = playersOrder +1;
			
			local listing = UpdateListing{
				Name=player.Name;
				Avatar=CacheAvatar(player.Name, player.UserId);
			};
			if player.Name == localplayer.Name then
				listing.LayoutOrder = 1;
			else
				listing.LayoutOrder = playersOrder+1;
			end
			updated[player.Name] = true;
		end
	end
	serverTabLabel.Text = "Players Online ("..#players.."/"..totalPlayers..")";
	
	--== Friends;
	local friendsTab = list:FindFirstChild("FriendsTab");
	if friendsTab == nil then
		local new = friendsTabTemplate:Clone();
		new.LayoutOrder = 2;
		new.Parent = list;
		friendsTab = new;
	end
	local friendIndex = 2;
	for userName, friendData in pairs(Interface.FriendsList) do
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
	if modData.Squad then
		local squadTab = list:FindFirstChild("SquadTab");
		if squadTab == nil then
			local new = friendsTabTemplate:Clone();
			new.Name = "SquadTab";
			new.LayoutOrder = -10;
			new.Parent = list;
			squadTab = new;
		end
		local socialTabLabel = squadTab.Labeltag;
		for userName, memberData in pairs(modData.Squad.Members) do
			local listing = UpdateListing{
				Name=userName;
				Avatar=CacheAvatar(userName, memberData.UserId);
				WorldId=memberData.World;
			};
			if userName == localplayer.Name then
				listing.LayoutOrder = -9;
			else
				listing.LayoutOrder = -7;
			end
			updated[userName] = true;
		end
		socialTabLabel.Text = "Squad ("..modData.Squad:LoopPlayers().."/6)";
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
	
	for name, listing in pairs(Interface.ActivePlayerListing) do
		if updated[name] == nil then
			Interface.ActivePlayerListing[name] = nil;
			game.Debris:AddItem(listing, 0);
		end
	end
	
	debounce = false;
	spawn(function() SelectPlayer(playerSelection, false); end);
end

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
		for name, listing in pairs(Interface.ActivePlayerListing) do
			listing.Visible = name:lower():match(searchBar.Text:lower()) ~= nil;
		end
	else
		for name, listing in pairs(Interface.ActivePlayerListing) do
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
		Interface.Update();
	end
end)

function Interface.init(modInterface)
	setmetatable(Interface, modInterface); 

	Interface:Bind("UpdateSocialMenu", function()
		if not menu.Visible then return end;
		Interface.Update();
	end)
	
	local window = Interface.NewWindow("SocialMenu", menu);
	window.CompactFullscreen = true;
	window:SetConfigKey("DisableSocialMenu");
	
	if modConfigurations.CompactInterface then
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1, 0));
	else
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, -35), UDim2.new(0.5, 0, -1, 0));
	end
	window.OnWindowToggle:Connect(function(visible)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			SelectPlayer(localplayer.Name, true);
			Interface.Update();
			
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
	
	modKeyBindsHandler:SetDefaultKey("KeyWindowSocialMenu", Enum.KeyCode.G);
	local quickButton = Interface:NewQuickButton("SocialMenu", "Social", "rbxassetid://3256270238");
	quickButton.LayoutOrder = 3;
	modInterface:ConnectQuickButton(quickButton, "KeyWindowSocialMenu");
	
	local amtLabel = quickButton:WaitForChild("AmtFrame"):WaitForChild("AmtLabel");
	task.spawn(function()
		UpdateApplicableFriends();
		repeat
			if menu.Visible then
				UpdateApplicableFriends();
				Interface.Update();
			end

			local onlineFriends = 0;
			for userName, friendData in pairs(Interface.FriendsList) do
				if friendData.InUniverse then 
					onlineFriends = onlineFriends +1;
				end
			end
			amtLabel.Text = onlineFriends > 0 and onlineFriends or "";
		until menu.Parent == nil or not task.wait(10);
	end)
	
	shared.modPlayers.OnPlayerDied:Connect(Interface.Update);
	
	return Interface;
end;

function Interface.disconnect()
	Interface.Disabled = true;
	invRemoteConn:Disconnect();
	shared.modPlayers.OnPlayerDied:Destroy();
end

script.AncestryChanged:Connect(function(c, p)
	if c == script and p == nil and Interface.disconnect then
		Interface.disconnect();
	end
end)

return Interface;
