local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};
Interface.__index = Interface;

local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");

local localplayer = game.Players.LocalPlayer;

local modData = require(localplayer:WaitForChild("DataModule"));

local modStatusLibrary = require(game.ReplicatedStorage.Library.StatusLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));

local menu = script.Parent.Parent:WaitForChild("Keypad");
local enterButton = menu:WaitForChild("enterButton");
local clearButton = menu:WaitForChild("clearButton");
local numpad = menu:WaitForChild("numpad");

local Inputframe = menu:WaitForChild("Inputframe");
local inputLabel = Inputframe:WaitForChild("label");

local templateButton = script:WaitForChild("templateButton");

local remotes = game.ReplicatedStorage.Remotes;
local remoteKeypadInput = modRemotesManager:Get("KeypadInput");

local branchColor = modBranchConfigs.BranchColor;
local activeInput = "";
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local window = Interface.NewWindow("Keypad", menu);
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1, 0));
	window.OnWindowToggle:Connect(function(visible)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			Interface:ToggleInteraction(false);
			activeInput = "";
			Interface.Update();
			spawn(function()
				repeat until not window.Visible or Interface.Object == nil or not Interface.Object:IsDescendantOf(workspace) or Interface.modCharacter.Player:DistanceFromCharacter(Interface.Object.Position) >= 16 or not wait(0.5);
				window:Close();
			end)
		else
			task.delay(0.3, function()
				Interface:ToggleInteraction(true);
			end)
		end
	end)
	
	local inputDebounce = false;
	for a=0, 9, 1 do
		local button = templateButton:Clone();
		button.Parent = numpad;
		local buttonText = button:WaitForChild("buttonText");
		buttonText.Text = a;
		button.MouseButton1Click:Connect(function()
			if inputDebounce then return end;
			inputDebounce = true;
			if #activeInput <= 10 then
				activeInput = activeInput..a;
				Interface.Update();
			end
			Interface:PlayButtonClick();
			wait(0.1);
			inputDebounce = false;
		end)
	end
	
	window:AddCloseButton(menu);
	return Interface;
end;

local enterDebounce = false;
enterButton.MouseButton1Click:Connect(function()
	if enterDebounce then return end;
	enterDebounce = true;
	Interface:PlayButtonClick();
	remoteKeypadInput:FireServer(Interface.Object, activeInput);
	wait(1);
	enterDebounce = false;
end)

local clearDebounce = false;
clearButton.MouseButton1Click:Connect(function()
	if clearDebounce then return end;
	clearDebounce = true;
	Interface:PlayButtonClick();
	activeInput = "";
	Interface.Update();
	wait(0.2);
	clearDebounce = false;
end)

function Interface.Update()
	inputLabel.Text = activeInput;
end

script.AncestryChanged:Connect(function(c, p)
	if c == script and p == nil then

	end
end)
return Interface;