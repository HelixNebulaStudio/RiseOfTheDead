local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local localPlayer = game.Players.LocalPlayer;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

local modStorageInterface = shared.require(game.ReplicatedStorage.Library.UI.StorageInterface);


local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local remoteAutoTurret = modRemotesManager:Get("AutoTurret");

    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local patItemLib = modItemsLibrary:Find("portableautoturret");
	local TurretConfigs = patItemLib.GetTurretConfigs();
	
	local storageId = "portableautoturret";
    local debounce = tick();
	
	local windowFrame = script:WaitForChild("AutoTurretFrame"):Clone();
	windowFrame.Parent = interface.ScreenGui;
	
	local configOpTemplate = script:WaitForChild("ConfigOption");
	local resetOpTemplate = script:WaitForChild("ResetOption");
	local configTitleTemplate = script:WaitForChild("ConfigTitle");

	local configScrollFrame = windowFrame:WaitForChild("ScrollingFrame");
	
	local slotLabel1Template = windowFrame:WaitForChild("ControlFrame"):WaitForChild("slotLabel1");
	local slotLabel2Template = windowFrame:WaitForChild("ControlFrame"):WaitForChild("slotLabel2");
	
	local activateButton = windowFrame:WaitForChild("ControlFrame"):WaitForChild("activateButton");
	local uiSizeConstraint = windowFrame:WaitForChild("UISizeConstraint");

	local window: InterfaceWindow = interface:NewWindow("AutoTurretWindow", windowFrame);
    window.CloseWithInteract = true;

    local binds = window.Binds;

	windowFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		window:Close();
	end)
	
	local activeStorageInterface, slotLabel, slotLabel2, storageItem;
	

	local dropdownOptions;
	local function clearOptions()
		if dropdownOptions then
			dropdownOptions:Destroy();
			dropdownOptions = nil;
		end
	end

	if modConfigurations.CompactInterface then
		windowFrame.AnchorPoint = Vector2.new(1, 0);
		windowFrame.Size = UDim2.new(0.5, 0, 1, 0);
		uiSizeConstraint.Parent = script;
		
		window:SetClosePosition(UDim2.new(1, 0, -1, 0), UDim2.new(1, 0, 0, 0));
	else
		uiSizeConstraint.Parent = windowFrame;
		window:SetClosePosition(UDim2.new(0.5, 0, -1, 0), UDim2.new(0.5, 0, 0.5, 0));
		
	end

    --MARK: OnToggle
	window.OnToggle:Connect(function(visible, useStorageItem)
		if visible then
            interface:ToggleWindow("Inventory", true);
			storageItem = modData.GetItemById(useStorageItem.ID);
            window:Update();
		end
		clearOptions();
	end)
	
    --MARK: OnUpdate
	window.OnUpdate:Connect(function()
		if activeStorageInterface then activeStorageInterface:Destroy() end;
		
		if slotLabel then slotLabel:Destroy() end;
		slotLabel = slotLabel1Template:Clone();
		slotLabel.Visible = true;
		slotLabel.Parent = windowFrame.ControlFrame;

		if slotLabel2 then slotLabel2:Destroy() end;
		slotLabel2 = slotLabel2Template:Clone();
		slotLabel2.Visible = true;
		slotLabel2.Parent = windowFrame.ControlFrame;
		
		activeStorageInterface = modStorageInterface.new(storageId, windowFrame, {slotLabel; slotLabel2});
		activeStorageInterface:Update();
		
        binds.Refresh();
	end)


	local function refreshButton(b)
		local text = b.Text;
		if text == "Enabled" then
			b.BackgroundColor3 = Color3.fromRGB(50, 100, 50);
		elseif text == "Disabled" then
			b.BackgroundColor3 = Color3.fromRGB(100, 50, 50);
		elseif text == "Random" then
			b.BackgroundColor3 = Color3.fromRGB(50, 50, 100);
		else
			b.BackgroundColor3 = Color3.fromRGB(100, 100, 100);
		end
	end
	
	function binds.Refresh()
		local isOnline = storageItem.Values.Online == true;
		activateButton.Text = isOnline and "Online" or "Offline";
		activateButton.BackgroundColor3 = isOnline and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(100, 50, 50);
		
		local configValues = storageItem.Values.Config or {};
		
		for _, obj in pairs(configScrollFrame:GetChildren()) do
			if obj:IsA("GuiObject") then
				obj:Destroy();
			end
		end
		
		for configKey, configInfo in pairs(TurretConfigs) do
			local newOptionFrame = configOpTemplate:Clone();
			newOptionFrame.LayoutOrder = configInfo.Order;
			
			local titleLabel = newOptionFrame:WaitForChild("Title");
			local descLabel = newOptionFrame:WaitForChild("Desc");
			local button = newOptionFrame:WaitForChild("Button");
			
			titleLabel.Text = configInfo.Title;
			descLabel.Text = configInfo.Desc;
			
			local configIndex = configValues[configKey] or 1;
			local optionText = configInfo.Options[configIndex];
			
			button.Text = optionText;
			
			button.MouseButton1Click:Connect(function()
				interface:PlayButtonClick();
				clearOptions();
				
				local optionsList = {};
				
				for a=1, #configInfo.Options do
					local opText = configInfo.Options[a];
					
					table.insert(optionsList, {
						Id=a; 
						Text=opText; 
						LayoutOrder=a;
						OnNewButton=function(optionInfo, newButton)
							configValues = storageItem.Values.Config or {};
							configIndex = configValues[configKey] or 1;
							
							newButton.Size = UDim2.new(1, 0, 0, 30);
							newButton:WaitForChild("UIStroke").Enabled = configIndex == a;
							
							refreshButton(newButton);
						end;
					});
				end

				dropdownOptions = interface.newDropdownList(optionsList, button);
				
				dropdownOptions.ScrollFrame.Size = UDim2.new(0, button.AbsoluteSize.X+2, 0, 35*math.min(5, #optionsList));
				dropdownOptions.ScrollFrame.ScrollBarThickness = 5;
				dropdownOptions.ScrollFrame.BackgroundTransparency = 0;
				dropdownOptions.ScrollFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50);
				dropdownOptions.ScrollFrame.Parent = windowFrame;
				
				local uiPadding: UIPadding = dropdownOptions.ScrollFrame.UIPadding;
				uiPadding.PaddingBottom = UDim.new(0, 1);
				uiPadding.PaddingLeft = UDim.new(0, 1);
				uiPadding.PaddingRight = UDim.new(0, 1);
				uiPadding.PaddingTop = UDim.new(0, 1);
				
				dropdownOptions:SetPosition(button.AbsolutePosition-Vector2.new(2,2));
				dropdownOptions:OnOptionClick(function(opIndex)
					interface:PlayButtonClick();

					local returnPacket = remoteAutoTurret:InvokeServer("config", {
						ConfigKey=configKey;
						OptionIndex=opIndex;
					});
					
					if returnPacket and returnPacket.Success then
						configValues[configKey] = opIndex;
						
						local opText = configInfo.Options[opIndex];
						button.Text = opText;
					end
					
					clearOptions();
				end)
				
			end)
			button:GetPropertyChangedSignal("Text"):Connect(function()
				refreshButton(button);
			end);
			refreshButton(button);
			
			local customPrompt = configInfo.CustomPrompt;
			if customPrompt == "HitList" then
				local newHitList = script:WaitForChild("HitList"):Clone();
				newOptionFrame:WaitForChild("UIPadding").PaddingBottom = UDim.new(0, 15);
				newHitList.Parent = newOptionFrame;
				
				local configHitlistBitString = configValues.Hitlist or configInfo.DefaultBitString;
				local configHitlistBitFlags = configInfo.HitListBitFlag;
				
				local hitlistLabel = script:WaitForChild("HitlistLabel");
				
				for tag, order in pairs(configHitlistBitFlags.Flags) do
					local newLabel = hitlistLabel:Clone();
					newLabel.Text = tag;
					newLabel.LayoutOrder = order;
					newLabel.Parent = newHitList;
					local labelButton: TextButton = newLabel:WaitForChild("Button");
					
					local flagVal = configHitlistBitFlags:Test(tag, configHitlistBitString);
					labelButton.BackgroundColor3 = flagVal and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(100, 50, 50);
					
					labelButton.MouseButton1Click:Connect(function()
						if tick()-debounce <= 1 then return end;
						debounce = tick();
						
						local returnPacket = remoteAutoTurret:InvokeServer("config:UseHitlist", {
							HitlistTag = tag;
							FlagValue = not flagVal;
						});
						if returnPacket and returnPacket.Success then
							flagVal = returnPacket.FlagValue;
							configHitlistBitString = configHitlistBitFlags:Set(configHitlistBitString, tag, flagVal);
						end
						
						flagVal = configHitlistBitFlags:Test(tag, configHitlistBitString);
						labelButton.BackgroundColor3 = flagVal and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(100, 50, 50);
						debounce = tick()-1;
					end)
				end
			end
			
			newOptionFrame.Parent = configScrollFrame;
		end
		

		local newReset = resetOpTemplate:Clone();
		local newResetButton = newReset:WaitForChild("resetButton");
		newResetButton.MouseButton1Click:Connect(function()
			if tick()-debounce <= 1 then return end;
			debounce = tick();
			local returnPacket = remoteAutoTurret:InvokeServer("resetconfig");

			if returnPacket and returnPacket.Success then
				storageItem = modData.GetItemById(storageItem.ID);
				storageItem.Values.Online = returnPacket.Values.Online;
				storageItem.Values.Config = returnPacket.Values.Config;
				binds.Refresh();
			end

			debounce = tick()-1;
		end)
		newReset.Parent = configScrollFrame;
		
		local newConfigTitle = configTitleTemplate:Clone();
		newConfigTitle.Parent = configScrollFrame;
	end
    
	activateButton.MouseButton1Click:Connect(function()
		if tick()-debounce <= 1 then return end;
		debounce = tick();
		local returnPacket = remoteAutoTurret:InvokeServer("toggleonline");
		
		if returnPacket and returnPacket.Success then
			storageItem = modData.GetItemById(storageItem.ID);
			storageItem.Values.Online = returnPacket.Values.Online;
			storageItem.Values.Config = returnPacket.Values.Config;
			binds.Refresh();
		end
		
		debounce = tick()-1;
	end)
	
	function remoteAutoTurret.OnClientInvoke(action, packet)
		if action == "refresh" then
			if storageItem == nil then return end;
			storageItem.Values.Online = packet.Online;
			storageItem.Values.Config = packet.Config;
			binds.Refresh();

		end
	end
	
	configScrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		clearOptions();
	end)

end

return interfacePackage;

