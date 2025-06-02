local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interface = {};
Interface.ArrangementOrder = {
	SmallToLarge=1;
	LargeToSmall=2;
}
local SquadData = {};
local squadInterfaces = {};

local localplayer = game.Players.LocalPlayer;

local modBranchConfigs = shared.require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));
local modAudio = shared.require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("Audio"));
local modMarkers = shared.require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("Markers"));
local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local branchColor = modBranchConfigs.BranchColor
--== Remotes;
local remoteSquadService = modRemotesManager:Get("SquadService");
local remoteOnInvitationsUpdate = modRemotesManager:Get("OnInvitationsUpdate");

--== Script;
function playButtonSound()
	modAudio.Play("ButtonSound", nil, nil, false);
end

function Interface.new(squadFrame, squadMemberFrame, squadInterfaceData)
	if squadMemberFrame == nil then error("Missing Squad Member Frame"); end;
	local arrangementOrder = squadInterfaceData.Order or Interface.ArrangementOrder.SmallToLarge;
	local descendants = squadFrame:GetDescendants();
	
	local squadInterface = {};
	
	local squadList = squadFrame:FindFirstChild("SquadList");
	local squadMemberInterfaces = {};
	local thumbnailType = squadInterfaceData.ThumbnailType or Enum.ThumbnailType.HeadShot;
	local thumbnailSize = squadInterfaceData.ThumbnailSize or Enum.ThumbnailSize.Size420x420;
	
	function squadInterface:Update()
		local updatedSquadMemberInterfaces = {};
		
		--== Markers
		local function UpdateMarkers()
			for _, player in pairs(game.Players:GetPlayers()) do
				if SquadData and SquadData.Members and SquadData.Members[player.Name] and player ~= localplayer then
					modMarkers.SetMarker(player.Name, player.Name, player.Name, modMarkers.MarkerTypes.Player);
					modMarkers.SetColor(player.Name, SquadData.Members[player.Name].Color);
				else
					modMarkers.ClearMarker(player.Name);
				end
			end
		end
		
		for userName, squadMember in pairs(SquadData.Members or {}) do
			local squadMemberInterface = squadMemberInterfaces[userName];
			local isSquadLeader = userName == SquadData.Leader;
			if userName ~= localplayer.Name then
				if squadMemberInterface == nil then
					local squadMFrame = squadList:FindFirstChild(userName);
					if squadMFrame == nil then
						squadMFrame = squadMemberFrame:Clone();
					end
					squadMemberInterface = {};
					squadMemberInterface.Frame = squadMFrame;
					squadMemberInterface.Avatar = squadMFrame:FindFirstChild("Avatar");
					squadMemberInterface.NameTag = squadMFrame:FindFirstChild("NameTag");
					squadMemberInterface.MarkerTag = squadMFrame:FindFirstChild("MarkerIcon");
					squadMemberInterface.HealthBar = squadMFrame:FindFirstChild("HealthBar");
					squadMemberInterface.HealthBarBack = squadMFrame:FindFirstChild("BackBar");
					
					squadMemberInterface.Frame.Name = userName;
					squadMemberInterface.Frame.Parent = squadList;
					
					squadMemberInterface.MarkerTag.ImageColor3 = modMarkers.Colors[squadMember.Color] or Color3.fromRGB(255, 255, 255);
					
					if squadInterfaceData.HideNameTags then
						squadMemberInterface.Frame.MouseEnter:Connect(function()
							squadMemberInterface.NameTag.Visible = true;
						end)
						squadMemberInterface.Frame.MouseLeave:Connect(function()
							squadMemberInterface.NameTag.Visible = false;
						end)
					end
					
					squadMemberInterfaces[userName] = squadMemberInterface;
				end
				
				squadMemberInterface.Frame.BorderColor3 = squadMember.Premium and Color3.fromRGB(140, 105, 0) or Color3.fromRGB(25, 25, 25);
				squadMemberInterface.NameTag.Text = userName;
				squadMemberInterface.NameTag.TextColor3 = squadMember.Premium and Color3.fromRGB(185, 139, 0) or Color3.fromRGB(255, 255, 255);
				squadMemberInterface.Avatar.Image = game.Players:GetUserThumbnailAsync(squadMember.UserId > 0 and squadMember.UserId or modGlobalVars.UseRandomId(), thumbnailType, thumbnailSize);
				squadMemberInterface.Frame.Visible = true;
				
				local healthBar = squadMemberInterface.HealthBar;
				local avatarLabel = squadMemberInterface.Avatar;
				
				if squadMemberInterface.HealthBar then
					squadMemberInterface.HealthBar.Visible = true;
					squadMemberInterface.HealthBarBack.Visible = true;
					
					local classPlayer = shared.modPlayers.GetByName(userName);
					if classPlayer then
						local function updateHealthbar(health, maxhealth)
							local percent = (health or 1) / (maxhealth or 1);
							if healthBar then
								healthBar:TweenSize(UDim2.new(math.clamp((percent or 1), 0, 1), 0, 0, 5), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.25, true);
							end;
						end
						local function updateAvatarDisplay(isAlive)
							spawn(UpdateMarkers);
							if avatarLabel then
								avatarLabel.ImageColor3 = isAlive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 0, 0);
							end
						end
						
						if classPlayer.SquadHealthConnection then classPlayer.OnHealthChanged:Disconnect(classPlayer.SquadHealthConnection); end
						if classPlayer.SquadIsAliveConnection then classPlayer.OnIsAliveChanged:Disconnect(classPlayer.SquadIsAliveConnection); end
						
						classPlayer.SquadHealthConnection = updateHealthbar;
						classPlayer.OnHealthChanged:Connect(updateHealthbar);
						
						classPlayer.SquadIsAliveConnection = updateAvatarDisplay;
						classPlayer.OnIsAliveChanged:Connect(updateAvatarDisplay);
						
						updateHealthbar(classPlayer.Health, classPlayer.MaxHealth);
						updateAvatarDisplay(classPlayer.IsAlive);
					end
				else
					if squadMemberInterface.HealthBar then
						squadMemberInterface.HealthBar.Visible = false;
					end
					if squadMemberInterface.HealthBarBack then
						squadMemberInterface.HealthBarBack.Visible = false;
					end
				end
			end
			updatedSquadMemberInterfaces[userName] = squadMemberInterface;
		end
		local squadListChildren = squadList:GetChildren();
		for a=1, #squadListChildren do
			if updatedSquadMemberInterfaces[squadListChildren[a].Name] == nil and squadListChildren[a]:FindFirstChild("Avatar") ~= nil then
				squadListChildren[a]:Destroy();
				squadMemberInterfaces[squadListChildren[a].Name] = nil;
			end
		end
		
		UpdateMarkers();
	end
	table.insert(squadInterfaces, squadInterface);
end

local buttonDebounce = false;
function Interface.setInvitationList(List, Frame)
	local interface = {};
	local frames = {};
	
	function interface:NewInvitations(requestsTable)
		local updatedList = {};
		for a=1, #requestsTable do
			local targetName = requestsTable[a].Name;
			local targetId = requestsTable[a].UserId;
			local targetAvatar = game.Players:GetUserThumbnailAsync(targetId > 0 and targetId or modGlobalVars.UseRandomId(), Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420);
			local inviteFrame = List:FindFirstChild(targetName);
			if frames[targetName] == nil then
				inviteFrame = inviteFrame or Frame:Clone();
				frames[targetName] = inviteFrame;
				inviteFrame.Name = requestsTable[a].Name;
				inviteFrame.Parent = List;
				inviteFrame.Visible = true;
				delay(5, function()
					inviteFrame.Visible = false;
				end)
			end
			inviteFrame.AvatarFrame.AvatarLabel.Image = targetAvatar;
			inviteFrame.AvatarFrame.NameTag.Text = targetName;
			updatedList[targetName] = frames[targetName];
		end
		local childrens = List:GetChildren();
		for a=1, #childrens do
			if childrens[a]:IsA("Frame") and updatedList[childrens[a].Name] == nil then
				frames[childrens[a].Name]:Destroy();
				frames[childrens[a].Name] = nil;
			end
		end
	end
	
	return interface;
end

function Interface:Update(squadTable)
	SquadData = squadTable or {};
	for a=1, #squadInterfaces do
		squadInterfaces[a]:Update();
	end
end

return Interface;