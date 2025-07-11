local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));
local modItem = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBlueprintLibrary = shared.require(game.ReplicatedStorage.Library.BlueprintLibraryRotd);
local modSyncTime = shared.require(game.ReplicatedStorage.Library:WaitForChild("SyncTime"));
local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modRichFormatter = shared.require(game.ReplicatedStorage.Library.UI.RichFormatter);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local processTypeNames = {
	Building = "Building";
	BuildComplete = "Build Completed";
	Deconstruction = "Deconstruction";
	PolishTool = "PolishTool";
}

local WorkbenchClass = {};
--==


function WorkbenchClass.init(interface: InterfaceInstance, workbenchWindow: InterfaceWindow)
	local modData = shared.require(localPlayer:WaitForChild("DataModule"));
	local binds = workbenchWindow.Binds;

	local processTemplate = script:WaitForChild("processFrame");

	local remoteDeconstruct = modRemotesManager:Get("DeconstructItem");
	local remotePolishTool = modRemotesManager:Get("PolishTool");
	local remoteBlueprintHandler = modRemotesManager:Get("BlueprintHandler");

	local refreshFunc;
	interface.Garbage:Tag(modData.OnDataEvent:Connect(function(action, hierarchyKey, data)
		if action ~= "sync" or hierarchyKey ~= "GameSave/Workbench" then return end;

		if refreshFunc ~= nil then
			refreshFunc();
		end
	end))

	local activeSyncs = {};
	interface.Garbage:Tag(modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
		local Time = modSyncTime.GetTime();
		for a=#activeSyncs, 1, -1 do
			local sync = activeSyncs[a];
			local i = a;
			if type(sync) == "function" then
				spawn(function()
					local keep = sync(Time);
					if keep ~= true then
						table.remove(activeSyncs, i);
					end
				end)
			end
		end
	end))

	function WorkbenchClass.new(itemId, library, storageItem)
		binds.ClearPages("processList");
		local listMenu = binds.List.create();
		listMenu.Menu.Name = "processList";
		listMenu:SetListPadding(UDim2.new(1, 0, 1, -20));
		listMenu:SetEnableScrollBar(false);
		listMenu:SetEnableSearchBar(false);

		local processList = binds.GetProcesses();
		local cateList = {};
		
		local function refreshProcessPage()
			processList = binds.GetProcesses();
			
			binds.ClearPages("processList");
			binds.ActiveWorkbenches.Processes = binds.Workbenches.Processes.Workbench.new();
			binds.RefreshNavigations();
			binds.SetPage(binds.ActiveWorkbenches.Processes.Menu);
		end
		refreshFunc = refreshProcessPage;
		
		local order = 0;
		for a=1, #processList do
			local process = processList[a];
			local newProcessFrame = processTemplate:Clone();
			local coreListLayout = newProcessFrame:WaitForChild("UIListLayout");
			local titleTag = newProcessFrame:WaitForChild("titleTag");
			local barFrame = newProcessFrame:WaitForChild("BarFrame");
			local progressBar = barFrame:WaitForChild("Bar");
			local timeTag = barFrame:WaitForChild("TimeTag");
			
			local buttonsFrame = newProcessFrame:WaitForChild("ButtonFrame");
			local cancelButton = buttonsFrame:WaitForChild("CancelButton");
			local cancelingBar = cancelButton:WaitForChild("Bar");
			local claimButton = buttonsFrame:WaitForChild("ClaimButton");
			local skipButton = buttonsFrame:WaitForChild("SkipButton");
			
			if cateList[process.Type] == nil then
				cateList[process.Type] = listMenu:NewBasicList()
				cateList[process.Type].Name = process.Type.."list"
				local newCateTab = listMenu:NewTab(cateList[process.Type]);
				newCateTab.titleLabel.Text = (processTypeNames[process.Type] or "Process");
				order = order+1;
				listMenu:Add(newCateTab, order);
				order = order+1;
				listMenu:Add(cateList[process.Type], order);
			end
			newProcessFrame.Parent = cateList[process.Type].list;
			newProcessFrame.Name = process.Data.ItemId;
			
			local skipCost = 0;

			local bpLib = modBlueprintLibrary.Get(process.Data.ItemId);
			local function refreshContent(t)
				t = modSyncTime.GetTime();
				
				if newProcessFrame:IsDescendantOf(interface.ScreenGui) then
					if process.Type == "Building" or process.Type == "BuildComplete" then
						titleTag.Text = "Build "..bpLib.Name;
						
						local timeLeft = process.Data.BT-t;
						local buildPercent = math.clamp(1-(timeLeft/bpLib.Duration), 0, 1);
						
						local initTween = progressBar:GetAttribute("initTween");
						if initTween == nil then
							progressBar:SetAttribute("initTween", tick());
							pcall(function()
								progressBar:TweenSize(UDim2.new(buildPercent, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.5, true);
							end);
							
						elseif (tick()-initTween) > 0.5 then
							progressBar.Size = UDim2.new(buildPercent, 0, 1, 0);
							pcall(function()
								progressBar:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, timeLeft, true);
							end);
						end
						
						if buildPercent >= 1 then
							process.Type = "BuildComplete";
						end;
						
						if cateList[process.Type] and cateList[process.Type].Parent ~= nil then
							newProcessFrame.Parent = cateList[process.Type].list;
						end
						if process.Type == "BuildComplete" then
							timeTag.Text = "Build Complete";
							progressBar.Size = UDim2.new(1, 0, 1, 0);
							cancelButton.Visible = false;
							claimButton.Visible = true;
							skipButton.Visible = false;
							skipCost = nil;

						else
							cancelButton.Visible = true;
							claimButton.Visible = false;
							
							skipButton.Visible = true;
							skipCost = modWorkbenchLibrary.GetSkipCost(timeLeft);
							skipButton.Text = "Skip Build ("..skipCost.." Perks)";
							
							timeTag.Text = modSyncTime.ToString(timeLeft > 0 and timeLeft or 0);
						end
						return true;
						
					elseif process.Type == "Deconstruction" then
						local data = process.Data;
						local itemLib = modItem:Find(data.ItemId);
						if itemLib then
							titleTag.Text = "Deconstruct "..itemLib.Name;
							
							local timeLeft = process.Data.T-t;
							local buildPercent = math.clamp(1-(timeLeft/600), 0, 1);

							local initTween = progressBar:GetAttribute("initTween");
							if initTween == nil then
								progressBar:SetAttribute("initTween", tick());
								pcall(function()
									progressBar:TweenSize(UDim2.new(buildPercent, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.5, true);
								end);

							elseif (tick()-initTween) > 0.5 then
								progressBar.Size = UDim2.new(buildPercent, 0, 1, 0);
								pcall(function()
									progressBar:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, timeLeft, true);
								end);
							end
							
							if buildPercent >= 1 then
								timeTag.Text = "Deconstruct Complete";
								progressBar.Size = UDim2.new(1, 0, 1, 0);
								cancelButton.Visible = false;
								claimButton.Visible = true;
							else
								cancelButton.Visible = true;
								claimButton.Visible = false;
								timeTag.Text = modSyncTime.ToString(timeLeft > 0 and timeLeft or 0);
							end
						else
							titleTag.Text = "Unknown item id: "..data.ItemId;
							cancelButton.Visible = false;
							claimButton.Visible = false;
						end
						return true;

					elseif process.Type == "PolishTool" then
						local data = process.Data;
						local itemLib = modItem:Find(data.ItemId);
						if itemLib then
							titleTag.Text = `Polish {itemLib.Name}`;

							local timeLeft = process.Data.T-t;
							local buildPercent = math.clamp(1-(timeLeft/modWorkbenchLibrary.PolishDuration), 0, 1);

							local initTween = progressBar:GetAttribute("initTween");
							if initTween == nil then
								progressBar:SetAttribute("initTween", tick());
								pcall(function()
									progressBar:TweenSize(UDim2.new(buildPercent, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.5, true);
								end);

							elseif (tick()-initTween) > 0.5 then
								progressBar.Size = UDim2.new(buildPercent, 0, 1, 0);
								pcall(function()
									progressBar:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, timeLeft, true);
								end);
							end

							if buildPercent >= 1 then
								timeTag.Text = "Polish Complete";
								progressBar.Size = UDim2.new(1, 0, 1, 0);
								cancelButton.Visible = false;
								claimButton.Visible = true;
								skipButton.Visible = false;

							else
								cancelButton.Visible = true;
								claimButton.Visible = false;
								
								skipButton.Visible = true;
								skipCost = modWorkbenchLibrary.GetSkipCost(timeLeft);
								skipButton.Text = "Skip Polish (".. skipCost .." Perks)";

								timeTag.Text = modSyncTime.ToString(timeLeft > 0 and timeLeft or 0);
							end
						else
							titleTag.Text = "Unknown item id: "..data.ItemId;
							cancelButton.Visible = false;
							claimButton.Visible = false;
						end
						return true;
						
					end
				end
				return;
			end
			
			local open = false;
			newProcessFrame.MouseButton1Click:Connect(function()
				interface:PlayButtonClick();
				if open then
					newProcessFrame:TweenSize(UDim2.new(1, 0, 0, 55), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true);
				else
					newProcessFrame:TweenSize(UDim2.new(1, 0, 0, 
						coreListLayout.AbsoluteContentSize.Y), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true);
				end
				open = not open;
			end)
			
			local actionButtonDebounce = false;
			local cancelInitTick;
			local cancelButtonDown = false;
			
			cancelButton.InputBegan:Connect(function(inputObject, gameProcessed)
				if not gameProcessed and inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
					cancelButtonDown = true;
					cancelInitTick = tick();
					interface:PlayButtonClick();
					local cancelTime = 1;
					RunService:BindToRenderStep("CancelConfirm", Enum.RenderPriority.Input.Value+1, function(delta)
						local cancelPercent = math.clamp((tick()-cancelInitTick)/cancelTime, 0, 1);
						cancelingBar.Size = UDim2.new(cancelPercent, 0, 1, 0);
						if cancelPercent >= 1 and not actionButtonDebounce then
							actionButtonDebounce = true;
							interface:PlayButtonClick();
							cancelButton.Text = "Cancelling";
							RunService:UnbindFromRenderStep("CancelConfirm");
							if process.Type == "Building" or process.Type == "BuildComplete" then

								local rPacket = remoteBlueprintHandler:InvokeServer("cancelbuild", {
									WorkbenchPart = binds.InteractPart;
									Index = process.Index;
								});
								
								if rPacket and rPacket.Success == true then
									cancelButtonDown = false;
									refreshProcessPage();
									
								else
									local failCode = rPacket and rPacket.FailCode;
									cancelButton.Text = modWorkbenchLibrary.BlueprintReplies[failCode] or ("Error Code: "..failCode);
									task.wait(1);
									cancelButton.Text = "Cancel";
									
								end
								
							elseif process.Type == "Deconstruction" then
								local serverReply = remoteDeconstruct:InvokeServer(binds.InteractPart, 3, process.Index);
								if serverReply == modWorkbenchLibrary.DeconstructModReplies.Success then
									cancelButtonDown = false;
									refreshProcessPage();
								else
									cancelButton.Text = modWorkbenchLibrary.DeconstructModReplies[serverReply] or ("Error Code: "..serverReply);
									wait(1);
									cancelButton.Text = "Cancel";
								end
								
							elseif process.Type == "PolishTool" then
								local serverReply = remotePolishTool:InvokeServer(binds.InteractPart, 3, process.Index);
								if serverReply == modWorkbenchLibrary.PolishToolReplies.Success then
									cancelButtonDown = false;
									refreshProcessPage();
								else
									cancelButton.Text = modWorkbenchLibrary.PolishToolReplies[serverReply] or ("Error Code: "..serverReply);
									wait(1);
									cancelButton.Text = "Cancel";
								end
								
							end
							delay(1, function() actionButtonDebounce = false; end);
						else
							cancelButton.Text = "Hold To Cancel";
						end
						if not cancelButtonDown then
							RunService:UnbindFromRenderStep("CancelConfirm");
							cancelingBar.Size = UDim2.new(0, 0, 1, 0);
							delay(0.2, function()
								if cancelButton then cancelButton.Text = "Cancel"; end
							end)
						end
					end)
				end
			end)
				
			cancelButton.InputEnded:Connect(function() 
				cancelButtonDown = false;
			end)
			
			claimButton.MouseButton1Click:Connect(function()
				if actionButtonDebounce then return end;
				actionButtonDebounce = true;
				interface:PlayButtonClick();
				if process.Type == "Building" or process.Type == "BuildComplete" then

					local rPacket = remoteBlueprintHandler:InvokeServer("claimbuild", {
						WorkbenchPart=binds.InteractPart;
						Index=process.Index;
					});
					
					if rPacket and rPacket.Success then
						binds.PlayCollectSound();
						refreshProcessPage();
						
					else
						local failCode = rPacket and rPacket.FailCode;
						claimButton.Text = modWorkbenchLibrary.BlueprintReplies[failCode] or ("Error Code: "..failCode);
						
					end
					
				elseif process.Type == "Deconstruction" then
					local serverReply = remoteDeconstruct:InvokeServer(binds.InteractPart, 2, process.Index);
					if serverReply == modWorkbenchLibrary.DeconstructModReplies.Success then
						cancelButtonDown = false;
						refreshProcessPage();
					else
						cancelButton.Text = modWorkbenchLibrary.DeconstructModReplies[serverReply] or ("Error Code: "..serverReply);
						wait(1);
						cancelButton.Text = "Cancel";
					end

				elseif process.Type == "PolishTool" then

					local serverReply = remotePolishTool:InvokeServer(binds.InteractPart, 2, process.Index);
					if serverReply == modWorkbenchLibrary.PolishToolReplies.Success then
						cancelButtonDown = false;
						refreshProcessPage();
					else
						cancelButton.Text = modWorkbenchLibrary.PolishToolReplies[serverReply] or ("Error Code: "..serverReply);
						wait(1);
						cancelButton.Text = "Cancel";
					end
					
					
				end
				actionButtonDebounce = false;
			end);
			
			skipButton.MouseButton1Click:Connect(function()
				if skipCost == nil then return end;
				interface:PlayButtonClick();
				
				if process.Type == "Building" or process.Type == "BuildComplete" then
					modClientGuis.promptDialogBox({
						Title=`Skip {titleTag.Text}`;
						Desc=`Are you sure you want to skip <b>{titleTag.Text}</b> process with <b>{modRichFormatter.PerkText(skipCost.." Perks")}</b>?`;
						Buttons={
							{
								Text="Skip";
								Style="Confirm";
								OnPrimaryClick=function(dialogWindow, textButton)
                                    local statusLabel = dialogWindow.Binds.StatusLabel;
									statusLabel.Text = "Skipping<...>";
									
									local rPacket = remoteBlueprintHandler:InvokeServer("skipbuild", {
										Index=process.Index;
									});
									
									if rPacket and rPacket.Success then
										statusLabel.Text = "Skipped!";
										task.wait(0.5);
										
									elseif rPacket.GoldShop then
										statusLabel.Text = "Not enough Perk";
										task.wait(1);
										interface:ToggleWindow("GoldMenu", true, "PerksPage");
										return;
										
									else
										statusLabel.Text = "Error: ".. rPacket and rPacket.FailMsg or "Unknown";
									end
								end;
							};
							{
								Text="Cancel";
								Style="Cancel";
							};
						}
					});

				elseif process.Type == "PolishTool" then
					modClientGuis.promptDialogBox({
						Title=`Skip {titleTag.Text}`;
						Desc=`Are you sure you want to skip <b>{titleTag.Text}</b> process with <b>{modRichFormatter.PerkText(skipCost.." Perks")}</b>?`;
						Buttons={
							{
								Text="Skip";
								Style="Confirm";
								OnPrimaryClick=function(dialogWindow, textButton)
                                    local statusLabel = dialogWindow.Binds.StatusLabel;
									statusLabel.Text = "Skipping<...>";
									
									local serverReply = remotePolishTool:InvokeServer(binds.InteractPart, 4, process.Index);
									if serverReply == modWorkbenchLibrary.PolishToolReplies.Success then
										statusLabel.Text = "Skipped!";
										refreshProcessPage();
										task.wait(0.5);

									elseif serverReply == modWorkbenchLibrary.PolishToolReplies.InsufficientPerks then
										statusLabel.Text = "Not enough Perk";
										task.wait(1);
										interface:ToggleWindow("GoldMenu", true, "PerksPage");

									else
										statusLabel.Text = "Error: "..tostring(serverReply);
									end
								end;
							};
							{
								Text="Cancel";
								Style="Cancel";
							};
						}
					});

				end

			end)
			
			table.insert(activeSyncs, refreshContent);
			refreshContent();
			order = order +1;
		end
		
		if #processList <= 0 then
			listMenu:NewLabel("No active process.");
		end
		
		return listMenu;
	end

	return WorkbenchClass
end

return WorkbenchClass;