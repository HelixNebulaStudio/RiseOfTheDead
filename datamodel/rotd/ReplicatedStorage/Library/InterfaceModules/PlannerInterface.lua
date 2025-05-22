local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

local timerRadialConfig = '{"version":1,"size":128,"count":128,"columns":8,"rows":8,"images":["rbxassetid://10606346824","rbxassetid://10606347195"]}';
--== Variables;
local Interface = {};
local PlannerLibrary = {
	["metalbarricade"]={Order=1; MaxCharges=3};
	["barbedwooden"]={Order=2; MaxCharges=4};
	["ticksnaretrap"]={Order=3; MaxCharges=5};
	["scarecrow"]={Order=4; MaxCharges=2};
	["gastankied"]={Order=5; MaxCharges=2};
	["barbedmetal"]={Order=6; MaxCharges=1};
};

Interface.PlannerLibrary = PlannerLibrary;

local RunService = game:GetService("RunService");
if RunService:IsServer() then return Interface end;

local localPlayer = game.Players.LocalPlayer;
local modData = shared.require(localPlayer:WaitForChild("DataModule"));
local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local modRadialImage = shared.require(game.ReplicatedStorage.Library.UI.RadialImage);
local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);

local remoteEngineersPlanner = modRemotesManager:Get("EngineersPlanner");

local windowFrameTemplate = script:WaitForChild("PlannerFrame");
local structureButton = script:WaitForChild("structureButton");

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;
	
	local scrollFrame = windowFrame:WaitForChild("ScrollingFrame");
	local infoFrame = windowFrame:WaitForChild("InfoFrame");
	
	windowFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("EngineerPlannerWindow");
	end)
	
	local window = Interface.NewWindow("EngineerPlannerWindow", windowFrame);
	
	local activeToolConfig;
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1, 0));
	window.OnWindowToggle:Connect(function(visible, toolConfig)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			Interface:ToggleInteraction(false);
			activeToolConfig = toolConfig;
			Interface.Update();
			
			task.spawn(function()
				while windowFrame.Visible do
					Interface.RefreshLoop()
					task.wait();
				end
			end)
			
		else
			task.delay(0.2, function()
				Interface:ToggleInteraction(true);
			end)
		end
	end)

	local selectedItemId = "metalbarricade";
	local itemButtons = {};
	
	local unlockButton = infoFrame:WaitForChild("unlockButton");
	unlockButton.MouseButton1Click:Connect(function()
		local itemLib = modItemsLibrary:Find(selectedItemId);

		local promptWindow = Interface:PromptQuestion("Unlock "..itemLib.Name, "A "..itemLib.Name.." Blueprint will be consumed.");
		local YesClickedSignal, NoClickedSignal;
		
		local debounce;
		YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
			if debounce then return end;
			debounce = true;
			Interface:PlayButtonClick();
			local r = remoteEngineersPlanner:InvokeServer(activeToolConfig.StorageItem, "unlock", selectedItemId);
			
			if r.Success then
				activeToolConfig.StorageItem.Values = r.Values;
			end
			
			wait(1.6);
			debounce = false;
			promptWindow:Close();
			Interface:OpenWindow("EngineerPlannerWindow", activeToolConfig);
			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
		NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
			if debounce then return end;
			Interface:PlayButtonClick();
			promptWindow:Close();
			Interface:OpenWindow("EngineerPlannerWindow", activeToolConfig);
			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
	end)
	
	
	function Interface.RefreshLoop()
		local liveTime = workspace:GetServerTimeNow();
		
		local storageItem = activeToolConfig.StorageItem;
		local itemValues = storageItem and storageItem.Values;
		local chargeValues = itemValues.Charges or {};
		
		for itemId, buttonInfo in pairs(itemButtons) do
			
			local structureButton = buttonInfo.StructureButton;

			local chargesLabel = structureButton:WaitForChild("ChargesLabel");
			
			local radialBarLabel = structureButton:WaitForChild("radialBar");
			local radialBar = modRadialImage.new(timerRadialConfig, radialBarLabel);

			local plannerInfo = PlannerLibrary[itemId];
			
			local lastChargeTime = chargeValues[itemId];
			if lastChargeTime == nil then
				chargesLabel.Text = "0/"..plannerInfo.MaxCharges;
				continue;
			end
			
			local chargeTime = 60;
			local chargeDif = (liveTime-lastChargeTime);
			local chargeAmt = math.floor(chargeDif/chargeTime);
			local chargeRemainder = math.fmod(chargeDif, chargeTime);
			
			local radialRatio = chargeRemainder/chargeTime;
			
			chargesLabel.Text = math.clamp(chargeAmt, 0, plannerInfo.MaxCharges) .."/"..plannerInfo.MaxCharges;
			
			radialBar:UpdateLabel(chargeAmt == plannerInfo.MaxCharges and 1 or radialRatio);
		end
	end
	
	function Interface.Select(selectMode)
		selectMode = selectMode or 2;
		local itemLib = modItemsLibrary:Find(selectedItemId);
		
		infoFrame.Title.Text = itemLib.Name;
		infoFrame.Desc.Text = itemLib.Description;
		infoFrame.ItemIcon.Image = itemLib.Icon;
		
		if activeToolConfig == nil then return end;
		local storageItem = activeToolConfig.StorageItem;
		local itemValues = storageItem and storageItem.Values;

		if itemValues == nil then Debugger:Warn("Missing itemvalues") return end;
		local unlocked = itemValues.Unlocked or {};
		
		local isUnlocked = unlocked[selectedItemId] == true;
		
		if selectMode == 1 and isUnlocked then
			activeToolConfig:Select(selectedItemId);
			window:Close();
			return;
		end
		
		unlockButton.Text = "Unlock Requires Blueprint";
		unlockButton.Visible = not isUnlocked;
	end
	
	function Interface.Update()
		local storageItem = activeToolConfig.StorageItem;
		local itemValues = storageItem and storageItem.Values;
		
		Debugger:Warn("Interface.Update()", itemValues);
		if itemValues == nil then Debugger:Warn("Missing itemvalues") return end;
		
		for itemId, itemInfo in pairs(PlannerLibrary) do
			local itemButtonObj;
			if itemButtons[itemId] == nil then
				local itemLib = modItemsLibrary:Find(itemId);
				local button = structureButton:Clone();
				button:WaitForChild("ItemName").Text = itemLib.Name;
				
				itemButtonObj = modItemInterface.newItemButton(itemId);
				itemButtonObj.HideTypeIcon = true;
				itemButtonObj.ImageButton.Active = false;
				itemButtonObj.ImageButton.Parent = button:WaitForChild("IconFrame");
				itemButtonObj.StructureButton = button;
				
				button.Parent = scrollFrame;
				button.LayoutOrder = itemInfo.Order or 999;
				
				local function selectClick(selectMode)
					selectedItemId = itemId;
					Interface.Select(selectMode);
				end
				
				button.MouseButton1Click:Connect(function()
					selectClick(1);
				end);
				itemButtonObj.ImageButton.MouseButton1Click:Connect(function()
					selectClick(1);
				end);
				
				button.MouseButton2Click:Connect(function()
					selectClick(2);
				end)
				itemButtonObj.ImageButton.MouseButton2Click:Connect(function()
					selectClick(2);
				end)
				
				itemButtons[itemId] = itemButtonObj;
			end
			itemButtonObj = itemButtons[itemId];
			
			local structureButton = itemButtonObj.StructureButton;
			local nameLabel = structureButton:WaitForChild("ItemName");
			local radialLabel = structureButton:WaitForChild("radialBar")
			
			local unlocked = itemValues.Unlocked or {};
			local isUnlocked = unlocked[itemId] == true
			if isUnlocked then
				itemButtonObj.DimOut = nil;
				nameLabel.TextColor3 = Color3.fromRGB(255,255,255);
				radialLabel.Visible = true;
				nameLabel.Size = UDim2.new(0.8, 0, 0, 20);
				
			else
				itemButtonObj.DimOut = true;
				nameLabel.TextColor3 = Color3.fromRGB(150,150,150);
				radialLabel.Visible = false;
				nameLabel.Size = UDim2.new(1, -10, 0, 20);
				
			end
			
			itemButtonObj:Update();
		end

		Interface.Select();
	end
	--Interface.Garbage:Tag();
	
	return Interface;
end;

return Interface;