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

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	local activeNpcName, activeStorageInterface;
	local equipmentsFrame: Frame;

	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;

	local mainFrame = windowFrame:WaitForChild("MainFrame");
	local leftFrame = mainFrame:WaitForChild("LeftFrame");
	local viewportFrame = leftFrame:WaitForChild("ViewportFrame")
	local rightScrollFrame: ScrollingFrame = mainFrame:WaitForChild("RightScrollFrame");
	local tasksTitle: TextLabel = mainFrame:WaitForChild("TasksTitle");
	local newTaskFrame = rightScrollFrame:WaitForChild("newTaskButton") :: Frame;
	local newTaskButton = newTaskFrame:WaitForChild("Button") :: TextButton;

	local window = Interface.NewWindow("NpcWindow", windowFrame);
	window.CompactFullscreen = true;
	
	if modConfigurations.CompactInterface then
		game.Debris:AddItem(windowFrame:FindFirstChild("UISizeConstraint"), 0);
		window:SetOpenClosePosition(UDim2.new(1, 0, 0.5, 0), UDim2.new(1.5, 0, 0.5, 0));

		windowFrame.AnchorPoint = Vector2.new(1, 0.5);
		windowFrame.Size = UDim2.new(0.5, 0, 1, 0);

		leftFrame.Size = UDim2.new(1, 0, 0, 360);

		tasksTitle.Position = UDim2.new(1, 0, 0, 360);
		tasksTitle.TextXAlignment = Enum.TextXAlignment.Left;
		tasksTitle.Size = UDim2.new(1, 0, 0, 30);

		rightScrollFrame.AnchorPoint = Vector2.new(0, 0);
		rightScrollFrame.Position = UDim2.new(0, 0, 0, 390);
		rightScrollFrame.Size = UDim2.new(1, 0, 0, -30);
		rightScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.None;
		rightScrollFrame.AutomaticSize = Enum.AutomaticSize.Y;

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

	newTaskButton.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();
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