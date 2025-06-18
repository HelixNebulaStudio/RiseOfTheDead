local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local modRadialImage = shared.require(game.ReplicatedStorage.Library.UI.RadialImage);
local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);


local TIMER_RADIAL_CONFIG = '{"version":1,"size":128,"count":128,"columns":8,"rows":8,"images":["rbxassetid://10606346824","rbxassetid://10606347195"]}';

local PlannerLibrary = {
	["metalbarricade"]={Order=1; MaxCharges=3};
	["barbedwooden"]={Order=2; MaxCharges=4};
	["ticksnaretrap"]={Order=3; MaxCharges=5};
	["scarecrow"]={Order=4; MaxCharges=2};
	["gastankied"]={Order=5; MaxCharges=2};
	["barbedmetal"]={Order=6; MaxCharges=1};
};

local interfacePackage = {
    Type = "Character";
    PlannerLibrary = PlannerLibrary;
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local remoteEngineersPlanner = modRemotesManager:Get("EngineersPlanner");
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local windowFrame = script:WaitForChild("PlannerFrame"):Clone();
	windowFrame.Parent = interface.ScreenGui;
	
	local scrollFrame = windowFrame:WaitForChild("ScrollingFrame");
	local infoFrame = windowFrame:WaitForChild("InfoFrame");
    local structureButton = script:WaitForChild("structureButton");
        
	local window: InterfaceWindow = interface:NewWindow("EngineerPlannerWindow", windowFrame);
    window.DisableInteractables = true;
    window.CloseWithInteract = true;
	window:SetClosePosition(UDim2.new(0.5, 0, -1, 0), UDim2.new(0.5, 0, 0.5, 0));

    local binds = window.Binds;

	local activeToolHandler: ToolHandlerInstance;
	local selectedItemId = "metalbarricade";
	local itemButtons = {};

    --MARK: OnToggle
	window.OnToggle:Connect(function(visible, toolHandler)
        if toolHandler then
			activeToolHandler = toolHandler;
        end
		if visible then
			interface:HideAll{[window.Name]=true;};
            
            window:Update();
			
			task.spawn(function()
				while windowFrame.Visible do
					binds.RefreshLoop()
					task.wait();
				end
			end)
			
		else
		end
	end)


	windowFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
        window:Close();
	end)
	

    local unlockButton = infoFrame:WaitForChild("unlockButton");
	unlockButton.MouseButton1Click:Connect(function()
		local itemLib = modItemsLibrary:Find(selectedItemId);

        modClientGuis.promptDialogBox({
            Title=`Unlock {itemLib.Name}?`;
            Desc=`Your {itemLib.Name} blueprint will be consumed.`;
            Buttons={
                {
                    Text="Unlock";
                    Style="Confirm";
                    OnPrimaryClick=function(dialogWindow)
                        local statusLabel = dialogWindow.Binds.StatusLabel;
                        statusLabel.Text = "Unlocking building plan<...>";

                        local r = remoteEngineersPlanner:InvokeServer(
                            activeToolHandler.StorageItem, 
                            "unlock", 
                            selectedItemId
                        );
                        
                        if r.Success then
                            activeToolHandler.StorageItem.Values = r.Values;
                        else
                            statusLabel.Text = r.FailMsg or `Please try again!`;
                            task.wait(2);
                        end
                        
                        window:Update();
                    end;
                };
                {
                    Text="Cancel";
                    Style="Cancel";
                };
            }
        });

	end)
	
	
	function binds.RefreshLoop()
		local liveTime = workspace:GetServerTimeNow();
		
		local storageItem = activeToolHandler.StorageItem;
		local itemValues = storageItem and storageItem.Values;
		local chargeValues = itemValues.Charges or {};
		
		for itemId, buttonInfo in pairs(itemButtons) do
			
			local structureButton = buttonInfo.StructureButton;

			local chargesLabel = structureButton:WaitForChild("ChargesLabel");
			
			local radialBarLabel = structureButton:WaitForChild("radialBar");
			local radialBar = modRadialImage.new(TIMER_RADIAL_CONFIG, radialBarLabel);

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
	
	function binds.Select(selectMode)
		selectMode = selectMode or 2;
		local itemLib = modItemsLibrary:Find(selectedItemId);
		
		infoFrame.Title.Text = itemLib.Name;
		infoFrame.Desc.Text = itemLib.Description;
		infoFrame.ItemIcon.Image = itemLib.Icon;
		
		if activeToolHandler == nil then return end;
		local storageItem = activeToolHandler.StorageItem;
		local itemValues = storageItem and storageItem.Values;

		if itemValues == nil then
            Debugger:Warn("Missing itemvalues");
            return; 
        end;
		local unlocked = itemValues.Unlocked or {};
		
		local isUnlocked = unlocked[selectedItemId] == true;
		
		if selectMode == 1 and isUnlocked then
            activeToolHandler.EquipmentClass.Properties.BuildSelectId = selectedItemId;
			window:Close();
			return;
		end
		
		unlockButton.Text = "Unlock Requires Blueprint";
		unlockButton.Visible = not isUnlocked;
	end
	
    --MARK: OnUpdate
	window.OnUpdate:Connect(function(toolHandler)
		local storageItem = activeToolHandler.StorageItem;
		local itemValues = storageItem and storageItem.Values;
		
		Debugger:Warn("Interface.Update()", itemValues);
		if itemValues == nil then
            Debugger:Warn("Missing itemvalues"); return end;
		
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
					binds.Select(selectMode);
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

		binds.Select();
	end)

end

return interfacePackage;

