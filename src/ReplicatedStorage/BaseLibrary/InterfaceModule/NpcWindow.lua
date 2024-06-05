local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;
local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local modNpcTasksLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcTasksLibrary);

local modStorageInterface = require(game.ReplicatedStorage.Library.UI.StorageInterface);
local modComponents = require(game.ReplicatedStorage.Library.UI.Components);

local remotePlayerDataFetch = modRemotesManager:Get("PlayerDataFetch");
local remoteNpcData = modRemotesManager:Get("NpcData");

local windowFrameTemplate = script:WaitForChild("NpcWindow");
local equipmentsStorageTemplate = script:WaitForChild("Equipments");
local taskListingTemplate = script:WaitForChild("taskListing");

local taskDetailTemplates = script:WaitForChild("TaskDetails");
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	local activeNpcName, activeStorageInterface;
	local equipmentsFrame: Frame;

	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;

	local titleLabel = windowFrame:WaitForChild("TitleFrame"):WaitForChild("Title");
	local mainFrame = windowFrame:WaitForChild("MainFrame") :: ScrollingFrame;
	local leftFrame = mainFrame:WaitForChild("LeftFrame");
	local viewportFrame = leftFrame:WaitForChild("ViewportFrame")
	local npcStatsLabel = viewportFrame:WaitForChild("ViewportLabel");
	local rightScrollFrame: ScrollingFrame = mainFrame:WaitForChild("RightScrollFrame");
	
	local activeTasksPage = rightScrollFrame:WaitForChild("ActiveTasksPage") :: Frame;
	local tasksTitle = activeTasksPage:WaitForChild("TasksTitle") :: TextLabel;
	local newTaskButton = activeTasksPage:WaitForChild("newTaskButton"):WaitForChild("Button") :: TextButton;

	local assignTaskPage = rightScrollFrame:WaitForChild("TaskOptionsPage");
	local taskPageCloseButton = assignTaskPage:WaitForChild("AssignTaskTitle"):WaitForChild("closeButton") :: TextButton;

	local window = Interface.NewWindow("NpcWindow", windowFrame);
	window.CompactFullscreen = true;
	
	if modConfigurations.CompactInterface then
		game.Debris:AddItem(windowFrame:FindFirstChild("UISizeConstraint"), 0);
		window:SetOpenClosePosition(UDim2.new(1, 0, 0.5, 0), UDim2.new(1.5, 0, 0.5, 0));

		windowFrame.AnchorPoint = Vector2.new(1, 0.5);
		windowFrame.Size = UDim2.new(0.5, 0, 1, 0);

		leftFrame.Size = UDim2.new(1, 0, 0, 360);

		rightScrollFrame.AnchorPoint = Vector2.new(0, 0);
		rightScrollFrame.Position = UDim2.new(0, 0, 0, 360);
		rightScrollFrame.Size = UDim2.new(1, 0, 0, 0);
		rightScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.None;
		rightScrollFrame.AutomaticSize = Enum.AutomaticSize.Y;

		local uiListLayout = Instance.new("UIListLayout");
		uiListLayout.Parent = mainFrame;
		uiListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			mainFrame.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y+100);
		end)

	else
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));

	end

	window:AddCloseButton(windowFrame);

	windowFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("NpcWindow");
	end)

	local taskProcessObjects = {};
	window.OnWindowToggle:Connect(function(visible, npcName)
		if equipmentsFrame then
			equipmentsFrame:Destroy();
		end

		if visible then
			equipmentsFrame = equipmentsStorageTemplate:Clone();
			equipmentsFrame.Parent = leftFrame;

			if activeNpcName ~= npcName then
				for k, obj in pairs(taskProcessObjects) do
					obj:Destroy();
				end
				table.clear(taskProcessObjects);
			end
			activeNpcName = npcName;
			titleLabel.Text = npcName;
			
			if activeNpcName then
				local packet = remotePlayerDataFetch:InvokeServer{
					[modRemotesManager.Ref("Action")] = "npcdatafetch";
					[modRemotesManager.Ref("Id")] = activeNpcName;
				}
				if packet then
					local data = packet[modRemotesManager.Ref("Data")];
					if data == nil then return end;

					local npcData = data.NpcData;
					local npcTasks = data.NpcTasks;

					local safehomeData = modData and modData.Profile and modData.Profile.Safehome;
					if modData.Profile == nil then return end;
					if safehomeData == nil then 
						modData.Profile.Safehome = {};
					end;
					if modData.Profile.Safehome.Npc == nil then
						modData.Profile.Safehome.Npc = {};
					end
					
					modData.Profile.Safehome.Npc[activeNpcName] = npcData;

					local tasksData = modData and modData.Profile and modData.Profile.NpcTaskData;
					if tasksData == nil then
						modData.Profile.NpcTaskData = {};
					end
					if modData.Profile.NpcTaskData.Npc == nil then
						modData.Profile.NpcTaskData.Npc = {};
					end
					modData.Profile.NpcTaskData.Npc[activeNpcName] = npcTasks;

				end

				local equipmentSlots = {};
				for _, obj in pairs(equipmentsFrame:GetChildren()) do 
					if obj:IsA("GuiObject") and obj.LayoutOrder > 0 then 
						obj:SetAttribute("Index", obj.LayoutOrder); 
						table.insert(equipmentSlots, obj) 
					end 
				end;

				if activeStorageInterface then activeStorageInterface:Destroy(); end;
				activeStorageInterface = modStorageInterface.new(activeNpcName.."Storage", equipmentsFrame, equipmentSlots);

				function activeStorageInterface:DecorateSlot(index, slotTable)
					local slotFrame = slotTable.Frame;
					slotFrame.ImageColor3 = Color3.fromRGB(60, 60, 60);
				end

				for _, obj in pairs(viewportFrame:GetChildren()) do
					if obj:IsA("Camera") or obj:IsA("Model") then
						obj:Destroy();
					end
				end
				local npcPrefab = workspace.Entity:FindFirstChild(activeNpcName);
				if npcPrefab then
					npcPrefab = npcPrefab:Clone();
					local camera = Instance.new("Camera");
					npcPrefab.Parent = viewportFrame;
					camera.Parent = viewportFrame;
					viewportFrame.CurrentCamera = camera;

					local rCframe = npcPrefab:GetPrimaryPartCFrame();
					local origin = rCframe.p + Vector3.new(0, 2, 0);
					camera.CFrame = CFrame.lookAt(origin + rCframe.LookVector*4, origin);
				end

			end
			Interface:HideAll{[window.Name]=true; ["Inventory"]=true;};
			Interface:OpenWindow("Inventory");
			Interface.Update();
		end
	end)

	local activePage = nil;

	function Interface.Update()
		if activeNpcName == nil then window:Close(); return end;

		local npcData = modData.Profile.Safehome.Npc[activeNpcName];
		if npcData == nil then window:Close(); return end;
		--local npcStorage = modData.Storages[activeNpcName.."Storage"];

		if activeStorageInterface then
			activeStorageInterface:Update();
		end

		local npcTasks = modData.Profile.NpcTaskData and modData.Profile.NpcTaskData.Npc and modData.Profile.NpcTaskData.Npc[activeNpcName];
		
		local npcStatsText = {};
		table.insert(npcStatsText, `Happiness: { string.format("%.1f", math.clamp(npcData.Happiness or 0, 0, 1) *100) }%`);
		table.insert(npcStatsText, `Hunger: { string.format("%.1f", math.clamp(npcData.Hunger or 0, 0, 1) *100) }%\n`);
		table.insert(npcStatsText, `Max Health: { string.format("%.0f", math.max(npcData.Health or 0, 0)) } hp`);
		table.insert(npcStatsText, `Max Armor: { string.format("%.0f", math.max(npcData.Armor or 0, 0)) } ap`);
		table.insert(npcStatsText, `Status: {npcTasks and #npcTasks > 0 and "Busy" or "Idle"}`);

		npcStatsLabel.Text = table.concat(npcStatsText, "\n");
	end

	function Interface.RefreshActiveTasksPage()
		if activeTasksPage.Visible == false then return end;
		local npcTasks = modData.Profile.NpcTaskData and modData.Profile.NpcTaskData.Npc and modData.Profile.NpcTaskData.Npc[activeNpcName];
		if npcTasks == nil then return end;

		local t = modSyncTime.GetTime();

		--Debugger:StudioWarn("npcTasks", npcTasks); -- {1:{"Id":scavengeColorCustoms "StartTime":1714420666 "Values":{}}}
		tasksTitle.Text = `Tasks ({#npcTasks}/1)`;
		local updatedFlag = {};
		for a=1, #npcTasks do
			local taskData = npcTasks[a];

			local taskLib = modNpcTasksLibrary:Find(taskData.Id);

			local taskProcessObj = taskProcessObjects[taskData.Id];
			updatedFlag[taskData.Id] = true;

			if taskProcessObj and taskProcessObj.StartTime ~= taskData.StartTime then
				taskProcessObj:Destroy();
				taskProcessObj = nil;
			end

			if taskProcessObj == nil or taskProcessObj.Button == nil then
				taskProcessObjects[taskData.Id] = modComponents.CreateProgressListing(Interface, {
					Id = taskData.Id;
					Parent = activeTasksPage;
				});
				taskProcessObj = taskProcessObjects[taskData.Id];
				taskProcessObj.StartTime = taskData.StartTime;

				taskProcessObj.SkipCost.Perks = taskLib.SkipCost.Perks;
				taskProcessObj.SkipCost.Gold = taskLib.SkipCost.Gold;

				taskProcessObj.OnSkipYes = function(packet: {Currency: string; YesLabel: TextLabel})
					local rPacket = remoteNpcData:InvokeServer("skiptask", activeNpcName, {
						Id = taskLib.Id;
						Currency= packet.Currency;
					});
					
					if rPacket.Success then
						modData.Profile.NpcTaskData.Npc[activeNpcName] = rPacket.Data;
						
						activePage = nil;
						Interface.RefreshPage();

					elseif rPacket.FailMsg then
						packet.YesLabel.Text = rPacket.FailMsg;
						task.wait(0.4);
					end
				end

				taskProcessObj.OnSkipNo = function()
				end

				taskProcessObj.ReopenWindow = function()
					window:Open(activeNpcName);
				end

				local completeDebounce = false;
				taskProcessObj.OnComplete = function(packet: {Button: TextButton})
					if completeDebounce then return end;
					completeDebounce = true;

					local rPacket = remoteNpcData:InvokeServer("completetask", activeNpcName, {
						Id = taskLib.Id;
					});
					Debugger:StudioWarn("rPacket", rPacket);

					if rPacket.Success then
						modData.Profile.NpcTaskData.Npc[activeNpcName] = rPacket.Data;

						if rPacket.TaskFailed then
							packet.Button.Text = rPacket.TaskFailed;
							task.wait(1);
						end
						
						activePage = nil;
						Interface.RefreshPage();

					elseif rPacket.FailMsg then
						packet.Button.Text = rPacket.FailMsg;
						task.wait(1);

					end

					completeDebounce = false;
				end

				local cancelDebounce = false;
				taskProcessObj.OnCancel = function(packet: {Button: TextButton})
					if cancelDebounce then return end;
					cancelDebounce = true;

					local rPacket = remoteNpcData:InvokeServer("canceltask", activeNpcName, {
						Id = taskLib.Id;
					});
					Debugger:StudioWarn("rPacket", rPacket);

					if rPacket.Success then
						modData.Profile.NpcTaskData.Npc[activeNpcName] = rPacket.Data;
						
						activePage = nil;
						Interface.RefreshPage();
					elseif rPacket.FailMsg then
						packet.Button.Text = rPacket.FailMsg;
						task.wait(1);
					end

					cancelDebounce = false;
				end;
			end

			local timeLeft = (taskData.EndTime)-t;
			local duration = taskData.EndTime - taskData.StartTime;
			local buildPercent = math.clamp(1-(timeLeft/duration), 0, 1);

			taskData.Title = taskLib.Name; 
			taskData.ProgressLabel = timeLeft > 0 and modSyncTime.ToString(timeLeft or 0) or "Complete";
			taskData.ProgressValue = buildPercent;

			local descText = `    <b>Task:</b> {taskLib.Description}\n`;
			for key, valueData in pairs(taskLib.Values) do
				local taskValueStr = taskData.Values[key];
				if valueData.Type == "ColorPicker" then
					local color = Color3.fromHex(taskValueStr);
					local backColor = Interface.ColorPicker.GetBackColor(color) :: Color3;

					taskValueStr = `<stroke color="#{backColor:ToHex()}" joins="miter" thickness="2"><font color="#{taskValueStr}">#{taskValueStr}</font></stroke>`;
				end
				descText = descText..`\n<b>{valueData.Title or key}:</b> {taskValueStr}`;
			end
			 
			taskData.DescText = descText;
			taskProcessObj:Update(taskData);
		end

		for k, obj in pairs(taskProcessObjects) do
			if updatedFlag[k] == true then continue end;
			obj:Destroy();
			taskProcessObjects[k] = nil;
		end
	end

	function Interface.RefreshPage()
		local currentPage = activePage or "ActiveTasksPage";

		for _, obj in pairs(rightScrollFrame:GetChildren()) do
			if not obj:IsA("GuiObject") then continue end;
			
			obj.Visible = obj.Name == currentPage;

			if obj.Visible and Interface["Refresh"..obj.Name] then
				Interface["Refresh"..obj.Name]();
			end
		end
	end

	rightScrollFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		for _, obj in pairs(rightScrollFrame:GetChildren()) do
			if not obj:IsA("GuiObject") then continue end;
			obj.Size = UDim2.new(1, rightScrollFrame.AbsoluteCanvasSize.Y>rightScrollFrame.AbsoluteSize.Y and -rightScrollFrame.ScrollBarThickness or 0, 0, 0);
		end
	end)

	newTaskButton.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();
		activePage = "TaskOptionsPage";
		Interface.RefreshPage();

		for _, obj in pairs(assignTaskPage:GetChildren()) do
			if obj:IsA("Frame") then obj:Destroy() end;
		end
		if activeNpcName == nil then return end;
		local tasksList = modNpcTasksLibrary:GetTasks(activeNpcName);
		local taskDataList = modData.Profile.NpcTaskData.Npc[activeNpcName] or {};

		for a=1, #tasksList do
			local taskLib = tasksList[a];

			local taskData = nil;
			for a=1, #taskDataList do
				if taskDataList[a].Id == taskLib.Id then
					taskData = taskDataList[a];
					break;
				end
			end

			if taskData then
				continue;
			end

			local taskValues = {};

			local newListing = taskListingTemplate:Clone() :: Frame;
			newListing.LayoutOrder = a;
			newListing.Parent = assignTaskPage;

			local listButton = newListing:WaitForChild("listButton") :: TextButton;
			local titleLabel = newListing:WaitForChild("Title");
			titleLabel.Text = taskLib.Name;

			local detailsFrame = newListing:WaitForChild("DetailsFrame");
			listButton.MouseButton1Click:Connect(function()
				Interface:PlayButtonClick();
				local prevVisible = detailsFrame.Visible;

				for _, obj in pairs(assignTaskPage:GetChildren()) do
					if obj:IsA("Frame") then
						obj.DetailsFrame.Visible = false;

						for _, obj in pairs(obj.DetailsFrame:GetChildren()) do
							if obj:GetAttribute("TaskValueKey") == nil then continue end;
							obj:Destroy();
						end
					end;
				end

				if prevVisible == true then return end;

				for key, valueData in pairs(taskLib.Values) do
					local type = valueData.Type;
					local template = taskDetailTemplates:FindFirstChild(type);
					if template == nil then Debugger:Warn("Missing task values:", key); continue end;

					local new = template:Clone();
					if type == "ColorPicker" then
						local colorPickerObj = Interface.ColorPicker;

						local pickButton = new:WaitForChild("pickButton") :: TextButton;
						pickButton.MouseButton1Click:Connect(function()
							Interface:PlayButtonClick();

							if modConfigurations.CompactInterface then
								Interface:CloseWindow("Inventory");
								colorPickerObj.Frame.Position = UDim2.new(0, 0, 0, 0);
								colorPickerObj.Frame.Size = UDim2.new(0.5, 0, 1, 0);
							else
								Interface.SetPositionWithPadding(colorPickerObj.Frame, pickButton.AbsolutePosition);
							end
							colorPickerObj.Frame.Visible = true;
					
							function colorPickerObj:OnColorSelect(selectColor: Color3, selectColorId: string)
								Interface:PlayButtonClick();
								colorPickerObj.Frame.Visible = false;
								pickButton.BackgroundColor3 = selectColor;

								pickButton.TextColor3 = Interface.ColorPicker.GetBackColor(selectColor);

								taskValues[key] = selectColorId;
								Debugger:StudioWarn("Selected color:", selectColorId);
							end
						end)

						new.Destroying:Connect(function()
							colorPickerObj.Frame.Visible = false;
						end)
					end
					new:SetAttribute("TaskValueKey", key);
					new.Parent = detailsFrame;
				end

				detailsFrame.Visible = true;
			end)

			local debounce = false;
			local assignButton = detailsFrame:WaitForChild("startButton") :: TextButton;
			assignButton.MouseButton1Click:Connect(function()
				if debounce then return end;
				debounce = true;

				Interface:PlayButtonClick();

				for key, valueData in pairs(taskLib.Values) do
					if taskValues[key] == nil and valueData.CanNil ~= true then
						if valueData.Type == "ColorPicker" then
							assignButton.Text = "Please pick a color!";
						end

						debounce = false;
						return;
					end
				end
				assignButton.Text = "Assigning..";

				Debugger:StudioWarn("Submit Values:", taskValues);
				local rPacket = remoteNpcData:InvokeServer("assigntask", activeNpcName, {
					Id=taskLib.Id;
					Values=taskValues;
				});

				if rPacket.Success then
					modData.Profile.NpcTaskData.Npc[activeNpcName] = rPacket.Data;
					
					activePage = nil;
					Interface.RefreshPage();
				else
					assignButton.Text = rPacket.FailMsg;

				end

				task.wait(0.6);
				assignButton.Text = "Assign";

				debounce = false;
			end)

			local descLabel = detailsFrame:WaitForChild("DescLabel") :: TextLabel;
			local descTxt = "";

			descTxt = descTxt..`    <b>Task:</b> {taskLib.Description}\n\n    <b>Duration:</b> {modSyncTime.ToString(taskLib.Duration)}`;

			--[[
				> &gt;
				< &lt
			]]

			if #taskLib.Requirements > 0 then
				descTxt = descTxt..`\n\n    <b>Requirements:</b> `
				for key, requireData in pairs(taskLib.Requirements) do
					if requireData.Type == "Mission" then
						local missionLib = modMissionLibrary.Get(requireData.Id);
						descTxt = descTxt..`\n        - {requireData.Type}: {missionLib.Name}`;
	
					elseif requireData.Type == "Stat" then
						local v = requireData.Value;
						if requireData.Id == "Happiness" then
							descTxt = descTxt..`\n        - {requireData.Id}: &gt;{ string.format("%.1f", v*100) }%`;
	
						elseif requireData.Id == "Hunger" then
							descTxt = descTxt..`\n        - {requireData.Id}: &gt;{ string.format("%.1f", v*100) }%`;
	
						end
						
					elseif requireData.Type == "Item" then
						local itemId = requireData.ItemId;
						local amount = requireData.Amount;

						local itemLib = modItemsLibrary:Find(itemId);
						descTxt = descTxt..`\n        - <b>{itemLib and itemLib.Name or itemId}</b> ({amount})`;
					end
				end
			end
			
			if #taskLib.FailFactors > 0 then
				descTxt = descTxt..`\n\n    <b>Fail Chances:</b> `
				for key, failFactor in pairs(taskLib.FailFactors) do
					if failFactor.Type == "Stat" then
						local v = failFactor.Value;
	
						if failFactor.Id == "Hunger" then
							descTxt = descTxt..`\n        - {failFactor.Id}: &lt;{ string.format("%.1f", v*100) }%`;

						elseif failFactor.Id == "Health" then
							descTxt = descTxt..`\n        - {failFactor.Id}: &lt;{ string.format("%.1f", v*100) }%`;

						end
					end
				end
			end
			
			descLabel.Text = descTxt;
		end
	end)

	taskPageCloseButton.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();
		activePage = nil;
		Interface.RefreshPage();
	end)

	Interface.Garbage:Tag(modData.OnDataEvent:Connect(function(action, hierarchyKey, data)
		if action ~= "sync" then return end;
		
		if hierarchyKey:sub(1, 13) == "Safehome/Npc/" then
			Interface.Update();
		end
	end));

	Interface.Garbage:Tag(modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
		if window.Visible == true then
			Interface.RefreshPage();
		end
	end))

	return Interface;
end;

return Interface;