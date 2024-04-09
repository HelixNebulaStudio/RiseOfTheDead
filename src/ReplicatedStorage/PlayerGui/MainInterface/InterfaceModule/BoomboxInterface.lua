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
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local remotes = game.ReplicatedStorage.Remotes;
local remoteBoomboxRemote = modRemotesManager:Get("BoomboxRemote");
	
local mainFrame = script.Parent.Parent:WaitForChild("Boombox");
local label = mainFrame:WaitForChild("label");
local addButton = mainFrame:WaitForChild("addButton");
local testButton = mainFrame:WaitForChild("testButton");
local inputBox = mainFrame:WaitForChild("Inputframe"):WaitForChild("TextBox");
local playList = mainFrame:WaitForChild("list"):WaitForChild("ScrollingFrame");

local templateButton = script:WaitForChild("testButton");

local testSound = script:WaitForChild("Sound");

local toolHandler;

mainFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
	Interface:CloseWindow("BoomboxWindow");
end)
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local window = Interface.NewWindow("BoomboxWindow", mainFrame);
	window.CompactFullscreen = true;
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	window.OnWindowToggle:Connect(function(visible, toolHandler)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			Interface.Update(toolHandler)
		else
			testSound:Stop();
		end
	end)
	
	window:AddCloseButton(mainFrame);
	return Interface;
end;

testSound.Ended:Connect(function()
	testButton.buttonText.Text = "Test Sound";
end)

local testDebounce = false;
testButton.MouseButton1Click:Connect(function()
	if testDebounce then return end;
	testDebounce = true;
	
	local inputId = tonumber(inputBox.Text);
	if inputId then
		if testSound.Playing and testSound.SoundId == ("rbxassetid://"..inputId) then
			testSound:Stop();
			testButton.buttonText.Text = "Test Sound";
		else
			testSound.SoundId = "rbxassetid://"..inputId;
			testButton.buttonText.Text = "Loading..";
			for a=1, 20 do
				if testSound.IsLoaded then
					testSound:Play();
					testButton.buttonText.Text = "Playing";
					testDebounce = false;
					return;
				end
				wait(0.1)
			end
			testButton.buttonText.Text = "Could not load";
			wait(1);
			testButton.buttonText.Text = "Test Sound";
		end 
		
	end
	testDebounce = false;
end)

addButton.MouseButton1Click:Connect(function()
	testSound:Stop();
	local inputId = tonumber(inputBox.Text);
	if inputId == nil then
		addButton.buttonText.Text = "Missing input";
		wait(1);
		addButton.buttonText.Text = "Add Track";
		return;
	end
	
	local promptWindow = Interface:PromptQuestion("Add track to boombox", "Are you sure you want to add track ("..inputId..") for <b><font color='rgb(170, 120, 0)'>200 Gold</font></b>?");
	local YesClickedSignal, NoClickedSignal;
	
	local debounce = false;
	YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
		if debounce then return end;
		debounce = true;
		Interface:PlayButtonClick();
		local r = remoteBoomboxRemote:InvokeServer("add", toolHandler.StorageItem.ID, inputId);
		if r == 1 then
			promptWindow.Frame.Yes.buttonText.Text = "Track added";
			
		elseif r == 2 then
			promptWindow.Frame.Yes.buttonText.Text = "Not enough gold";
			
			wait(1);
			promptWindow:Close();
			Interface:OpenWindow("GoldMenu", "GoldPage");
			return;
			
		elseif r == 3 then
			promptWindow.Frame.Yes.buttonText.Text = "Purchase failed";
			
		elseif r == 4 then
			promptWindow.Frame.Yes.buttonText.Text = "Already exist";
			
		elseif r == 5 then
			promptWindow.Frame.Yes.buttonText.Text = "Playlist full";
			
		end
		wait(1.6);
		debounce = false;
		promptWindow:Close();
		Interface:OpenWindow("BoomboxWindow", toolHandler);
		YesClickedSignal:Disconnect();
		NoClickedSignal:Disconnect();
	end);
	NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
		if debounce then return end;
		Interface:PlayButtonClick();
		promptWindow:Close();
		Interface:OpenWindow("BoomboxWindow", toolHandler);
		YesClickedSignal:Disconnect();
		NoClickedSignal:Disconnect();
	end);
end)

function Interface.Update(toolH)
	toolHandler = toolH;
	if toolHandler == nil then Interface:CloseWindow("BoomboxWindow"); return; end;
	
	local storageItem = toolHandler.StorageItem;
	
	storageItem = modData.GetItemById(storageItem.ID);
	for _, obj in pairs(playList:GetChildren()) do
		if obj:IsA("GuiObject") then
			obj:Destroy();
		end
	end
	
	local songsList = storageItem.Values.Songs or {};
	local songsCount = 0;
	for songId, songName in pairs(songsList) do
		local new = templateButton:Clone();
		local buttonText = new:WaitForChild("buttonText");
		
		buttonText.Text = ("$name: $id"):gsub("$name", songName):gsub("$id", songId);
		new.MouseButton1Click:Connect(function()
			toolHandler.PrimaryFireRequest(true, songId);
			Interface:CloseWindow("BoomboxWindow");
		end)
		new.Parent = playList;
		songsCount = songsCount+1;
		
		local deleteButton = new:WaitForChild("deleteButton");
		local gradient = deleteButton:WaitForChild("UIGradient");
		
		local delButtonDown = false;
		deleteButton.MouseButton1Down:Connect(function()
			delButtonDown = true;
			local colorA, colorB, colorC = Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200), Color3.fromRGB(100, 100, 100);
			local color = {
				ColorSequenceKeypoint.new(0, colorA),
				ColorSequenceKeypoint.new(0.001, colorA),
				ColorSequenceKeypoint.new(0.002, colorB),
				ColorSequenceKeypoint.new(1, colorB)
			};
			gradient.Color = ColorSequence.new(color);
			
			local deleteTick = tick();
			local deleteTime = 1;
			local deleteDebounce = false;
			RunService:BindToRenderStep("DeleteTrack", Enum.RenderPriority.Input.Value+1, function(delta)
				if not mainFrame.Visible then RunService:UnbindFromRenderStep("DeleteTrack"); return end;
				
				local confirmPercent = math.clamp((tick()-deleteTick)/deleteTime, 0.001, 0.997);
				color[2] = ColorSequenceKeypoint.new(confirmPercent, colorA);
				color[3] = ColorSequenceKeypoint.new(confirmPercent+0.002, colorB);
				gradient.Color = ColorSequence.new(color);
				
				if confirmPercent >= 0.997 and not deleteDebounce then
					deleteDebounce = true;
					Interface:PlayButtonClick();
					RunService:UnbindFromRenderStep("DeleteTrack");
					
					remoteBoomboxRemote:InvokeServer("delete", storageItem.ID, songId);
					color[2] = ColorSequenceKeypoint.new(0.001, colorA);
					color[3] = ColorSequenceKeypoint.new(0.002, colorC);
					color[4] = ColorSequenceKeypoint.new(1, colorC);
					gradient.Color = ColorSequence.new(color);
					
					wait(0.2);
					Interface.Update(toolHandler);
				end
				if not Interface.Button1Down or not delButtonDown then
					color[2] = ColorSequenceKeypoint.new(0.001, colorA);
					color[3] = ColorSequenceKeypoint.new(0.002, colorB);
					gradient.Color = ColorSequence.new(color);
					RunService:UnbindFromRenderStep("ConfirmTrade");
				end
			end)
		end)
		
		deleteButton.MouseButton1Up:Connect(function()
			delButtonDown = false;
		end)
	end
	
	playList.CanvasSize = UDim2.new(0, 0, 0, playList.UIListLayout.AbsoluteContentSize.Y);
	label.Text = ("Add sound track to this boom box. Playlist: $songs/10"):gsub("$songs", songsCount);
	inputBox.Text = "";
	testButton.buttonText.Text = "Test Sound";
end

function Interface.disconnect()
	
end

script.AncestryChanged:Connect(function(c, p)
	if c == script and p == nil and Interface.disconnect then
		Interface.disconnect();
	end
end)
return Interface;
