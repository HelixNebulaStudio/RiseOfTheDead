local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local remotes = game.ReplicatedStorage.Remotes;
local remoteVoteSystem = modRemotesManager:Get("VoteSystem");
	
local mainFrame = script.Parent.Parent:WaitForChild("VoteMenu");
local voteFrame = mainFrame:WaitForChild("Frame"):WaitForChild("VoteFrame");

local closeButton = mainFrame:WaitForChild("Frame"):WaitForChild("CloseButton");
local yesButton = mainFrame:WaitForChild("Frame"):WaitForChild("YesButton");

local dvdTextLabel = mainFrame:WaitForChild("Frame"):WaitForChild("ImageLabel"):WaitForChild("TextLabel");

local selection = {};
local alreadyVoted = false;
local labelsDict = {};

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local window = Interface.NewWindow("VoteWindow", mainFrame);
	window:AddCloseButton(mainFrame);
	
	mainFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("VoteWindow");
	end)
	if modConfigurations.CompactInterface then
		mainFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton").Visible = true;

		window.CompactFullscreen = true;
		
		game.Debris:AddItem(mainFrame:FindFirstChild("UISizeConstraint"), 0);
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0, 0), UDim2.new(0.5, 0, -1, 0));
		
	else
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.5, 0, -1, 0));
		
	end
	
	window.OnWindowToggle:Connect(function(visible)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			Interface.Update()
			
			task.spawn(function()
				local flip = true;
				local function bounce()
					if not window.Visible then return end;
					if not dvdTextLabel:IsDescendantOf(localplayer) then return end;
					
					local currentPos = Vector2.new(dvdTextLabel.Position.X.Offset, dvdTextLabel.Position.Y.Offset);
					
					local randomPos = Vector2.new(
						math.random(0, 7500)/100 * (math.random(1, 2) == 1 and 1 or -1), 
						math.random(0, 7500)/100 * (math.random(1, 2) == 1 and 1 or -1));
					if flip then
						flip = false;
						randomPos = Vector2.new(75* (math.random(1, 2) == 1 and 1 or -1), randomPos.Y);
					else
						flip = true;
						randomPos = Vector2.new(randomPos.X, 75* (math.random(1, 2) == 1 and 1 or -1));
					end
					
					local duration = (currentPos-randomPos).Magnitude/55;
					
					dvdTextLabel:TweenPosition(
						UDim2.new(0.5, randomPos.X, 0.5, randomPos.Y),
						Enum.EasingDirection.InOut,
						Enum.EasingStyle.Linear,
						duration,
						true,
						bounce
					)
				end
				bounce()
			end)
		end
	end)
	
	local voteLabels = voteFrame:GetChildren();
	for a=1, #voteLabels do
		local label = voteLabels[a];
		if label:IsA("GuiObject") then
			
			labelsDict[label.Name] = label;
			Interface.Garbage:Tag(label.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if input.UserInputState == Enum.UserInputState.Begin then
						if alreadyVoted then return end;
						local clickSelected = false;
						for _, nlabel in pairs(selection) do
							if nlabel then
								nlabel.TextStrokeTransparency = 1;
							end
							selection[nlabel.Name] = nil;
							
							if nlabel == label then
								clickSelected = true;
							end
						end
						
						if selection[label.Name] or clickSelected then
							selection[label.Name] = nil;
							label.TextStrokeTransparency = 1;
						else
							selection[label.Name] = label;
							label.TextStrokeTransparency = 0;
						end
					end
				end
			end));
		end
	end
	
	Interface.Garbage:Tag(closeButton.MouseButton1Click:Connect(function()
		Interface:CloseWindow("VoteWindow");
	end));
	
	local debounce = false;
	Interface.Garbage:Tag(yesButton.MouseButton1Click:Connect(function()
		if alreadyVoted then return end;
		if debounce then return end;
		debounce = true;
		
		local selected = 0;
		local selectedLabel = nil;
		for _, label in pairs(selection) do
			selected = selected +1;
			selectedLabel = label;
		end
		
		if selected == 1 then
			local promptWindow = Interface:PromptQuestion(selectedLabel.Text,
				("Are you sure you are voting for <b>"..selectedLabel.Text.."</b>"), 
				"Vote", "Return", "rbxassetid://9164091486");
			local YesClickedSignal, NoClickedSignal;
		
			local submitDebounce = tick();
			YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
				if tick()-submitDebounce <= 0.2 then return end;
				submitDebounce = tick();
				
				local promptYesText = promptWindow.Frame.Yes.buttonText;
				
				Interface:PlayButtonClick();
				promptYesText.Text = "Submitting..";
				
				
				local returnPacket = remoteVoteSystem:InvokeServer({
					Action="submit";
					VoteKey=modGlobalVars.VoteKey;
					VoteId=selectedLabel.Name;
				});
				
				Debugger:Log("returnPacket", returnPacket);
				if returnPacket.Success == true then
					promptYesText.Text = "Thank you for your vote~!";
					task.wait(1);
				else
					promptYesText.Text = returnPacket.Failed;
					task.wait(2);
					promptYesText.Text = "Submit Vote";
				end
				
				promptWindow:Close();
				Interface:OpenWindow("VoteWindow");
				YesClickedSignal:Disconnect();
				NoClickedSignal:Disconnect();
			end);
			NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
				Interface:PlayButtonClick();
				promptWindow:Close();
				Interface:OpenWindow("VoteWindow");
				YesClickedSignal:Disconnect();
				NoClickedSignal:Disconnect();
			end);
			
		else
			if selected <= 0 then
				yesButton.Text = "Select your favourite!"
				task.wait(2);
				yesButton.Text = "Submit Vote";
			else
				yesButton.Text = "You can only select one!"
				task.wait(2);
				yesButton.Text = "Submit Vote";
			end
		end
		
		debounce = false;
	end));
	
	if modBranchConfigs.CurrentBranch.Name ~= "Dev" and modGlobalVars.VoteKey then
		task.delay(5, function()
			local allowsYT = false;
			
			if modData
				and modData.Profile
				and modData.Profile.PolicyData
				and modData.Profile.PolicyData.AllowedExternalLinkReferences
			then
				for _, socialType in pairs(modData.Profile.PolicyData.AllowedExternalLinkReferences) do
					if socialType == "YouTube" then
						allowsYT = true;
						break;
					end
				end
			end
			
			if allowsYT == false or modData.Profile.TrustLevel < 50 then 
				return 
			end;
			
			local voteFlag = modData:GetFlag("vote:"..modGlobalVars.VoteKey, true);
			if (voteFlag == nil or voteFlag.Value == nil) and modBranchConfigs.WorldInfo.Type == 1 then
				Interface:OpenWindow("VoteWindow");
			end
		end)
	end
	
	return Interface;
end;

function Interface.Update()
	local allowsYT = false;
	
	if modData
		and modData.Profile
		and modData.Profile.PolicyData
		and modData.Profile.PolicyData.AllowedExternalLinkReferences
	then
		for _, socialType in pairs(modData.Profile.PolicyData.AllowedExternalLinkReferences) do
			if socialType == "YouTube" then
				allowsYT = true;
				break;
			end
		end
	end
	
	if allowsYT == false or modData.Profile.TrustLevel < 50 then 
		Interface:CloseWindow("VoteWindow"); 
		Interface:PromptWarning("You are not eligible to vote. Contact developers if you think this is a mistake.");
		return 
	end;
	
	if modBranchConfigs.CurrentBranch.Name == "Dev" and not RunService:IsStudio() then
		Interface:CloseWindow("VoteWindow");
		Interface:PromptWarning("There is not active vote.");
	end
	
	local pollData = remoteVoteSystem:InvokeServer({Action="get"; VoteKey=modGlobalVars.VoteKey;});
	if pollData then
		if RunService:IsStudio() then
			Debugger:Warn("pollData", pollData);
		end
		if (pollData.PlayerVote and pollData.PlayerVote.Value) or pollData.VoteEnded == true then
			alreadyVoted = true;
			closeButton.Visible = false;
			yesButton.Visible = false;
			
			voteFrame.Position = UDim2.new(0.5, 0, 1, -15);
			voteFrame.Size = UDim2.new(1, -30, 0, 160)
			voteFrame.UIGridLayout.CellSize = UDim2.new(0, 160, 0, 35);
			
			for a=1, #pollData.Polls do
				local data = pollData.Polls[a];
				if labelsDict[data.Id] then
					
					local label = labelsDict[data.Id];
					if label:GetAttribute("Title") == nil then
						label:SetAttribute("Title", label.Text);
					end
					
					local votes = data.Count or 0;
					label.Text = label:GetAttribute("Title").."<br/> Votes:"..votes;
					
					if label.Name == pollData.PlayerVote.Value then
						label.TextStrokeTransparency = 0;
					else
						label.TextStrokeTransparency = 1;
					end
					
					if a == 1 then
						label.TextSize = 16;
					elseif a == 2 then
						label.TextSize = 15;
					elseif a == 3 then
						label.TextSize = 14;
					elseif a == 4 then
						label.TextSize = 13;
					elseif a == 5 then
						label.TextSize = 12;
					else
						label.TextSize = 11;
					end
					
					label.LayoutOrder = a;
				end
			end
			
		end
	end
end

--Interface.Garbage is only initialized after .init();
return Interface;