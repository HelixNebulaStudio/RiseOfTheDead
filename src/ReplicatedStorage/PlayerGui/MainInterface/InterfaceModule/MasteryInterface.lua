local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local DragSmoothness = 0.5; -- 0-1;
--== Variables;
local Interface = {};
Interface.IsDragging = false;
Interface.DragStartVector = Vector2.new();
Interface.TreeFrameOffset = Vector2.new();

local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");
local UserInputService = game:GetService("UserInputService");

local player = game.Players.LocalPlayer;
local modData = require(player:WaitForChild("DataModule"));

local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modSkillTreeLibrary = require(game.ReplicatedStorage.Library.SkillTreeLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local branchColor = modBranchConfigs.BranchColor

local modRadialImage = require(game.ReplicatedStorage.Library.UI.RadialImage);
local modNodeGridUI = require(game.ReplicatedStorage.Library.UI.NodeGridUI);

local remoteSkillTree = modRemotesManager:Get("SkillTree");

--==
local masteryFrame = script.Parent.Parent:WaitForChild("MasteryFrame");
local masteryList = masteryFrame:WaitForChild("MainFrame"):WaitForChild("List");
local masteryLayout = masteryList:WaitForChild("UIGridLayout");
local masteryPadding = masteryList:WaitForChild("UIPadding");

local skillFrame = masteryFrame:WaitForChild("SkillFrame");
local pageFrame = skillFrame:WaitForChild("pageInfo");
local templatePageOption = script:WaitForChild("pageOption");
local templateNewPageOption = script:WaitForChild("newPageOption");

local skillPointsLabel = pageFrame:WaitForChild("skillpointsLabel");
local dropDownButton = pageFrame:WaitForChild("dropDownButton");
local pageList = pageFrame:WaitForChild("pageList");
local pageNameInput = pageFrame:WaitForChild("pageNameInput");

local savePageButton = pageFrame:WaitForChild("saveButton");
local undoPageButton = pageFrame:WaitForChild("undoButton");

local centerButton = pageFrame:WaitForChild("centerButton");

local treeFrame = skillFrame:WaitForChild("TreeFrame");
local templateItemFrame = script:WaitForChild("ItemMasteryFrame");
local templateSkillButton = script:WaitForChild("skillButton");
local templateLabel = script:WaitForChild("Label");
local treeTypesButtons = {treeFrame.offensive; treeFrame.defensive; treeFrame.synergy};

local nodeMenu = modNodeGridUI.new(); nodeMenu.StartLayerIndex = 2; nodeMenu.DisableRecenter = true;
local centerNode = nodeMenu:NewNode(treeFrame.Center, "root", nil, 1); centerNode.Radius = 0; centerNode.NodePadding = 0;

local TreeScaling = {
	Scale=1;
	PointsRadius={Value=20; Default=20;};
	TypeRadius={Value=50; Default=50;};
	TreeRadius={Value=80; Default=80;};
};

local pointsLabelScale, optionScale, skillIconScale = 25, 100, 55;

local authPointsLabel = templateLabel:Clone(); authPointsLabel.Parent = treeFrame;
local enduPointsLabel = templateLabel:Clone(); enduPointsLabel.Parent = treeFrame;
local synePointsLabel = templateLabel:Clone(); synePointsLabel.Parent = treeFrame;

local authPointNode = nodeMenu:NewNode(authPointsLabel, "AuthPoints", "root", 1); authPointNode.Radius = TreeScaling.PointsRadius.Value; authPointNode.NodePadding = 0;
local enduPointNode = nodeMenu:NewNode(enduPointsLabel, "EnduPoints", "root", 2); enduPointNode.Radius = TreeScaling.PointsRadius.Value; enduPointNode.NodePadding = 0;
local synePointNode = nodeMenu:NewNode(synePointsLabel, "SynePoints", "root", 3); synePointNode.Radius = TreeScaling.PointsRadius.Value; synePointNode.NodePadding = 0;

local authNode = nodeMenu:NewNode(treeFrame.offensive, "Authority", "AuthPoints", 1); authNode.Radius = TreeScaling.TypeRadius.Value; authNode.NodePadding = 0;
local enduNode = nodeMenu:NewNode(treeFrame.defensive, "Endurance", "EnduPoints", 1); enduNode.Radius = TreeScaling.TypeRadius.Value; enduNode.NodePadding = 0;
local syneNode = nodeMenu:NewNode(treeFrame.synergy, "Synergy", "SynePoints", 1); syneNode.Radius = TreeScaling.TypeRadius.Value; syneNode.NodePadding = 0;

local authTreeList = modSkillTreeLibrary.Authority:GetSorted();
local enduTreeList = modSkillTreeLibrary.Endurance:GetSorted();
local syneTreeList = modSkillTreeLibrary.Synergy:GetSorted();

local TreeMenu = {};
local skillRadialConfig = '{"version":1,"size":128,"count":64,"columns":8,"rows":8,"images":["rbxassetid://4451316528"]}';

local selectedId, descriptionFrame;
local random = Random.new();

local PageCache = {
	CurrentPage = nil;
	Tree = {};
};
local markDirty = false;

local SkillButton = {};
SkillButton.__index = SkillButton;
--== Script;
for _, button in pairs(treeTypesButtons) do
	button.MouseMoved:Connect(function()
		for a=1, #treeTypesButtons do
			local b = treeTypesButtons[a];
			local buttonColor = b.Name == "offensive" and Color3.fromRGB(255, 60, 60)
								or b.Name == "defensive" and Color3.fromRGB(27, 106, 23)
								or b.Name == "synergy" and Color3.fromRGB(54, 104, 241)
			b.ImageColor3 = b==button and buttonColor or Color3.fromRGB(255, 255, 255);
			b.TextLabel.Visible = b==button;
		end
	end)
	button.MouseLeave:Connect(function()
		button.ImageColor3 = Color3.fromRGB(255, 255, 255);
		button.TextLabel.Visible = false;
	end)
end

local function LoadTree()
	if markDirty then return end;
	if modData.Profile.SkillTree == nil then return end;
	
	local savedTree = modData.Profile.SkillTree.Trees[PageCache.CurrentPage];
	if savedTree == nil then return end;
	
	PageCache.Tree = {Data={};};
	PageCache.Tree.Name = savedTree.Name;
	
	for k, v in pairs(savedTree.Data) do
		PageCache.Tree.Data[k] = v;
	end
end

local function HideDescription()
	descriptionFrame.Visible = false;
	SkillButton.DescId = nil;
	for a=1, #TreeMenu do
		TreeMenu[a].Button.ZIndex = 5;
		TreeMenu[a].Bar.ZIndex = 5;
		TreeMenu[a].Icon.ZIndex = 5;
	end
end

local descriptionCache = {};
local function UpdateDescription(parent)
	if descriptionFrame then HideDescription() end;
	if selectedId == nil then return end;
	local playerLevel = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.Level or 0;
	
	local lib, class = modSkillTreeLibrary:Find(selectedId);
	local points = PageCache.Tree.Data and PageCache.Tree.Data[lib.Id] or nil;
	local level = points and points/lib.UpgradeCost or nil;
	
	descriptionFrame = parent:FindFirstChild("skillDesc");
	
	if descriptionCache[selectedId] ~= level and descriptionFrame then
		descriptionFrame:Destroy();
		descriptionFrame = nil
	end
	descriptionCache[selectedId] = level;
	if descriptionFrame == nil then
		local descFrame = script.skillDesc:Clone();
		
		local mouseLeaveFrame = descFrame:WaitForChild("mouseLeaveFrame");
		mouseLeaveFrame.MouseLeave:Connect(function()
			selectedId = nil;
			HideDescription();
		end)
		
		local parentChangeConn;
		parentChangeConn = descFrame:GetPropertyChangedSignal("Parent"):Connect(function()
			if descFrame and descFrame.Parent == nil then
				descFrame = nil;
				parentChangeConn:Disconnect();
			end
		end)
		
		local savedTree = modData.Profile.SkillTree.Trees[PageCache.CurrentPage] or {};
		
		local topBar = descFrame:WaitForChild("TopBar");
		local titleTag = topBar:WaitForChild("Title");
		local contentFrame = descFrame:WaitForChild("Content");
		local descTag = contentFrame:WaitForChild("DescLabel");
		
		titleTag.Text = lib.Name;
		local descText = lib.Description; 
		
		if playerLevel < lib.Level then
			descText = ('<font size="18" face="ArialBold" color="rgb(255,102,102)">Unlocks at level '..lib.Level..'.</font> <br/> <br/>')..descText;
			
		else
			if lib.MaxLevel ~= level then
				descText = ('<font size="18" face="ArialBold">Upgrade Cost: '..lib.UpgradeCost..' Points</font> <br/> <br/>')..descText;
				
			end
		end
		for key, info in pairs(lib.Stats) do
			key = "$"..key;
			if descText:match(key) then
				if info.Default then
					descText = string.gsub(descText, "$Default", tostring(info.Default));
				end
				
				if level then
					local interval = (info.Max-info.Base)/lib.MaxLevel;
					local levelStr = "";
					if level == 1 then
						levelStr = levelStr..'<font face="ArialBold" color="rgb(255,230,51)">'..info.Base..'</font> / ';
						
					else
						levelStr = levelStr..info.Base.." / ";
						
					end
					for a=1, (lib.MaxLevel-2) do
						local t = info.Base+(interval*a);
						t = math.ceil(t*100)/100;
						if level == (a+1) then
							t = '<font face="ArialBold" color="rgb(255,230,51)">'..t..'</font>';
							
						end
						levelStr = levelStr.. tostring(t) .." / ";
					end
					if level == lib.MaxLevel then
						levelStr = levelStr..'<font face="ArialBold" color="rgb(255,230,51)">'..info.Max..'</font>';
						
					else
						levelStr = levelStr..info.Max;
						
					end
					
					descText = string.gsub(descText, key, "("..levelStr..")");
				else
					descText = string.gsub(descText, key, "("..info.Base.."-"..info.Max..")");
				end
			end
		end
		
		descTag.Text = descText;
		local textBounds = TextService:GetTextSize(descTag.Text, descTag.TextSize, descTag.Font, Vector2.new(225, 1000));
		
		contentFrame.Size = UDim2.new(1, 225, 0, textBounds.Y+20);--45+math.clamp(descObject.ContentSize.Y, 25, 200)); 
		mouseLeaveFrame.Size = UDim2.new(1, contentFrame.AbsoluteSize.X+20, 1, contentFrame.AbsoluteSize.Y+20);
		descFrame.Parent = parent;
		descriptionFrame = descFrame;
	else
		descriptionFrame.Visible = true;
	end

	parent.ZIndex = 7;
	if parent:FindFirstChild("skillIcon") then
		parent.skillIcon.ZIndex = 7;
	end
	if parent:FindFirstChild("radialBar") then
		parent.radialBar.ZIndex = 7;
	end
end

local function TogglePageButtons()
	local savedTree = modData.Profile.SkillTree.Trees[PageCache.CurrentPage] or {};
	local match = savedTree.Name == PageCache.Tree.Name;
	
	if match then
		for k, v in pairs(PageCache.Tree.Data) do
			if savedTree.Data[k] ~= v then
				match = false;
				break;
			end
		end
	end
	if match then
		for k, v in pairs(savedTree.Data) do
			if PageCache.Tree.Data[k] ~= v then
				match = false;
				break;
			end
		end
	end
	savePageButton.Visible = not match;
	undoPageButton.Visible = not match;
end

local function CenterTreeDisplay()
	if Interface.IsDragging then Debugger:Warn("Can't center while dragging tree."); return end;
	treeFrame.Position = UDim2.new(0.5, 0, 0.5, 0);
	
	TreeScaling.Scale = 1;
	TreeScaling.PointsRadius.Value = TreeScaling.PointsRadius.Default;
	TreeScaling.TypeRadius.Value = TreeScaling.TypeRadius.Default;
	TreeScaling.TreeRadius.Value = TreeScaling.TreeRadius.Default;
	
	local pointsLabelSize = UDim2.new(0, pointsLabelScale, 0, pointsLabelScale);
	authPointsLabel.Size = pointsLabelSize;
	enduPointsLabel.Size = pointsLabelSize;
	synePointsLabel.Size = pointsLabelSize;
	
	local optionSize = UDim2.new(0, optionScale, 0, optionScale);
	treeFrame.offensive.Size = optionSize;
	treeFrame.defensive.Size = optionSize;
	treeFrame.synergy.Size = optionSize;
	
	templateSkillButton.Size = UDim2.new(0, skillIconScale, 0, skillIconScale);
end

local function updateSkillPoints()
	local playerLevel = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.Level or 0;
	local points = 0;
	local authP, enduP, syneP = 0, 0, 0;
	
	for id, v in pairs(PageCache.Tree.Data) do
		points = points + v;
		if modSkillTreeLibrary.Authority:Find(id) then
			authP = authP + v;
		elseif modSkillTreeLibrary.Endurance:Find(id) then
			enduP = enduP + v;
		elseif modSkillTreeLibrary.Synergy:Find(id) then
			syneP = syneP + v;
		end;
	end
	local pointsAvailable = playerLevel-points;
	
	authPointsLabel.Text = authP;
	enduPointsLabel.Text = enduP;
	synePointsLabel.Text = syneP;
	
	skillPointsLabel.Text = "Skill Points: "..pointsAvailable.."/"..playerLevel;
	
	
	local amtLabel = Interface.Windows.MasteryMenu.QuickButton:WaitForChild("AmtFrame"):WaitForChild("AmtLabel");
	amtLabel.Text = pointsAvailable > 0 and pointsAvailable or "";
	
	return playerLevel-points;
end

local function LoadDropDown()
	if modData.Profile.SkillTree == nil then
		Debugger:Warn("Missing skill tree data");
		return;
	end
	
	pageList:ClearAllChildren();
	local debounce = false;
	
	local trees = modData.Profile.SkillTree.Trees;
	for index=1, #trees do
		local new = templatePageOption:Clone();
		new.Position = UDim2.new(0, 0, index, 0);
		
		local label = new:WaitForChild("nameLabel");
		label.Text = trees[index].Name;
		
		new.MouseButton1Click:Connect(function()
			PageCache.CurrentPage = index;
			modData.Profile.SkillTree.ActiveTree = PageCache.CurrentPage;
			remoteSkillTree:FireServer(modData.Profile.SkillTree);
			pageList.Visible = false;
			Interface.Update();
		end)
		
		local deleteButton = new:WaitForChild("deleteButton");
		local delConfirmBar = deleteButton:WaitForChild("confirmBar");
		
		local holdDownDelete = false;
		deleteButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				holdDownDelete = true;
				
				local startTick = tick();
				local downTime = 1;
				local a = 0;
				repeat
					a = math.clamp( (tick()-startTick)/downTime, 0, 1)
					delConfirmBar.Size = UDim2.new(math.clamp(a, 0.1, 1), 0, 1, 0);
					RunService.RenderStepped:Wait();
				until not holdDownDelete or a >= 1;
				delConfirmBar.Size = UDim2.new(0, 0, 1, 0);
				if a >= 1 then
					if debounce then return end;
					debounce = true;
					PageCache.Tree = nil;
					table.remove(modData.Profile.SkillTree.Trees, index);
					PageCache.CurrentPage = 1;
					new:Destroy(); --templatePageOption
					Interface.Update();
					LoadDropDown();
					debounce = false;
				end
			end
		end)
		deleteButton.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				holdDownDelete = false;
			end
		end)
		
		deleteButton.Visible = #trees > 1;
		new.Size = UDim2.new(0, deleteButton.Visible and 185 or 210, 1, 0);
		new.Parent = pageList;
	end
	
	local newPageButton = templateNewPageOption:Clone();
	newPageButton.Position = UDim2.new(0, 0, #trees+1, 0);
	newPageButton.Parent = pageList;
	local textLabel = newPageButton:WaitForChild("nameLabel");
	
	if not modData.Profile.Premium and #trees >= 2 then
		newPageButton.AutoButtonColor = false;
		textLabel.Text = "New Page (Premium)";
	elseif #trees >= 5 then
		newPageButton.AutoButtonColor = false;
		textLabel.Text = "Maxed Pages";
	else
		newPageButton.AutoButtonColor = true;
		textLabel.Text = "New Page";
	end
	newPageButton.MouseButton1Click:Connect(function()
		if not modData.Profile.Premium and #trees >= 2 then return end;
		if #trees >= 5 then return end;
		if debounce then return end;
		debounce = true;
		table.insert(modData.Profile.SkillTree.Trees, {Name="Untitled"..#trees, Data={};});
		PageCache.CurrentPage = #modData.Profile.SkillTree.Trees;
		Interface.Update();
		LoadDropDown();
		pageList.Visible = false;
		debounce = false;
	end)
	
	pageList.Visible = true;
end

--== SkillButton Object
function SkillButton.new(lib, disabled)
	local newButton = templateSkillButton:Clone();
	local radialBar = newButton:WaitForChild("radialBar");
	local skillIcon = newButton:WaitForChild("skillIcon");
	
	local self = {
		Button = newButton;
		Bar = radialBar;
		Icon = skillIcon;
		Id = lib.Id;
		Lib = lib;
		Disabled = disabled == true;
		Radial = modRadialImage.new(skillRadialConfig, radialBar);
		
		Node=nil;
	};
	
	skillIcon.Image = lib.Icon;
	radialBar.ImageColor3 = branchColor;
	self.Button.Parent = treeFrame;
	
	setmetatable(self, SkillButton);
	
--	local debugTag = Instance.new("IntValue");
--	debugTag.Value = 0;
--	debugTag.Parent = newButton;
--	debugTag:GetPropertyChangedSignal("Value"):Connect(function()
--		PageCache.Tree.Data[self.Lib.Id] = debugTag.Value;
--		self:Update();
--		TogglePageButtons();
--	end)
	
	self.Button.MouseMoved:Connect(function()
		selectedId = lib.Id;
		if SkillButton.DescId ~= selectedId then
			SkillButton.DescId = selectedId;
			UpdateDescription(self.Button);
		end
	end)
	
	self.TotalCost = self.Lib.UpgradeCost*self.Lib.MaxLevel;
	local function addPoint()
		if self.Disabled then return end;
		if updateSkillPoints() < self.Lib.UpgradeCost then Debugger:Log("Out of skill points."); return end;
		if PageCache.Tree.Data[self.Lib.Id] == nil or PageCache.Tree.Data[self.Lib.Id] < self.TotalCost then
			PageCache.Tree.Data[self.Lib.Id] = math.clamp((PageCache.Tree.Data[self.Lib.Id] or 0) +self.Lib.UpgradeCost, 0, self.TotalCost);
			UpdateDescription(self.Button);
			self:Update();
			modAudio.Play("StorageWeaponPickup", nil, nil, false);
			TogglePageButtons();
			
			markDirty = true;
			return true;
		end
	end
	local function minusPoint()
		if self.Disabled then return end;
		if PageCache.Tree.Data[self.Lib.Id] then
			PageCache.Tree.Data[self.Lib.Id] = math.clamp(PageCache.Tree.Data[self.Lib.Id] -self.Lib.UpgradeCost, 0, self.TotalCost);
			if PageCache.Tree.Data[self.Lib.Id] <= 0 then
				PageCache.Tree.Data[self.Lib.Id] = nil;
			end
			UpdateDescription(self.Button);
			self:Update();
			modAudio.Play("StorageWeaponDrop", nil, nil, false);
			TogglePageButtons();

			markDirty = true;
			return true;
		end
	end
	
	
	if UserInputService.TouchEnabled then
		local plus = true;
		self.Button.MouseButton1Click:Connect(function()
			if descriptionFrame and descriptionFrame.Visible and selectedId == lib.Id then
				if plus and addPoint() ~= true then
					plus = false;
				elseif not plus and minusPoint() ~= true then
					plus = true;
				end
			end
			selectedId = lib.Id;
			if SkillButton.DescId ~= selectedId then
				SkillButton.DescId = selectedId;
				UpdateDescription(self.Button);
			end
		end)
	else
		self.Button.MouseButton1Click:Connect(addPoint);
		self.Button.MouseButton2Click:Connect(minusPoint);
	end
	self:Update();
	
	return self;
end

function SkillButton:Update()
	local tree = PageCache.Tree;
	
	local greyshade = 100;
	self.Icon.ImageColor3 = self.Disabled and Color3.fromRGB(greyshade, greyshade, greyshade) or Color3.fromRGB(255, 255, 255);
	self.Button.ImageColor3 = self.Disabled and Color3.fromRGB(greyshade, greyshade, greyshade) or Color3.fromRGB(255, 255, 255);
	
	self.Radial:UpdateLabel( (tree.Data[self.Lib.Id] or 0) /self.TotalCost);
	updateSkillPoints();
end

function SkillButton:Destroy()
	if self.Node then
		nodeMenu:Destroy(self.Node.NodeId)
	end
	if self.Button then self.Button:Destroy(); end;
	for a=1, #TreeMenu do
		if TreeMenu[a] == self then
			table.remove(TreeMenu, a);
			break;
		end
	end
end
--== SkillButton Object

pageNameInput:GetPropertyChangedSignal("Text"):Connect(function()
	selectedId = nil;
	local text = pageNameInput.Text;
	if #text > 0 then
		pageNameInput.Text = text:sub(1, math.min(#text, 16));
		PageCache.Tree.Name = pageNameInput.Text;
		TogglePageButtons();
	end
end)

dropDownButton.MouseButton1Click:Connect(function()
	selectedId = nil;
	if not pageList.Visible then
		LoadDropDown();
	else
		pageList.Visible = false;
	end
end)

undoPageButton.MouseButton1Down:Connect(function()
	selectedId = nil;
	markDirty = false;
	LoadTree();
	Interface.Update();
	TogglePageButtons();
end)

savePageButton.MouseButton1Click:Connect(function()
	selectedId = nil;
	local savedTree = modData.Profile.SkillTree.Trees[PageCache.CurrentPage];
	savedTree.Name = PageCache.Tree.Name;
	
	savedTree.Data = {};
	for k, v in pairs(PageCache.Tree.Data) do
		savedTree.Data[k] = v;
	end
	
	modData.Profile.SkillTree.ActiveTree = PageCache.CurrentPage;
	remoteSkillTree:FireServer(modData.Profile.SkillTree);
	Interface.Update();
	TogglePageButtons();
	markDirty = false;
end)

centerButton.MouseButton1Click:Connect(function()
	selectedId = nil;
	CenterTreeDisplay();
	Interface.RefreshTree();
end)

skillFrame.InputBegan:Connect(function(inputObject, gameProcessed)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
		local mousePosition = UserInputService:GetMouseLocation();
		if mousePosition.X >= skillFrame.AbsolutePosition.X and mousePosition.X <= skillFrame.AbsolutePosition.X+skillFrame.AbsoluteSize.X
		and mousePosition.Y >= skillFrame.AbsolutePosition.Y and mousePosition.Y <= skillFrame.AbsolutePosition.Y+skillFrame.AbsoluteSize.Y then
			Interface.IsDragging = true;
			Interface.DragStartVector = mousePosition;
			Interface.TreeFrameOffset = Vector2.new(treeFrame.Position.X.Offset, treeFrame.Position.Y.Offset);
			RunService:BindToRenderStep("treeDrag", Enum.RenderPriority.Input.Value, function()
				local mousePosition = UserInputService:GetMouseLocation();
				local diff = mousePosition-Interface.DragStartVector;
				if Interface.TreeFrameLerp == nil then Interface.TreeFrameLerp = treeFrame.Position end;
				Interface.TreeFrameLerp = treeFrame.Position;
				treeFrame.Position = Interface.TreeFrameLerp:Lerp(UDim2.new(0.5, Interface.TreeFrameOffset.X+diff.X, 0.5, Interface.TreeFrameOffset.Y+diff.Y), DragSmoothness);
			end)
		end
	end
	if not gameProcessed then
		pageList.Visible = false;
	end
end)

skillFrame.InputEnded:Connect(function(inputObject, gameProcessed)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
		Interface.IsDragging = false;
		RunService:UnbindFromRenderStep("treeDrag");
	end
end)

skillFrame.InputChanged:Connect(function(inputObject, gameProcessed)
	if not gameProcessed then
		if inputObject.UserInputType == Enum.UserInputType.MouseWheel then
			TreeScaling.Scale = math.clamp(TreeScaling.Scale + inputObject.Position.Z*0.1, 0.5, 1.5);
			
			TreeScaling.PointsRadius.Value = TreeScaling.Scale * TreeScaling.PointsRadius.Default;
			TreeScaling.TypeRadius.Value = TreeScaling.Scale * TreeScaling.TypeRadius.Default;
			TreeScaling.TreeRadius.Value = TreeScaling.Scale * TreeScaling.TreeRadius.Default;
			
			local pointsLabelSize = UDim2.new(0, TreeScaling.Scale*pointsLabelScale, 0, TreeScaling.Scale*pointsLabelScale);
			authPointsLabel.Size = pointsLabelSize; enduPointsLabel.Size = pointsLabelSize; synePointsLabel.Size = pointsLabelSize;
			
			local optionSize = UDim2.new(0, TreeScaling.Scale*optionScale, 0, TreeScaling.Scale*optionScale);
			treeFrame.offensive.Size = optionSize;
			treeFrame.defensive.Size = optionSize;
			treeFrame.synergy.Size = optionSize;
			
			templateSkillButton.Size = UDim2.new(0, TreeScaling.Scale*skillIconScale, 0, TreeScaling.Scale*skillIconScale);
			Interface.RefreshTree();
		end
	end
end)

if modConfigurations.CompactInterface then
	masteryFrame.Position = UDim2.new(0.5, 0, 0.5, 0);
	masteryFrame.Size = UDim2.new(1, 0, 1, 0);
	
	masteryFrame:WaitForChild("touchCloseButton").Visible = true;
	masteryFrame:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("MasteryMenu");
	end)
	masteryFrame:WaitForChild("HelpButton").Visible = false;
end

function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local window = Interface.NewWindow("MasteryMenu", masteryFrame);
	window.CompactFullscreen = true;
	window:SetConfigKey("DisableMasteryMenu");
	
	if modConfigurations.CompactInterface then
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1, 80));
	else
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, -35), UDim2.new(0.5, 0, -1, 80));
	end
	window.OnWindowToggle:Connect(function(visible)
		selectedId = nil;
		if visible then
			Interface:RequestData("GameSave/Masteries");
			
			Interface:HideAll{[window.Name]=true;};
			Interface.Update();
			CenterTreeDisplay();
			
		else
			for a=#TreeMenu, 1, -1 do
				TreeMenu[a]:Destroy();
			end
			LoadTree();
			Interface.Update();
			TogglePageButtons();
		end
	end)
	
	modKeyBindsHandler:SetDefaultKey("KeyWindowMasteryMenu", Enum.KeyCode.L);
	local quickButton = Interface:NewQuickButton("MasteryMenu", "Masteries", "rbxassetid://2938848546");
	quickButton.LayoutOrder = 5;
	modInterface:ConnectQuickButton(quickButton, "KeyWindowMasteryMenu");
	
	return Interface;
end

function Interface.RefreshTree()
	local playerLevel = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.Level or 0;
	
	pageNameInput.Text = PageCache.Tree.Name;
	nodeMenu.Clockwise = false;
	nodeMenu.Radius = TreeScaling.TreeRadius.Value;
	nodeMenu.NodePadding = script.NodePadding.Value;
	nodeMenu.StartRadian = 0;

	authPointNode.Radius = TreeScaling.PointsRadius.Value; authPointNode.NodePadding = 0;
	enduPointNode.Radius = TreeScaling.PointsRadius.Value; enduPointNode.NodePadding = 0;
	synePointNode.Radius = TreeScaling.PointsRadius.Value; synePointNode.NodePadding = 0;
	authNode.Radius = TreeScaling.TypeRadius.Value; authNode.NodePadding = 0;
	enduNode.Radius = TreeScaling.TypeRadius.Value; enduNode.NodePadding = 0;
	syneNode.Radius = TreeScaling.TypeRadius.Value; syneNode.NodePadding = 0;
	
	for a=#TreeMenu, 1, -1 do
		TreeMenu[a]:Destroy();
	end
	
	local nextLevelTier = nil;
	local function generateTreeNode(treeType, lib, index)
		local create = false;
		local disabled = false;
		if playerLevel >= lib.Level then
			create = true;
		elseif nextLevelTier == nil then
			nextLevelTier = lib.Level;
			disabled = true;
			create = true;
		elseif lib.Level == nextLevelTier then
			disabled = true;
			create = true;
		end
		if create then
			local newSkillButton = SkillButton.new(lib, disabled);
			if lib.Id == selectedId then
				UpdateDescription(newSkillButton.Button);
			end
			table.insert(TreeMenu, newSkillButton);
			newSkillButton.Button.Name = lib.Id;
			newSkillButton.Node = nodeMenu:NewNode(newSkillButton.Button, lib.Id, lib.Link or treeType, index);
		end
	end
	
	nextLevelTier = nil;
	for a=1, #authTreeList do
		generateTreeNode("Authority", authTreeList[a], a);
	end
	nextLevelTier = nil;
	for a=1, #enduTreeList do
		generateTreeNode("Endurance", enduTreeList[a], a);
	end
	nextLevelTier = nil;
	for a=1, #syneTreeList do
		generateTreeNode("Synergy", syneTreeList[a], a);
	end
	
	nodeMenu:UpdateNodeTree();
	local hiddenLinkFrames = {authPointNode.LinkFrame; enduPointNode.LinkFrame; synePointNode.LinkFrame; authNode.LinkFrame; enduNode.LinkFrame; syneNode.LinkFrame;};
	for a=1, #hiddenLinkFrames do if hiddenLinkFrames[a] and hiddenLinkFrames[a].Visible then hiddenLinkFrames[a].Visible = false; end end;
end

function Interface.Update()
	if masteryFrame.Visible then
		if modData.GameSave and modData.GameSave.Masteries then
			for itemId, level in pairs(modData.GameSave.Masteries) do
				local listing = masteryList:FindFirstChild(itemId);
				if listing == nil then
					listing = templateItemFrame:Clone();
					listing.Name = itemId;
					listing.Parent = masteryList;
				end
				local itemInfo = modItemsLibrary:Find(itemId);
				
				local levelBar = listing:WaitForChild("LevelFrame"):WaitForChild("LevelBar");
				local itemIcon = listing:WaitForChild("ItemIcon");
				local titleTag = listing:WaitForChild("Title");
				local valueTag = listing:WaitForChild("Value");
				titleTag.Text = itemInfo and itemInfo.Name or itemId;
				itemIcon.Image = itemInfo and itemInfo.Icon or "";
				valueTag.Text = "("..level.."/20)";
				levelBar.Size = UDim2.new(math.clamp(level/20, 0, 1), 0, 1, 0);
			end
		else
			Debugger:Warn("Missing mastery data.");
		end
	end
	
	if masteryFrame.Visible and modData.Profile then
		--== Skill tree
		local skillTreeData = modData.Profile and modData.Profile.SkillTree or nil;
		
		if PageCache.CurrentPage == nil then PageCache.CurrentPage = skillTreeData.ActiveTree; end;
		LoadTree();

		updateSkillPoints();
		
		Interface.RefreshTree();
	end
end

function Interface.disconnect()
	
end

return Interface;
