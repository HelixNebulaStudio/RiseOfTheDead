local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local TweenService = game:GetService("TweenService");

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local remotes = game.ReplicatedStorage.Remotes;
local remoteMysteryChest = modRemotesManager:Get("MysteryChest");
	
local mainFrame = script.Parent.Parent:WaitForChild("MysteryChest");

local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, false, 0);
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local window = Interface.NewWindow("MysteryChestWindow", mainFrame);
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	
	local frame = mainFrame:WaitForChild("Frame");
	
	local adLabel = frame:WaitForChild("adLabel");
	local textInput = frame:WaitForChild("TextInput");
	local enterButton = frame:WaitForChild("enterButton");
	
	local hueValue = 0;
	local hueRate = 1/5 * 1/60;
	local submitCd = tick()-1;
	
	window.OnWindowToggle:Connect(function(visible)
		if visible then
			enterButton.buttonText.Text = "Submit";
			
			task.spawn(function()
				repeat
					adLabel.TextColor3 = Color3.fromHSV(hueValue, 0.392157, 1);
					hueValue = hueValue + hueRate;
					task.wait();
				until not mainFrame:IsDescendantOf(localplayer) or not mainFrame.Visible;
			end)

			Interface:ToggleInteraction(false);
			spawn(function()
				repeat until not window.Visible or Interface.Object == nil or not Interface.Object:IsDescendantOf(workspace) or Interface.modCharacter.Player:DistanceFromCharacter(Interface.Object.Position) >= 16 or not wait(0.5);
				Interface:ToggleWindow("MysteryChestWindow", false);
			end)
			
		else
			task.delay(0.3, function()
				Interface:ToggleInteraction(true);
			end)
			
		end
	end)
	
	Interface.Garbage:Tag(enterButton.MouseButton1Click:Connect(function()
		if tick()-submitCd <= 1 then return end; submitCd = tick();
		
		enterButton.buttonText.Text = "Unboxing..";
		local rPacket = remoteMysteryChest:InvokeServer(Interface.InteractData.Script, textInput.Text);
		
		if rPacket == nil then Debugger:Log("rPacket", rPacket) return end;
		
		if rPacket.Storage then
			modData.SetStorage(rPacket.Storage);
			Interface:OpenWindow("ExternalStorage", rPacket.Storage.Id, rPacket.Storage);
			modAudio.Play("CrateOpen");
			modAudio.Play("GrandOpen");
			
		elseif rPacket.Error then
			enterButton.buttonText.Text = rPacket.Error;
			
		end
	end));
	
	window:AddCloseButton(mainFrame);
	return Interface;
end;

--Interface.Garbage is only initialized after .init();
return Interface;
