local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local timerRadialConfig = '{"version":1,"size":128,"count":128,"columns":8,"rows":8,"images":["rbxassetid://10606346824","rbxassetid://10606347195"]}';

--== Variables;
local Interface = {};

local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modCardGame = require(game.ReplicatedStorage.Library.CardGame);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local modRadialImage = require(game.ReplicatedStorage.Library.UI.RadialImage);
local remoteCardGame = modRemotesManager:Get("CardGame");
	
local mainFrame = script.Parent.Parent:WaitForChild("CardGameFrame");

local templatePlayRequest = script:WaitForChild("templatePlayRequest");
local templatePlayerPanel = script:WaitForChild("templatePlayerPlanel");

local branchColor = modBranchConfigs.BranchColor

--== Script;
Interface.LeaveMatchDebounce = tick();

function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local characterModule = modData:GetModCharacter();
	
	local cardViewport = mainFrame:WaitForChild("CardViewport");
	local cardWorldModel = cardViewport:WaitForChild("WorldModel");
	local cardsToolPrefab = cardWorldModel:WaitForChild("cardgame");
	local pickedCardsModel = cardWorldModel:WaitForChild("pickedCards");
	
	
	local viewportCam = workspace.CurrentCamera;

	local buttonBackground = mainFrame:WaitForChild("ButtonBackground");
	local actionButton = mainFrame:WaitForChild("actionButton");
	local bluffButton = mainFrame:WaitForChild("bluffButton");
	local playersFrame = mainFrame:WaitForChild("Players");
	local timerBar = mainFrame:WaitForChild("timerRadialBar");
	local broadcastLabel = mainFrame:WaitForChild("broadcastLabel");
	local resourceLabel = mainFrame:WaitForChild("resourceLabel");
	local radialBar = modRadialImage.new(timerRadialConfig, timerBar);
	
	local templateCardPrefab = script:WaitForChild("CardPart");
	local templateActionButton = actionButton:Clone();

	local playerPanelsList = {};
	local spectatorsList = {};

	local onPlayerSelect;
	local inputBeganClick = false;
	
	local function refreshButtonsPanel()
		local buttonsVisible = mainFrame.actionButton.Visible or mainFrame.bluffButton.Visible;

		buttonBackground.Visible = buttonsVisible or timerBar.Visible;
		if not buttonsVisible and timerBar.Visible then
			buttonBackground.Size = UDim2.new(0, 40, 0, 40);
		else
			buttonBackground.Size = UDim2.new(0, 450, 0, 40);
		end
	end
	
	local window = Interface.NewWindow("CardGameWindow", mainFrame);
	window.IgnoreHideAll = true;
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	
	window.OnWindowToggle:Connect(function(visible)
		if visible then
			if Interface.Windows.StatusBar then
				Interface.Windows.StatusBar:Close();
			end
			task.spawn(function()
				local localEndTime, newEndTime;
				
				while window.Visible do
					RunService.RenderStepped:Wait();

					local lobby = Interface.GameData and Interface.GameData.Lobby;
					if lobby == nil then continue end;
					
					local localWieldModel = localPlayer.Character:FindFirstChild("fotlcardgame");
					local pivotCFrame 
					
					cardViewport.CurrentCamera = workspace.CurrentCamera;
					
					
					if Interface.CardPrefabsList then
						local mousePosition = UserInputService:GetMouseLocation();
						local xRatio = math.clamp(mousePosition.X/viewportCam.ViewportSize.X, 0, 1)*2 -1;
						local yRatio = math.clamp(mousePosition.Y/viewportCam.ViewportSize.Y, 0, 1)*2 -1.5;

						local unitRay = viewportCam:ViewportPointToRay(mousePosition.X, mousePosition.Y, 0);
						local raycastResult = cardWorldModel:Raycast(unitRay.Origin, unitRay.Direction*128);
						
						local hitPart = raycastResult and raycastResult.Instance;
						
						local cardPrefabsList = Interface.CardPrefabsList;
						local countSelected = 0;
						for a=1, #cardPrefabsList do
							local cardPart = cardPrefabsList[a];
							
							if inputBeganClick and hitPart == cardPart then
								if hitPart:GetAttribute("Selected") == true then
									hitPart:SetAttribute("Selected", false);
								else
									hitPart:SetAttribute("Selected", true);

								end
							end
							
							local pivotCFrame = viewportCam.CFrame:ToWorldSpace(CFrame.new(((a-0.5) - #cardPrefabsList/2) * 0.8, 
								-0.2, -2.8 + (cardPart:GetAttribute("Selected") == true and 0.2 or (hitPart == cardPart and 0.05 or 0))) 
									* CFrame.Angles(math.rad(90) + yRatio *0.2, math.rad(180), xRatio *0.2));

							cardPart.CFrame = pivotCFrame;

							local playerTable;
							for a=1, #lobby.Players do
								if lobby.Players[a].Player == localPlayer then
									playerTable = lobby.Players[a];
									break;
								end
							end
							
							--== Card selection;
							local cardSwitchSelected = false;
							local selectedCount = {};

							for a=1, #cardPrefabsList do
								if cardPrefabsList[a]:GetAttribute("Selected") == true then
									table.insert(selectedCount, cardPrefabsList[a].Name);

									if #selectedCount >= #playerTable.Cards then
										Debugger:Log("Selected enough cards", selectedCount, #selectedCount, playerTable.Cards, #playerTable.Cards);
										cardSwitchSelected = true;
										break;
									end
								end
							end

							if cardSwitchSelected then
								cardViewport:TweenPosition(UDim2.new(0.5, 0, 1.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 1, true);

								local pingTick = tick();
								local rPacket = remoteCardGame:InvokeServer("pickcards", {
									StageIndex = lobby.StageIndex;
									PickedCards = selectedCount;
								});
								if rPacket.NewCards then
									playerTable.Cards = rPacket.NewCards;
								end
								local pingLapsed = tick()-pingTick;
								task.wait(math.clamp(1-pingLapsed, 0.5, 1));

								pickedCardsModel:ClearAllChildren();
								Interface.CardPrefabsList = nil;

								cardViewport:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 1, true);
							end
							
							
							if Interface.CardPrefabsList == nil then break end;
						end
						
						cardsToolPrefab:PivotTo(CFrame.new(0, 10000, 0));
						
					else
						if localWieldModel and characterModule.CharacterProperties.FirstPersonCamera then
							pivotCFrame = localWieldModel:GetPivot();

						else
							local mousePosition = UserInputService:GetMouseLocation();
							local xRatio = math.clamp(mousePosition.X/viewportCam.ViewportSize.X, 0, 1)*2 -1;
							local yRatio = math.clamp(mousePosition.Y/viewportCam.ViewportSize.Y, 0, 1)*2 -1.5;
							pivotCFrame = viewportCam.CFrame:ToWorldSpace(CFrame.new(0, -1.4, -2.8) * CFrame.Angles(math.rad(90) + yRatio *0.2, math.rad(180), xRatio *0.2));

						end

						cardsToolPrefab:PivotTo(pivotCFrame);
						
					end
					
					--==
					if lobby.RadialStartTime and lobby.RadialEndTime then
						local duration = lobby.RadialEndTime-lobby.RadialStartTime;
						local localTime = DateTime.now().UnixTimestampMillis;
						
						if newEndTime ~= lobby.RadialEndTime then
							newEndTime = lobby.RadialEndTime;
							localEndTime = localTime + duration;
						end
						
						local timeLeft = localEndTime - localTime;
						local ratio = 1-math.clamp(timeLeft/duration, 0, 1);
						
						if ratio > 0 and ratio < 1 then
							radialBar:UpdateLabel(ratio);
							timerBar.Visible = true;

						else
							timerBar.Visible = false;

						end
					end
					
					refreshButtonsPanel();
					
					inputBeganClick = false;
				end
			end)
			
		else
			if Interface.Windows.StatusBar then
				Interface.Windows.StatusBar:Open();
			end
			
		end
	end)
	
	Interface.Garbage:Tag(UserInputService.InputBegan:Connect(function(inputObj)
		if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
			inputBeganClick = true;
			
		elseif inputObj.UserInputType == Enum.UserInputType.Touch then
			inputBeganClick = true;
			
		end
		
	end))
	
	local closeDebounce = tick();
	mainFrame:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		local promptWindow = Interface:PromptQuestion("Leave Match?",
			"Are you sure you want to leave this match?", 
			"Leave", "Cancel", "rbxassetid://10862651147");
		local YesClickedSignal, NoClickedSignal;

		YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
			Interface:PlayButtonClick();
			
			Interface.LeaveMatchDebounce = tick();
			task.spawn(function()
				local rPacket = remoteCardGame:InvokeServer("leave");
			end)
			Interface:CloseWindow("CardGameWindow");
			
			promptWindow:Close();
			promptWindow = nil;

			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
		NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
			Interface:PlayButtonClick();
			promptWindow:Close();
			promptWindow = nil;

			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
	end)
	
	local function onActionClicked(param)
		Interface:PlayButtonClick();
		
		local lobby = param.Lobby;
		local optionIndex =  param.OptionIndex;
		local optionLib = modCardGame.ActionOptions[optionIndex];
		
		if optionLib.PickCards then
			local playerTable = lobby.Players[lobby.TurnIndex];

			mainFrame.actionButton.Visible = false;
			mainFrame.bluffButton.Visible = false;
			
			cardViewport:TweenPosition(UDim2.new(0.5, 0, 1.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 1, true);
			
			local pingTick = tick();
			local rPacket = remoteCardGame:InvokeServer("pickcards", {
				StageIndex = lobby.StageIndex;
				OptionIndex = optionIndex;
			});
			local pingLapsed = tick()-pingTick;
			task.wait(math.clamp(1-pingLapsed, 0.5, 1));
			
			local pickedCards = playerTable.Cards;
			for a=1, 2 do
				table.insert(pickedCards, rPacket.PickedCards[a]);
			end
			
			Debugger:Log("PickedCards", pickedCards);

			pickedCardsModel:ClearAllChildren();
			
			local cardPrefabsList = {};
			local c = 0;
			for _, cardType in pairs(pickedCards) do
				c = c+1;
				
				local cardLib = modCardGame.Cards[cardType];
				
				local newCardPrefab = templateCardPrefab:Clone();
				newCardPrefab.Name = cardType;
				newCardPrefab.TextureID = cardLib.Texture;
				newCardPrefab.Parent = pickedCardsModel;
				table.insert(cardPrefabsList, newCardPrefab);
				
			end

			Interface.CardPrefabsList = cardPrefabsList;
			task.wait();
			cardViewport:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 1, true);
			
			
		elseif optionLib.SelectTarget then
			onPlayerSelect = function(player)
				mainFrame.actionButton.Visible = false;
				mainFrame.bluffButton.Visible = false;
				
				task.spawn(function()
					local rPacket = remoteCardGame:InvokeServer("playaction", {
						StageIndex = lobby.StageIndex;
						OptionIndex = optionIndex;
						TargetPlayer = player;
					});
				end)
			end
			
			for player, panel in pairs(playerPanelsList) do
				local cantSelectText;
				for _, pT in pairs(lobby.Players) do
					if pT.Player == player then
						
						if optionLib.RequiresTargetResources and pT.R <= 0 then
							cantSelectText = "No Resources";
						end
						
						break;
					end
				end
				
				if cantSelectText == nil then
					panel.selectButton.Text = "Select";
					panel.selectButton.BackgroundColor3 = actionButton.BackgroundColor3;
					
				else
					panel.selectButton.Text = cantSelectText;
					panel.selectButton.BackgroundColor3 = bluffButton.BackgroundColor3;
					
				end
				panel.selectButton.Visible = true;
				panel.selectButton.Size = UDim2.new(1.35, 0, 0, 50);
				panel.selectButton:TweenSize(UDim2.new(1, 0, 0, 30), Enum.EasingDirection.InOut, Enum.EasingStyle.Bounce, 0.5, true);
			end
			
		else
			mainFrame.actionButton.Visible = false;
			mainFrame.bluffButton.Visible = false;
			
			task.spawn(function()
				local rPacket = remoteCardGame:InvokeServer("playaction", {
					StageIndex = lobby.StageIndex;
					OptionIndex = optionIndex;
				});
			end)
		end
	end
	
	Interface.Garbage:Tag(mainFrame.actionButton.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();
		local lobby = modCardGame.LoadLobby(Interface.GameData.Lobby);
		
		if lobby.State == modCardGame.GameState.Idle then
			mainFrame.actionButton.Visible = false;
			mainFrame.bluffButton.Visible = false;
			task.spawn(function()
				local rPacket = remoteCardGame:InvokeServer("startgame");
			end)
			
		elseif lobby.State == modCardGame.GameState.Active then
			if lobby.TurnIndex then
				local turnPlayerTable = lobby.Players[lobby.TurnIndex];

				local stageInfo = lobby.Stage;
				Debugger:Log("action Stage", lobby.Stage);

				if stageInfo.Type == modCardGame.StageType.NextTurn and turnPlayerTable.Player == localPlayer then
					for _, panel in pairs(playerPanelsList) do
						panel.selectButton.Visible = false;
					end

					for _, obj in pairs(mainFrame.bluffButton:GetChildren()) do
						if obj:IsA("GuiObject") then
							game.Debris:AddItem(obj, 0);
						end
					end

					for a=1, #modCardGame.ActionOptions do
						local optionLib = modCardGame.ActionOptions[a];

						local cardInfo = optionLib.Requires and modCardGame.Cards[optionLib.Requires];
						local hasCard = table.find(turnPlayerTable.Cards, optionLib.Requires);

						if optionLib.Requires == nil or hasCard then
							local newButton = templateActionButton:Clone();

							newButton.Text = optionLib.Text;

							if cardInfo then
								newButton.BackgroundColor3 = cardInfo.Color;

							else
								newButton.BackgroundColor3 = actionButton.BackgroundColor3;

							end

							if optionLib.Cost and turnPlayerTable.R < optionLib.Cost then
								newButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60);
							end
							if optionLib.SpaceCost and turnPlayerTable.R+optionLib.SpaceCost > 10 then
								newButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60);
							end

							newButton.MouseButton1Click:Connect(function()
								if optionLib.Cost and turnPlayerTable.R < optionLib.Cost then
									return;
								end
								if optionLib.SpaceCost and turnPlayerTable.R+optionLib.SpaceCost > 10 then
									return;
								end

								onActionClicked{
									Lobby = lobby;
									OptionIndex = a;
								}
							end)

							newButton.Visible = true;
							newButton.Parent = mainFrame.actionButton;
						end
					end

				elseif (stageInfo.Type == modCardGame.StageType.Dispute or stageInfo.Type == modCardGame.StageType.SwapCards)
					and ((stageInfo.TargettedPlayer == nil and turnPlayerTable.Player ~= localPlayer)
						or stageInfo.TargettedPlayer == localPlayer) then
					
					mainFrame.actionButton.Visible = false;
					mainFrame.bluffButton.Visible = false;

					Debugger:Log("accept action");
					task.spawn(function()
						local rPacket = remoteCardGame:InvokeServer("decideaction", {
							StageIndex = lobby.StageIndex;
							CallBluff = false;
						});
					end)

				elseif stageInfo.Type == modCardGame.StageType.BluffConclusion and stageInfo.Loser == localPlayer then
					Debugger:Log("BluffConclusion card 1")
					mainFrame.actionButton.Visible = false;
					mainFrame.bluffButton.Visible = false;
					task.spawn(function()
						local rPacket = remoteCardGame:InvokeServer("fold", {
							StageIndex = lobby.StageIndex;
							FoldCard = 1;
						});
						if rPacket.NewCards then
							for a=1, #lobby.Players do
								if lobby.Players[a].Player == localPlayer then
									lobby.Players[a].Cards = rPacket.NewCards;
									break;
								end
							end
						end
					end)
					
				elseif stageInfo.Type == modCardGame.StageType.Sacrifice and stageInfo.TargettedPlayer == localPlayer then
					Debugger:Log("Sacrifice card 1")
					
					mainFrame.actionButton.Visible = false;
					mainFrame.bluffButton.Visible = false;
					task.spawn(function()
						local rPacket = remoteCardGame:InvokeServer("fold", {
							StageIndex = lobby.StageIndex;
							FoldCard = 1;
						});
						if rPacket.NewCards then
							for a=1, #lobby.Players do
								if lobby.Players[a].Player == localPlayer then
									lobby.Players[a].Cards = rPacket.NewCards;
									break;
								end
							end
						end
					end)

				elseif stageInfo.Type == modCardGame.StageType.AttackDispute and stageInfo.Victim == localPlayer then
					Debugger:Log("block attack")
					mainFrame.actionButton.Visible = false;
					mainFrame.bluffButton.Visible = false;

					task.spawn(function()
						local rPacket = remoteCardGame:InvokeServer("attackdispute", {
							StageIndex = lobby.StageIndex;
							AttackDisputeChoice = 1;
						});
					end)
					
				end
			end
			
		elseif lobby.State == modCardGame.GameState.End then
			mainFrame.actionButton.Visible = false;
			mainFrame.bluffButton.Visible = false;

			task.spawn(function()
				local rPacket = remoteCardGame:InvokeServer("newmatch");
			end)
			
		end
	end));
	
	Interface.Garbage:Tag(mainFrame.bluffButton.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();
		local lobby = modCardGame.LoadLobby(Interface.GameData.Lobby);
		
		if lobby.State == modCardGame.GameState.Active then

			if lobby.TurnIndex then
				local turnPlayerTable = lobby.Players[lobby.TurnIndex];

				local stageInfo = lobby.Stage;
				Debugger:Log("bluff Stage", lobby.Stage);

				if stageInfo.Type == modCardGame.StageType.NextTurn and turnPlayerTable.Player == localPlayer then
					for _, panel in pairs(playerPanelsList) do
						panel.selectButton.Visible = false;
					end

					for _, obj in pairs(mainFrame.actionButton:GetChildren()) do
						if obj:IsA("GuiObject") then
							game.Debris:AddItem(obj, 0);
						end
					end

					for a=1, #modCardGame.ActionOptions do
						local optionLib = modCardGame.ActionOptions[a];

						local cardInfo = optionLib.Requires and modCardGame.Cards[optionLib.Requires];
						local hasCard = table.find(turnPlayerTable.Cards, optionLib.Requires);

						if cardInfo and not hasCard then
							local newButton = templateActionButton:Clone();

							newButton.Text = optionLib.Text;

							if cardInfo then
								newButton.BackgroundColor3 = cardInfo.Color;
							else
								newButton.BackgroundColor3 = bluffButton.BackgroundColor3;
							end

							if optionLib.Cost and turnPlayerTable.R < optionLib.Cost then
								newButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60);
							end
							
							if optionLib.SpaceCost and turnPlayerTable.R+optionLib.SpaceCost > 10 then
								newButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60);
							end
							
							newButton.MouseButton1Click:Connect(function()
								if optionLib.Cost and turnPlayerTable.R < optionLib.Cost then
									return;
								end
								if optionLib.SpaceCost and turnPlayerTable.R+optionLib.SpaceCost > 10 then
									return;
								end

								onActionClicked{
									Lobby = lobby;
									OptionIndex = a;
								}
							end)

							newButton.Visible = true;
							newButton.Parent = mainFrame.bluffButton;
						end
					end

				elseif (stageInfo.Type == modCardGame.StageType.Dispute or stageInfo.Type == modCardGame.StageType.SwapCards)
					and ((stageInfo.TargettedPlayer == nil and turnPlayerTable.Player ~= localPlayer)
						or stageInfo.TargettedPlayer == localPlayer) then
					
					mainFrame.actionButton.Visible = false;
					mainFrame.bluffButton.Visible = false;
					
					Debugger:Log("call bluff")
					task.spawn(function()
						local rPacket = remoteCardGame:InvokeServer("decideaction", {
							StageIndex = lobby.StageIndex;
							CallBluff = true;
						});
					end)

				elseif stageInfo.Type == modCardGame.StageType.BluffConclusion and stageInfo.Loser == localPlayer then
					Debugger:Log("BluffConclusion card 2")
					mainFrame.actionButton.Visible = false;
					mainFrame.bluffButton.Visible = false;
					task.spawn(function()
						local rPacket = remoteCardGame:InvokeServer("fold", {
							StageIndex = lobby.StageIndex;
							FoldCard = 2;
						});
						if rPacket.NewCards then
							for a=1, #lobby.Players do
								if lobby.Players[a].Player == localPlayer then
									lobby.Players[a].Cards = rPacket.NewCards;
									break;
								end
							end
						end
					end)
					
				elseif stageInfo.Type == modCardGame.StageType.Sacrifice and stageInfo.TargettedPlayer == localPlayer then
					Debugger:Log("Sacrifice card 2")
					mainFrame.actionButton.Visible = false;
					mainFrame.bluffButton.Visible = false;
					task.spawn(function()
						local rPacket = remoteCardGame:InvokeServer("fold", {
							StageIndex = lobby.StageIndex;
							FoldCard = 2;
						});
						if rPacket.NewCards then
							for a=1, #lobby.Players do
								if lobby.Players[a].Player == localPlayer then
									lobby.Players[a].Cards = rPacket.NewCards;
									break;
								end
							end
						end
					end)
					
				elseif stageInfo.Type == modCardGame.StageType.AttackDispute and stageInfo.Victim == localPlayer then
					Debugger:Log("bluff BlockAttack")
					mainFrame.actionButton.Visible = false;
					mainFrame.bluffButton.Visible = false;

					task.spawn(function()
						local rPacket = remoteCardGame:InvokeServer("attackdispute", {
							StageIndex = lobby.StageIndex;
							AttackDisputeChoice = 2;
						});
					end)
					
				end
			end
			
		end
	end));

	Interface.Garbage:Tag(mainFrame.actionButton:GetPropertyChangedSignal("Visible"):Connect(function()
		if mainFrame.actionButton.Visible == false then
			for _, obj in pairs(mainFrame.actionButton:GetChildren()) do
				if obj:IsA("GuiObject") then
					game.Debris:AddItem(obj, 0);
				end
			end
		end
	end))
	Interface.Garbage:Tag(mainFrame.bluffButton:GetPropertyChangedSignal("Visible"):Connect(function()
		if mainFrame.bluffButton.Visible == false then
			for _, obj in pairs(mainFrame.bluffButton:GetChildren()) do
				if obj:IsA("GuiObject") then
					game.Debris:AddItem(obj, 0);
				end
			end
		end
	end))
	
	function Interface.Update()
		if Interface.GameData == nil then return end;
		
		local lobby = modCardGame.LoadLobby(Interface.GameData.Lobby);
		
		if lobby.BroadcastMsg then
			local bMsg = lobby.BroadcastMsg.Text;
			
			if bMsg then
				for a=1, #lobby.Players do
					local playerTable = lobby.Players[a];
					bMsg = string.gsub(bMsg, playerTable.Player.Name, "<b><font color='rgb(135, 193, 255)'>" ..tostring(playerTable.Player.Name).. "</font></b>");
				end
				
				for cardKey, cardInfo in pairs(modCardGame.Cards) do
					bMsg = string.gsub(bMsg, cardKey, "<b><font color='#" ..cardInfo.Color:ToHex() .. "'>" ..cardKey.. "</font></b>");
				end
				
				if lobby.BroadcastMsg.ActionId then
					local actionId = lobby.BroadcastMsg.ActionId; 
					
					if actionId == 1 then
						broadcastLabel.TextColor3 = Color3.fromRGB(224, 255, 199);
						
					elseif actionId == 2 then
						broadcastLabel.TextColor3 = Color3.fromRGB(255, 166, 166);

					elseif actionId == 3 then
						broadcastLabel.TextColor3 = Color3.fromRGB(255, 166, 166);

					elseif actionId == 4 then
						broadcastLabel.TextColor3 = Color3.fromRGB(198, 223, 150);

					elseif actionId == 5 then
						broadcastLabel.TextColor3 = Color3.fromRGB(255, 172, 137);
						
					elseif actionId == 6 then
						broadcastLabel.TextColor3 = Color3.fromRGB(198, 152, 255);
						
					elseif actionId == 7 then
						broadcastLabel.TextColor3 = Color3.fromRGB(162, 255, 201);
						
					end
					
				else
					broadcastLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
					
				end
				
				if lobby.BroadcastMsg.SndId then
					modAudio.Preload(lobby.BroadcastMsg.SndId, 5);
					modAudio.Play(lobby.BroadcastMsg.SndId, nil, nil, false);
				end
				
				broadcastLabel.Text = bMsg;
				
			else
				broadcastLabel.Text = "";
				
			end
		else
			broadcastLabel.Text = "";
		end
		
		local updatedPanel = {};
		
		local localPlayerTable;
		
		for a=1, #lobby.Players do
			local playerTable = lobby.Players[a];
			if playerTable.Player == localPlayer then
				localPlayerTable = playerTable;
				continue;
			end
			
			local playerPanel = playerPanelsList[playerTable.Player];
			if playerPanel == nil then
				playerPanel = templatePlayerPanel:Clone();
				
				local selectButton = playerPanel:WaitForChild("selectButton");
				selectButton.MouseButton1Click:Connect(function()
					if selectButton.Text ~= "Select" then Debugger:Log("Cannot select", playerTable.Player); return end;
					Interface:PlayButtonClick();
					selectButton.Visible = false;
					if onPlayerSelect then
						onPlayerSelect(playerTable.Player);
						
					else
						Debugger:Log("Missing onPlayerSelect");
						
					end
				end)
			end
			playerPanelsList[playerTable.Player] = playerPanel;
			
			local nameLabel = playerPanel:WaitForChild("nameLabel");
			nameLabel.Text = playerTable.Player.Name;
			
			local resourceLabel = playerPanel:WaitForChild("resourceLabel");
			resourceLabel.Text = "Waiting";
			
			
			playerPanel.LayoutOrder = a;
			playerPanel.Parent = playersFrame;
			
			table.insert(updatedPanel, playerPanel);
		end
		

		if lobby.State == modCardGame.GameState.Idle then
			if lobby.Host == localPlayer then
				for a=1, #lobby.Spectators do
					local playerTable = lobby.Spectators[a];

					local requestPanel = spectatorsList[playerTable.Player];
					if requestPanel == nil then
						requestPanel = templatePlayRequest:Clone();

						local acceptButton = requestPanel:WaitForChild("acceptButton");
						acceptButton.MouseButton1Click:Connect(function()
							Interface:PlayButtonClick();
							requestPanel.Visible = false;
							requestPanel:SetAttribute("RefreshTick", tick());

							local rPacket = remoteCardGame:InvokeServer("acceptrequest", {AcceptPlayer=playerTable.Player;});
						end)

						local denyButton = requestPanel:WaitForChild("denyButton");
						denyButton.MouseButton1Click:Connect(function()
							Interface:PlayButtonClick();
							requestPanel.Visible = false;
							requestPanel:SetAttribute("RefreshTick", tick());
						end)

					end
					spectatorsList[playerTable.Player] = requestPanel;

					if requestPanel.Visible == false and requestPanel:GetAttribute("RefreshTick") and tick()-requestPanel:GetAttribute("RefreshTick") >= 5 then
						requestPanel.Visible = true;
					end

					local nameLabel = requestPanel:WaitForChild("nameLabel");
					nameLabel.Text = playerTable.Player.Name .."'s requesting to play";

					requestPanel.LayoutOrder = a+10;
					requestPanel.Parent = playersFrame;

					table.insert(updatedPanel, requestPanel);
					if #updatedPanel > 3 then
						break;
					end
				end
				
				if lobby.CanStart then
					actionButton.Text = "Start";
					actionButton.Visible = true;
				end
			end

		elseif lobby.State == modCardGame.GameState.Active then

			if lobby.TurnIndex then
				local turnPlayerTable = lobby.Players[lobby.TurnIndex]; -- player of this turn;
				local localPlayerTable; 
				
				for _, playerTable in pairs(lobby.Players) do
					if playerTable.Player == localPlayer then
						localPlayerTable = playerTable;
						
					end
					
					local panel = playerPanelsList[playerTable.Player];
					if panel then
						local nameLabel = panel:WaitForChild("nameLabel");

						if turnPlayerTable and playerTable.Player == turnPlayerTable.Player then
							nameLabel.TextColor3 = branchColor
						else
							nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
						end
						
						local resourceLabel = panel:WaitForChild("resourceLabel");
						if #playerTable.Cards > 0 then
							resourceLabel.Text = (playerTable.R or 0) .. "/10";
						else
							resourceLabel.Text = "Defeated";
						end

						local cardLImage = panel:WaitForChild("CardL");
						cardLImage.Visible = #playerTable.Cards > 0

						local cardRImage = panel:WaitForChild("CardR");
						cardRImage.Visible = #playerTable.Cards > 1;
					end
				end
				
				if localPlayerTable then
					-- Local player;
					local cardLInfo = modCardGame.Cards[localPlayerTable.Cards[1]];
					local cardRInfo = modCardGame.Cards[localPlayerTable.Cards[2]];
					
					if cardLInfo then
						cardWorldModel.cardgame.CardL.Transparency = 0;
						cardWorldModel.cardgame.CardL.TextureID = cardLInfo.Texture;
					else
						cardWorldModel.cardgame.CardL.Transparency = 1;
					end
					
					if cardRInfo then
						cardWorldModel.cardgame.CardR.Transparency = 0;
						cardWorldModel.cardgame.CardR.TextureID = cardRInfo.Texture;
					else
						cardWorldModel.cardgame.CardR.Transparency = 1;
					end
					
					cardViewport.Visible = true;
					
					resourceLabel.Text = (localPlayerTable.R or 0) .. "/10";
					resourceLabel.Visible = true;
					

					local stageInfo = lobby.Stage;

					for _, panel in pairs(playerPanelsList) do
						panel.selectButton.Visible = false;
					end
					
					if stageInfo.Type == modCardGame.StageType.NextTurn and turnPlayerTable.Player == localPlayer then
						actionButton.Visible = true;
						bluffButton.Visible = true;
						actionButton.Text = "Action";
						bluffButton.Text = "Bluff";
						
					elseif stageInfo.Type == modCardGame.StageType.Dispute 
						and ((stageInfo.TargettedPlayer == nil and turnPlayerTable.Player ~= localPlayer)
							or stageInfo.TargettedPlayer == localPlayer) then
						actionButton.Visible = true;
						bluffButton.Visible = true;
						actionButton.Text = "Accept Action";
						bluffButton.Text = "Call Bluff";

					elseif stageInfo.Type == modCardGame.StageType.Sacrifice and stageInfo.TargettedPlayer == localPlayer then
						actionButton.Visible = true;
						bluffButton.Visible = true;

						actionButton.Text = "Sacrifice ".. tostring(localPlayerTable.Cards[1]);
						bluffButton.Text = "Sacrifice ".. tostring(localPlayerTable.Cards[2]);
						
					elseif stageInfo.Type == modCardGame.StageType.AttackDispute and stageInfo.Victim == localPlayer then
						if #localPlayerTable.Cards > 1 then
							actionButton.Visible = true;
							bluffButton.Visible = true;
							
							if table.find(localPlayerTable.Cards, "Zombie") then
								actionButton.Text = "Zombie Block Attack";
								bluffButton.Text = "Surrender";

							else
								actionButton.Text = "Surrender";
								bluffButton.Text = "Bluff Zombie Block";

							end
							
						else
							actionButton.Visible = true;
							if table.find(localPlayerTable.Cards, "Zombie") then
								actionButton.Text = "Zombie Block Attack";
								
							else
								actionButton.Text = "Bluff Zombie Block";
								
							end
							
						end
						
					elseif stageInfo.Type == modCardGame.StageType.SwapCards and turnPlayerTable.Player ~= localPlayer then
						actionButton.Visible = true;
						bluffButton.Visible = true;
						actionButton.Text = "Accept Action";
						bluffButton.Text = "Call Bluff";

					elseif stageInfo.Type == modCardGame.StageType.BluffConclusion and stageInfo.Loser == localPlayer and #localPlayerTable.Cards >= 2 then
						actionButton.Visible = true;
						bluffButton.Visible = true;

						actionButton.Text = "Surrender "..localPlayerTable.Cards[1];
						bluffButton.Text = "Surrender "..localPlayerTable.Cards[2];
						
					else
						actionButton.Visible = false;
						bluffButton.Visible = false;
						
					end

				else
					cardViewport.Visible = false;
					resourceLabel.Visible = false;
					actionButton.Visible = false;
					bluffButton.Visible = false;
					
				end
				
			end

		elseif lobby.State == modCardGame.GameState.End then
			cardViewport.Visible = false;
			resourceLabel.Visible = false;
			actionButton.Visible = false;
			bluffButton.Visible = false;
			
			if lobby.Host == localPlayer then
				actionButton.Visible = true;
				actionButton.Text = "New Match";
			end
			
		end
		
		for player, panel in pairs(spectatorsList) do
			if table.find(updatedPanel, panel) == nil then
				spectatorsList[player] = nil;
				game.Debris:AddItem(panel, 0);
			end
		end
		for player, panel in pairs(playerPanelsList) do
			if table.find(updatedPanel, panel) == nil then
				playerPanelsList[player] = nil;
				game.Debris:AddItem(panel, 0);
			end
		end
	end
	
	function remoteCardGame.OnClientInvoke(action, packet)
		if tick()-Interface.LeaveMatchDebounce <= 5 then return end;
		
		if action == "sync" then
			Interface.GameData = packet;
			
		elseif action == "swapcards" then
			cardViewport:TweenPosition(UDim2.new(0.5, 0, 1.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.5, true);

			local lobby = Interface.GameData and Interface.GameData.Lobby;
			if lobby == nil then return end;
			
			local playerTable;
			for a=1, #lobby.Players do
				if lobby.Players[a].Player == localPlayer then
					playerTable = lobby.Players[a];
					break;
				end
			end
			playerTable.Cards = packet;
			task.wait(0.5);

			pickedCardsModel:ClearAllChildren();
			Interface.CardPrefabsList = nil;

			cardViewport:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 1, true);
			
		end
		
		if window.Visible == false then
			window:Open();
		end
		Interface.Update();
	end
	
	return Interface;
end;

--Interface.Garbage is only initialized after .init();
return Interface;