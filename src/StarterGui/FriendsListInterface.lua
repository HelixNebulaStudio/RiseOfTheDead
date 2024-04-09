--== Variables;
local Interface = {};
Interface.__index = Interface;
Interface.FriendsList = {};
Interface.MenuInterface = nil;

local TeleportService = game:GetService("TeleportService");
local player = game.Players.LocalPlayer;

local modGuiTween = require(game.StarterGui:WaitForChild("GuiObjectTween"));
local modAudio = require(game.ReplicatedStorage:WaitForChild("Library", 60):WaitForChild("Audio", 60));
local modBranchConfigs = require(game.ReplicatedStorage:WaitForChild("Library", 60):WaitForChild("BranchConfigurations", 60));
local modLevelBadge = require(game.ReplicatedStorage.Library.LevelBadge);
local branchColor = modBranchConfigs.BranchColor

local buttonDebounce = false;
--== Script;
function playButtonSound()
	modAudio.Play("ButtonSound", nil, nil, false);
end

function UpdateApplicableFriends()
	local friends = {};
	pcall(function() friends = player.UserId > 0 and player:GetFriendsOnline() or {}; end)
	local thumbnailType = Enum.ThumbnailType.HeadShot;
	local thumbnailSize = Enum.ThumbnailSize.Size420x420;
	
	Interface.FriendsList = {};
	local IdList = {};
	for a=1, #friends do
		local inUniverse = false;
		if friends[a].LocationType == 1 or friends[a].LocationType == 4 then
			for world, worldId in pairs(modBranchConfigs.CurrentBranch.Worlds) do
				if friends[a].PlaceId == worldId then
					inUniverse = true;
					break;
				end
			end
		end
		local thumbnail, loaded = game.Players:GetUserThumbnailAsync(friends[a].VisitorId, thumbnailType, thumbnailSize);
		friends[a].Avatar = thumbnail;
		friends[a].InUniverse = inUniverse;
		friends[a].IsPremium = false;
		if inUniverse then
			friends[a].WorldName = modBranchConfigs.GetWorldName(friends[a].PlaceId);
		end
		table.insert(IdList, friends[a].VisitorId);
		Interface.FriendsList[friends[a].UserName] = friends[a];
	end
end

function Interface.new(listFrame, friendsFrame, addons, menuFrame)
	local interface = setmetatable({}, Interface);
	interface.FriendsListFrame = listFrame;--menuFrame:FindFirstChild("FriendsList", true);
	if interface.FriendsListFrame == nil then error("Missing FriendsList"); end;
	interface.FriendFrame = friendsFrame;
	
	interface.FramesList = {};
	
	if addons then
		if addons.Searchbar ~= nil then
			addons.Searchbar:GetPropertyChangedSignal("Text"):Connect(function()
				if addons.Searchbar.Text:len() > 0 then
					local friendListChildrens = interface.FriendsListFrame:GetChildren();
					for a=1, #friendListChildrens do
						if friendListChildrens[a]:IsA("Frame") then
							if string.find(friendListChildrens[a].Name:lower(), addons.Searchbar.Text:lower()) then
								friendListChildrens[a].Visible = true;
							else
								friendListChildrens[a].Visible = false;
							end
						end
					end
				else
					local friendListChildrens = interface.FriendsListFrame:GetChildren();
					for a=1, #friendListChildrens do
						if friendListChildrens[a]:IsA("Frame") then
							friendListChildrens[a].Visible = true;
						end
					end
				end
			end)
		end
	end
	
	interface:Update();
	return interface;
end

function Interface:Update()
	--print("FriendsListInterface>> Updating friends menu");
	UpdateApplicableFriends();
	
	--local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
	
	local remotes = game.ReplicatedStorage.Remotes;
	local remoteWorldTravelRequest = remotes.Interactable.WorldTravelRequest;
	--remoteWorldTravelRequest:InvokeServer("Social", playerSelection)
	local updatedList = {};
	
	local countFriends = 0;
	for userName, friendData in pairs(Interface.FriendsList) do
		countFriends = countFriends+1;
		local playerFrame = self.FramesList[friendData.UserName];
		if playerFrame == nil then
			playerFrame = self.FriendsListFrame:FindFirstChild(friendData.UserName) or self.FriendFrame:Clone();
			
			local joinButton = playerFrame:WaitForChild("JoinButton");
			local defaultJoinColor = joinButton.ImageColor3;
			joinButton.MouseEnter:Connect(function()
				if buttonDebounce then return end;
				joinButton.ImageColor3 = Color3.new(branchColor.r*0.75, branchColor.g*0.75, branchColor.b*0.75);
			end);
			joinButton.MouseLeave:Connect(function()
				joinButton.ImageColor3 = defaultJoinColor;
			end);
			
			joinButton.MouseButton1Click:Connect(function()
				if buttonDebounce then return end;
				buttonDebounce = true;
				playButtonSound();
				
				joinButton.ImageColor3 = branchColor;
				if modGuiTween then
					modGuiTween.FadeTween(Interface.MenuInterface.MenuFrame.FriendsFrame, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
				end
				Interface.MenuInterface.LoadLabel.Text = "Joining "..friendData.UserName.."..";
				local success = remoteWorldTravelRequest:InvokeServer("Social", friendData.UserName);
				wait(0.5);
				Interface.MenuInterface.MenuFrame.FriendsFrame.Visible = false;
				if modGuiTween then
					modGuiTween.FadeTween(Interface.MenuInterface.LoadLabel, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
				end
				
				if not success then
					if modGuiTween then
						modGuiTween.FadeTween(Interface.MenuInterface.LoadLabel, modGuiTween.FadeDirection.Out, TweenInfo.new(0.48));
					end
					Interface.MenuInterface.LoadLabel.Text = "Joining failed..";
					wait(0.5);
					Interface.MenuInterface.MenuFrame.FriendsFrame.Visible = true;
					if modGuiTween then
						modGuiTween.FadeTween(Interface.MenuInterface.MenuFrame.FriendsFrame, modGuiTween.FadeDirection.In, TweenInfo.new(0.48));
					end
				end
				
				joinButton.ImageColor3 = defaultJoinColor;
				buttonDebounce = false;
			end)
			
			playerFrame.Parent = self.FriendsListFrame;
		end
		self.FramesList[friendData.UserName] = playerFrame;
		updatedList[friendData.UserName] = playerFrame;
		playerFrame.AvatarLabel.Image = friendData.Avatar;
		playerFrame.nameLabel.Text = friendData.UserName;
		if friendData.InUniverse then
			playerFrame.LayoutOrder = 0;
			playerFrame.AvatarLabel.ImageColor3 = Color3.fromRGB(255, 255, 255);
			playerFrame.worldLabel.Text = friendData.WorldName;
			playerFrame.worldLabel.TextStrokeTransparency = 0.7;
			playerFrame.worldLabel.TextTransparency = 0;
			playerFrame.nameLabel.TextStrokeTransparency = 0.7;
			playerFrame.nameLabel.TextTransparency = 0;
			
			playerFrame.JoinButton.Visible = true;
		else
			playerFrame.LayoutOrder = 201;
			playerFrame.JoinButton.Visible = false;
			playerFrame.AvatarLabel.ImageColor3 = Color3.fromRGB(70, 70, 70);
			playerFrame.worldLabel.Text = friendData.LastLocation == "Online" and "Website" or friendData.LastLocation;
			playerFrame.worldLabel.TextStrokeTransparency = 1;
			playerFrame.worldLabel.TextTransparency = 0.6;
			playerFrame.nameLabel.TextStrokeTransparency = 1;
			playerFrame.nameLabel.TextTransparency = 0.6;
		end
		if friendData.IsPremium then
			playerFrame.ImageColor3 = Color3.fromRGB(100, 60, 60);
			--playerFrame.BackgroundFrame.BorderColor3 = Color3.fromRGB(135, 106, 9); --rbxassetid://2679195955
		end
	end
	local friendListChildrens = self.FriendsListFrame:GetChildren();
	for a=1, #friendListChildrens do
		local name = friendListChildrens[a].Name;
		if updatedList[name] == nil and self.FramesList[name] ~= nil then
			self.FramesList[name]:Destroy();
			self.FramesList[name] = nil;
		end
	end
	self.FriendsListFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(countFriends/3)*215-15);
end

return Interface;