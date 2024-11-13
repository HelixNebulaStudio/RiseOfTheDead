local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Workbench = {};
local Interface = {} :: any;

local StatNames = {
	FireRate = "Fire Rate";
	ReloadSpeed = "Reload Time";
	MaxAmmoLimit = "Ammo Capacity";
	HeadshotMultiplier = "Headshot Multiplier";
	FocusDuration = "Focus Duration";
	SpinUpTime = "Spin Up Time";
	ProjectileLifeTime = "Projectile LifeTime";
	ProjectileVelocity = "Projectile Velocity";
	ExplosionRadius = "Explosion Radius";
	FocusWalkSpeedReduction = "Focus MoveSpeed Increase"
}

local TweenService = game:GetService("TweenService");
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local player = game.Players.LocalPlayer;

local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
local modItemModsLibrary = require(game.ReplicatedStorage.Library.ItemModsLibrary);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modItemLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modToolTweaks = require(game.ReplicatedStorage.Library.ToolTweaks);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));

local modComponents = require(game.ReplicatedStorage.Library.UI.Components);
local modGraphRenderer = require(game.ReplicatedStorage.Library.UI.GraphRenderer);

local tweakSystemIndex = 2;
local graphYSize = 260;

local intersectPointTemplate = script:WaitForChild("IntersectPoint");
local tweakFrameTemplate = script:WaitForChild("TweakFrame");
local tweakTypeTemplate = script:WaitForChild("tweakType");
local modStatTemplate = script:WaitForChild("modStat");

local tweakFrame2Template = script:WaitForChild("TweakFrame2");

local remoteTweakItem = modRemotesManager:Get("TweakItem");

function Workbench.new(itemId, library, storageItem)
	local traitLib = modWorkbenchLibrary.ItemUpgrades[itemId] and modWorkbenchLibrary.ItemUpgrades[itemId].TraitStats;
	if traitLib == nil then return end;
	
	local itemLib = modItemLibrary:Find(itemId);
	local listMenu = Interface.List.create();
	listMenu.Menu.Name = "tweakItem";
	listMenu.ContentList.ScrollingEnabled = true;
	listMenu:SetEnableScrollBar(false);
	listMenu:SetEnableSearchBar(false);
	
	local statTweakPoints = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.TweakPoints or 0;
	
	if tweakSystemIndex == 1 then
		local newFrame = tweakFrameTemplate:Clone();
		local titleLabel = newFrame:WaitForChild("titleTag");
		titleLabel.Text = "Tweak "..itemLib.Name;
		local buttonsFrame = newFrame:WaitForChild("ButtonFrame");
		local tweakPoints = buttonsFrame:WaitForChild("tweakPoints");

		local tweakPerksButton = buttonsFrame:WaitForChild("TweakPerksButton");
		local tweakPointsButton = buttonsFrame:WaitForChild("TweakPointsButton");

		tweakPoints.Text = "Tweak Points: "..statTweakPoints;

		local tweaksList = buttonsFrame:WaitForChild("TweaksList"):WaitForChild("List");
		local traitTitle = tweaksList:WaitForChild("tweakTitle");

		local function refreshTweaks()
			local tweakId = storageItem.Values.Tweak;
			if tweakId then
				local tweaks = modToolTweaks.LoadTrait(storageItem.ItemId, tweakId);
				traitTitle.Text = "Title:  "..tweaks.Title;

				for _, obj in pairs(tweaksList:GetChildren()) do
					if obj:IsA("GuiObject") and obj.Name ~= "tweakTitle" then
						obj:Destroy();
					end
				end

				for key, value in pairs(tweaks.Stats) do
					local statLib;
					local order = 0;
					for a=1, #traitLib do if traitLib[a].Stat == key then statLib = traitLib[a]; order = a; break; end end;

					if statLib then
						local new = tweakTypeTemplate:Clone();
						new.LayoutOrder = order;
						new.Parent = tweaksList;
						local nameTag = new:WaitForChild("tweakName");
						local statName = StatNames[key] or key;
						nameTag.Text = statName..": "..(statLib.Negative and "-" or "+")..(math.floor(value*100)/100).."%";

						local bar = new:WaitForChild("barFrame"):WaitForChild("Bar");
						bar.Size = UDim2.new((value-statLib.Value.Min)/(statLib.Value.Max-statLib.Value.Min), 0, 1, 0);
					end
				end
			end
		end
		refreshTweaks();

		local actionButtonDebounce = false;
		local function purchase(button, action)
			if actionButtonDebounce then return end;
			actionButtonDebounce = true;
			Interface:PlayButtonClick();
			local prevText = button.Text;
			button.Text = "Tweaking..";
			local serverReply, itemValues = remoteTweakItem:InvokeServer(Interface.Object, action, storageItem.ID);
			if serverReply == modWorkbenchLibrary.PurchaseReplies.Success then
				local tweakId = itemValues.Tweak;
				button.Text = "Tweak Complete!";

				if tweakId then
					storageItem.Values.Tweak = tweakId;
				end
				refreshTweaks();
				Interface:UpdateWindow("WeaponStats", storageItem);
				
			else
				button.Text = modWorkbenchLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply);
				button.Text = button.Text:gsub("$Currency", action == 1 and "Points" or "Perks");

				if serverReply == modWorkbenchLibrary.PurchaseReplies.InsufficientCurrency then
					wait(1);
					Interface:OpenWindow("GoldMenu", "PerksPage");
					return;
				end
			end
			wait(0.3);
			button.Text = prevText;
			statTweakPoints = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.TweakPoints or 0;
			tweakPoints.Text = "Tweak Points: "..statTweakPoints;
			actionButtonDebounce = false;
		end

		tweakPointsButton.MouseButton1Click:Connect(function()
			purchase(tweakPointsButton, 1);
		end)
		tweakPerksButton.MouseButton1Click:Connect(function()
			purchase(tweakPerksButton, 2);
		end)

		if traitLib then
			tweakPerksButton.Visible = true;
			tweakPointsButton.Visible = true;

		else
			tweakPerksButton.Visible = false;
			tweakPointsButton.Visible = false;

		end

		listMenu:Add(newFrame);
	else
		
		local newFrame = tweakFrame2Template:Clone();
		
		local titleLabel = newFrame:WaitForChild("titleTag");
		titleLabel.Text = "Tweak "..itemLib.Name;
		
		local graphFrame = newFrame:WaitForChild("GraphFrame");
		
		local tweakSeed = storageItem.Values.Tweak;
		
		local lastPivotChanged = tick();
		local tweakPivot = storageItem.Values.TweakPivot; --0.5;
		
		local graphZoom = 1;
		local graphData = modToolTweaks.LoadGraph(tweakSeed);
		
		local graphObject = modGraphRenderer.new(graphFrame);
		graphObject.ToolTipEnabled = false;
		graphObject.Resolution = 100;
		graphObject.Range = {Min=-100; Max=100;};

		local tweakLabel = newFrame:WaitForChild("TweakValue");
		local pivotLerpTag = newFrame:WaitForChild("PivotLerp");
		pivotLerpTag:GetPropertyChangedSignal("Value"):Connect(function()
			local txt = string.format("%.3f", math.abs(pivotLerpTag.Value)) .."%";--modFormatNumber.Beautify(math.abs(math.round( *1000)/1000))
			tweakLabel.Text = txt;
		end)
		
		
		function graphObject:OnDataRender(dataPoint: any, point: ImageButton, line: Frame)
			if dataPoint.IsPeak then
				point.Size = UDim2.new(0, 6, 0, 6);
				point.BackgroundColor3 = modToolTweaks.GetTierColor(dataPoint.Value);

			else
				point.Visible = false;
				
			end
		end

		local buttonsFrame = newFrame:WaitForChild("Buttons");
		local tweakButton = newFrame:WaitForChild("TweakButton");
		local startButton = newFrame:WaitForChild("StartButton");
		local calibrateButton = newFrame:WaitForChild("CalibrateButton");
		
		local tweakMod = newFrame:WaitForChild("TweakMod");
		local xBarFrame = newFrame:WaitForChild("XBar");

		local tweakValues = storageItem.Values and storageItem.Values.TweakValues or {};
		
		local function updateStats()
			tweakValues = storageItem.Values and storageItem.Values.TweakValues or {};
			
			local sortedList = {};
			local itemStorage = modData.GetItemStorage(storageItem.ID);
			if itemStorage then
				for modId, storageItemOfMod in pairs(itemStorage.Container) do
					table.insert(sortedList, storageItemOfMod);
				end
			end
			table.sort(sortedList, function(a,b) return a.Index < b.Index; end);
			
			for _, obj in pairs(tweakMod:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj:Destroy();
				end
			end
			
			for a=1, #sortedList do
				local storageItem = sortedList[a];
				local tweakV = tweakValues[a];
				if tweakV == nil then continue end;
				
				local modLib = modItemModsLibrary.Get(storageItem.ItemId);
				if modLib == nil then continue end;
				
				local tcolor = modToolTweaks.GetTierColor(tweakV);
				
				local newIcon = modStatTemplate:Clone();
				newIcon.Image = modLib.Icon;
				newIcon.ImageColor3 = tcolor;
				newIcon.Parent = tweakMod;
				newIcon.LayoutOrder = storageItem.Index;
				
				local descTag = newIcon:WaitForChild("descTag");
				descTag.Text = "+"..string.format("%.2f", math.abs(tweakV)).."%";
				descTag.TextColor3 = tcolor;
			end
			
		end
		updateStats();
		
		listMenu.Menu:GetPropertyChangedSignal("Visible"):Connect(function()
			if listMenu.Menu.Visible then
				updateStats();
			end
		end)
		
		
		local updateGraphTick = tick();
		local xBarTweenToggle = true;
		local function updateGraph()
			updateGraphTick = tick();
			graphObject.Data = {
				LineA = graphData;
			};
			graphFrame.Size = UDim2.new(graphZoom, 0, 0, graphYSize);
			xBarFrame.Size = UDim2.new(graphZoom, 0, 0, graphYSize);
			graphObject.Render();

			
			local showStartTweaking = storageItem.Values == nil or storageItem.Values.TweakValues == nil or tweakPivot == nil;
			
			if storageItem.Values and storageItem.Values.TF1 == nil then
				showStartTweaking = true;
			end
			
			if showStartTweaking then
				startButton.Visible = true;
				tweakButton.Visible = false;
				calibrateButton.Visible = false;
				buttonsFrame.Visible = false;

			else
				startButton.Visible = false;
				tweakButton.Visible = true;
				calibrateButton.Visible = true;
				buttonsFrame.Visible = true;

			end
			
			if showStartTweaking then
				xBarFrame.Visible = false;
				tweakMod.Visible = false;
				return;
			end

			tweakValues = storageItem.Values and storageItem.Values.TweakValues or {};
			
			local rootValue = tweakValues[1];
			if rootValue == nil then return end;
			
			xBarFrame.BarFrame.barValue.Text = string.format("%.3f", math.abs(rootValue)).."%";
			xBarFrame.Visible = true;
			
			tweakMod.Visible = true;
			
			TweenService:Create(pivotLerpTag, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Value=rootValue;
			}):Play();
			TweenService:Create(tweakLabel, TweenInfo.new(0.5), {TextTransparency=0}):Play();
			task.delay(5, function()
				if tick()-updateGraphTick < 5 then return end;
				TweenService:Create(tweakLabel, TweenInfo.new(0.5), {TextTransparency=1}):Play();
			end)
			
			if graphZoom <= 1 then
				graphFrame.AnchorPoint = Vector2.new(0.5, 0);
				if xBarTweenToggle == true then
					if player:IsAncestorOf(xBarFrame) then
						xBarFrame:TweenPosition(UDim2.new(tweakPivot, 0, 0, 25), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.5, true);
					else
						xBarFrame.Position = UDim2.new(tweakPivot, 0, 0, 25);
					end
					
				else
					xBarTweenToggle = true;
					xBarFrame.Position = UDim2.new(tweakPivot, 0, 0, 25);
					
				end
				
			else
				xBarTweenToggle = false;
				graphFrame.AnchorPoint = Vector2.new(tweakPivot, 0);
				pcall(function()
					xBarFrame:TweenPosition(UDim2.new(0.5, 0, 0, 25), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0, true);
				end)
				xBarFrame.Position = UDim2.new(0.5, 0, 0, 25);
				
			end
			
			xBarFrame.IntersectPoint.Position = UDim2.new(0.5, 0, 0.5+(-rootValue/200), 0);
			xBarFrame.IntersectPoint.BackgroundColor3 = modToolTweaks.GetTierColor(rootValue);
			
			local flip = false;
			for a=2, 5 do
				local value = tweakValues[a];
				
				local intPoint = xBarFrame:FindFirstChild("IntersectPoint"..a);
				if intPoint == nil then
					intPoint = intersectPointTemplate:Clone();
					intPoint.Name = "IntersectPoint"..a;
					intPoint.Parent = xBarFrame;
					
					intPoint.MouseEnter:Connect(function()
						intPoint.valueLabel.Visible = true;
					end)

					intPoint.MouseLeave:Connect(function()
						intPoint.valueLabel.Visible = false;
					end)
				end
				
				local spacing = 0.05;
				local flipV = flip and 1 or -1
				local xPos = 0.5 + spacing * math.floor(a/2) * flipV;
				
				if tweakPivot <= 0.05 and flipV < 0 then
					xPos = xPos +1;
					
				elseif tweakPivot > 0.95 and flipV > 0 then
					xPos = xPos -1;
					
				end
				
				if value == nil then
					intPoint.Visible = false;
					
				else
					intPoint.Visible = true;
					intPoint.BackgroundColor3 = modToolTweaks.GetTierColor(value);
					intPoint.valueLabel.Text = string.format("%.3f", math.abs(value)).."%";
					if player:IsAncestorOf(intPoint) then
						intPoint:TweenPosition(UDim2.new(xPos, 0, 0.5+(-value/200), 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.5, true);
					else
						intPoint.Position = UDim2.new(xPos, 0, 0.5+(-value/200), 0);
					end
					
				end
				flip = not flip;
			end
		end
		updateGraph();
		
		local zoomPlus = newFrame:WaitForChild("zoomPlus");
		zoomPlus.MouseButton1Click:Connect(function()
			if graphZoom <= 1 then
				graphZoom = 2;
			elseif graphZoom <= 2 then
				graphZoom = 4;
			elseif graphZoom <= 4 then
				graphZoom = 8;
			elseif graphZoom <= 8 then
				graphZoom = 16;
			end
			updateGraph();
		end)
		
		local zoomSub = newFrame:WaitForChild("zoomSub");
		zoomSub.MouseButton1Click:Connect(function()
			if graphZoom >= 16 then
				graphZoom = 8;
			elseif graphZoom >= 8 then
				graphZoom = 4;
			elseif graphZoom >= 4 then
				graphZoom = 2;
			elseif graphZoom >= 2 then
				graphZoom = 1;
			end
			updateGraph();
		end)

		local lastMoveOnGraphFrame = tick();
		local function moveFrameUpdate()
			lastMoveOnGraphFrame = tick();
			local mousePosition = UserInputService:GetMouseLocation();
			local isOnLeft = mousePosition.X <= xBarFrame.BarFrame.AbsolutePosition.X;

			xBarFrame.BarFrame.barValue.Visible = true;
			zoomPlus.Visible = true;
			zoomSub.Visible = true;
			if isOnLeft then
				zoomPlus.Position = UDim2.new(0, 5, 0, 255);
				zoomSub.Position = UDim2.new(0, 5, 0, 280);

			else
				zoomPlus.Position = UDim2.new(1, -25, 0, 255);
				zoomSub.Position = UDim2.new(1, -25, 0, 280);
			end

			if isOnLeft and xBarFrame.Position.X.Scale >= 0.2 then
				xBarFrame.BarFrame.barValue.AnchorPoint = Vector2.new(1, 1);
				xBarFrame.BarFrame.barValue.TextXAlignment = Enum.TextXAlignment.Right;

			elseif not isOnLeft and xBarFrame.Position.X.Scale <= 0.8 then
				xBarFrame.BarFrame.barValue.AnchorPoint = Vector2.new(0, 1);
				xBarFrame.BarFrame.barValue.TextXAlignment = Enum.TextXAlignment.Left;

			else
				if isOnLeft then
					xBarFrame.BarFrame.barValue.AnchorPoint = Vector2.new(0, 1);
					xBarFrame.BarFrame.barValue.TextXAlignment = Enum.TextXAlignment.Left;
				else
					xBarFrame.BarFrame.barValue.AnchorPoint = Vector2.new(1, 1);
					xBarFrame.BarFrame.barValue.TextXAlignment = Enum.TextXAlignment.Right;
				end
			end
		end
		graphFrame.MouseMoved:Connect(function()
			moveFrameUpdate();
		end)
		graphFrame.MouseLeave:Connect(function()
			moveFrameUpdate();
			task.delay(0.2, function()
				if tick()-lastMoveOnGraphFrame < 0.2 then
					return;
				end
				zoomPlus.Visible = false;
				zoomSub.Visible = false;
				xBarFrame.BarFrame.barValue.Visible = false;
			end)
		end)
		
		
		graphFrame.InputChanged:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				graphZoom = math.clamp(graphZoom + input.Position.Z/2, 1, 16);
				updateGraph();
			end
		end)
		
		graphFrame.InputBegan:Connect(function(input: InputObject)
			if not RunService:IsStudio() then return end;
			if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Eight then
				Debugger:Warn("Debug 8");
				remoteTweakItem:InvokeServer(Interface.Object, 8, storageItem.ID);
			end
		end)
		
		function listMenu:OnMenuToggle()
			if not newFrame.Visible then return end
			
			zoomPlus.Visible = true; 
			zoomSub.Visible = true;
			if UserInputService.MouseEnabled then
				task.delay(1, function()
					zoomPlus.Visible = false;
					zoomSub.Visible = false;
				end)
			end
		end
		
		
		local lockinSlideAmount = nil;
		local sliderButtons = {};
		
		local branchColor = modToolTweaks.GetTierColor(10);
		local lastTouchSlider = tick();
		local function refreshSlider()
			local amt = lockinSlideAmount or 0;
			buttonsFrame.subIndicator.Text = amt;
			
			local activeColor = branchColor;
			if math.abs(amt) == 4 then
				activeColor = modToolTweaks.GetTierColor(20);
			elseif math.abs(amt) == 5 then
				activeColor = modToolTweaks.GetTierColor(40);
			elseif math.abs(amt) == 6 then
				activeColor = modToolTweaks.GetTierColor(60);
			elseif math.abs(amt) == 7 then
				activeColor = modToolTweaks.GetTierColor(80);
			end
			
			for a=1, #sliderButtons do
				local butInfo = sliderButtons[a];
				
				if math.abs(amt) >= 4 then
					butInfo.Button.ImageColor3 = math.sign(butInfo.Index) == math.sign(amt) and activeColor or Color3.fromRGB(255,255,255);
				
				else
					if amt < 0 and butInfo.Index < 0 and butInfo.Index >= amt then
						butInfo.Button.ImageColor3 = activeColor;
					elseif amt > 0 and butInfo.Index > 0 and butInfo.Index <= amt then
						butInfo.Button.ImageColor3 = activeColor;
					else
						butInfo.Button.ImageColor3 = Color3.fromRGB(255,255,255);
					end
				end
			end
		end
		
		for _, obj in pairs(buttonsFrame:GetChildren()) do
			if obj:IsA("ImageButton") then
				local isLeft = obj.Name:sub(1,4) == "Left";
				
				local order = obj.LayoutOrder;
				table.insert(sliderButtons, {Index=order; Button=obj});
			end
		end
		
		local tweakPoints = buttonsFrame:WaitForChild("tweakPoints");
		tweakPoints.Text = statTweakPoints;
		
		local tweakText = tweakButton.Text;
		local tweakDebounce = false;
		tweakButton.MouseButton1Click:Connect(function()
			if tweakDebounce then return end;
			tweakDebounce = true;
			
			--tweakPivot = math.random(1, 9999)/10000;
			--updateGraph();
			
			Interface:PlayButtonClick();
			if lockinSlideAmount == nil then
				tweakButton.Text = "Tweak first";
				tweakButton.BackgroundColor3 = Color3.fromRGB(90, 49, 28);
				task.wait(RunService:IsStudio() and 0.4 or 2);
				tweakButton.Text = tweakText;
				tweakButton.BackgroundColor3 = Color3.fromRGB(185, 100, 57);
				tweakDebounce = false;
				return;
			end

			local serverReply, itemValues = remoteTweakItem:InvokeServer(Interface.Object, 4, storageItem.ID, lockinSlideAmount);
			if serverReply == modWorkbenchLibrary.PurchaseReplies.Success then
				
				if itemValues.Tweak then
					storageItem.Values.Tweak = itemValues.Tweak;
					tweakSeed = itemValues.Tweak;
					graphData = modToolTweaks.LoadGraph(tweakSeed);
				end

				if itemValues.TweakPivot then
					storageItem.Values.TweakPivot = itemValues.TweakPivot;
					tweakPivot = itemValues.TweakPivot;
					
					storageItem.Values.TweakValues = itemValues.TweakValues;
					tweakValues = storageItem.Values.TweakValues;
				end

				updateGraph();
				updateStats();

				lockinSlideAmount = nil;
				refreshSlider();
			end
			tweakDebounce = false;
		end)
		
		
		local calibrateDebounce = false;
		local calibrateText = calibrateButton.Text;
		calibrateButton.MouseButton1Click:Connect(function()
			if calibrateDebounce then return end;
			calibrateDebounce = true;

			Interface:PlayButtonClick();
			calibrateButton.Text = "Calibrating..";

			local serverReply, newCalibration, newTweakPoints = remoteTweakItem:InvokeServer(Interface.Object, 5, storageItem.ID);
			if serverReply == modWorkbenchLibrary.PurchaseReplies.Success then
				lockinSlideAmount = newCalibration;
				refreshSlider();
				
				calibrateButton.Text = calibrateText;
				if modData.GameSave and modData.GameSave.Stats then
					modData.GameSave.Stats.TweakPoints = newTweakPoints;
				end
			else
				
				calibrateButton.Text = modWorkbenchLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply);
				calibrateButton.Text = string.gsub(calibrateButton.Text, "$Currency", "Tweak Point");
			end

			statTweakPoints = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.TweakPoints or 0;
			tweakPoints.Text = statTweakPoints;

			updateStats();
			
			calibrateDebounce = false;
		end)
		
		
		startButton.MouseButton1Click:Connect(function()
			if tweakDebounce then return end;
			tweakDebounce = true;
			Interface:PlayButtonClick();

			local serverReply, itemValues = remoteTweakItem:InvokeServer(Interface.Object, 3, storageItem.ID);
			if serverReply == modWorkbenchLibrary.PurchaseReplies.Success then
				
				if itemValues.Tweak then
					storageItem.Values.Tweak = itemValues.Tweak;
					tweakSeed = itemValues.Tweak;
					graphData = modToolTweaks.LoadGraph(tweakSeed);
				end
				
				if itemValues.TweakPivot then
					storageItem.Values.TweakPivot = itemValues.TweakPivot;
					tweakPivot = itemValues.TweakPivot;
				end
				
				if itemValues.TweakValues then
					storageItem.Values.TweakValues = itemValues.TweakValues;
					tweakValues = storageItem.Values.TweakValues;
				end
				
				if itemValues.TF1 then
					storageItem.Values.TF1 = itemValues.TF1;
				end
				
				updateGraph();
				updateStats();
			end
			
			tweakDebounce = false;
		end)
		
		listMenu:Add(newFrame);
	end
	
	return listMenu;
end

function Workbench.init(interface)
	Interface = interface;
	return Workbench;
end

return Workbench;