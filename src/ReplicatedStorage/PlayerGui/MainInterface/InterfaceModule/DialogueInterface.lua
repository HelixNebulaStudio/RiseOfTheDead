local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interface = {
	CloseWindow = nil;
	ToggleWindow = nil;
	ItemViewport = nil;
};
Interface.InDialogue = false;

local unevaluableAnswers = {
	"Hmm, I don't know how to answer that..";
	"Sorry, I didn't quite get that question..";
	"Umm, could you specify more detail?";
	"Maybe someone else has the answer to that.";
};

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local TextService = game:GetService("TextService");
local localplayer = game.Players.LocalPlayer;

local remotes = game.ReplicatedStorage.Remotes;
local remoteMissionCheckFunction = remotes.Interface.MissionCheckFunction;

local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modBranchConfigs = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));
local modMissionLibrary = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("MissionLibrary"));
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modFacesLibrary = require(game.ReplicatedStorage.Library.FacesLibrary);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modAssetHandler = require(game.ReplicatedStorage.Library.AssetHandler);

local modScreenRelativeTextSize = require(game.ReplicatedStorage.Library.UI.ScreenRelativeTextSize);
local branchColor = modBranchConfigs.BranchColor;

local remoteDialogueHandler = modRemotesManager:Get("DialogueHandler");

local dialogueFrame = script.Parent.Parent:WaitForChild("DialogueFrame");
local backgroundFrame = dialogueFrame:WaitForChild("BackgroundFrame");
local timerBar = dialogueFrame:WaitForChild("timerBar");

local messageFrame = backgroundFrame:WaitForChild("MessageFrame");
local questionsList = backgroundFrame:WaitForChild("QuestionList");

local questionOption = questionsList:WaitForChild("questionOption");
local questionInput = questionOption:WaitForChild("SearchFrame"):WaitForChild("SearchBar");

local dialogueButtonTemplate = script:WaitForChild("dialogueButton");

local loadedDialog;
local random = Random.new();

local NpcName, NpcModel;

local lastExpireTime;
local window;
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	window = Interface.NewWindow("Dialogue", dialogueFrame);
	window.CompactFullscreen = true;
	
	if modConfigurations.CompactInterface then
		dialogueFrame.AnchorPoint = Vector2.new(0.5, 1);
		dialogueFrame.Position = UDim2.new(0.5, 0, 0, 0);
		dialogueFrame.Size = UDim2.new(1, 0, 0.5, 0);
		
		backgroundFrame.Size = UDim2.new(1, 0, 1, 0);
		
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 1, 0), UDim2.new(0.5, 0, 2, 0));
		
		dialogueFrame:WaitForChild("touchCloseButton").Visible = true;
		dialogueFrame.touchCloseButton:WaitForChild("closeButton").MouseButton1Click:Connect(function()
			window:Close();
		end)
		
	else
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 1, 0), UDim2.new(0.5, 0, 2, 0));
		
	end
	
	window.OnWindowToggle:Connect(function(visible, modInteractable)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			Interface:ToggleInteraction(false);
			
			if modInteractable then
				Interface:DialogueInteract(modInteractable);
				spawn(function()
					repeat until not window.Visible or Interface.Object == nil or localplayer:DistanceFromCharacter(Interface.Object.Position) >= 15 or not wait(0.5);
					window:Close();
				end)
			end
		else
			Interface:CloseDialogue();
			task.delay(0.3, function()
				Interface:ToggleInteraction(true);
			end)
		end
	end)

	function remoteDialogueHandler.OnClientInvoke(action, packet)
		if action == "talk" then
			local dialogPacket = packet;
			window:Open();
			Interface:OnDialogue(dialogPacket);
			
		end

		return;
	end

	modAssetHandler.init();
	
	window:AddCloseButton(dialogueFrame);
	return Interface;
end;

function formatDialogues(txt)
	if txt then
		txt = string.gsub(txt, "$PlayerName", localplayer.Name);
	end
	return txt;
end

function Interface:SetDialogueText(text)
	local dialogLabel = messageFrame.Message;
	dialogLabel.TextScaled = false;
	dialogLabel.Text = formatDialogues(text or "");
	dialogLabel.TextSize = modScreenRelativeTextSize.GetTextSize("P");
	
	local sizeRequired = TextService:GetTextSize(dialogLabel.Text, dialogLabel.TextSize, dialogLabel.Font, Vector2.new(dialogLabel.AbsoluteSize.X, math.huge));
	if sizeRequired.Y > dialogLabel.AbsoluteSize.Y then
		dialogLabel.TextScaled = true;
	end
end

function Interface:DialogueInteract(modInteractable)
	if modInteractable == nil then Interface:CloseWindow("Dialogue"); return; end;

	local npcModel = modInteractable.Object and modInteractable.Object.Parent;
	
	local dialogPacket = remoteDialogueHandler:InvokeServer("dialogue", {
		NpcName=modInteractable.NpcName;
		NpcModel=npcModel;
	});
	
	Interface:OnDialogue(dialogPacket);
end

function Interface:OnDialogue(dialogPacket)
	for _, child in pairs(questionsList:GetChildren()) do 
		if child:IsA("TextButton") and child.Name ~= "questionOption" then child:Destroy() end; 
	end
	
	if dialogPacket == nil then
		Debugger:Warn("Missing dialogue data.");
		Interface:CloseWindow("Dialogue");
		return;
	end

	Interface.InDialogue = true;
	
	NpcName = dialogPacket.Name;
	NpcModel = dialogPacket.Prefab;
	

	local humanoid = NpcModel and NpcModel:FindFirstChildWhichIsA("Humanoid");
	if humanoid then
		task.spawn(function()
			while window.Visible do
				task.wait(0.1);
				if humanoid:GetAttribute("IsDead") or not workspace:IsAncestorOf(humanoid) then
					Interface:CloseWindow("Dialogue");
					break;
				end
			end
		end)
	end

	messageFrame.NameTag.Text = NpcName;
	self:SetDialogueText("");
	
	Debugger:StudioLog("dialogPacket", dialogPacket);

	local initReply = dialogPacket.InitReply;
	if modConfigurations.SpecialEvent.AprilFools then
		local listOfAprilFoolsInit = {
			"Why hello, legendary one!\n";
			"It's the legendary one!\n";
			"Oh hello there, legendary one!\n";
		}
		initReply = listOfAprilFoolsInit[math.random(1, #listOfAprilFoolsInit)]..initReply;
	end
	self:SetDialogueText(initReply);
	

	local function refreshDialogues()
		local dialogChoices = dialogPacket.Choices;

		for _, child in pairs(questionsList:GetChildren()) do 
			if child:IsA("TextButton") and child.Name ~= "questionOption" then child:Destroy() end; 
		end
		
		local pinnedMissionId;
		if modData.GameSave and modData.GameSave.Missions then
			local missionsList = modData.GameSave.Missions;
			for a=1, #missionsList do
				if missionsList[a].Pinned then
					pinnedMissionId = missionsList[a].Id;
				end
			end
		end
		
		local dialogueButtons = {};
		local serverTime = modSyncTime.GetTime();

		for choiceTag, choiceInfo in pairs(dialogChoices) do
			local data = choiceInfo.Data;
			local sayStr = choiceInfo.Say;
			local replyStr = choiceInfo.Reply;
			local faceSet = choiceInfo.Face;

			local unlockTime = data and data.ChoiceUnlockTime and (data.ChoiceUnlockTime-serverTime) or nil;
						
			local newDialogue = dialogueButtonTemplate:Clone();
			newDialogue.Parent = script;
			
			local textLabel = newDialogue:WaitForChild("TextLabel");
			textLabel.Text = formatDialogues(sayStr);
			local textSize = textLabel.TextSize;
			
			local missionLib = choiceInfo.MissionId and modMissionLibrary.Get(choiceInfo.MissionId) or nil;
			
			local function updateText()
				serverTime = modSyncTime.GetTime();
				unlockTime = data and data.ChoiceUnlockTime and (data.ChoiceUnlockTime-serverTime) or nil;
				
				local newText = formatDialogues(sayStr);
				if missionLib then
					local missionType = missionLib.MissionType;
					local fontColor = '<font color="rgb(255, 255, 255)">';
					
					if pinnedMissionId == nil or pinnedMissionId == choiceInfo.MissionId then
						if missionType == 1 then
							fontColor = '<font color="rgb(255, 106, 106)">';
						elseif missionType == 3 then
							fontColor = '<font color="rgb(186, 146, 255)">';
						elseif missionType == 5 then
							fontColor = '<font color="rgb(255, 203, 142)">';
						else
							fontColor = '<font color="rgb(162, 210, 255)">';
						end
					else
						if missionType == 1 then
							fontColor = '<font color="rgb(100, 61, 61)">';
						elseif missionType == 3 then
							fontColor = '<font color="rgb(85, 77, 100)">';
						elseif missionType == 5 then
							fontColor = '<font color="rgb(100, 88, 75)">';
						else
							fontColor = '<font color="rgb(83, 92, 100)">';
						end
					end
					
					newText = fontColor.."["..missionLib.Name.."]"..'</font> '..'<font size="'.. textSize-2 ..'">' ..newText.."</font>";
				end
				
				if data and data.UserPrompt then
					newText = `<b>[Chat]</b> {newText}`;
				end

				if unlockTime and unlockTime > 0 then
					textLabel.Text = newText.." ("..modSyncTime.ToString(unlockTime)..")";
					textLabel.TextColor3 = Color3.fromRGB(150, 150, 150);
					textLabel:SetAttribute("TextColor", textLabel.TextColor3);
					textLabel:SetAttribute("AutoColor", false);
				else
					textLabel.Text = newText;
					textLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
					textLabel:SetAttribute("TextColor", textLabel.TextColor3);
					textLabel:SetAttribute("AutoColor", true);
				end

			end
			
			updateText();

			task.spawn(function() 
				if unlockTime then
					local updateTextConn
					updateTextConn = modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
						if not newDialogue:IsDescendantOf(localplayer.PlayerGui) or unlockTime == nil or unlockTime <= 0 then
							updateTextConn:Disconnect()
							return;
						end;
						updateText();
					end)
				end
			end)
			

			local diagIcon = newDialogue:WaitForChild("DialogueIcon");
			
			if choiceTag:find("general_") == nil then
				diagIcon.Visible = true;
				diagIcon.ImageColor3 = Color3.fromRGB(255, 255, 255);
				textLabel.Position = UDim2.new(0, 32, 0, 0);
				textLabel.Size = UDim2.new(1, -32, 0, 0);
				
				if choiceTag:find("heal_") then
					diagIcon.Image = "rbxassetid://2770153676";

				elseif choiceTag:find("shop_") then
					diagIcon.Image = "rbxassetid://4629984614";
					diagIcon.ImageColor3 = Color3.fromRGB(255, 240, 23);

				elseif choiceTag:find("guide_") then
					diagIcon.Image = "rbxassetid://3291004554";

				elseif missionLib then
					diagIcon.Image = "rbxassetid://1550983590";

				else
					diagIcon.Visible = false;
					textLabel.Position = UDim2.new(0, 0, 0, 0);
					textLabel.Size = UDim2.new(1, 0, 0, 0);
				end
			end
			
			newDialogue.Name = choiceTag or "untagged";
			newDialogue.LayoutOrder = choiceInfo.Order;
			if data and data.Order then
				newDialogue.LayoutOrder = data.Order;
			end
			
			table.insert(dialogueButtons, newDialogue);
			newDialogue.MouseMoved:Connect(function()
				if textLabel:GetAttribute("AutoColor") ~= false then
					textLabel.TextColor3 = branchColor;
				end
			end)
			
			newDialogue.MouseLeave:Connect(function()
				textLabel.TextColor3 = textLabel:GetAttribute("TextColor") or Color3.new(255, 255, 255);
			end)

			updateText();
			task.spawn(function()
				local canStart, failReasons;
				if choiceInfo.CheckMission then
					canStart, failReasons = remoteMissionCheckFunction:InvokeServer(choiceInfo.CheckMission);
				end
				
				local function onOptionClicked()
					if choiceInfo.CheckMission == nil or canStart == true then
						-- MARK: Set Reply text
						self:SetDialogueText(replyStr);
						
						local faceInfo = faceSet and modFacesLibrary:Find(faceSet);
						if faceInfo and NpcModel and NpcModel:FindFirstChild("Head") and NpcModel.Head:FindFirstChild("face") then
							NpcModel.Head.face.Texture = faceInfo.Texture;
						end

						if data and data.UserPrompt then
							task.spawn(function()
								questionInput.Text = sayStr;
								local newDialoguePacket = remoteDialogueHandler:InvokeServer("userprompt", {
									NpcName = NpcName;
									NpcModel = NpcModel;
									UserPrompt = sayStr;
								});
								questionInput.Text = "";
								if newDialoguePacket.Name ~= NpcName then return end;

								Interface:SetDialogueText(newDialoguePacket.InitReply);
								Debugger:StudioLog("newDialoguePacket", newDialoguePacket);
								dialogPacket = newDialoguePacket;
								refreshDialogues();
							end)
						end
						
					else
						local failDialogues = choiceInfo.FailResponses or {};
						if #failDialogues <= 0 then
							table.insert(failDialogues, {Reply="Nevermind, come back later..."});
						end
						
						local reply = failDialogues[random:NextInteger(1, #failDialogues)];
						reply = reply.Reply;
						
						if #failReasons > 0 then
							reply = reply..'<font size="10"><b>'.."\n\nRequirements: ";
							reply = reply.."\n • ".. table.concat(failReasons, "\n • ").."</b></font>";
						end
						
						self:SetDialogueText(reply);
					end
					newDialogue.Visible = false;
					for _, child in pairs(questionsList:GetChildren()) do 
						if child:IsA("TextButton") and child.Name ~= "questionOption" then child:Destroy() end; 
					end
					
					if choiceInfo.CheckMission == nil or canStart == true then
						local newDialoguePacket = remoteDialogueHandler:InvokeServer("dialogue", {
							NpcName = NpcName;
							NpcModel = NpcModel;
							ChoiceTag = choiceTag;
						});

						Debugger:StudioLog("newDialoguePacket", newDialoguePacket);
						dialogPacket = newDialoguePacket;
						refreshDialogues();
					end
					
					if choiceInfo.ToggleWindow then
						Interface:ToggleWindow(choiceInfo.ToggleWindow, true, data);
					end
				end
				
				if RunService:IsStudio() then
					newDialogue.MouseButton2Click:Connect(onOptionClicked);
				end
				
				newDialogue.MouseButton1Click:Connect(function()
					unlockTime = data and data.ChoiceUnlockTime and (data.ChoiceUnlockTime-modSyncTime.GetTime()) or nil;
					if unlockTime and unlockTime > 0 then return end;
					onOptionClicked()
				end)
			end);
			
			if choiceInfo.InspectItem then
				local itemViewportObject = Interface.ItemViewport.new();
				itemViewportObject:SetZIndex(4);
				local frame = itemViewportObject.Frame;

				frame.Parent = dialogueFrame;
				frame.AnchorPoint = Vector2.new(0.5, 1);
				frame.Position = UDim2.new(0.5, 0, 0, 0);
				frame.Size = UDim2.new(0.5, 0, 0.5, 0);
				frame.Visible = true;

				local closeConn;
				closeConn = dialogueFrame:GetPropertyChangedSignal("Visible"):Connect(function()
					if not dialogueFrame.Visible then
						if itemViewportObject then itemViewportObject:Destroy(); end
					end
				end)
				itemViewportObject.Garbage:Tag(function()
					itemViewportObject = nil;
					if closeConn then
						closeConn:Disconnect();
						closeConn = nil;
					end
				end)

				itemViewportObject:SetDisplay(choiceInfo.InspectItem);
			end
			
			newDialogue.Parent = questionsList;
			questionOption.Visible = true;--choiceInfo.AskMe == true or (#dialogueButtons > 1);
		end

		questionOption.Visible = true;--dialogPacket.AskMe == true or (#dialogueButtons > 1);
		
		
		if dialogPacket.ExpireTime then
			local expireTime = dialogPacket.ExpireTime;
			lastExpireTime = expireTime;

			local currTime = workspace:GetServerTimeNow();
			
			timerBar.ImageColor3 = branchColor;
			timerBar.Visible = true;
			local timeLeft = expireTime-currTime;

			timerBar.Size = UDim2.new(1, 0, 0, 3);
			TweenService:Create(
				timerBar,
				TweenInfo.new(timeLeft),
				{
					Size = UDim2.new(0, 0, 0, 3)
				}
			):Play();
			
			task.delay(timeLeft, function()
				if lastExpireTime == nil then 
					timerBar.Visible = false;
					return
				end;
				if lastExpireTime ~= expireTime then return end;
				Interface:CloseWindow("Dialogue");
			end)

		else
			timerBar.Visible = false;
			lastExpireTime = nil;

		end
	end
	
	questionsList.CanvasPosition = Vector2.new();
	refreshDialogues();
	
end

function Interface:CloseDialogue()
	task.spawn(function()
		remoteDialogueHandler:InvokeServer("close", {
			NpcName=NpcName;
			NpcModel=NpcModel;
		});
	end)
	questionInput:ReleaseFocus();
	questionInput.Text = "";
	Interface.InDialogue = false;
end

questionInput:GetPropertyChangedSignal("Text"):Connect(function()
	if questionInput.Text:len() <= 0 then
		for _, child in pairs(questionsList:GetChildren()) do
			if child:IsA("TextButton") and child.Name ~= "questionOption" then child.Visible = true; end;
		end
	else
		for _, child in pairs(questionsList:GetChildren()) do
			if child:IsA("TextButton") and child.Name ~= "questionOption" then
				if child.TextLabel.Text:lower():find(questionInput.Text:lower()) then
					child.Visible = true;
				else
					child.Visible = false;
				end
			end;
		end
	end
end)

local lastInputText = nil;
questionInput.FocusLost:Connect(function(enterPressed, inputObject)
	local inputText = questionInput.Text;
	
	if inputText and #inputText >= 2 then
		lastExpireTime = nil;
		timerBar.Visible = false;
	end

	if enterPressed then
		for _, child in pairs(questionsList:GetChildren()) do
			if child:IsA("TextButton") and child.Visible and child.Name ~= "questionOption" then 
				break;
			end;
		end

		if NpcName and lastInputText ~= inputText then
			lastInputText = inputText;

			lastExpireTime = nil;
			timerBar.Visible = false;

			Interface:SetDialogueText("*thinking...*");

			local dialogPacket = remoteDialogueHandler:InvokeServer("userprompt", {
				NpcName = NpcName;
				NpcModel = NpcModel;
				UserPrompt = inputText;
			});

			Debugger:StudioLog("UserPrompt dialogPacket", dialogPacket);
			Interface:OnDialogue(dialogPacket);
		end
	end
end)

return Interface;