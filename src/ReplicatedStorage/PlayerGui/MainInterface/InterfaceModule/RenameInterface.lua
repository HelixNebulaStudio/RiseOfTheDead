local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local modItemInterface = require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modStorageInterface = require(game.ReplicatedStorage.Library.UI.StorageInterface);

local remotes = game.ReplicatedStorage.Remotes;
local remoteRenameItem = modRemotesManager:Get("RenameItem");
	
local mainFrame = script.Parent.Parent:WaitForChild("RenamePrompt");
local inputBox = mainFrame:WaitForChild("Inputframe"):WaitForChild("TextBox");
local label = mainFrame:WaitForChild("label");

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
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local window = Interface.NewWindow("RenameWindow", mainFrame);
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	window.OnWindowToggle:Connect(function(visible, storageItem)
		if visible and storageItem then
			activeStorageItem = modGlobalVars.CloneTable(storageItem);
			inputBox.Text = activeStorageItem.CustomName or "";
			Interface.Update();
		end
	end)
	
	window:AddCloseButton(mainFrame);
	return Interface;
end;

renameButton.MouseButton1Click:Connect(function()
	if activeStorageItem == nil then return end;
	Interface:PlayButtonClick();
	
	local itemLib = modItemsLibrary:Find(activeStorageItem.ItemId);
	local clearName = #inputBox.Text <= 0;
	
	local promptWindow;
	local filteredName = not clearName and remoteRenameItem:InvokeServer("test", activeStorageItem.ID, inputBox.Text) or "";
	if clearName then
		promptWindow = Interface:PromptQuestion("Clear name for "..activeStorageItem.CustomName, "Are you sure you want to clear the name of the "..itemLib.Name.."?");
	else
		promptWindow = Interface:PromptQuestion("Rename "..itemLib.Name, "Are you sure you want to rename the "..itemLib.Name.." to ("..filteredName..") for 50 Gold?");
	end
	if type(filteredName) == "string" then
		local YesClickedSignal, NoClickedSignal;
		
		local debounce = false;
		YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
			if debounce then return end;
			debounce = true;
			Interface:PlayButtonClick();
			local r = remoteRenameItem:InvokeServer("set", activeStorageItem.ID, filteredName);
			if r == 1 then
				promptWindow.Frame.Yes.buttonText.Text = "Item Renamed!";
				
			elseif r == 2 then
				promptWindow.Frame.Yes.buttonText.Text = "Not enough gold";
				wait(1);
				promptWindow:Close();
				Interface:OpenWindow("GoldMenu", "GoldPage");
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
			Interface:PlayButtonClick();
			promptWindow:Close();
			Interface:OpenWindow("RenameWindow", activeStorageItem);
			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
		
	end
end)

testButton.MouseButton1Click:Connect(function()
	if activeStorageItem == nil then return end;
	Interface:PlayButtonClick();
	
	if #inputBox.Text > 0 then
		local filteredName = remoteRenameItem:InvokeServer("test",activeStorageItem.ID, inputBox.Text);
		if type(filteredName) == "string" then
			inputBox.Text = filteredName;
			
		end
	end
end)

function Interface.Update()
	local itemLib = modItemsLibrary:Find(activeStorageItem.ItemId);
	
	if #inputBox.Text > 0 then
		activeStorageItem.CustomName = inputBox.Text;
		renameButton.buttonText.Text = "Rename";
	else
		activeStorageItem.CustomName = nil;
		renameButton.buttonText.Text = "Clear Custom Name";
	end
	activeStorageItem.Index = 1;
	
	storageRenameSlot.Container = {};
	storageRenameSlot.Container[activeStorageItem.ID] = activeStorageItem;
	modData.SetStorage(storageRenameSlot);
	itemSlotInterface:Update(storageRenameSlot);
	modStorageInterface.SetQuickTarget();
end

inputBox:GetPropertyChangedSignal("Text"):Connect(function()
	inputBox.Text = inputBox.Text:sub(1, 30);
	Interface.Update();
end)

function Interface.disconnect()
	
end

script.AncestryChanged:Connect(function(c, p)
	if c == script and p == nil and Interface.disconnect then
		Interface.disconnect();
	end
end)
return Interface;