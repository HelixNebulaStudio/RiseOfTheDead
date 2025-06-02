local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modStorageInterface = shared.require(game.ReplicatedStorage.Library.UI.StorageInterface);

local interfacePackage = {
    Type = "Character";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local remoteRenameItem = modRemotesManager:Get("RenameItem");

    local mainFrame = script:WaitForChild("RenamePrompt"):Clone();
    mainFrame.Parent = interface.ScreenGui;

    local inputBox = mainFrame:WaitForChild("Inputframe"):WaitForChild("TextBox");
    local _label = mainFrame:WaitForChild("label");

    local renameButton = mainFrame:WaitForChild("renameButton");
    local testButton = mainFrame:WaitForChild("testButton");
    local slotFrame = {mainFrame:WaitForChild("Slot")};


    local activeStorageItem = nil;
    local itemSlotInterface = modStorageInterface.new("renameTempStorage", mainFrame, slotFrame);
    itemSlotInterface.ViewOnly = true;
    itemSlotInterface.OnItemButton1Click = nil;

    local storageRenameSlot = {
        Id="renameTempStorage";
        Size=1;
        Container={};
        PremiumStorage = 100;
    }

    
	local window: InterfaceWindow = interface:NewWindow("RenameItem", mainFrame);
	window:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0));
	window.OnToggle:Connect(function(visible, storageItem)
		if visible and storageItem then
            activeStorageItem = storageItem:Clone();
            activeStorageItem.ID = storageItem.ID;
            activeStorageItem.Index = 1;

			window:Update();
		end
	end)
	window:AddCloseButton(mainFrame);


    renameButton.MouseButton1Click:Connect(function()
        if activeStorageItem == nil then return end;
        interface:PlayButtonClick();
        
        local itemLib = modItemsLibrary:Find(activeStorageItem.ItemId);
        local clearName = #inputBox.Text <= 0;
        
        local promptWindow;
        local filteredName = not clearName and remoteRenameItem:InvokeServer("test", activeStorageItem.ID, inputBox.Text) or "";
        if clearName then
            promptWindow = modClientGuis.promptQuestion("Clear name for "..itemLib.Name, "Are you sure you want to clear the name of the "..itemLib.Name.."?");
        else
            promptWindow = modClientGuis.promptQuestion("Rename "..itemLib.Name, "Are you sure you want to rename the "..itemLib.Name.." to ("..filteredName..") for 50 Gold?");
        end
        if type(filteredName) == "string" then
            local YesClickedSignal, NoClickedSignal;
            
            local debounce = false;
            YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
                if debounce then return end;
                debounce = true;
                interface:PlayButtonClick();
                local r = remoteRenameItem:InvokeServer("set", activeStorageItem.ID, filteredName);
                if r == 1 then
                    promptWindow.Frame.Yes.buttonText.Text = "Item Renamed!";
                    
                elseif r == 2 then
                    promptWindow.Frame.Yes.buttonText.Text = "Not enough gold";
                    wait(1);
                    promptWindow:Close();
                    interface:ToggleWindow("GoldMenu", true, "GoldPage");
                    return;
                    
                elseif r == 3 then
                    promptWindow.Frame.Yes.buttonText.Text = "Purchase failed";
                    
                end
                wait(1.6);
                debounce = false;
                promptWindow:Close();
                YesClickedSignal:Disconnect();
                NoClickedSignal:Disconnect();
            end);
            NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
                if debounce then return end;
                interface:PlayButtonClick();
                promptWindow:Close();
                interface:ToggleWindow("RenameItem", true, activeStorageItem);
                YesClickedSignal:Disconnect();
                NoClickedSignal:Disconnect();
            end);
            
        end
    end)

    testButton.MouseButton1Click:Connect(function()
        if activeStorageItem == nil then return end;
        interface:PlayButtonClick();
        
        if #inputBox.Text > 0 then
            local filteredName = remoteRenameItem:InvokeServer("test", activeStorageItem.ID, inputBox.Text);
            if type(filteredName) == "string" then
                inputBox.Text = filteredName;
                
            end
        end
    end)

    inputBox:GetPropertyChangedSignal("Text"):Connect(function()
        inputBox.Text = inputBox.Text:sub(1, 30);
    end)

    window.OnUpdate:Connect(function()
        local customName = activeStorageItem:GetCustomName();
        inputBox.Text = customName or "";

        local itemLib = modItemsLibrary:Find(activeStorageItem.ItemId);
        
        if customName == nil then
            activeStorageItem.CustomName = inputBox.Text;
            renameButton.buttonText.Text = "Rename";
        else
            activeStorageItem.CustomName = nil;
            renameButton.buttonText.Text = "Clear Custom Name";
        end
        
        storageRenameSlot.Container = {};
        storageRenameSlot.Container[activeStorageItem.ID] = activeStorageItem;

        modData.SetStorage(storageRenameSlot);
        itemSlotInterface:Update(storageRenameSlot);

        modStorageInterface.SetQuickTarget();
    end)
end

return interfacePackage;

