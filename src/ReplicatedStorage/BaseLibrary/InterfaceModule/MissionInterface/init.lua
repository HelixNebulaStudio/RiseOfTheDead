local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;
local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modMissionsLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modMarkers = require(game.ReplicatedStorage.Library.Markers);
local modTableManager = require(game.ReplicatedStorage.Library.TableManager);
local modBattlePassLibrary = require(game.ReplicatedStorage.Library.BattlePassLibrary);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);

local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);
local modHeadIcons = require(game.ReplicatedStorage.BaseLibrary.HeadIcons);

local modGuiObjectTween = require(game.ReplicatedStorage.Library.UI.GuiObjectTween);
local modItemInterface = require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modRadialImage = require(game.ReplicatedStorage.Library.UI.RadialImage);
local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);
local modComponents = require(game.ReplicatedStorage.Library.UI.Components);

local remotes = game.ReplicatedStorage.Remotes;
local remotePinMission = remotes.Interface.PinMission;

local remoteMissionRemote = modRemotesManager:Get("MissionRemote");
local remoteBattlepassRemote = modRemotesManager:Get("BattlepassRemote")

local windowFrameTemplate = script:WaitForChild("MissionMenu");
local missionPinHudTemplate = script:WaitForChild("MissionPinHud");

local templateLevelSlot = script:WaitForChild("LevelSlot");
local templateStartSlot = script:WaitForChild("LevelSlotStart");

local templateMissionBoard = script:WaitForChild("MissionsBoard");
local templateRMissionButton = script:WaitForChild("RMissionButton");

local templatePassReward = script:WaitForChild("PassReward");
local templateLockedLabel = script:WaitForChild("LockedLabel");

local timerRadialBar = script:WaitForChild("radialBar");
timerRadialBar.AnchorPoint = Vector2.new(0, 1);
timerRadialBar.Position = UDim2.new(0, 0, 1, 0);
timerRadialBar.Size = UDim2.new(0, 18, 0, 18);
timerRadialBar.ZIndex = 3;

local timerRadialConfig = '{"version":1,"size":128,"count":128,"columns":8,"rows":8,"images":["rbxassetid://10606346824","rbxassetid://10606347195"]}';
local BarColors = {
	Green=Color3.fromRGB(27, 106, 23);
	Yellow=Color3.fromRGB(163, 143, 27);
	Red=Color3.fromRGB(118, 54, 54);
}
local firstSync=false;
--==
local Interface = {
	UpdateBattlePass = function(action) end;
	Update = function() end;
};

modData.OnDataEvent:Connect(function(action, hierarchyKey, data)
	if action ~= "sync" then return end;
	
	if hierarchyKey == "BattlePassSave" then
		Interface.UpdateBattlePass();
	end
	
	if hierarchyKey == "GameSave/Missions" then
		firstSync=true;
		Interface.Update();
	end
end)

local boardMissionColors = {
	Easy = Color3.fromRGB(100, 100, 100);
	Normal = Color3.fromRGB(51, 102, 204);
	Hard = Color3.fromRGB(101, 59, 169);
};

local bpColors = {
	CurrentNormal = Color3.fromRGB(135, 255, 135);
	CurrentPassOwner = Color3.fromRGB(255, 112, 112);
	CurrentPremium = Color3.fromRGB(255, 220, 112);
	
	Normal = Color3.fromRGB(90, 120, 90);
	PassOwner = Color3.fromRGB(120, 53, 53);
	Premium = Color3.fromRGB(120, 103, 53);
	
	LockedNormal = Color3.fromRGB(80, 80, 80);
	LockedPassOwner = Color3.fromRGB(80, 49, 49);
	LockedPremium = Color3.fromRGB(80, 72, 49);
}

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	Interface.UpdateBattlePass = function(action) end;
	Interface.Update = function() end;

	local branchColor = modBranchConfigs.BranchColor

	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;
	
	if modConfigurations.CompactInterface then
		windowFrame.Position = UDim2.new(0.5, 0, 0.5, 0);
		windowFrame.Size = UDim2.new(1, 0, 1, 0);
		windowFrame:WaitForChild("UICorner"):Destroy();

		windowFrame:WaitForChild("touchCloseButton").Visible = true;
		windowFrame:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
			Interface:CloseWindow("Missions");
		end)
		windowFrame:WaitForChild("HelpButton").Visible = false;
		windowFrame:WaitForChild("hintLabel").Visible = false;
	end
	
	local LeftFrame = windowFrame:WaitForChild("LeftBackground");
	local MissionListFrame = LeftFrame:WaitForChild("MissionList");
	local missionListPadding = LeftFrame:WaitForChild("UIPadding");
	local PinnedMissionFrame = windowFrame:WaitForChild("PinnedBackground");

	local missionPinHud = missionPinHudTemplate:Clone();
	missionPinHud.Parent = modInterface.MainInterface;
	
	local hudSizeConstraint = missionPinHud:WaitForChild("UISizeConstraint");
	local pinnedTitleTag = missionPinHud:WaitForChild("Title");
	local pinnedTaskTag = missionPinHud:WaitForChild("Task");
	local pinnedTimerTag = missionPinHud:WaitForChild("Timer");
	local pinnedHintLabel = missionPinHud:WaitForChild("Hint");
	local pinnedTasklist = missionPinHud:WaitForChild("Tasklist");
	local taskTemplate = script:WaitForChild("Task");

	local missionListingTemplate = script:WaitForChild("MissionListing");

	local notifyMissionFrame = script:WaitForChild("NotifyMission");

	local activeDetailsFrameTemplate = script:WaitForChild("ActiveMissionFrame");
	local taskListingTemplate = script:WaitForChild("TaskListing");
	local logListingTemplate = script:WaitForChild("LogListing");
	local redoButtonTemplate = script:WaitForChild("redoButton");

	local missionMapTemplate = script:WaitForChild("MissionsMap");
	local mapEntryTemplate = script:WaitForChild("mapEntry");
	
	local listTemplate = script:WaitForChild("listTemplate");
	local tabTemplate = script:WaitForChild("tabTemplate");

	local availableDetailsFrameTemplate = script:WaitForChild("AvailableMissionFrame");

	local RightFrame = windowFrame:WaitForChild("RightBackground");
	local MissionDisplayFrame = RightFrame;

	local camera = workspace.CurrentCamera;
	
	if modConfigurations.CompactInterface then
		missionPinHud.Position = UDim2.new(1, 0, 0, 30);
		missionPinHud:WaitForChild("Hint").Visible = false;
		hudSizeConstraint.MaxSize = Vector2.new(camera.ViewportSize.X-100, math.huge);

		missionPinHud.UIListLayout.Padding = UDim.new(0, 3);
		pinnedTitleTag.Size = UDim2.new(0, 0, 0, 16);
		pinnedTaskTag.Size = UDim2.new(0, 0, 0, 11);
		taskTemplate.Size = UDim2.new(0, 0, 0, 11);
		pinnedHintLabel.Size = UDim2.new(0, 0, 0, 11);
		pinnedTimerTag.Size = UDim2.new(0, 0, 0, 11);
	end

	---
	local missionListings = {};
	local tabAndLists = {};
	local titleLabels = {};
	local pinnedMissionName, notifyPinnedMission, newPinNotification;
	local activeMissionLogic = {};
	local lastProgressionPoint = nil;
	local lastIncompleteFlag = nil;

	local missionMarkerColor = Color3.fromRGB(251, 255, 0);

	local itemToolTip = modItemInterface.newItemTooltip();
	---
	local function cancelAllMissionFunctions()
		for _, m in pairs(activeMissionLogic) do
			if m.Cancel then
				m.Cancel();
			end
		end
	end

	local function getMissionData(id)
		for a=1, #modData.GameSave.Missions do
			local missionData = modData.GameSave.Missions[a];
			if missionData.Id == id then
				return missionData;
			end
		end

		return;
	end

	local function loadObjectiveDescription(mission, objName, obj)
		if RunService:IsStudio() then
			Debugger:Warn("[Studio] loadObjectiveDescription ",mission.SaveData);
		end
		local itemId = mission.SaveData.ItemId;
		local itemlib = mission.SaveData.ItemId and modItemsLibrary:Find(itemId);
		local desc = obj.Description;

		local needCount = tonumber(mission.ObjectivesCompleted[objName]);
		local objectiveAmount = obj.Amount or mission.SaveData.Amount or 1;
		desc = string.gsub(desc, "$Amount", needCount and objectiveAmount and objectiveAmount == needCount and needCount or (objectiveAmount - (needCount or 0)).."/"..objectiveAmount);
		desc = string.gsub(desc, "$ItemName", itemlib and itemlib.Name or itemId or "");
		return desc;
	end

	local function getNpc(npcName)
		if npcName == nil then return end;
		for _, obj in pairs(workspace.Entity:GetChildren()) do
			local ownerTag = obj:GetAttribute("Player");
			if (ownerTag == nil or ownerTag == localPlayer.Name) and obj.Name == npcName then
				return obj;
			end
		end
		return;
	end
	
	local hideComplete = modData.Settings and modData.Settings["HideCM"] == 1;

	local rewardsPresets = {
		Perks={Text="+$value Perks"};
		Item={Text="$amt $item"};
		Mission={Text="Unlock mission \"$value\""};
	};

	for id, lib in pairs(modMissionsLibrary.List()) do
		if lib.Rewards and lib.RewardText == nil then
			local text = "Rewarded: ";
			for a=1, #lib.Rewards do
				local reward = lib.Rewards[a];
				local rewardType = reward.Type;
				local preset = rewardsPresets[rewardType];
				if preset then
					if rewardType == "Mission" then
						local rewardMission = modMissionsLibrary.Get(reward.Id);
						text = text..preset.Text:gsub("$value", rewardMission and rewardMission.Name or "MissionId("..reward.Id..")");

					elseif rewardType == "Perks" then
						local perkAmount = reward.Amount;
						if lib.MissionType == 4 then
							text = text..preset.Text:gsub("$value", "$dailyPerks");
						else
							text = text..preset.Text:gsub("$value", perkAmount);
						end

					elseif rewardType == "Item" then
						local itemLib = modItemsLibrary:Find(reward.ItemId);
						if itemLib then
							text = text..preset.Text:gsub("$amt", reward.Quantity):gsub("$item", itemLib.Name);
						end

					end

				end
				if a ~= #lib.Rewards then
					text = text..", ";
				end
			end
			lib.RewardText = text;
		end
	end
	
	
	---
	local window = Interface.NewWindow("Missions", windowFrame);
	window.CompactFullscreen = true;
	if modConfigurations.CompactInterface then
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 2, 0));

	else
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, -35), UDim2.new(0.5, 0, -1.5, 0));

	end
	
	window.OnWindowToggle:Connect(function(visible, action)
		if visible then
			if action == "giftshop" then
				Interface:HideAll{[window.Name]=true; ["Inventory"]=true;};
			else
				Interface:HideAll{[window.Name]=true;};
			end
			Interface.Update();
			Interface.RefreshMissionMap();
			Interface.UpdateBattlePass(action);
			
			modData:RequestData("GameSave/Missions");
			
		else
			itemToolTip.Frame.Visible = false;
			MissionDisplayFrame:ClearAllChildren();
			modData:SaveSettings();

		end
	end)
	if not firstSync then
		modData:RequestData("GameSave/Missions");
	end
	
	
	local keyId = "KeyWindowMissions";
	modKeyBindsHandler:SetDefaultKey(keyId, Enum.KeyCode.B);

	local quickButton = Interface:NewQuickButton("Missions", "Missions", "rbxassetid://2273398923");
	local amtLabel = quickButton:WaitForChild("AmtFrame"):WaitForChild("AmtLabel");

	modInterface:ConnectQuickButton(quickButton, keyId);

	---
	
	local function countAvailableMissions()
		local c = 0;
		if modData.GameSave and modData.GameSave.Missions then
			local missionsList = modData.GameSave.Missions;
			for a=1, #missionsList do
				local missionData = missionsList[a];
				if missionData.CatType == 4 then continue end;
				if missionData.Type == 2 then
					c = c +1;
				end
			end
		end
		amtLabel.Text = c > 0 and c or "";
		amtLabel.Parent.Visible = c > 0;
		return c;
	end

	local function refreshPinnedMissionFrame()
		local visible = false;
		for _, obj in pairs(PinnedMissionFrame:GetChildren()) do
			if obj:IsA("ImageButton") then
				visible = true;
				break;
			end
		end
		if visible then
			missionListPadding.PaddingTop = UDim.new(0, 90);
			PinnedMissionFrame.Visible = true;
		else
			missionListPadding.PaddingTop = UDim.new(0, 5);
			PinnedMissionFrame.Visible = false;
		end
	end

	local missionTypeOrder = {
		Core=1;
		Side=2;
		Faction=4;
		Premium=5;
		Secret=6;
		Event=7;
		Unreleased=8;
	};
	
	if modBranchConfigs.CurrentBranch.Name == "Live" then
		missionTypeOrder.Unreleased = nil;
	end

	local activeEntryTween: Tween;	
	function Interface.RefreshMissionMap()
		local mapTypes = {
			[modMissionsLibrary.MissionTypes.Core] = 0;
			[modMissionsLibrary.MissionTypes.Side] = 1;
			[modMissionsLibrary.MissionTypes.Premium] = 2;
		};

		local function validMissionType(missionLib)
			return mapTypes[missionLib.MissionType] ~= nil;
		end
		
		local missionsProfile = modTableManager.GetDataHierarchy(modData.Profile, "GameSave/Missions");

		local missionsData = {};
		local pinnedMissionData = nil;
		local selectableMissions, selectIndex = {}, 1;

		for a=1, #missionsProfile do
			local missionData = missionsProfile[a];

			local lib = modMissionsLibrary.Get(missionData.Id);

			if missionData.Pinned then
				pinnedMissionData = missionData;
			end

			missionsData[missionData.Id] = missionData;
			-- {"Type":2 "StartTime":1697328143 "ProgressionPoint":1 "Id":67 "AddTime":1697328143 "CatType":4 "SaveData":{}}
			if missionData.Type ~= 3 and validMissionType(lib) then 
				table.insert(selectableMissions, missionData);
				if missionData.Pinned then
					selectIndex = #selectableMissions;
				end
			end
		end
		
		local activeHighlightEntry = nil;
		local function highlightMapEntry()
			local missionMap = MissionDisplayFrame.MissionsMap;
			local backButton: TextButton = missionMap.BackMission;
			local nextButton: TextButton = missionMap.NextMission;
			local scrollFrame = missionMap.ScrollingFrame;
			
			if #selectableMissions <= 0 then
				backButton.Visible = false;
				nextButton.Visible = false;
				
				return;
			end
			
			backButton.Visible = true;
			nextButton.Visible = true;
			
			local missionData = selectableMissions[selectIndex];
			
			local id = missionData.Id;
			
			local newEntry: TextButton = scrollFrame:FindFirstChild(id);
			if newEntry == nil then return end;
			
			scrollFrame.CanvasPosition = Vector2.new(
				newEntry.Position.X.Offset - (missionMap.AbsoluteSize.X/2) + (newEntry.AbsoluteSize.X/2), 
				newEntry.Position.Y.Offset - (missionMap.AbsoluteSize.Y/2) + (newEntry.AbsoluteSize.Y/2)
			);
			task.spawn(function()
				task.wait(0.1);
				activeHighlightEntry = id;

				activeEntryTween = TweenService:Create(
					newEntry, 
					TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 1, true), {
						BackgroundColor3=Color3.fromRGB(75, 75, 75);
					}
				);
				
				while activeHighlightEntry == id do
					activeEntryTween:Play();
					task.wait(1);
				end
			end)
		end
		
		local missionMap = MissionDisplayFrame:FindFirstChild("MissionsMap");
		if missionMap == nil then
			missionMap = missionMapTemplate:Clone();
			missionMap.Parent = MissionDisplayFrame;
			
			local backButton:TextButton = missionMap:WaitForChild("BackMission");
			local nextButton:TextButton = missionMap:WaitForChild("NextMission");
			
			backButton.MouseButton1Click:Connect(function()
				if #selectableMissions <= 0 then return end;
				
				Interface:PlayButtonClick();
				selectIndex = selectIndex-1;
				if selectIndex < 1 then
					selectIndex = #selectableMissions;
				end
				highlightMapEntry();
			end)
			nextButton.MouseButton1Click:Connect(function()
				if #selectableMissions <= 0 then return end;
				
				Interface:PlayButtonClick();
				selectIndex = selectIndex+1;
				if selectIndex > #selectableMissions then
					selectIndex = 1;
				end
				highlightMapEntry();
			end)

			local mapCanvas :ScrollingFrame = missionMap:WaitForChild("ScrollingFrame");
			mapCanvas:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
				activeHighlightEntry = nil;
				if activeEntryTween then
					activeEntryTween:Cancel();
				end
			end)
		end
		
		local scrollFrame = missionMap:WaitForChild("ScrollingFrame");
		
		local rootNode = nil;
		local missionChecked = {};

		local function mapOutMission(id, parentNode)
			local lib = modMissionsLibrary.Get(id);
			if lib == nil then return end;
			if missionChecked[id] then Debugger:Warn("Mission (",id,") already mapped."); return end; missionChecked[id] = true;
			if not validMissionType(lib) then return end;
			
			local newNode = {
				Id=id;
				Type=mapTypes[lib.MissionType];
				Children={};
			};
			
			if parentNode == nil then
				rootNode = newNode;
				
			else
				table.insert(parentNode.Children, newNode);
				
			end
			
			local linkNextMission = lib.LinkNextMission;
			
			if lib.Rewards then
				for a=1, #lib.Rewards do
					local rewardInfo = lib.Rewards[a];
					if rewardInfo.Type ~= "Mission" then continue end;
					if rewardInfo.Id == linkNextMission then continue; end
					
					mapOutMission(rewardInfo.Id, newNode);
				end
			end
			
			if linkNextMission then
				mapOutMission(lib.LinkNextMission, newNode);
			end
		end
		mapOutMission(1, nil);
		
		local function sortChildren(node)
			table.sort(node.Children, function(a, b)
				return a.Type > b.Type;
			end)
			for a=1, #node.Children do
				sortChildren(node.Children[a]);
			end
		end
		sortChildren(rootNode);
		
		
		local function countChildren(node, baseType)
			local c = 0;
			
			if baseType == nil then baseType = node.Type; end
			
			for a=1, #node.Children do
				local nextNode = node.Children[a];
				if nextNode.Type > baseType then
					c = c + 1 + countChildren(nextNode, baseType);
				end
			end
			
			return c;
		end
		
		local pinRequestDebounce = false;
		
		local entryXSize, entryYSize = (mapEntryTemplate.Size.X.Offset+20), (mapEntryTemplate.Size.Y.Offset+20);
		local order = 0;
		local function renderNode(node, parentNode, depth)
			depth = depth or 0;
			local id = node.Id;
			local lib = modMissionsLibrary.Get(id);
			
			local missionData = missionsData[id];

			local orderPos = order;
			if depth then
				orderPos = orderPos - depth;
			end
			node.Order = orderPos;

			local newEntry: TextButton = scrollFrame:FindFirstChild(id);
			if newEntry == nil then
				newEntry = mapEntryTemplate:Clone();
				newEntry.Name = id;

				newEntry.MouseButton1Click:Connect(function()
					if modBranchConfigs.CurrentBranch.Name == "Dev" then
						Debugger:Warn("Id",id,"ChildCount",countChildren(node),"Order",node.Order, "missionData", missionData);
					end
					if missionData == nil then return end;
					Interface:PlayButtonClick();
					Interface.Select(id);
				end)
				newEntry.MouseButton2Click:Connect(function()
					if missionData == nil then return end;
					
					if pinRequestDebounce then return end;
					pinRequestDebounce = true;

					Interface:PlayButtonClick();
					remotePinMission:FireServer(missionData.Id);

					task.wait(modConfigurations.CompactInterface and 1 or 0.5);
					pinRequestDebounce = false;
				end)

				if parentNode then
					if node.Type == parentNode.Type then
						local bar = Instance.new("Frame");
						bar.Name = "bar";
						bar.BackgroundColor3 = Color3.fromRGB(100, 100, 100);
						bar.BorderSizePixel = 0;
						bar.AnchorPoint = Vector2.new(0.5, 1);
						bar.Position = UDim2.new(0.5, 0, 0.5, 0);
						bar.Size = UDim2.new(0, 10, 0, (node.Order-parentNode.Order)*entryYSize);
						bar.ZIndex = 1;
						bar.Parent = newEntry;

					elseif node.Type > parentNode.Type then
						local bar = Instance.new("Frame");
						bar.Name = "bar";
						bar.BackgroundColor3 = Color3.fromRGB(100, 100, 100);
						bar.BorderSizePixel = 0;
						bar.AnchorPoint = Vector2.new(1, 0.5);
						bar.Position = UDim2.new(0.5, 0, 0.5, 0);
						bar.Size = UDim2.new(0, (node.Type-parentNode.Type)*entryXSize, 0, 10);
						bar.ZIndex = 1;
						bar.Parent = newEntry;

					end
				end

			end
			
			
			local titleLabel: TextLabel = newEntry:WaitForChild("Title") :: TextLabel;
			local dbSuffix = " ("..lib.MissionId..")";
			titleLabel.Text = lib.Name.. (modBranchConfigs.CurrentBranch.Name == "Dev" and dbSuffix or "");
			
			local npcLib = modNpcProfileLibrary:Find(lib.From);
			local avatarLabel: ImageButton = newEntry:WaitForChild("Avatar") :: ImageButton;
			if npcLib and npcLib.Avatar then
				avatarLabel.Image = npcLib.Avatar;
			end
		
			if missionData then
				newEntry.AutoButtonColor = true;
				if missionData.Type == 1 then -- Active
					newEntry.BackgroundColor3 = Color3.fromRGB(100, 113, 120);
				elseif missionData.Type == 2 then -- Available
					newEntry.BackgroundColor3 = Color3.fromRGB(100, 100, 100);
				elseif missionData.Type == 3 then -- Complete
					newEntry.BackgroundColor3 = Color3.fromRGB(50, 50, 50);
				elseif missionData.Type == 4 then -- Failed
					newEntry.BackgroundColor3 = Color3.fromRGB(100, 80, 80);
				end
				titleLabel.TextColor3 = Color3.fromRGB(255,255,255);
				avatarLabel.ImageColor3 = Color3.fromRGB(255,255,255);

				for _, obj in pairs(newEntry:GetChildren()) do
					if obj.Name ~= "bar" then continue end;
					obj.BackgroundColor3 = Color3.fromRGB(100, 100, 100);
				end
				
			else
				newEntry.AutoButtonColor = false;
				newEntry.BackgroundColor3 = Color3.fromRGB(25, 25, 25);
				titleLabel.TextColor3 = Color3.fromRGB(50,50,50);
				avatarLabel.ImageColor3 = Color3.fromRGB(0, 0, 0);
				
				for _, obj in pairs(newEntry:GetChildren()) do
					if obj.Name ~= "bar" then continue end;
					obj.BackgroundColor3 = Color3.fromRGB(25, 25, 25);
				end
				
			end
			
			newEntry.Position = UDim2.new(0, node.Type*entryXSize, 0, orderPos*entryYSize);
			newEntry.Parent = scrollFrame;
			
			local strokeUI = newEntry:WaitForChild("UIStroke");
			if pinnedMissionData and pinnedMissionData.Id == node.Id then
				strokeUI.Color = branchColor;
				strokeUI.Enabled = true;

			else
				strokeUI.Enabled = false;
			end
			
			order = order +1;
			
			for a=1, #node.Children do
				local childNode = node.Children[a];
				local newDepth = depth;
				if childNode.Type > node.Type then
					newDepth = newDepth +1;
				end
				renderNode(childNode, node, newDepth);
			end
			
		end
		renderNode(rootNode);
		highlightMapEntry();
	end
	
	function Interface.Select(id)
		MissionDisplayFrame:ClearAllChildren();
		
		if id == nil then return end
		local data = getMissionData(id);
		local book = modMissionsLibrary.Get(id);
		if data == nil then Debugger:Warn("Missing mission data. Id:",id); return end;
		if book == nil then Debugger:Warn("Missing mission library. Id:",id); return end;
		if data.Type == 1 or data.Type == 3 then
			local menu = activeDetailsFrameTemplate:Clone();
			local titleTag = menu:WaitForChild("Title");
			local fromTag = menu:WaitForChild("FromTag");
			local descTag = menu:WaitForChild("Desc");
			titleTag.Text = book.Name;
			fromTag.Text = book.From or "";
			descTag.Text = book.Description;
			
			local closeButton = menu:WaitForChild("closeButton");
			closeButton.MouseButton1Click:Connect(function()
				MissionDisplayFrame:ClearAllChildren();
				Interface.RefreshMissionMap();
			end)

			if data.Type == 3 and book.CanRedo then
				local newRedoButton = redoButtonTemplate:Clone();
				
				local debounce = false;
				newRedoButton.MouseButton1Click:Connect(function()
					Interface:PlayButtonClick();
					local promptWindow = Interface:PromptQuestion("Redo "..book.Name, 
						"Are you sure you want to redo mission, <b>"..book.Name.."</b>?\n\n<b>Your choices will be updated after redoing.</b>");
					local YesClickedSignal, NoClickedSignal;

					YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
						if debounce then return end;
						debounce = true;
						Interface:PlayButtonClick();

						local _r = remoteMissionRemote:InvokeServer("Redo", id);

						promptWindow:Close();
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
					end);
					NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
						if debounce then return end;
						Interface:PlayButtonClick();
						promptWindow:Close();
						Interface:OpenWindow("Missions");
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
					end);
				end)

				newRedoButton.Parent = MissionDisplayFrame;
			end

			if book.MissionType == modMissionsLibrary.MissionTypes.Repeatable then
				if data.AddTime and book.ExpireTime then
					local timeLapsed = book.ExpireTime-math.clamp(os.time()-data.AddTime, 0, book.ExpireTime);
					descTag.Text = descTag.Text.."\n".."Refreshes: "..(modSyncTime.ToString(timeLapsed));
				end
				titleTag.Text = titleTag.Text.." (Board Mission)";
				
				if data.Type ~= 3 then
					menu.AbortButton.Visible = true;
				end

				local debounce = false;
				menu.AbortButton.MouseButton1Click:Connect(function()
					Interface:PlayButtonClick();
					local promptWindow = Interface:PromptQuestion("Abort "..book.Name, 
						"Are you sure you want to abort mission, <b>"..book.Name.."</b>?\n\n<b>It will be considered as failed mission.</b>");
					local YesClickedSignal, NoClickedSignal;

					YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
						if debounce then return end;
						debounce = true;
						Interface:PlayButtonClick();

						local _r = remoteMissionRemote:InvokeServer("Abort", id);

						promptWindow:Close();
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
					end);
					NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
						if debounce then return end;
						Interface:PlayButtonClick();
						promptWindow:Close();
						Interface:OpenWindow("Missions");
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
					end);
				end)
				
			elseif book.MissionType == modMissionsLibrary.MissionTypes.Secret then
				titleTag.Text = titleTag.Text.." (Secret Mission)";
			end

			local taskLabel = menu:WaitForChild("tasksLabel");
			local taskList = menu:WaitForChild("TaskBackground"):WaitForChild("TaskList");
			
			local logList = menu:WaitForChild("LogBackground"):WaitForChild("LogList");
			local logLayout = logList:WaitForChild("UIListLayout");


			if book.Checkpoint then
				taskLabel.Text = "Checkpoint:";

				for a=1, #book.Checkpoint do
					local checkpointInfo = book.Checkpoint[a];

					local newTaskLabel = taskListingTemplate:Clone();
					local label = newTaskLabel:WaitForChild("TaskLabel");
					label.Text = checkpointInfo.Text;
					
					if data.SaveData then
						for k, v in pairs(data.SaveData) do
							if label.Text:find("$"..k) then
								local newVal = v;

								if tonumber(newVal) then
									newVal = modFormatNumber.Beautify(tonumber(newVal));
								end

								label.Text = label.Text:gsub("$"..k, newVal);
							end
						end
					end
					
					local pointColor = Color3.fromRGB(60, 60, 60);
					
					if data.ProgressionPoint > a or data.Type == 3 then --set complete
						pointColor = Color3.fromRGB(180, 180, 180);
					elseif data.ProgressionPoint == a then
						pointColor = Color3.fromRGB(180, 60, 60);
					end
					
					local completionBox = newTaskLabel:WaitForChild("CompletionBox");
					completionBox.BackgroundColor3 = pointColor;
					
					newTaskLabel.Parent = taskList;
				end


			elseif book.Progression then
				taskLabel.Text = "Progression:";
				for a=1, #book.Progression do
					local progressionPointInfo = book.Progression[a];

					local newTaskLabel = taskListingTemplate:Clone();
					local label = newTaskLabel:WaitForChild("TaskLabel");
					label.Text = typeof(progressionPointInfo) == "table" and progressionPointInfo.ActiveText or progressionPointInfo;

					if data.SaveData then
						for k, v in pairs(data.SaveData) do
							if label.Text:find("$"..k) then
								local newVal = v;

								if tonumber(newVal) then
									newVal = modFormatNumber.Beautify(tonumber(newVal));
								end

								label.Text = label.Text:gsub("$"..k, newVal);
							end
						end
					end

					local pointColor = Color3.fromRGB(60, 60, 60);

					if data.ProgressionPoint > a or data.Type == 3 then --set complete
						pointColor = Color3.fromRGB(180, 180, 180);
					elseif data.ProgressionPoint == a then
						pointColor = Color3.fromRGB(180, 60, 60);
					end

					local completionBox = newTaskLabel:WaitForChild("CompletionBox");
					completionBox.BackgroundColor3 = pointColor;
					
					newTaskLabel.Parent = taskList;
				end

			elseif book.Objectives or data.Type == 3 then
				taskLabel.Text = "Objectives:";
				for objName, obj in pairs(book.Objectives) do
					local newTaskLabel = taskListingTemplate:Clone();
					local label = newTaskLabel:WaitForChild("TaskLabel");

					label.Text = loadObjectiveDescription(data, objName, obj);

					if data.SaveData then
						for k, v in pairs(data.SaveData) do
							if label.Text:find("$"..k) then
								local newVal = v;

								if tonumber(newVal) then
									newVal = modFormatNumber.Beautify(tonumber(newVal));
								end

								label.Text = label.Text:gsub("$"..k, newVal);
							end
						end
					end
					
					local pointColor = Color3.fromRGB(60, 60, 60);
					if data.ObjectivesCompleted[objName] then
						pointColor = Color3.fromRGB(180, 180, 180);
					end
					
					local completionBox = newTaskLabel:WaitForChild("CompletionBox");
					completionBox.BackgroundColor3 = pointColor;
					
					newTaskLabel.Parent = taskList;
				end

			end

			if data.Type == 3 then
				local order = 1;
				for a=1, #(book.LogEntry or {}) do
					local logEntries = book.LogEntry[a];
					if logEntries.Dialogue then
						local logListing = logListingTemplate:Clone();
						logListing.Text = (localPlayer.Name..": ".. logEntries.Dialogue):gsub("$PlayerName", localPlayer.Name);
						logListing.LayoutOrder = order;
						local textBounds = TextService:GetTextSize(logListing.Text, logListing.TextSize, logListing.Font, Vector2.new(logListing.AbsoluteSize.X, 999));
						logListing.Size = UDim2.new(1, -10, 0, textBounds.Y);
						logListing.Parent = logList;
						order = order +1;
					end

					local logListing = logListingTemplate:Clone();
					logListing.Text = logEntries.Speaker..": ".. logEntries.Reply;
					logListing.LayoutOrder = order;
					local textBounds = TextService:GetTextSize(logListing.Text, logListing.TextSize, logListing.Font, Vector2.new(logListing.AbsoluteSize.X, 999));
					logListing.Size = UDim2.new(1, -10, 0, textBounds.Y);
					logListing.Parent = logList; 
					order = order +1;
				end
				logList.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y);
				logList.CanvasPosition = Vector2.new(0, 9999);
			end

			menu.Parent = MissionDisplayFrame;
			
			
		else
			local menu = availableDetailsFrameTemplate:Clone();
			local titleTag = menu:WaitForChild("Title");
			local fromTag = menu:WaitForChild("FromTag");
			local descTag = menu:WaitForChild("Desc");
			titleTag.Text = book.Name;
			fromTag.Text = book.From or "";
			descTag.Text = book.Description;
			menu.Parent = MissionDisplayFrame;

			local closeButton = menu:WaitForChild("closeButton");
			closeButton.MouseButton1Click:Connect(function()
				MissionDisplayFrame:ClearAllChildren();
				Interface.RefreshMissionMap();
			end)
			
			if book.MissionType == modMissionsLibrary.MissionTypes.Repeatable then
				if data.AddTime and book.ExpireTime then
					local timeLapsed = book.ExpireTime-math.clamp(os.time()-data.AddTime, 0, book.ExpireTime);
					descTag.Text = descTag.Text.."\n".."Refreshes: "..(modSyncTime.ToString(timeLapsed));
				end
				titleTag.Text = titleTag.Text.." (Board Mission)";
			elseif book.MissionType == modMissionsLibrary.MissionTypes.Secret then
				titleTag.Text = titleTag.Text.." (Secret Mission)";
			end

			local requirementsTitle = menu:WaitForChild("requirementsList");
			if book.StartRequirements then
				local requirementsMenu = menu:WaitForChild("RequirementsBackground");
				local requirementsList = requirementsMenu:WaitForChild("RequirementsList");
				local listLayout = requirementsList:WaitForChild("UIListLayout");

				requirementsTitle.Visible = true;
				requirementsMenu.Visible = true;

				local requirementPresets = {
					{Tag="Premium"; Text="• Premium Member"};
					{Tag="Level"; Text="• Mastery Level: $value"};
				};
				
				for a=1, #requirementPresets do
					local preset = requirementPresets[a];
					if book.StartRequirements[preset.Tag] then
						local newLabel = logListingTemplate:Clone();
						newLabel.Font = Enum.Font.Arial;
						newLabel.Text = preset.Text:gsub("$value", tostring(book.StartRequirements[preset.Tag]));
						newLabel.LayoutOrder = a;
						newLabel.Size = UDim2.new(1, -10, 0, 15);
						newLabel.Visible = true;
						newLabel.Parent = requirementsList;
					end
				end
				if book.StartRequirements.MissionCompleted then
					for a=1, #book.StartRequirements.MissionCompleted do
						local reqMissionId = book.StartRequirements.MissionCompleted[a];
						local reqMissionLib = modMissionsLibrary.Get(reqMissionId);
						
						local newLabel = logListingTemplate:Clone();
						newLabel.Font = Enum.Font.Arial;
						newLabel.Text = "• Mission: ".. reqMissionLib.Name;
						newLabel.LayoutOrder = a;
						newLabel.Size = UDim2.new(1, -10, 0, 15);
						newLabel.Visible = true;
						newLabel.Parent = requirementsList;
					end 
				end
				requirementsList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y);
			end
			local rewardsTitle = menu:WaitForChild("rewardsLabel");
			if book.Rewards then
				local rewardsMenu = menu:WaitForChild("RewardsBackground");
				local rewardsList = rewardsMenu:WaitForChild("RewardsList");
				local listLayout = rewardsList:WaitForChild("UIListLayout");
				rewardsTitle.Visible = true;
				rewardsMenu.Visible = true;

				for a=1, #book.Rewards do
					local reward = book.Rewards[a];
					local rewardType = reward.Type;
					local preset = rewardsPresets[rewardType];
					if preset then
						local newLabel = logListingTemplate:Clone();
						newLabel.Font = Enum.Font.Arial;
						if rewardType == "Mission" then
							local rewardMission = modMissionsLibrary.Get(reward.Id);
							newLabel.Text = preset.Text:gsub("$value", rewardMission and rewardMission.Name or "MissionId("..reward.Id..")");

						elseif rewardType == "Perks" then
							local perkAmount = reward.Amount;
							--if book.MissionType == 4 then
							--	local playerLevel = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.Level or 0;
							--	perkAmount = math.clamp(playerLevel, 1, modGlobalVars.MaxDailyMissionPerkReward);
							--end
							newLabel.Text = preset.Text:gsub("$value", perkAmount);

						elseif rewardType == "Item" then
							local itemLib = modItemsLibrary:Find(reward.ItemId);
							newLabel.Text = preset.Text:gsub("$amt", reward.Quantity):gsub("$item", itemLib.Name);

						end
						newLabel.LayoutOrder = a;
						newLabel.Size = UDim2.new(1, -10, 0, 15);
						newLabel.Visible = true;
						newLabel.Parent = rewardsList;
					end
				end
				rewardsList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y);
			end
			
			
		end
	end
	
	local repeatableMissionList = {};
	local levelSlotsInfo = {};
	local finalSlotInfo = {
		Slot=nil;
	};
	
	local pinRequestDebounce = false;
	function Interface.Update()
		hideComplete = modData.Settings and modData.Settings["HideCM"] == 1;
		local _maxActiveMissions = modData.Profile and modData.Profile.Premium and 5 or 3;

		local missionsList = modTableManager.GetDataHierarchy(modData.Profile, "GameSave/Missions") or {};

		local missionTypesList = {};
		for typeKey, _ in pairs(missionTypeOrder) do
			missionTypesList[typeKey] = {};
		end
		
		table.clear(repeatableMissionList);
		
		local pinnedMission = nil;
		local pinnedMissionLib;
		for a=1, #missionsList do
			local book = modMissionsLibrary.Get(missionsList[a].Id);
			if missionsList[a].Pinned then
				pinnedMissionLib = book;
				pinnedMission = missionsList[a];
				if pinnedMissionName ~= book.Name then
					cancelAllMissionFunctions();
				end
			end

			local typeKey = modMissionsLibrary.GetTypeKey(book.MissionType);
			
			if missionTypesList[typeKey] then
				table.insert(missionTypesList[typeKey], {
					Data=missionsList[a];
					Lib=book;
				});
				
			elseif typeKey == "Repeatable" then
				table.insert(repeatableMissionList, {
					Data=missionsList[a];
					Lib=book;
				});
				
			end
		end
		
		
		local headIconUpdated = {};
		local updated = {}; 
		
		local function newMissionList(typeKey, typeOrder, config)
			config = config or {};
			
			local newTab, newList;
			if tabAndLists[typeKey] == nil then
				newTab = tabTemplate:Clone();
				local titleLabel = newTab:WaitForChild("titleLabel");
				local semiCollapseSign = newTab:WaitForChild("semiCollapseSign");
				local collapseSign = newTab:WaitForChild("collapseSign");
				local expandSign = newTab:WaitForChild("expandSign");
				
				newTab.Name = typeKey;
				newTab.Parent = MissionListFrame;
				newTab.LayoutOrder = typeOrder;

				newList = listTemplate:Clone();
				newList.Name = typeKey;

				newList.Parent = MissionListFrame;
				newList.LayoutOrder = typeOrder;

				if typeKey == "Premium" then -- Premium missions;
					titleLabel.TextColor3 = Color3.fromRGB(185, 139, 0);
					collapseSign.BackgroundColor3 = titleLabel.TextColor3;
					expandSign.BackgroundColor3 = titleLabel.TextColor3;
					semiCollapseSign.BackgroundColor3 = titleLabel.TextColor3;
				end

				local function toggle()
					if config.ForceExpand then
						modData.Settings["HideTab"..typeKey] = nil;
						collapseSign.Visible = false;
						semiCollapseSign.Visible = false;
						expandSign.Visible = false;
						newList.Visible = true;
						for _, obj in pairs(newList:GetChildren()) do
							if not obj:IsA("GuiObject") then continue end;
							obj.Visible = true;
							
						end		

					elseif modData.Settings["HideTab"..typeKey] == nil then -- Show only active;
						collapseSign.Visible = true;
						semiCollapseSign.Visible = false;
						--newList.Visible = false;

						local exist = false;
						for _, obj in pairs(newList:GetChildren()) do
							if not obj:IsA("GuiObject") then continue end;
							if obj:GetAttribute("ForceShow") == true then
								obj.Visible = true;
								exist = true;
								
							elseif obj:GetAttribute("MissionStatus") == 1 then
								obj.Visible = true;
								exist = true;
							else
								obj.Visible = false;
							end
						end
						newList.Visible = exist;

					elseif modData.Settings["HideTab"..typeKey] == 1 then -- Hide complete only
						collapseSign.Visible = false;
						semiCollapseSign.Visible = true;

						local exist = false;
						for _, obj in pairs(newList:GetChildren()) do
							if obj:GetAttribute("ForceShow") == true then
								obj.Visible = true;
								exist = true;

							elseif obj:GetAttribute("MissionStatus") == 3 then
								obj.Visible = false;
								
							elseif obj:GetAttribute("MissionStatus") == 1 or obj:GetAttribute("MissionStatus") == 2
								or obj:GetAttribute("MissionStatus") == 4 then
								obj.Visible = true;
								exist = true;
								
							end
						end
						newList.Visible = exist;

					else
						collapseSign.Visible = false;
						semiCollapseSign.Visible = false;
						newList.Visible = true;

						for _, obj in pairs(newList:GetChildren()) do
							if obj:GetAttribute("MissionStatus") ~= nil then
								obj.Visible = true;
							end
						end
						
					end
				end
				
				
				newTab.MouseButton1Click:Connect(function()
					Interface:PlayButtonClick();
					modData:UpdateSettings(function()
						if modData.Settings["HideTab"..typeKey] == nil then
							modData.Settings["HideTab"..typeKey] = 1;

						elseif modData.Settings["HideTab"..typeKey] == 1 then
							modData.Settings["HideTab"..typeKey] = 2;

						else
							modData.Settings["HideTab"..typeKey] = nil;

						end
					end)
					toggle();
				end)
				
				tabAndLists[typeKey] = {Tab=newTab; List=newList; Toggle=toggle;};
			else
				newTab = tabAndLists[typeKey].Tab;
				newList = tabAndLists[typeKey].List;
			end
			
			return newTab, newList;
		end
		
		local function createListing(missionInfo, newTab, newList)
			local missionData = missionInfo.Data;
			local book = missionInfo.Lib;

			local key = missionData.StartTime..":"..missionData.Id;
			local newListing = missionListings[key];

			local function pinButton()
				if pinRequestDebounce then return end;
				pinRequestDebounce = true;

				Interface:PlayButtonClick();
				remotePinMission:FireServer(missionData.Id);

				wait(modConfigurations.CompactInterface and 1 or 0.5);
				pinRequestDebounce = false;
			end
			
			if newListing == nil or newListing.Parent == nil then
				newListing = missionListingTemplate:Clone();
				newListing.Parent = newList;

				local missionTypeIcon = newListing:WaitForChild("MissionType");

				if missionInfo.Lib.MissionType == modMissionsLibrary.MissionTypes.Repeatable then
					missionTypeIcon.Image = "rbxassetid://13870681338";
					missionTypeIcon.Visible = true;

				elseif missionInfo.Lib.MissionType == modMissionsLibrary.MissionTypes.Faction then
					missionTypeIcon.Image = "rbxassetid://9890634236";
					missionTypeIcon.Visible = true;
				end

				newListing.Visible = not hideComplete;

				local missionIdTag = Instance.new("IntValue");
				missionIdTag.Name = "MissionId";
				missionIdTag.Value = missionData.Id;
				missionIdTag.Parent = newListing;

				newListing:SetAttribute("MissionStatus", missionData.Type);
				titleLabels[key] = {Label=newListing:WaitForChild("Title"); Color=Color3.fromRGB(255, 255, 255)};


				newListing.MouseLeave:Connect(function()
					newListing.Title.TextColor3 = titleLabels[key].Color;
				end)
				newListing.MouseEnter:Connect(function()
					for k, other in pairs(titleLabels) do
						other.Label.TextColor3 = titleLabels[k].Color;
					end
					newListing.Title.TextColor3 = branchColor;
				end)
				newListing.MouseButton1Click:Connect(function()
					newListing.Title.TextColor3 = Color3.new(branchColor.R*1.5, branchColor.G*1.5, branchColor.B*1.5);
					Interface.Select(missionData.Id);
					delay(0.25, function()
						newListing.Title.TextColor3 = titleLabels[key].Color;
					end);
				end)

				newListing.TouchLongPress:Connect(pinButton);
				newListing.MouseButton2Click:Connect(pinButton);
			end
			newListing.Name = key;
			updated[key] = true;
			missionListings[key] = newListing;

			local titleTag = newListing:WaitForChild("Title");
			local fromTag = newListing:WaitForChild("QuestFrom");
			local taskTag = newListing:WaitForChild("NextTask");
			local pinStatus = newListing:WaitForChild("pinStatus");

			if missionData.Pinned and missionData.Type ~= 3 then
				newListing.LayoutOrder = 0;
				newListing.ImageColor3 = Color3.fromRGB(100, 100, 100);
				pinStatus.BackgroundColor3 = missionMarkerColor;
				pinStatus.Visible = true;
				newListing.Parent = PinnedMissionFrame;

			else
				newListing.Parent = newList;
				if missionData.Type == 1 then
					newListing.LayoutOrder = 1;
					newListing.ImageColor3 = Color3.fromRGB(100, 100, 100);
					pinStatus.BackgroundColor3 = missionMarkerColor;
					titleTag.TextColor3 = Color3.fromRGB(200, 200, 200);
					pinStatus.Visible = true;

				elseif missionData.Type == 2 then
					newListing.LayoutOrder = 2;
					newListing.ImageColor3 = Color3.fromRGB(100, 100, 100);
					pinStatus.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
					titleTag.TextColor3 = Color3.fromRGB(255, 255, 255);
					pinStatus.Visible = true;

				elseif missionData.Type == 3 then
					missionData.Pinned = false;
					newListing.LayoutOrder = 4;
					newListing.ImageColor3 = Color3.fromRGB(30, 30, 30);
					titleTag.TextColor3 = Color3.fromRGB(110, 110, 110);
					pinStatus.Visible = false;

				elseif missionData.Type == 4 then
					newListing.LayoutOrder = 2;
					newListing.ImageColor3 = Color3.fromRGB(100, 80, 80);
					pinStatus.BackgroundColor3 = Color3.fromRGB(159, 82, 82);
					pinStatus.Visible = true;
					titleTag.TextColor3 = Color3.fromRGB(255, 255, 255);

				end
				titleLabels[key].Color = titleTag.TextColor3;
			end

			if book then
				local dbSuffix = " ("..book.MissionId..")";
				
				titleTag.Text = book.Name.. (modBranchConfigs.CurrentBranch.Name == "Dev" and dbSuffix or "");
				fromTag.Text = book.From or "";

				if missionData.Type == 1 then -- Active
					taskTag.Text = "";

					if book.Checkpoint then
						local checkpointInfo = book.Checkpoint[missionData.ProgressionPoint];

						taskTag.Text = "• ".. checkpointInfo.Text;
						if missionData.SaveData then
							for k, v in pairs(missionData.SaveData) do
								if taskTag.Text:find("$"..k) then
									local newVal = v;
									
									if tonumber(newVal) then
										newVal = modFormatNumber.Beautify(tonumber(newVal));
									end
									
									taskTag.Text = taskTag.Text:gsub("$"..k, newVal);
								end
							end
						end

					elseif book.Progression then
						local progressionTask = book.Progression[missionData.ProgressionPoint];

						taskTag.Text = progressionTask and "• "..progressionTask or "";
						if missionData.SaveData then
							for k, v in pairs(missionData.SaveData) do
								if taskTag.Text:find("$"..k) then
									taskTag.Text = taskTag.Text:gsub("$"..k, v);
								end
							end
						end

					elseif book.Objectives then
						local allCompleted = true;
						for objName, obj in pairs(book.Objectives) do
							if missionData.ObjectivesCompleted[objName] ~= true then
								taskTag.Text = loadObjectiveDescription(missionData, objName, obj);
								allCompleted = false;
								break;
							end
						end
						if allCompleted then
							local itemlib = missionData.SaveData.ItemId and modItemsLibrary:Find(missionData.SaveData.ItemId);
							taskTag.Text = book.ObjectivesCompleteText:gsub("$ItemName", itemlib and itemlib.Name or missionData.SaveData.ItemId or "");
						end
						taskTag.Text = "• "..taskTag.Text;

					end

				elseif missionData.Type == 2 then -- Available
					taskTag.Text = book.GuideText or "";
					if book.From and workspace.Entity:FindFirstChild(book.From) then
						local npcName = book.From;
						modHeadIcons.Set(npcName, "Mission");
						headIconUpdated[npcName] = true;
					end

				elseif missionData.Type == 3 then -- Completed
					--local playerLevel = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.Level or 0;
					--taskTag.Text = book.RewardText and string.gsub(book.RewardText, "$dailyPerks", perkAmount) or "";

				elseif missionData.Type == 4 then -- Failed
					local failedReason = tonumber(missionData.FailTag) or missionData.FailTag;
					if failedReason == 1 then
						failedReason = "You ran out of time.";
					elseif failedReason == 2 then
						failedReason = "You died.";
					elseif failedReason == 3 then
						failedReason = "The mission was removed.";
					elseif failedReason == 4 then
						failedReason = "The mission has expired.";
					end

					taskTag.Text = "Failed: "..tostring(failedReason);
				end

				if missionData.Pinned then
					pinnedTitleTag.Text = book.Name;

					if newPinNotification then
						local titleLabel = newPinNotification:WaitForChild("Title");
						local taskLabel = newPinNotification:WaitForChild("Task");
						titleLabel.Text = pinnedMissionName;
						taskLabel.Text = pinnedTaskTag.Text;
					end

					local missionTypeTitle = ""
					for mType, id in pairs(modMissionsLibrary.MissionTypes) do
						if book.MissionType == id then
							missionTypeTitle = mType;
							if mType == "Repeatable" then
								missionTypeTitle = "Board";
							end
							break;
						end
					end

					Interface.UpdatePinnedHud = function()
						missionsList = modTableManager.GetDataHierarchy(modData.Profile, "GameSave/Missions");
						
						local missionId = missionData.Id;
						for a=1, #missionsList do
							if missionsList[a].Id == missionId then
								missionData = missionsList[a];
								break;
							end
						end
						if missionData == nil then
							Debugger:Warn("Mission data for pinned (",missionId,") no longer exist.");
							Interface.UpdatePinnedHud = nil;
							missionPinHud.Visible = false;
							return;
						end
						
						local timeLapsed = os.time()-missionData.StartTime;

						pinnedHintLabel.Text = (timeLapsed <= 10 and "New " or "")..missionTypeTitle.." Mission";

						local missionTimer = book.Timer or missionData.Timer;
						if missionTimer then
							local timeLeft = math.clamp(missionTimer-timeLapsed, 0, math.huge);
							if timeLeft > 0 then
								if timeLeft < 10 then
									pinnedTimerTag.TextColor3 = Color3.fromRGB(255, 128, 128);
								else
									pinnedTimerTag.TextColor3 = Color3.fromRGB(255, 255, 255);
								end
								pinnedTimerTag.Text = modSyncTime.ToString(timeLeft);
								pinnedTimerTag.Visible = true;
							else
								pinnedTimerTag.Text = "";
								pinnedTimerTag.Visible = false;
							end 
						else
							pinnedTimerTag.Visible = false;
						end
					end
					Interface.UpdatePinnedHud();


					if missionData.Type == 1 then
						if book.Checkpoint then
							local checkpointInfo = book.Checkpoint[missionData.ProgressionPoint];

							local incomplete = false;

							local objectiveIds = checkpointInfo.Objectives;
							if objectiveIds then
								for _, obj in pairs(pinnedTasklist:GetChildren()) do
									if obj:IsA("GuiObject") then
										obj:Destroy();
									end
								end

								for a=1, #objectiveIds do
									local objectiveId = objectiveIds[a];
									local objectiveInfo = book.Objectives[objectiveId];

									local newTask = taskTemplate:Clone();
									
									local taskStr = loadObjectiveDescription(missionData, objectiveId, objectiveInfo);
									newTask.LayoutOrder = objectiveInfo.Index;
									newTask.Parent = pinnedTasklist;

									if missionData.ObjectivesCompleted[objectiveId] == true then
										taskStr = "<s>"..taskStr.."</s>"
									else
										incomplete = true;
									end
									newTask.Text = "• "..taskStr;
								end

								pinnedTasklist.Visible = true;
								pinnedTaskTag.Visible = false;
								pinnedTaskTag.Text = "";
								
								if not incomplete then
									local newTask = taskTemplate:Clone();

									local itemlib = missionData.SaveData.ItemId and modItemsLibrary:Find(missionData.SaveData.ItemId);
									local compText = checkpointInfo.CompleteText;
									compText = string.gsub(compText, "$ItemName", itemlib and itemlib.Name or missionData.SaveData.ItemId or "");
									
									newTask.LayoutOrder = 99;
									newTask.Text = "• "..compText;
									newTask.Parent = pinnedTasklist;
								end
								
							else
								pinnedTasklist.Visible = false;
								pinnedTaskTag.Visible = true;

								pinnedTaskTag.Text = checkpointInfo.Text;
								if missionData.SaveData then
									for k, v in pairs(missionData.SaveData) do
										if pinnedTaskTag.Text:find("$"..k) then
											local newVal = v;
											
											if tonumber(newVal) then
												newVal = modFormatNumber.Beautify(tonumber(newVal));
											end
											
											pinnedTaskTag.Text = pinnedTaskTag.Text:gsub("$"..k, newVal);
										end
									end
								end

							end


							if lastProgressionPoint ~= missionData.ProgressionPoint then
								lastProgressionPoint = missionData.ProgressionPoint;
								lastIncompleteFlag = incomplete;

								if missionData.ProgressionPoint > 1 then
									modAudio.Play("MissionUpdated", nil, nil, false);
								end

							elseif lastIncompleteFlag ~= incomplete then
								lastIncompleteFlag = incomplete;

								modAudio.Play("MissionUpdated", nil, nil, false);
							end

							if book.LogicScript then
								local missionLogic = require(book.LogicScript);
								
								if activeMissionLogic[book.Name] == nil then
									activeMissionLogic[book.Name] = missionLogic;
								end;

								local missionFunction = missionLogic["Checkpoint"..missionData.ProgressionPoint];
								if missionFunction then spawn(missionFunction); end;
							end
							
							if checkpointInfo.Notify == true and missionPinHud.Visible and notifyPinnedMission then
								task.spawn(notifyPinnedMission, true);
							end
							
						elseif book.Progression and missionData.ProgressionPoint and book.Progression[missionData.ProgressionPoint] then
							pinnedTaskTag.Text = book.Progression[missionData.ProgressionPoint];

							if missionData.SaveData then
								for k, v in pairs(missionData.SaveData) do
									if pinnedTaskTag.Text:find("$"..k) then

										local newVal = v;

										if tonumber(newVal) then
											newVal = modFormatNumber.Beautify(tonumber(newVal));
										end
										
										pinnedTaskTag.Text = pinnedTaskTag.Text:gsub("$"..k, newVal);
									end
								end
							end
							if lastProgressionPoint ~= missionData.ProgressionPoint then
								lastProgressionPoint = missionData.ProgressionPoint;
								if missionData.ProgressionPoint > 1 then
									modAudio.Play("MissionUpdated", nil, nil, false);
								end
							end

							if book.LogicScript then
								local missionLogic = require(book.LogicScript);
								
								if activeMissionLogic[book.Name] == nil then
									activeMissionLogic[book.Name] = missionLogic;
								end;
								local missionFunction = missionLogic["ProgressionPoint"..missionData.ProgressionPoint];
								if missionFunction then spawn(missionFunction); end;
							end

							pinnedTasklist.Visible = false;
							pinnedTaskTag.Visible = true;


						elseif book.Objectives then
							for _, obj in pairs(pinnedTasklist:GetChildren()) do
								if obj:IsA("GuiObject") then
									obj:Destroy();
								end
							end

							local incomplete = false;
							for name, objective in pairs(book.Objectives) do
								local newTask = taskTemplate:Clone();

								newTask.LayoutOrder = objective.Index;
								newTask.Text = loadObjectiveDescription(missionData, name, objective);
								newTask.Parent = pinnedTasklist;

								if missionData.ObjectivesCompleted[name] == true then
									newTask.Text = "<s>"..newTask.Text.."</s>"
								else
									incomplete = true;
								end
							end

							if incomplete then

								pinnedTasklist.Visible = true;
								pinnedTaskTag.Text = "Complete the objectives";
								pinnedTaskTag.Visible = false;

							else
								pinnedTasklist.Visible = false;
								pinnedTaskTag.Visible = true;

								local itemlib = missionData.SaveData.ItemId and modItemsLibrary:Find(missionData.SaveData.ItemId);
								pinnedTaskTag.Text = book.ObjectivesCompleteText:gsub("$ItemName", itemlib and itemlib.Name or missionData.SaveData.ItemId or "");
							end

						else
							pinnedTaskTag.Text = "No available task";

						end

					elseif missionData.Type == 2 or missionData.Type == 4 then
						pinnedTaskTag.Text = book.GuideText or "";

						pinnedTasklist.Visible = false;
						pinnedTaskTag.Visible = true;
					end


					if pinnedMissionName ~= book.Name then
						pinnedMissionName = book.Name;

						notifyPinnedMission = function(checkpointNotify)
							local mainGui = missionPinHud.Parent;
							if mainGui == nil then return end;
							for _,c in pairs(mainGui:GetChildren()) do
								if c.Name == "NotifyMission" and c:IsA("GuiObject") then
									c:Destroy();
								end
							end
							
							local taskText = pinnedTaskTag.Text;
							newPinNotification = notifyMissionFrame:Clone();
							newPinNotification.Parent = mainGui;
							
							local titleLabel = newPinNotification:WaitForChild("Title");
							local taskLabel = newPinNotification:WaitForChild("Task");
							
							if checkpointNotify == true then
								titleLabel.Text = "Objective";
								titleLabel.Size = UDim2.new(1, 0, 0.13, 0);
								taskLabel.Text = taskText;
								taskLabel.Size = UDim2.new(1, 0, 0.25, 0);
								
							else
								titleLabel.Text = pinnedMissionName;
								taskLabel.Text = taskText;
								
							end
							
							newPinNotification.Position = UDim2.new(0.5, 0, 0.32, 0);
							modGuiObjectTween.FadeTween(newPinNotification, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(0));
							newPinNotification.Visible = true;
							task.wait();
							
							modGuiObjectTween.FadeTween(newPinNotification, modGuiObjectTween.FadeDirection.In, TweenInfo.new(2));
							pcall(function()
								newPinNotification:TweenPosition(UDim2.new(0.5, 0, 0.3, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 2, true);
							end)
							wait(5);
							
							pcall(function()
								newPinNotification:TweenPosition(UDim2.new(0.85, 0, 0, 40), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 2, true);
							end)
							modGuiObjectTween.FadeTween(newPinNotification, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(1.8));
							newPinNotification = nil;
						end;

						if missionPinHud.Visible and notifyPinnedMission then
							spawn(notifyPinnedMission);
						end
					end
				end
			else
				warn("Unknown mission ("..missionData.Id..")");
				titleTag.Text = "Unknown Mission ("..missionData.Id..")";
			end
		end
		
		-- Repeatable Missions;
		if #repeatableMissionList > 0 then 
			local countRepeatableMissions = 0;
			for a=1, #repeatableMissionList do
				local missionData = repeatableMissionList[a].Data;
				if missionData.Type == 1 or missionData.Type == 3 then continue end;
				countRepeatableMissions = countRepeatableMissions +1;
			end
			local repeatableTab, repeatableList = newMissionList("Repeatable", 0); -- {ForceExpand=true;}
			repeatableTab:WaitForChild("titleLabel").Text = "Missions Board: ".. countRepeatableMissions;

			local hourlyMissionListing = repeatableList:FindFirstChild("hourlyMission");
			local titleLabel;

			if hourlyMissionListing == nil then
				hourlyMissionListing = missionListingTemplate:Clone();
				hourlyMissionListing.Name = "hourlyMission";

				titleLabel = hourlyMissionListing:WaitForChild("Title");

				local defaultTextColor = Color3.fromRGB(255,255,255);
				titleLabel.TextColor3 = defaultTextColor
				hourlyMissionListing.ImageColor3 = Color3.fromRGB(100, 100, 100);

				hourlyMissionListing.MouseMoved:Connect(function()
					hourlyMissionListing.ImageColor3 = Color3.fromRGB(160, 160, 160);
				end)
				hourlyMissionListing.MouseLeave:Connect(function()
					hourlyMissionListing.ImageColor3 = Color3.fromRGB(100, 100, 100);
				end)

				-- MARK: loadBoardMissions()
				local function loadBoardMissions()
					MissionDisplayFrame:ClearAllChildren();

					local missionBoard = templateMissionBoard:Clone();
					missionBoard.Parent = MissionDisplayFrame;
					
					local closeButton = missionBoard:WaitForChild("closeButton");
					closeButton.MouseButton1Click:Connect(function()
						MissionDisplayFrame:ClearAllChildren();
						Interface.RefreshMissionMap();
					end)
					
					local listFrame = missionBoard:WaitForChild("list");

					local hasActiveRepeatableMission = false;

					local function refreshActiveRepeatable()
						hasActiveRepeatableMission = false;
						for a=1, #repeatableMissionList do
							if repeatableMissionList[a].Data.Type == 1 then
								hasActiveRepeatableMission = true;
							end
						end


						for _, obj in pairs(listFrame:GetChildren()) do
							if not obj:IsA("GuiObject") then continue end;

							local newButton = obj;

							local color: Color3 = boardMissionColors[obj:GetAttribute("Tier")] or Color3.fromRGB(100, 100, 100);
							local h, s, v = color:ToHSV();

							if hasActiveRepeatableMission then
								newButton.AutoButtonColor = false;
								newButton.BackgroundColor3 = Color3.fromHSV(h, s, v*0.5);

							else
								newButton.AutoButtonColor = true;
								newButton.BackgroundColor3 = color;

							end

						end
					end

					local lastMissionBoardUpdate = tick();
					missionBoard.MouseMoved:Connect(function()
						if tick()-lastMissionBoardUpdate < 1 then return end;
						lastMissionBoardUpdate = tick();

						refreshActiveRepeatable();
					end)


					-- MARK: Board Missions Rendering
					for a=1, #repeatableMissionList do
						local missionData = repeatableMissionList[a].Data;
						if missionData.Type == 1 or missionData.Type == 3 then continue end;

						local missionLib = repeatableMissionList[a].Lib;

						local newButton = templateRMissionButton:Clone();
						local titleLabel = newButton:WaitForChild("Title");
						local descLabel = newButton:WaitForChild("Desc");
						local rewardLabel = newButton:WaitForChild("Reward");

						local skipHoldDownObj = modComponents.CreateHoldDownButton(Interface, {
							Text="";
						});
						local skipHoldButton = skipHoldDownObj.Button;
						skipHoldButton.AnchorPoint = Vector2.new(1, 0);
						skipHoldButton.BackgroundColor3 = Color3.fromRGB(120, 57, 57);
						skipHoldButton.Position = UDim2.new(1, -5, 0, 5);
						skipHoldButton.Size = UDim2.new(0, 15, 0, 15);
						skipHoldButton.Parent = newButton;

						skipHoldDownObj.OnHoldDownConfirm = function()
							local r = remoteMissionRemote:InvokeServer("MissionBoardSkip", missionData.Id);

							if r and r.Success then
								Debugger.Expire(newButton);
							end
						end;

						titleLabel.Text = missionLib.Name;
						descLabel.Text = missionLib.Description;
						newButton:SetAttribute("Tier", missionLib.Tier);
						
						local rewardStrList = {};
						for b=1, #missionLib.Rewards do
							local rewardInfo = missionLib.Rewards[b];
							if rewardInfo.Type == "Perks" then
								table.insert(rewardStrList, rewardInfo.Amount.." Perks");

							elseif rewardInfo.Type == "Item" then
								local itemLib = modItemsLibrary:Find(rewardInfo.ItemId);
								if itemLib then
									table.insert(rewardStrList, itemLib.Name.. (rewardInfo.Quantity > 1 and " x"..rewardInfo.Quantity or ""));
								else
									table.insert(rewardStrList, "Unknown item: "..(rewardInfo.ItemId or ""));
								end
							end
						end
						
						rewardLabel.Text = table.concat(rewardStrList, ", ");

						newButton.Parent = listFrame;
						newButton.MouseButton1Click:Connect(function()
							refreshActiveRepeatable();

							if hasActiveRepeatableMission then
								return;
							end

							Interface:PlayButtonClick();

							local debounce;
							local promptWindow = Interface:PromptQuestion("Start "..titleLabel.Text .."?", descLabel.Text);
							local YesClickedSignal, NoClickedSignal;

							YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
								if debounce then return end;
								debounce = true;
								Interface:PlayButtonClick();

								local r = remoteMissionRemote:InvokeServer("MissionBoardStart", missionData.Id);
								r = r or {};

								if r.FailMsg then
									Interface:PromptWarning("Failed: ".. r.FailMsg);
									task.wait(1);
								end
								
								debounce = false;
								promptWindow:Close();

								YesClickedSignal:Disconnect();
								NoClickedSignal:Disconnect();
							end);
							NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
								if debounce then return end;
								Interface:PlayButtonClick();
								promptWindow:Close();
								Interface:OpenWindow("Missions");
								YesClickedSignal:Disconnect();
								NoClickedSignal:Disconnect();
							end);

						end)

					end
					refreshActiveRepeatable();
				end

				hourlyMissionListing.MouseButton1Click:Connect(function()
					Interface:PlayButtonClick();

					loadBoardMissions();
				end)
			end

			hourlyMissionListing.LayoutOrder = 0;
			titleLabel = hourlyMissionListing:WaitForChild("Title");
			local questFrom = hourlyMissionListing:WaitForChild("QuestFrom");

			questFrom.Visible = false;
			titleLabel.Text = "Pick Mission";
			hourlyMissionListing:SetAttribute("ForceShow", true);

			hourlyMissionListing.Parent = repeatableList;

			for a=1, #repeatableMissionList do
				local missionData = repeatableMissionList[a].Data;
				if missionData.Type == 2 or missionData.Type == 4 then continue end;

				createListing(repeatableMissionList[a], repeatableTab, repeatableList);
			end
		end
		
		-- General Missions;
		for typeKey, typeMissions in pairs(missionTypesList) do
			local typeIndex = modMissionsLibrary.MissionTypes[typeKey];
			local typeOrder = missionTypeOrder[typeKey];

			local newTab, newList = newMissionList(typeKey, typeOrder);

			local completedCount = 0;
			local missionsOfType = modMissionsLibrary.CountMissions({[typeIndex]=true;});
			for a=1, #typeMissions do
				local missionData = typeMissions[a].Data;
				if missionData.Type == 3 then
					completedCount = completedCount +1;
				end
				createListing(typeMissions[a], newTab, newList);
			end
			local allComplete = completedCount == missionsOfType;
			newTab.titleLabel.Text = (allComplete and "" or "• ")..typeKey.." missions ("..completedCount.."/"..missionsOfType..")";
		end

		for typeKey, tabListTable in pairs(tabAndLists) do
			tabListTable.Toggle();
		end

		for key, listing in pairs(missionListings) do
			if updated[key] == nil then
				listing:Destroy();
				missionListings[key] = nil;
			end
		end

		--== Markers
		if pinnedMission then
			local function setPinnedMarker(missionWorld, markInfo)
				if missionWorld == nil or missionWorld == modBranchConfigs.WorldName then
					if markInfo.Type == modMarkers.MarkerTypes.Waypoint then
						modMarkers.SetMarker("PinMissionMarker", markInfo.Target, markInfo.Label, markInfo.Type);

					elseif markInfo.Type == modMarkers.MarkerTypes.Npc then
						local npcModel = getNpc(markInfo.Target);

						if npcModel then
							modMarkers.SetMarker("PinMissionMarker", npcModel.PrimaryPart, markInfo.Label, markInfo.Type);
						end
					end
				else
					modMarkers.SetMarker("PinMissionMarker", missionWorld, modBranchConfigs.GetWorldDisplayName(missionWorld), modMarkers.MarkerTypes.Travel);
				end
				modMarkers.SetColor("PinMissionMarker", markInfo.Color or missionMarkerColor);
			end

			if pinnedMissionLib and pinnedMission.Type == 2 then -- Available
				
				if pinnedMissionLib.From then
					local npcModel = getNpc(pinnedMissionLib.From);

					if npcModel then
						modMarkers.SetMarker("PinMissionMarker", npcModel.PrimaryPart, pinnedMissionLib.From, modMarkers.MarkerTypes.Npc);
						modMarkers.SetColor("PinMissionMarker", missionMarkerColor);

					else
						local npcLib = modNpcProfileLibrary:Find(pinnedMissionLib.From);
						local npcWorld = pinnedMissionLib.NpcWorld or (npcLib and npcLib.World) or nil;

						if npcWorld ~= modBranchConfigs.WorldName then

							modMarkers.SetMarker("PinMissionMarker", npcWorld, modBranchConfigs.GetWorldDisplayName(npcWorld), modMarkers.MarkerTypes.Travel);
							modMarkers.SetColor("PinMissionMarker", missionMarkerColor);
						else
							modMarkers.ClearMarker("PinMissionMarker");
						end
					end
					
				end

			elseif pinnedMissionLib and pinnedMissionLib.Markers then
				if pinnedMissionLib.Progression then
					local markInfo = pinnedMissionLib.Markers[pinnedMission.ProgressionPoint];
					if markInfo then
						local missionWorld = markInfo.World or pinnedMissionLib.World;
						setPinnedMarker(missionWorld, markInfo);
					else
						modMarkers.ClearMarker("PinMissionMarker");
					end

				elseif pinnedMissionLib.Objectives then
					local markInfo = pinnedMissionLib.Markers["Complete"];

					for objName, obj in pairs(pinnedMissionLib.Objectives) do
						if pinnedMission.ObjectivesCompleted[objName] ~= true then
							markInfo = pinnedMissionLib.Markers[objName];
							break;
						end
					end
					if markInfo then
						local missionWorld = markInfo.World or pinnedMissionLib.World;
						setPinnedMarker(missionWorld, markInfo);
					else
						modMarkers.ClearMarker("PinMissionMarker");
					end

				else
					modMarkers.ClearMarker("PinMissionMarker");
				end
			else
				modMarkers.ClearMarker("PinMissionMarker");
			end
		else
			modMarkers.ClearMarker("PinMissionMarker");
			pinnedTitleTag.Text = "";
			cancelAllMissionFunctions();
		end

		for name, icon in pairs(modHeadIcons.GetIcons()) do
			if icon and icon.Active == "Mission" then
				if headIconUpdated[name] == nil then modHeadIcons.Clear(name, "Mission"); end;
			end
		end
	end

	Interface.Garbage:Tag(pinnedTitleTag:GetPropertyChangedSignal("Text"):Connect(function()
		if modConfigurations.DisablePinnedMission then missionPinHud.Visible = false; Debugger:Warn("Pinned Mission Disabled"); return end;
		if pinnedTitleTag.Text:len() > 0 then
			missionPinHud.Visible = true;
			modGuiObjectTween.FadeTween(missionPinHud, modGuiObjectTween.FadeDirection.In, TweenInfo.new(2));
		else
			modGuiObjectTween.FadeTween(missionPinHud, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(2));
		end
	end));

	Interface.Garbage:Tag(modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
		if Interface.UpdatePinnedHud then
			Interface.UpdatePinnedHud();
		end
	end));

	PinnedMissionFrame.ChildAdded:Connect(refreshPinnedMissionFrame)
	PinnedMissionFrame.ChildRemoved:Connect(refreshPinnedMissionFrame);

	modGuiObjectTween.FadeTween(missionPinHud, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(0));
	modConfigurations.OnChanged("DisablePinnedMission", function(oldValue, value)
		Debugger:Warn("DisablePinnedMission changed", oldValue, "v", value);
		if not value then
			if pinnedTitleTag.Text:len() > 0 then
				missionPinHud.Visible = true;
				modGuiObjectTween.FadeTween(missionPinHud, modGuiObjectTween.FadeDirection.In, TweenInfo.new(2));
				if notifyPinnedMission then
					spawn(notifyPinnedMission);
				end
			else
				modGuiObjectTween.FadeTween(missionPinHud, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(2));
			end
		else
			missionPinHud.Visible = false;
		end
	end)
	
	
	modInterface:Bind("UpdateMissions", function()
		if not windowFrame:IsDescendantOf(localPlayer.PlayerGui) then return end;
		Interface.Update();
		countAvailableMissions();
	end)
	
	task.delay(5, function()
		if not windowFrame:IsDescendantOf(localPlayer.PlayerGui) then return end;
		Interface.Update();
	end);
	
	--== MissionPrize;
	local unixTime = modSyncTime.GetTime();
	
	local BottomFrame = windowFrame:WaitForChild("BottomBackground");
	local battlePassContent = BottomFrame:WaitForChild("battlePass");
	local hintLabel = BottomFrame:WaitForChild("hint");

	local activeBpId = modBattlePassLibrary.Active;
	local battlepassLib = modBattlePassLibrary:Find(activeBpId);
	
	local dOYToday = os.date("%j", unixTime); 
	local dOYEnd = battlepassLib and os.date("%j", battlepassLib.EndUnixTime) or 0;
	
	local yearToday = os.date("%Y", unixTime);
	local yearEnd = battlepassLib and os.date("%Y", battlepassLib.EndUnixTime) or 0;
	
	local leftFrameSizeXAnchor = 0.3;
	local rightFrameSizeXAnchor = 1-leftFrameSizeXAnchor;
	
	PinnedMissionFrame.Size = UDim2.new(leftFrameSizeXAnchor, 0, 0, 90);
	
	local daysLeft = dOYEnd-dOYToday-1;
	if activeBpId == nil or daysLeft < 0 or yearToday ~= yearEnd then
		BottomFrame.Visible = false;
		LeftFrame.Size = UDim2.new(leftFrameSizeXAnchor, 0, 0.9, 0);
		LeftFrame.Position = UDim2.new(0, 0, 1, 0);
		RightFrame.Size = UDim2.new(rightFrameSizeXAnchor, 0, 0.9, 0);
		RightFrame.Position = UDim2.new(1, 0, 1, 0);
		
		hintLabel.Text = "Mission Pass has ended";
		
	else
		BottomFrame.Visible = true;
		LeftFrame.Size = UDim2.new(leftFrameSizeXAnchor, 0, 0.9, -60);
		LeftFrame.Position = UDim2.new(0, 0, 1, -60);
		RightFrame.Size = UDim2.new(rightFrameSizeXAnchor, 0, 0.9, -60);
		RightFrame.Position = UDim2.new(1, 0, 1, -60);
		
		hintLabel.Text = "Mission Pass: ".. daysLeft .." Days Left";
		
		local bpButtonFunc;

		--== MARK: Mission Pass
		modData:RequestData("BattlePassSave/Passes/"..activeBpId);

		table.clear(levelSlotsInfo)
		function Interface.UpdateBattlePass(action)
			local battlePassData, seasonData;

			local function refreshData()
				battlePassData = modData.Profile and modData.Profile.BattlePassSave or nil;
				seasonData = battlePassData and battlePassData.Passes and battlePassData.Passes[activeBpId] or {Claim={}; Level=0;};
				return battlePassData, seasonData;
			end
			refreshData();
			
			local seasonLevel = seasonData.Level;
			local seasonTokens = seasonData.Tokens or 0;
			local treeList = battlepassLib.Tree;
			local treeCount = #treeList;

			local totalDist = 0;
			
			for lvl=0, treeCount do
				local lvlSlotInfo = levelSlotsInfo[lvl];

				if lvlSlotInfo == nil then
					local info = {};
					
					info.LevelSlot = lvl == 0 and templateStartSlot:Clone() or templateLevelSlot:Clone();
					info.LevelSlot.LayoutOrder = lvl;
					
					levelSlotsInfo[lvl] = info;
					lvlSlotInfo = info;
				end
				
				local lvlSlot = lvlSlotInfo.LevelSlot;
				
				local leafLib = treeList[lvl] or {};
				local rewardInfo = leafLib.Reward;
				
				if leafLib.Empty == true then
					lvlSlot.Size = UDim2.new(0, 20, 1, 0);
					
				else
					lvlSlot.Size = UDim2.new(0, 80, 1, 0);
					
					if lvl == 0 and lvlSlotInfo.btStart == nil then
						lvlSlotInfo.btStart = true;
						
						local frame = Instance.new("Frame");
						frame.BackgroundTransparency = 1;
						frame.Size = UDim2.new(0, 70, 0, 70);
						local bpIconButton = Instance.new("ImageButton");
						bpIconButton.BackgroundTransparency = 1;
						bpIconButton.Rotation = 1;
						bpIconButton.AnchorPoint = Vector2.new(0.5, 0.5);
						bpIconButton.Position = UDim2.new(0.5, 0, 0.5, 0);
						bpIconButton.Size = UDim2.new(0, 70, 0, 70);
						bpIconButton.Image = battlepassLib.Icon;
						bpIconButton.Parent = frame;
						frame.Parent = lvlSlot;
						
						bpButtonFunc = function()
							refreshData();
							Interface:PlayButtonClick();

							MissionDisplayFrame:ClearAllChildren();

							local passRewardFrame = templatePassReward:Clone();
							passRewardFrame.Parent = MissionDisplayFrame;

							local titleLabel = passRewardFrame:WaitForChild("Title");
							titleLabel.Text =  '<font size="14">'.."Mission Pass</font>\n<b>".. battlepassLib.Title .."</b>";

							local contentFrame = passRewardFrame:WaitForChild("Frame");
							local claimButton = contentFrame:WaitForChild("ClaimButton");
							local slotFrame = contentFrame:WaitForChild("Slot");
							local descLabel = contentFrame:WaitForChild("Description");

							local itemIcon = bpIconButton:Clone();
							itemIcon.Size = UDim2.new(1, 0, 1, 0);
							itemIcon.Parent = slotFrame;

							slotFrame.AnchorPoint = Vector2.new(0.5, 0);
							slotFrame.Position = UDim2.new(0.5, 0, 0, -10);
							slotFrame.Size = UDim2.new(0.7, 0, 0.6, 0);

							descLabel.Position = UDim2.new(0, 0, 0.6, 0);
							descLabel.Size = UDim2.new(1, 0, 0, 0);
							descLabel.ClipsDescendants = false;

							descLabel.Text = battlepassLib.Desc;

							local price = battlepassLib.Price;
							claimButton.Text = "Unlock for ".. modFormatNumber.Beautify(battlepassLib.Price) .." Gold";

							claimButton.TextScaled = false;
							claimButton.Position = UDim2.new(0.5, 0, 1, -40);
							claimButton.Size = UDim2.new(0.6, 0, 0, 40);
							claimButton.BackgroundColor3 = branchColor;
							game.Debris:AddItem(claimButton:FindFirstChild("UITextSizeConstraint"), 0);

							claimButton.Visible = false;

							if seasonData.Owned ~= true then
								claimButton.Visible = true;
							end

							claimButton.MouseButton1Click:Connect(function()
								refreshData();
								Interface:PlayButtonClick();

								local goldTxt = "<b><font color='rgb(170, 120, 0)'> ".. price.." Gold</font></b>";
								local promptWindow = Interface:PromptQuestion("Unlock Mission Pass for ".. goldTxt.. "?",
									"Are you sure you want to unlock Mission Pass: ".. battlepassLib.Title .. " for "..goldTxt.."?", 
									"Purchase", "Cancel");
								local YesClickedSignal, NoClickedSignal;

								YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
									Interface:PlayButtonClick();
									promptWindow.Frame.Yes.buttonText.Text = "Purchasing...";

									local r = remoteBattlepassRemote:InvokeServer("purchase", lvl);
									if r.FailMsg then
										if r.FailMsg == "Insufficient Gold" then
											task.wait(2);
											promptWindow:Close();
											Interface:OpenWindow("GoldMenu", "GoldPage");
											return;

										else
											promptWindow.Frame.Yes.buttonText.Text = r.FailMsg;
											task.wait(2);

										end

									elseif r.Success == true then
										promptWindow.Frame.Yes.buttonText.Text = "Unlocked!";

									end
									promptWindow:Close();
									Interface:OpenWindow("Missions");

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
							
							
							local function buyLevelFunc(lvlAmt)
								local price = modBattlePassLibrary.BuyLevelCost * lvlAmt;
								
								local goldTxt = "<b><font color='rgb(170, 120, 0)'> ".. price.." Gold</font></b>";
								local promptWindow = Interface:PromptQuestion("Level up Mission Pass for ".. goldTxt.. "?",
									"Are you sure you want to level up Mission Pass by ".. lvlAmt .." for "..goldTxt.."?", 
									"Level Up", "Cancel");
								local YesClickedSignal, NoClickedSignal;

								YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
									Interface:PlayButtonClick();
									promptWindow.Frame.Yes.buttonText.Text = "Leveling Up...";

									local r = remoteBattlepassRemote:InvokeServer("purchaselvls", lvlAmt);
									if r.FailMsg then
										if r.FailMsg == "Insufficient Gold" then
											task.wait(2);
											promptWindow:Close();
											Interface:OpenWindow("GoldMenu", "GoldPage");
											return;

										else
											promptWindow.Frame.Yes.buttonText.Text = r.FailMsg;
											task.wait(2);

										end

									elseif r.Success == true then
										promptWindow.Frame.Yes.buttonText.Text = "Leveled Up!";

									end
									promptWindow:Close();
									Interface:OpenWindow("Missions");

									YesClickedSignal:Disconnect();
									NoClickedSignal:Disconnect();
								end);

								NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
									Interface:PlayButtonClick();
									promptWindow:Close();

									YesClickedSignal:Disconnect();
									NoClickedSignal:Disconnect();
								end);
							end
							
							local buyOneLevelButton = claimButton:Clone();
							buyOneLevelButton.BackgroundColor3 = Color3.fromRGB(170, 120, 0);
							buyOneLevelButton.AnchorPoint = Vector2.new(0, 1);
							buyOneLevelButton.Position = UDim2.new(0, 0, 1, 0);
							buyOneLevelButton.Size = UDim2.new(0.5, -10, 0, 30);
							buyOneLevelButton.Text = "Unlock 1 Level";
							buyOneLevelButton.Parent = contentFrame;
							buyOneLevelButton.Visible = true;
							
							buyOneLevelButton.MouseButton1Click:Connect(function()
								buyLevelFunc(1);
							end)
							

							local buyTenLevelButton = claimButton:Clone();
							buyTenLevelButton.BackgroundColor3 = Color3.fromRGB(170, 120, 0);
							buyTenLevelButton.AnchorPoint = Vector2.new(1, 1);
							buyTenLevelButton.Position = UDim2.new(1, 0, 1, 0);
							buyTenLevelButton.Size = UDim2.new(0.5, -10, 0, 30);
							buyTenLevelButton.Text = "Unlock 10 Levels";
							buyTenLevelButton.Parent = contentFrame;
							buyTenLevelButton.Visible = true;

							buyTenLevelButton.MouseButton1Click:Connect(function()
								buyLevelFunc(10);
							end)
						end
						bpIconButton.MouseButton1Click:Connect(bpButtonFunc);
					end
					
					if rewardInfo then
						if lvlSlotInfo.ItemButton == nil then
							local itemButtonObj = modItemInterface.newItemButton(rewardInfo.ItemId);
							local itemLib = modItemsLibrary:Find(rewardInfo.ItemId);
							
							local aspectRatioConstraint = Instance.new("UIAspectRatioConstraint");
							aspectRatioConstraint.Parent = itemButtonObj.ImageButton;

							itemButtonObj.ImageButton.AnchorPoint = Vector2.new(0.5, 0.5);
							itemButtonObj.ImageButton.Position = UDim2.new(0.5, 0, 0.5, 0);
							itemButtonObj.ImageButton.Size = UDim2.new(0, 50, 0, 50);
							itemButtonObj.ImageButton.Parent = lvlSlot;
							
							lvlSlotInfo.ItemButton = itemButtonObj;
							
							lvlSlotInfo.GetClaimState = function(l)
								refreshData();
								seasonLevel = seasonData.Level;
								
								local r = "n/a";
								if seasonLevel > l then
									if table.find(seasonData.Claim, l) then
										r = "Claimed";
									else
										r = "CanClaim";
									end
								else
									r ="Locked";
								end
								return r;
							end
							
							itemButtonObj.ImageButton.MouseButton1Click:Connect(function()
								if itemButtonObj.DimOut then return end;
								itemToolTip.Frame.Visible = false;
								refreshData();
								Interface:PlayButtonClick();

								MissionDisplayFrame:ClearAllChildren();

								local passRewardFrame = templatePassReward:Clone();
								passRewardFrame.Parent = MissionDisplayFrame;

								local titleLabel = passRewardFrame:WaitForChild("Title");
								local titleStr = '<font size="10">'.."Level "..lvl

								if rewardInfo.PassOwner then
									titleLabel.TextColor3 = bpColors.CurrentPassOwner
									titleStr = titleStr.." (Mission Pass)";
									
								elseif rewardInfo.RequiresPremium then
									titleLabel.TextColor3 = bpColors.CurrentPremium;
									titleStr = titleStr.." (Premium)";
									
								end
								titleLabel.Text = titleStr.."</font>\n<b>".. (rewardInfo.ItemNameOverwrite or itemLib.Name) .."</b>";
								
								local contentFrame = passRewardFrame:WaitForChild("Frame");
								local claimButton = contentFrame:WaitForChild("ClaimButton");
								local slotFrame = contentFrame:WaitForChild("Slot");
								local descLabel = contentFrame:WaitForChild("Description");
								
								local cloneItemButton = itemButtonObj.ImageButton:Clone();
								cloneItemButton.Size = UDim2.new(1, 0, 1, 0);
								cloneItemButton.Parent = slotFrame;
								
								itemToolTip:BindHoverOver(cloneItemButton, function()
									itemToolTip.Frame.Parent = windowFrame;
									itemToolTip:Update(itemLib.Id);
									itemToolTip:SetPosition(cloneItemButton);
								end);

								local function h3(txt)
									return '<b><font size="18">' .. txt .. '</font></b>'
								end
								
								local descText = "";
								descText = descText..h3("Unlock Level: ").. lvl;
								
								if leafLib.Requirements then
									descText = descText.."\n"..h3("Unlock Requirements: ");
									for a=1, #leafLib.Requirements do
										local rInfo = leafLib.Requirements[a];
										
										if rInfo.Type == "Stats" then
											if rInfo.Key == "Level" then
												descText = descText.."\n    • ".. rInfo.Key.." ".. rInfo.Value;
											else
												descText = descText.."\n    • ".. rInfo.Value.." ".. rInfo.Key;
											end

										elseif rInfo.Type == "Mission" then
											local missionLib = modMissionsLibrary.Get(rInfo.Key);

											descText = descText.."\n    • Mission: ".. missionLib.Name .." ".. rInfo.Value;
											
										elseif rInfo.Type == "Premium" then
											descText = descText.."\n    • Premium Member";
											
										end
										
									end
									
								end
								
								descText = descText.."\n\n"..h3("Name: ").. (rewardInfo.ItemNameOverwrite or itemLib.Name);
								descText = descText.."\n"..h3("Type: ").. itemLib.Type;
								descText = descText.."\n"..h3("Description: ").. (rewardInfo.ItemDescriptionOverwrite or itemLib.Description);
								
								descLabel.Text = descText;

								if lvlSlotInfo.GetClaimState(lvl) ~= "CanClaim" then return end;
								
								claimButton.Visible = true;
								
								local requiresMP = seasonData.Owned ~= true and rewardInfo.PassOwner == true
								if requiresMP then
									claimButton.Text = "Requires Mission Pass";
								end
								
								if rewardInfo.RequiresPremium == true and modData.IsPremium == false then
									claimButton.Text = "Requires Premium";
								end
								
								local  claimText = claimButton.Text;
								claimButton.MouseButton1Click:Connect(function()
									if requiresMP then
										bpButtonFunc();
										return;
									end
									refreshData();
									if lvlSlotInfo.GetClaimState(lvl) ~= "CanClaim" then return end;
									
									claimButton.Text = "Claiming...";
									local r = remoteBattlepassRemote:InvokeServer("claim", lvl);
									if r.FailMsg then
										if r.FailMsg == "Requires Mission Pass" then
											bpButtonFunc();
											
										elseif r.FailMsg == "Requires Premium" then
											Interface:OpenWindow("GoldMenu", "premium");
											return;
											
										else
											claimButton.Text = r.FailMsg;
											task.wait(2);
											
										end
										
									elseif r.Success == true then
										game.Debris:AddItem(lvlSlotInfo.GlowLabel, 0);
										itemButtonObj.DimOut = true;
										
										Interface:OpenWindow("Inventory");
										claimButton.Visible = false;
										
									end
									claimButton.Text = claimText;
								end)
							end)
						end
						
						local itemButtonObj = lvlSlotInfo.ItemButton;
						
						local claimState = lvlSlotInfo.GetClaimState(lvl);
						
						if claimState == "CanClaim" then
							game.Debris:AddItem(itemButtonObj.ImageButton:FindFirstChild("LockLabel"), 0);

							local newGlow = itemButtonObj.ImageButton:FindFirstChild("ClaimGlow") or modItemInterface.newGlowEffect();
							newGlow.Name = "ClaimGlow"
							newGlow.ImageColor3 = Color3.fromRGB(255, 255, 255);
							newGlow.ImageTransparency = 0.6;
							newGlow.Parent = itemButtonObj.ImageButton;
							lvlSlotInfo.GlowLabel = newGlow;
							itemButtonObj.DimOut = nil;
							
							
						elseif claimState == "Claimed" then
							game.Debris:AddItem(itemButtonObj.ImageButton:FindFirstChild("LockLabel"), 0);
							game.Debris:AddItem(lvlSlotInfo.GlowLabel, 0);
							itemButtonObj.DimOut = true;
							
							
						elseif claimState == "Locked" then
							if leafLib.Requirements then
								itemButtonObj.DimOut = nil;

								local lockLabel = itemButtonObj.ImageButton:FindFirstChild("LockLabel") or templateLockedLabel:Clone();
								lockLabel.Name = "LockLabel";
								lockLabel:SetAttribute("DimOutIgnore", true);
								lockLabel.Parent = itemButtonObj.ImageButton;
							end
							
							
						end
						
						local itemData = rewardInfo.Data or {};
						itemData.ItemId = rewardInfo.ItemId;
						itemData.Quantity = rewardInfo.Quantity or 1;
						itemButtonObj:Update(itemData);
					end
				end

				if lvl <= seasonLevel then
					totalDist = totalDist + lvlSlot.AbsoluteSize.X;
				end
					
				
				if seasonLevel > lvl then
					if rewardInfo == nil then
						lvlSlot.ImageColor3 = bpColors.Normal
						
					else
						if rewardInfo.PassOwner then
							lvlSlot.ImageColor3 = bpColors.PassOwner;

						elseif rewardInfo.RequiresPremium then
							lvlSlot.ImageColor3 = bpColors.Premium;

						else
							lvlSlot.ImageColor3 = bpColors.Normal;
							
						end
					end
					
				elseif seasonLevel == lvl then
					if rewardInfo == nil then
						lvlSlot.ImageColor3 = bpColors.CurrentNormal

					else
						if rewardInfo.PassOwner then
							lvlSlot.ImageColor3 = bpColors.CurrentPassOwner;

						elseif rewardInfo.RequiresPremium then
							lvlSlot.ImageColor3 = bpColors.CurrentPremium;

						else
							lvlSlot.ImageColor3 = bpColors.CurrentNormal;
							
						end
					end
					
				else
					if rewardInfo == nil then
						lvlSlot.ImageColor3 = bpColors.LockedNormal

					else
						if rewardInfo.PassOwner then
							lvlSlot.ImageColor3 = bpColors.LockedPassOwner;

						elseif rewardInfo.RequiresPremium then
							lvlSlot.ImageColor3 = bpColors.LockedPremium;
							
						else
							lvlSlot.ImageColor3 = bpColors.LockedNormal;
							
						end
					end
					
				end
				
				lvlSlot.Parent = battlePassContent;
			end
			
			--== MARK: Post Rewards

			local rewardsLib = modRewardsLibrary:Find(activeBpId);
			if rewardsLib then
				local postRewardInfo = "rewardlib";
				local lvlSlotInfo = levelSlotsInfo[postRewardInfo];

				if lvlSlotInfo == nil then
					local info = {};

					info.LevelSlot = templateLevelSlot:Clone();
					info.LevelSlot.LayoutOrder = #treeList;
					info.LevelSlot.Size = UDim2.new(0, 120, 1, 0);

					levelSlotsInfo[postRewardInfo] = info;
					lvlSlotInfo = info;
					
					if lvlSlotInfo.ItemButton == nil then
						local itemButtonObj = modItemInterface.newItemButton("unknowncrate");
						
						local aspectRatioConstraint = Instance.new("UIAspectRatioConstraint");
						aspectRatioConstraint.Parent = itemButtonObj.ImageButton;

						itemButtonObj.ImageButton.AnchorPoint = Vector2.new(0.5, 0.5);
						itemButtonObj.ImageButton.Position = UDim2.new(0.5, 0, 0.5, 0);
						itemButtonObj.ImageButton.Size = UDim2.new(0, 100, 0, 100);
						itemButtonObj.ImageButton.Rotation = 1;
						itemButtonObj.ImageButton.Parent = info.LevelSlot;

						lvlSlotInfo.ItemButton = itemButtonObj;
						
						itemButtonObj.ImageButton.MouseButton1Click:Connect(function()
							itemToolTip.Frame.Visible = false;
							refreshData();
							Interface:PlayButtonClick();

							MissionDisplayFrame:ClearAllChildren();

							local passRewardFrame = templatePassReward:Clone();
							passRewardFrame.Parent = MissionDisplayFrame;

							local titleLabel = passRewardFrame:WaitForChild("Title");
							local titleStr = "<b>Post Rewards!</b>";
							titleLabel.TextColor3 = bpColors.CurrentPassOwner;

							local contentFrame = passRewardFrame:WaitForChild("Frame");
							local claimButton = contentFrame:WaitForChild("ClaimButton");
							local slotFrame = contentFrame:WaitForChild("Slot");
							local descLabel = contentFrame:WaitForChild("Description") :: TextLabel;
							local scrollFrame = contentFrame:WaitForChild("ScrollFrame");
							
							slotFrame.Visible = false;
							claimButton.Visible = false;
							scrollFrame.Visible = true;
							descLabel.Size = UDim2.new(1, 0, 1, 0);
							
							local descText = "";
							if seasonData.Owned ~= true then
								titleStr = titleStr.." (Mission Pass)";
								descText = "Requires Mission Pass!\n"..descText;
							end

							descText = descText.. modRichFormatter.RichFontSize(`Unlock a reward every {modBattlePassLibrary.PostRewardLvlFmod} levels.`, 20);
							
							local str = "\nPossible Rewards: \n";
							
							descText = descText.. modRichFormatter.RichFontSize("\nReward drops will expire after 24 hours.", 11);
							titleLabel.Text = titleStr;
							
							local groups = modDropRateCalculator.Calculate(rewardsLib);

							for a=1, #groups do

								for b=1, #groups[a] do
									local rewardInfo = groups[a][b];
									
									if rewardInfo.ItemId or rewardInfo.Type then
										local lib = modItemsLibrary:Find(rewardInfo.ItemId or rewardInfo.Type);
										if lib then
											local oddsProb = rewardInfo.Chance/groups[a].TotalChance;

											local itemButtonObject = modItemInterface.newItemButton(lib.Id);
											local newItemButton = itemButtonObject.ImageButton;
											
											itemToolTip:BindHoverOver(newItemButton, function()
												itemToolTip.Frame.Parent = windowFrame;
												itemToolTip:Update(lib.Id);
												itemToolTip:SetPosition(newItemButton);
											end);
											
											newItemButton.Parent = scrollFrame;

											itemButtonObject:Update();
											
											local quantityLabel = newItemButton:WaitForChild("QuantityLabel");
											quantityLabel.Font = Enum.Font.Arial;
											quantityLabel.TextSize = 10;
											quantityLabel.Visible = true;
											
											quantityLabel.Text = math.ceil(oddsProb *1000)/10 .."%";
										end
									end
								end
							end

							descText = descText.."\n\n"..str;
							descLabel.Text = descText;
							descLabel.LineHeight = 1.2;
							
						end)

						itemButtonObj:Update();
					end
					
					info.LevelSlot.Parent = battlePassContent;
				end
				
				if seasonLevel > treeCount then
					lvlSlotInfo.LevelSlot.ImageColor3 = bpColors.CurrentPassOwner;
					
				else
					lvlSlotInfo.LevelSlot.ImageColor3 = bpColors.LockedPassOwner;
					
				end
				
				local postRewards = seasonData.PostRewards;
				if seasonLevel > treeCount then
					for lvl, rewardInfo in pairs(postRewards) do
						local postLvlSlotInfo = levelSlotsInfo[lvl];

						if postLvlSlotInfo == nil then
							local info = {};

							info.LevelSlot = templateLevelSlot:Clone();

							levelSlotsInfo[lvl] = info;
							postLvlSlotInfo = info;
						end

						local lvlSlot = postLvlSlotInfo.LevelSlot;
						lvlSlot.LayoutOrder = tonumber(lvl);
						
						if postLvlSlotInfo.ItemButton == nil then
							local itemButtonObj = modItemInterface.newItemButton(rewardInfo.ItemId);
							local itemLib = modItemsLibrary:Find(rewardInfo.ItemId);

							local aspectRatioConstraint = Instance.new("UIAspectRatioConstraint");
							aspectRatioConstraint.Parent = itemButtonObj.ImageButton;

							itemButtonObj.ImageButton.AnchorPoint = Vector2.new(0.5, 0.5);
							itemButtonObj.ImageButton.Position = UDim2.new(0.5, 0, 0.5, 0);
							itemButtonObj.ImageButton.Size = UDim2.new(1, 0, 1, 0);
							itemButtonObj.ImageButton.Parent = lvlSlot;
							
							postLvlSlotInfo.ItemButton = itemButtonObj;

							postLvlSlotInfo.GetClaimState = function(l)
								refreshData();
								seasonLevel = seasonData.Level;

								local r = "n/a";
								if seasonData.PostRewards[l] ~= nil then
									r = "CanClaim";
								else
									r = "Claimed";
								end
								
								return r;
							end

							local radialBarLabel = timerRadialBar:Clone();
							radialBarLabel.Parent = itemButtonObj.ImageButton;

							local radialBar = modRadialImage.new(timerRadialConfig, radialBarLabel);
							local itemUpdateFunc = itemButtonObj.Update;

							itemButtonObj.Update = function(self, storageItemData)
								itemUpdateFunc(self, storageItemData);
								if rewardInfo.ExpireTime == nil then return end;
								local timeRemaining = rewardInfo.ExpireTime - workspace:GetServerTimeNow();
								local timeLeftRatio = timeRemaining/shared.Const.OneDaySecs;
								radialBar:UpdateLabel(math.max(timeLeftRatio, 0.1));

								if timeRemaining <= (3600*4) then
									radialBarLabel.ImageColor3 = BarColors.Yellow;
								elseif timeRemaining <= 3600 then
									radialBarLabel.ImageColor3 = BarColors.Red;
								else
									radialBarLabel.ImageColor3 = BarColors.Green;
								end
							end

							itemButtonObj.ImageButton.MouseButton1Click:Connect(function()
								if itemButtonObj.DimOut then return end;
								if workspace:GetAttribute("IsDev") == true then
									Debugger:Warn(`Level {lvl} RewardInfo`,rewardInfo);
								end

								itemToolTip.Frame.Visible = false;
								refreshData();
								Interface:PlayButtonClick();

								MissionDisplayFrame:ClearAllChildren();

								local passRewardFrame = templatePassReward:Clone();
								passRewardFrame.Parent = MissionDisplayFrame;

								local titleLabel = passRewardFrame:WaitForChild("Title");
								titleLabel.Text = '<font size="12">'.."Level "..lvl.."</font>\n<b>".. itemLib.Name .."</b>";
								
								if rewardInfo.RequiresPremium then
									titleLabel.Text = titleLabel.Text.." (Premium)";
								end
								
								local contentFrame = passRewardFrame:WaitForChild("Frame");
								local claimButton = contentFrame:WaitForChild("ClaimButton") :: TextButton;
								local slotFrame = contentFrame:WaitForChild("Slot");
								local descLabel = contentFrame:WaitForChild("Description");

								if rewardInfo.ItemId ~= "gold" then
									claimButton.AnchorPoint = Vector2.new(1, 1);
									claimButton.Position = UDim2.new(1, 0, 1, 0);
	
									local holdDownScrapObj = modComponents.CreateHoldDownButton(Interface, {
										Text = `<b>Trade in for {rewardInfo.TokensAmount or "1"} Gift Shop Tokens</b>`;
										Color = Color3.fromRGB(165, 140, 75);
									})
	
									local holdDownScrapButton: TextButton = holdDownScrapObj.Button;
									holdDownScrapButton.AnchorPoint = Vector2.new(0, 1);
									holdDownScrapButton.Position = UDim2.new(0, 0, 1, 0);
									holdDownScrapButton.Size = UDim2.new(0.5, -10, 0, 30);
									holdDownScrapButton.TextSize = 16;
									holdDownScrapButton.Parent = contentFrame;

									local noteLabel = Instance.new("TextLabel");
									noteLabel.Text = "";
									noteLabel.AnchorPoint = Vector2.new(0, 1);
									noteLabel.Position = UDim2.new(0, 0, 1, -40);
									noteLabel.BackgroundTransparency = 1;
									noteLabel.TextColor3 = Color3.fromRGB(200, 200, 200);
									noteLabel.TextSize = 9;
									noteLabel.Size = UDim2.new(1, 0, 0, 20);
									if modItemsLibrary:HasTag(itemLib.Id, "Skin Perm") then
										noteLabel.Text = "* Once claimed, each skin permanents can only be traded for 1 gift shop token in Rat shop.";
									else
										noteLabel.Text = "* Once claimed, this is no longer tradable for gift shop tokens.";
									end
									noteLabel.Parent = contentFrame;

									local lastMoved = tick();
									claimButton.MouseMoved:Connect(function()
										noteLabel.TextTransparency = 0;
										lastMoved = tick();
										task.wait(1);
										if tick()-lastMoved < 1 then return end;
										TweenService:Create(noteLabel, TweenInfo.new(1), {TextTransparency=1}):Play();
									end)
		
									holdDownScrapObj.OnHoldDownConfirm = function()
										holdDownScrapButton.Text = "Trading in...";
										local r = remoteBattlepassRemote:InvokeServer("tradeinreward", lvl);
										if r.FailMsg then
											
											
										elseif r.Success == true then
											game.Debris:AddItem(postLvlSlotInfo.GlowLabel, 0);
											itemButtonObj.DimOut = true;
											itemButtonObj:Update();
											
											task.delay(3, function()
												lvlSlot.ClipsDescendants = true;
												lvlSlot.AutomaticSize = Enum.AutomaticSize.None;
												lvlSlot:TweenSize(UDim2.new(0, 0, 1, 0));
												
												task.wait(1);
												game.Debris:AddItem(lvlSlot, 0);
												levelSlotsInfo[lvl] = nil;
												itemButtonObj:Destroy();
											end)
	
											holdDownScrapButton.Visible = false;
											claimButton.Visible = false;
										end
									end;

								end
								
								local cloneItemButton = itemButtonObj.ImageButton:Clone();
								cloneItemButton.Parent = slotFrame;

								itemToolTip:BindHoverOver(cloneItemButton, function()
									itemToolTip.Frame.Parent = windowFrame;
									itemToolTip:Update(rewardInfo.ItemId);
									itemToolTip:SetPosition(cloneItemButton);
								end); 

								local function h3(txt)
									return '<b><font size="18">' .. txt .. '</font></b>'
								end

								local descText = "";
								descText = descText..h3("Unlock Level: ").. lvl;

								descText = descText.."\n\n"..h3("Name: ").. itemLib.Name;
								descText = descText.."\n"..h3("Type: ").. itemLib.Type;
								descText = descText.."\n"..h3("Description: ").. itemLib.Description;

								if rewardInfo.ExpireTime then
									local timeLeft = rewardInfo.ExpireTime-workspace:GetServerTimeNow();
									descText = descText.."\n\n"..h3("Expires: ").. modSyncTime.ToString(timeLeft);
								end

								descLabel.Text = descText;

								if postLvlSlotInfo.GetClaimState(lvl) ~= "CanClaim" then return end;

								claimButton.Visible = true;

								local requiresMP = seasonData.Owned ~= true;
								if requiresMP then
									claimButton.Text = "Requires Mission Pass";
								end

								local  claimText = claimButton.Text;
								claimButton.MouseButton1Click:Connect(function()
									if requiresMP then
										bpButtonFunc();
										return;
									end
									refreshData();
									if postLvlSlotInfo.GetClaimState(lvl) ~= "CanClaim" then return end;

									claimButton.Text = "Claiming...";
									local r = remoteBattlepassRemote:InvokeServer("claimpostreward", lvl);
									if r.FailMsg then
										if r.FailMsg == "Requires Mission Pass" then
											bpButtonFunc();

										else
											claimButton.Text = r.FailMsg;
											task.wait(2);

										end

									elseif r.Success == true then
										game.Debris:AddItem(postLvlSlotInfo.GlowLabel, 0);
										itemButtonObj.DimOut = true;
										itemButtonObj:Update();
										
										task.delay(3, function()
											lvlSlot.ClipsDescendants = true;
											lvlSlot.AutomaticSize = Enum.AutomaticSize.None;
											lvlSlot:TweenSize(UDim2.new(0, 0, 1, 0));
											
											task.wait(1);
											game.Debris:AddItem(lvlSlot, 0);
											levelSlotsInfo[lvl] = nil;
											itemButtonObj:Destroy();
										end)

										Interface:OpenWindow("Inventory");
										claimButton.Visible = false;

									end
									claimButton.Text = claimText;
								end)
							end)
						end

						local itemButtonObj = postLvlSlotInfo.ItemButton;

						local claimState = postLvlSlotInfo.GetClaimState(lvl);

						if claimState == "CanClaim" then
							game.Debris:AddItem(itemButtonObj.ImageButton:FindFirstChild("LockLabel"), 0);

							local newGlow = itemButtonObj.ImageButton:FindFirstChild("ClaimGlow") or modItemInterface.newGlowEffect();
							newGlow.Name = "ClaimGlow"
							newGlow.ImageColor3 = Color3.fromRGB(255, 255, 255);
							newGlow.ImageTransparency = 0.6;
							newGlow.Parent = itemButtonObj.ImageButton;
							postLvlSlotInfo.GlowLabel = newGlow;
							itemButtonObj.DimOut = nil;
							itemButtonObj.ImageButton.radialBar.Visible = true;


						elseif claimState == "Claimed" then
							game.Debris:AddItem(itemButtonObj.ImageButton:FindFirstChild("LockLabel"), 0);
							game.Debris:AddItem(postLvlSlotInfo.GlowLabel, 0);
							itemButtonObj.DimOut = true;
							itemButtonObj.ImageButton.radialBar.Visible = false;

						end

						local itemData = rewardInfo.Data or {};
						itemData.ItemId = rewardInfo.ItemId;
						itemData.Quantity = rewardInfo.Quantity or 1;
						itemButtonObj:Update(itemData);

						lvlSlot.ImageColor3 = bpColors.CurrentPassOwner;
						lvlSlot.Parent = battlePassContent;
						
						
					end
				end
			end

			--== MARK: Gift Shop
			local giftShop = "giftshop";
			local lvlSlotInfo = levelSlotsInfo[giftShop];

			if lvlSlotInfo == nil then
				local info = {};

				info.LevelSlot = templateLevelSlot:Clone() :: ImageLabel;
				info.LevelSlot.LayoutOrder = 9999-1;
				info.LevelSlot.Size = UDim2.new(0, 120, 1, 0);

				levelSlotsInfo[giftShop] = info;
				lvlSlotInfo = info;
				
				if lvlSlotInfo.ItemButton == nil then
					local itemButtonObj = modItemInterface.newItemButton("unknowngift");
					
					local aspectRatioConstraint = Instance.new("UIAspectRatioConstraint");
					aspectRatioConstraint.Parent = itemButtonObj.ImageButton;

					itemButtonObj.ImageButton.AnchorPoint = Vector2.new(0, 0.5);
					itemButtonObj.ImageButton.Position = UDim2.new(0, 0, 0.5, 0);
					itemButtonObj.ImageButton.Size = UDim2.new(0, 100, 0, 100);
					itemButtonObj.ImageButton.Rotation = 1;
					itemButtonObj.ImageButton.Parent = info.LevelSlot;

					info.LevelSlot.AutomaticSize = Enum.AutomaticSize.X;

					local tokenLabel = Instance.new("TextLabel");
					tokenLabel.RichText = true;
					tokenLabel.AutomaticSize = Enum.AutomaticSize.X;
					tokenLabel.Font = Enum.Font.Arial;
					tokenLabel.TextColor3 = Color3.fromRGB(255,255,255);
					tokenLabel.BackgroundTransparency = 1;
					tokenLabel.TextScaled = true;
					tokenLabel.Size = UDim2.new(0, 0, 1, 0);
					tokenLabel.Position = UDim2.new(0, 100, 0, 0);
					tokenLabel.Parent = info.LevelSlot;
					lvlSlotInfo.Label = tokenLabel;

					local padding = Instance.new("UIPadding");
					padding.PaddingLeft = UDim.new(0, 0);
					padding.PaddingRight = UDim.new(0, 15);
					padding.PaddingTop = UDim.new(0, 15);
					padding.PaddingBottom = UDim.new(0, 15);
					padding.Parent = tokenLabel;

					local slotPadding = Instance.new("UIPadding");
					slotPadding.PaddingLeft = UDim.new(0, 10);
					slotPadding.PaddingRight = UDim.new(0, 10);
					slotPadding.Parent = info.LevelSlot;

					lvlSlotInfo.ItemButton = itemButtonObj;
					
					local function loadGiftShop()
						itemToolTip.Frame.Visible = false;
						refreshData();
						Interface:PlayButtonClick();

						MissionDisplayFrame:ClearAllChildren();
						local passRewardFrame = templatePassReward:Clone();
						passRewardFrame.Parent = MissionDisplayFrame;

						local titleLabel = passRewardFrame:WaitForChild("Title");
						local titleStr = "<b>Gift Shop!</b>";
						titleLabel.TextColor3 = bpColors.CurrentPremium;

						local contentFrame = passRewardFrame:WaitForChild("Frame");
						local claimButton = contentFrame:WaitForChild("ClaimButton");
						local slotFrame = contentFrame:WaitForChild("Slot");
						local descLabel = contentFrame:WaitForChild("Description");
						local scrollFrame = contentFrame:WaitForChild("ScrollFrame");
						
						slotFrame.Visible = false;
						claimButton.Visible = false;
						scrollFrame.Visible = true;
						descLabel.Size = UDim2.new(1, 0, 1, 0);
						
						local descText = "Trade in your rewards for past mission pass rewards! You can also trade in skin permanents in the Rat shop. Accumulated Tokens will only be usable during current mission pass.";

						if modData.IsPremium ~= true then
							titleStr = titleStr.." (Premium)";
							descText = "Requires Premium!\n"..descText;
						end

						titleLabel.Text = titleStr;
						descLabel.Text = descText;

						local uiGridLayout = scrollFrame:WaitForChild("UIGridLayout") :: UIGridLayout;
						uiGridLayout.CellPadding = UDim2.new(0, 10, 0, 10);
						uiGridLayout.CellSize = UDim2.new(0, 120, 0, 120);
						uiGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;

						scrollFrame.Size = UDim2.new(1, 0, 1, -50);

						local giftShopRewards = modBattlePassLibrary.GiftShop;
						local giftShopButtonTemplate = script:WaitForChild("GiftShopButton");

						for a=1, #giftShopRewards do
							local shopLib = giftShopRewards[a];

							local newButton = giftShopButtonTemplate:Clone() :: TextButton;
							local slotLabel = newButton:WaitForChild("ItemSlot");
							local costLabel = newButton:WaitForChild("Title") :: TextLabel;

							local giftItemButtonObj = modItemInterface.newItemButton(shopLib.ItemId);
							giftItemButtonObj.ImageButton.Parent = slotLabel;
							giftItemButtonObj:Update();

							newButton.Parent = scrollFrame;

							itemToolTip:BindHoverOver(giftItemButtonObj.ImageButton, function()
								itemToolTip.Frame.Parent = windowFrame;
								itemToolTip:Update(shopLib.ItemId);
								itemToolTip:SetPosition(giftItemButtonObj.ImageButton);
							end);
							

							local tradeCost = shopLib.Cost;
							costLabel.Text = `{tradeCost} Tokens`;

							local itemLib = modItemsLibrary:Find(shopLib.ItemId);
							local function onButtonClick()
								Interface:PlayButtonClick();

								if tradeCost == nil then
									costLabel.TextColor3 = Color3.fromRGB(200, 50, 50);
									TweenService:Create(costLabel, TweenInfo.new(1), {
										TextColor3 = Color3.fromRGB(255, 255, 255);
									}):Play();
									return;
								end

								seasonTokens = seasonData.Tokens or 0;
								if seasonTokens < tradeCost then
									lvlSlotInfo.Label.TextColor3 = Color3.fromRGB(200, 50, 50);
									TweenService:Create(lvlSlotInfo.Label, TweenInfo.new(1), {
										TextColor3 = Color3.fromRGB(255, 255, 255);
									}):Play();
									return;
								end

								local promptWindow = Interface:PromptQuestion(`Trade For {itemLib.Name}`, 
									`Are you sure you would like to trade in <b>{modFormatNumber.Beautify(tradeCost)} Tokens</b> for a {itemLib.Name}`, "Trade", "Cancel", itemLib.Icon);
								local YesClickedSignal, NoClickedSignal;
			
								local debounce = false;
								YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
									if debounce then return end;
									debounce = true;
									Interface:PlayButtonClick();
			
									local _r = remoteBattlepassRemote:InvokeServer("purchasegiftshop", shopLib.ItemId);
									Interface:OpenWindow("Inventory");
									Interface:OpenWindow("Missions", "giftshop");

									promptWindow:Close();
									YesClickedSignal:Disconnect();
									NoClickedSignal:Disconnect();
								end);
								NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
									if debounce then return end;
									Interface:PlayButtonClick();
									promptWindow:Close();
									Interface:OpenWindow("Missions", "giftshop");
									YesClickedSignal:Disconnect();
									NoClickedSignal:Disconnect();
								end);
							end
							
							giftItemButtonObj.ImageButton.MouseButton1Click:Connect(onButtonClick);
							newButton.MouseButton1Click:Connect(onButtonClick);
						end
					end

					lvlSlotInfo.Label.InputBegan:Connect(function(inputObject)
						if (inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch) 
							and inputObject.UserInputState == Enum.UserInputState.Begin then
							loadGiftShop();
						end
					end)
					itemButtonObj.ImageButton.MouseButton1Click:Connect(loadGiftShop);
					itemButtonObj.ImageButton:GetAttributeChangedSignal("FireClick"):Connect(loadGiftShop);

					itemButtonObj:Update();
				end

				lvlSlotInfo.LevelSlot.ImageColor3 = bpColors.Premium;
				info.LevelSlot.Parent = battlePassContent;
			end
			lvlSlotInfo.Label.Text = "<b>".. modFormatNumber.Beautify(seasonTokens or 0) .." Tokens</b>";
			if action == "giftshop" then
				lvlSlotInfo.ItemButton.ImageButton:SetAttribute("FireClick", not lvlSlotInfo.ItemButton.ImageButton:GetAttribute("FireClick") );
			end

			--== MARK: Final Level 
			if seasonLevel > treeCount then
				if finalSlotInfo.Slot == nil then
					finalSlotInfo.Slot = templateLevelSlot:Clone();
					finalSlotInfo.Slot.Size = UDim2.new(0, 160, 1, 0);
					finalSlotInfo.Slot.LayoutOrder = 9999;

					local finalLabel = Instance.new("TextLabel");
					finalLabel.RichText = true;
					finalLabel.Size = UDim2.new(1, 0, 1, 0);
					finalLabel.Font = Enum.Font.Arial;
					finalLabel.TextColor3 = Color3.fromRGB(255,255,255);
					finalLabel.BackgroundTransparency = 1;
					finalLabel.TextScaled = true;
					finalLabel.TextStrokeColor3 = Color3.fromRGB(255,255,255);
					finalLabel.TextStrokeTransparency = 1;
					
					local padding = Instance.new("UIPadding");
					padding.PaddingLeft = UDim.new(0, 10);
					padding.PaddingRight = UDim.new(0, 10);
					padding.PaddingTop = UDim.new(0, 15);
					padding.PaddingBottom = UDim.new(0, 15);
					padding.Parent = finalLabel;
					
					finalSlotInfo.Label = finalLabel;
					finalLabel.Parent = finalSlotInfo.Slot;
				end

				finalSlotInfo.BackgroundColor3 = bpColors.CurrentPassOwner;
				finalSlotInfo.Label.Text = "<b>Level ".. tostring(seasonLevel) .."</b>";
				finalSlotInfo.Slot.Parent = battlePassContent;
				
				battlePassContent.UIPadding.PaddingRight = UDim.new(0, 0);
				
			else
				battlePassContent.UIPadding.PaddingRight = UDim.new(0, 100);
			end 
			

			if seasonLevel > treeCount then
				battlePassContent.CanvasPosition = battlePassContent.AbsoluteCanvasSize;
					
			else
				local midCanvasPoint = totalDist- (battlePassContent.AbsoluteSize.X/2);
				battlePassContent.CanvasPosition = Vector2.new(midCanvasPoint, 0);
			end
		end
	end
	
	battlePassContent:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		for _, info in pairs(levelSlotsInfo) do
			if info.GlowLabel == nil then continue end;
			local rays = info.GlowLabel:FindFirstChild("Rays");
			if rays == nil then continue end;
			
			local offset = BottomFrame:GetAttribute("RayRange") or Vector2.new(-60, -60);
			if rays.AbsolutePosition.X <= (BottomFrame.AbsolutePosition.X + offset.X)
				or rays.AbsolutePosition.X >= (BottomFrame.AbsolutePosition.X+BottomFrame.AbsoluteSize.X + offset.Y) then
				rays.Visible = false;
			else
				rays.Visible = true;
			end
			
		end
	end)
	
	Interface.Garbage:Tag(function()
		Interface.Update = function() end;
	end)

	return Interface;
end;

return Interface;