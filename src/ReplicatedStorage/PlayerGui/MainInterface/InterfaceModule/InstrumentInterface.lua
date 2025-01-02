local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local UserInputService = game:GetService("UserInputService");

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modInstrument = require(game.ReplicatedStorage.Library.InstrumentModule);
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));

local templateButton = script:WaitForChild("TextButton");

local instrFrame = script.Parent.Parent:WaitForChild("InstrumentFrame");
local inputKeyBox = instrFrame:WaitForChild("input");
local notesList = instrFrame:WaitForChild("noteButtons");
local buttonsFrame = instrFrame:WaitForChild("Buttons");
local octiveLabel = instrFrame:WaitForChild("octiveLabel");

local isInstrumentFocus = false;
local isShiftDown = false;

local activeInstrument;
local toolHandler;

Interface.ToggleAdv = false;
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	
	local window = Interface.NewWindow("InstrumentWindow", instrFrame);

	if modConfigurations.CompactInterface then
		instrFrame.Size = UDim2.new(1, 0, 0, 100);
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 1, 0), UDim2.new(0.5, 0, -1.5, 0));
		
	else
		instrFrame.Size = UDim2.new(0, 784, 0, 90);
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 1, -75), UDim2.new(0.5, 0, -1.5, 0));
		
	end
	
	window:AddCloseButton(instrFrame);
	instrFrame:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("InstrumentWindow");
	end)
	window.OnWindowToggle:Connect(function(visible, toolHandler)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			Interface.Update(toolHandler);
			Interface.Refresh();
		end
	end)
	
	buttonsFrame.ToggleAdv.MouseButton1Click:Connect(function()
		Interface.ToggleAdv = not Interface.ToggleAdv;
		Interface.Refresh();
		Interface.Update(toolHandler);
	end)
	
	function Interface.Refresh()
		local octiveVal = 5;
		if activeInstrument.IsShiftDown then octiveVal = 6; end
		if activeInstrument.IsCtrlDown then octiveVal = 4; end
		
		octiveLabel.UphotKey.BackgroundColor3 = not activeInstrument.IsShiftDown and Color3.fromRGB(255,255,255) or Color3.fromRGB(153, 185, 255);
		octiveLabel.DownhotKey.BackgroundColor3 = not activeInstrument.IsCtrlDown and Color3.fromRGB(255,255,255) or Color3.fromRGB(153, 185, 255);
		octiveLabel.Text = "Octave: "..octiveVal;
		
		if Interface.ToggleAdv then
			instrFrame.Size = modConfigurations.CompactInterface and UDim2.new(1, 0, 0, 200) or UDim2.new(0, 784, 0, 190);
			
		else
			instrFrame.Size = modConfigurations.CompactInterface and UDim2.new(1, 0, 0, 100) or UDim2.new(0, 784, 0, 90);
			
		end
	end
	
	Interface.Garbage:Tag(UserInputService.InputBegan:Connect(function(inputObject)
		if activeInstrument == nil then return end;
		activeInstrument.AdvanceMode = Interface.ToggleAdv;
		
		if inputObject.KeyCode == Enum.KeyCode.LeftShift or inputObject.KeyCode == Enum.KeyCode.RightShift then
			activeInstrument.IsShiftDown = true;
		end
		if inputObject.KeyCode == Enum.KeyCode.LeftControl or inputObject.KeyCode == Enum.KeyCode.RightControl then
			activeInstrument.IsCtrlDown = true;
		end
		Interface.Refresh();
	end))
	

	Interface.Garbage:Tag(UserInputService.InputEnded:Connect(function(inputObject)
		if activeInstrument == nil then return end;
		activeInstrument.AdvanceMode = Interface.ToggleAdv;
		
		if inputObject.KeyCode == Enum.KeyCode.LeftShift or inputObject.KeyCode == Enum.KeyCode.RightShift then
			activeInstrument.IsShiftDown = false;
		end
		if inputObject.KeyCode == Enum.KeyCode.LeftControl or inputObject.KeyCode == Enum.KeyCode.RightControl then
			activeInstrument.IsCtrlDown = false;
		end
		Interface.Refresh();
	end))

	local inputBeganConn = UserInputService.InputBegan:Connect(function(inputObject)
		if inputObject.KeyCode == Enum.KeyCode.LeftShift or inputObject.KeyCode == Enum.KeyCode.RightShift then
			isShiftDown = true;
		end
		if inputKeyBox:IsFocused() and activeInstrument then
			activeInstrument:ProcessInputBegan(inputObject);
		end
	end)

	local inputEndedConn = UserInputService.InputEnded:Connect(function(inputObject)
		if inputObject.KeyCode == Enum.KeyCode.LeftShift or inputObject.KeyCode == Enum.KeyCode.RightShift then
			isShiftDown = false;
		end
		if activeInstrument then
			activeInstrument:ProcessInputEnded(inputObject);
		end
	end)
	
	Interface.Garbage:Tag(function()
		if activeInstrument then
			activeInstrument:Destroy();
		end
		if inputBeganConn then
			inputBeganConn:Disconnect();
		end
		if inputEndedConn then
			inputEndedConn:Disconnect();
		end
	end)
	
	return Interface;
end;

inputKeyBox:GetPropertyChangedSignal("Text"):Connect(function()
	local lastNoteIndex = #inputKeyBox.Text;
	local latestNote = inputKeyBox.Text:sub(lastNoteIndex, lastNoteIndex);
	inputKeyBox.Text = latestNote;
	
end)

-- ▶ play ■ stop
local lastAdvMode = false;
function Interface.Update(toolH)
	toolHandler = toolH;
	local storageItem = toolHandler.StorageItem;
	
	for _, obj in pairs(notesList:GetChildren()) do
		if obj:IsA("GuiObject") then
			obj:Destroy();
		end
	end
	
	if storageItem == nil then Debugger:Log("Missing instrument item") return end
	
	if toolHandler.Instrument then
		if activeInstrument then
			activeInstrument:Destroy();
		end
		activeInstrument = modInstrument.new(toolHandler.Instrument, toolHandler.Handle, toolHandler.Handle);
		activeInstrument.Player = game.Players.LocalPlayer;
		activeInstrument.StorageItem = storageItem;
		
		if lastAdvMode ~= Interface.ToggleAdv then
			lastAdvMode = Interface.ToggleAdv;
			
			for _, obj in pairs(notesList:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj:Destroy();
				end
			end
		end
		
		local baseOctave = 5;
		for _, note in pairs(modInstrument.Notes) do
			if Interface.ToggleAdv then
				
				local advKeyList = note.AdvKey;
				
				for octive=-1, 1 do
					local advKeyInfo = advKeyList[octive+2];
					
					local new = templateButton:Clone();
					new.Text = note.Name..(baseOctave+octive);
					
					new.LayoutOrder = (-octive * 12) + note.Index;
					new.Parent = notesList;

					local hotKey = new:WaitForChild("hotKey");
					local hotKeyLabel = hotKey:WaitForChild("button");
					hotKeyLabel.Text = advKeyInfo.Key;

					new.MouseButton1Down:Connect(function()
						if activeInstrument == nil then return end;
						activeInstrument.AdvanceMode = Interface.ToggleAdv;

						activeInstrument:ProcessInputBegan({KeyCode=advKeyInfo.KeyCode});
					end)
					new.MouseButton1Up:Connect(function()
						if activeInstrument == nil then return end;
						activeInstrument.AdvanceMode = Interface.ToggleAdv;

						activeInstrument:ProcessInputEnded({KeyCode=advKeyInfo.KeyCode});
					end)
					
				end
				
			else
				
				local new = templateButton:Clone();
				new.Text = note.Name;
				new.Parent = notesList;

				local hotKey = new:WaitForChild("hotKey");
				local hotKeyLabel = hotKey:WaitForChild("button");
				hotKeyLabel.Text = note.Key;

				new.MouseButton1Down:Connect(function()
					if activeInstrument == nil then return end;
					activeInstrument.AdvanceMode = Interface.ToggleAdv;

					activeInstrument:ProcessInputBegan({KeyCode=note.KeyCode});
				end)
				new.MouseButton1Up:Connect(function()
					if activeInstrument == nil then return end;
					activeInstrument.AdvanceMode = Interface.ToggleAdv;

					activeInstrument:ProcessInputEnded({KeyCode=note.KeyCode});
				end)
				
			end
		end
	end
end

return Interface;