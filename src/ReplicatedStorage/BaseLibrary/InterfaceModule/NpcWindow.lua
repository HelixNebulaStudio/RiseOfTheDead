local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;
local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modPlayers = require(game.ReplicatedStorage.Library.Players);

local modNpcTasksLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcTasksLibrary);

local modStorageInterface = require(game.ReplicatedStorage.Library.UI.StorageInterface);

local remotePlayerDataFetch = modRemotesManager:Get("PlayerDataFetch");

local windowFrameTemplate = script:WaitForChild("NpcWindow");
local equipmentsStorageTemplate = script:WaitForChild("Equipments");
local taskListingTemplate = script:WaitForChild("taskListing");

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	local activeNpcName, activeStorageInterface;
	local equipmentsFrame: Frame;

	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;

	local mainFrame = windowFrame:WaitForChild("MainFrame") :: ScrollingFrame;
	local leftFrame = mainFrame:WaitForChild("LeftFrame");
	local viewportFrame = leftFrame:WaitForChild("ViewportFrame")
	local rightScrollFrame: ScrollingFrame = mainFrame:WaitForChild("RightScrollFrame");
	
	local activeTasksPage = rightScrollFrame:WaitForChild("ActiveTasksPage") :: Frame;
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

	window.OnWindowToggle:Connect(function(visible, npcName)
		if equipmentsFrame then
			equipmentsFrame:Destroy();
		end

		if visible then
			equipmentsFrame = equipmentsStorageTemplate:Clone();
			equipmentsFrame.Parent = leftFrame;

			activeNpcName = npcName;
			
			if activeNpcName then
				local packet = remotePlayerDataFetch:InvokeServer{
					[modRemotesManager.Ref("Action")] = "npcdatafetch";
					[modRemotesManager.Ref("Id")] = activeNpcName;
				}
				if packet then
					local data = packet[modRemotesManager.Ref("Data")];

					local safehomeData = modData and modData.Profile and modData.Profile.Safehome;
					if modData.Profile == nil then return end;
					if safehomeData == nil then 
						modData.Profile.Safehome = {};
					end;
					if modData.Profile.Safehome.Npc == nil then
						modData.Profile.Safehome.Npc = {};
					end
					
					modData.Profile.Safehome.Npc[activeNpcName] = data;
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

	function Interface.Update()
		if activeNpcName == nil then window:Close(); return end;

		local safehomeData = modData.Profile.Safehome;
		local npcData = safehomeData.Npc[activeNpcName];

		if npcData == nil then window:Close(); return end;
		Debugger:StudioWarn(activeNpcName, npcData);

		local npcStorage = modData.Storages[activeNpcName.."Storage"];
		Debugger:StudioWarn("Storage", npcStorage);

		if activeStorageInterface then
			activeStorageInterface:Update();
		end
	end

	local activePage = nil;
	function Interface.RefreshPage()
		local currentPage = activePage or "ActiveTasksPage";

		for _, obj in pairs(rightScrollFrame:GetChildren()) do
			if not obj:IsA("GuiObject") then continue end;
			
			obj.Visible = obj.Name == currentPage;
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

		for a=1, #tasksList do
			local taskLib = tasksList[a];

			local newListing = taskListingTemplate:Clone() :: Frame;
			local listButton = newListing:WaitForChild("listButton") :: TextButton;
			local titleLabel = newListing:WaitForChild("Title");
			titleLabel.Text = taskLib.Name;

			local detailsFrame = newListing:WaitForChild("DetailsFrame");
			listButton.MouseButton1Click:Connect(function()
				local prevVisible = detailsFrame.Visible;

				for _, obj in pairs(assignTaskPage:GetChildren()) do
					if obj:IsA("Frame") then
						obj.DetailsFrame.Visible = false;
					end;
				end

				if prevVisible == true then return end;
				detailsFrame.Visible = true;
			end)

			newListing.LayoutOrder = a;
			newListing.Parent = assignTaskPage;
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
	
	return Interface;
end;

return Interface;