local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;
local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);

local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modSafehomesLibrary = require(game.ReplicatedStorage.Library.SafehomesLibrary);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);

local remotes = game.ReplicatedStorage.Remotes;
local remoteSafehomeRequest = modRemotesManager:Get("SafehomeRequest");
	
local windowFrameTemplate = script:WaitForChild("Safehome");
local templateListing = script:WaitForChild("safehomeListing");
local templateStatsPage = script:WaitForChild("StatsPage");
local templateSurvivorsListing = script:WaitForChild("survivorsListing");
local templateNpcCapacity = script:WaitForChild("NpcCapacity");
local templateAppearanceListing = script:WaitForChild("AppearanceListing");

Interface.Page = "Safehome Stats"
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local colorPickerObj = Interface.ColorPicker;

	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;

	local window = Interface.NewWindow("Safehome", windowFrame);
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	window.OnWindowToggle:Connect(function(visible)
		if visible then
			modData:RequestData("Safehome");
			Interface:HideAll{[window.Name]=true};
			Interface:ToggleInteraction(false);
			Interface.Update();

		else
			colorPickerObj.Frame.Visible = false;
			task.delay(0.3, function()
				Interface:ToggleInteraction(true);
			end)

		end
	end)

	window:AddCloseButton(windowFrame);
	local titleLabel = windowFrame:WaitForChild("TitleFrame"):WaitForChild("Title");

	local optionsScrollList = windowFrame:WaitForChild("OptionsScroll");
	local scrollFrame = windowFrame:WaitForChild("ScrollingFrame");

	for _, obj in pairs(optionsScrollList:GetChildren()) do
		if obj:IsA("TextButton") then
			local page = obj.Text;

			obj.MouseButton1Click:Connect(function()
				Interface:PlayButtonClick();

				Interface.Page = page;
				Interface.Update();
			end)
		end
	end

	local factionTag = workspace:GetAttribute("FactionHeadquarters");
	if factionTag then
		modConfigurations.Set("DisableSafehomeMenu", true);
	end
	
	window:SetConfigKey("DisableSafehomeMenu");
	
	modKeyBindsHandler:SetDefaultKey("KeyWindowSafehome", Enum.KeyCode.U);
	local quickButton = Interface:NewQuickButton("Safehome", "Safehome", "rbxassetid://7045405631");
	quickButton.LayoutOrder = 10;
	modInterface:ConnectQuickButton(quickButton, "KeyWindowSafehome");
	
	
	windowFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("Safehome");
	end)
	
	Interface.Garbage:Tag(workspace:GetAttributeChangedSignal("SafehomeMap"):Connect(function()
		if windowFrame.Visible then
			Interface.Update();
		end
	end))
	
	local safehomeData = modData and modData.Profile and modData.Profile.Safehome;
	local lastFetch = tick();
	local function fetchSafehomeData()
		if tick()-lastFetch <= 0.5 then return end;
		lastFetch = tick();

		local rPacket = remoteSafehomeRequest:InvokeServer("fetch");
		if rPacket == nil then return end;

		if rPacket.Data then 
			modData.Profile.Safehome = rPacket.Data; 
			safehomeData = modData.Profile.Safehome; 

			Debugger:Warn("safehomeData", safehomeData);
		end
	end

	local debounce = false;
	function Interface.Update()
		safehomeData = modData and modData.Profile and modData.Profile.Safehome;
		if safehomeData == nil then return end;
		local homesData = safehomeData.Homes;
		local page = Interface.Page;

		debounce = false;

		if page == "Safehome Locations" then

			for _, obj in pairs(scrollFrame:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj:Destroy();
				end
			end

			local indexedList = modSafehomesLibrary:GetIndexList();


			for a=1, #indexedList do
				local safehomeLib = indexedList[a];
				local new = templateListing:Clone();

				new.Name = safehomeLib.Id;
				new.LayoutOrder = a;

				local titleLabel = new:WaitForChild("Title");
				titleLabel.Text = safehomeLib.Name;
				local imageLabel = new:WaitForChild("ImageLabel");
				imageLabel.Image = safehomeLib.Image;

				local setButton = new:WaitForChild("setButton");
				local inspectButton = new:WaitForChild("inspectButton");

				if workspace:GetAttribute("SafehomeMap") == safehomeLib.Id then
					inspectButton.Visible = false;
					setButton.Text = "Active";
					setButton.AutoButtonColor = false;

				elseif safehomeLib.Unlocked or homesData[safehomeLib.Id] then
					inspectButton.Visible = false;

					setButton.MouseButton1Click:Connect(function()
						if debounce then return end;
						debounce = true;
						local rPacket = remoteSafehomeRequest:InvokeServer("setSafehome", {SafehomeId=safehomeLib.Id;});
						if rPacket.Data then
							modData.Profile.Safehome = rPacket.Data;
						end
						Interface.Update();
					end)

				else
					if safehomeLib.Price then
						setButton.Text = modFormatNumber.Beautify(safehomeLib.Price).." Gold";
						setButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100);

						setButton.MouseButton1Click:Connect(function()
							Interface:PlayButtonClick();


							local promptWindow = Interface:PromptQuestion(
								"Purchase Safehome", 
								"Are you sure you want to purchase ("..safehomeLib.Name..") for "..modFormatNumber.Beautify(safehomeLib.Price).." Gold?",
								nil,
								nil,
								safehomeLib.Image
							);
							local YesClickedSignal, NoClickedSignal;

							YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
								if debounce then return end;
								debounce = true;
								Interface:PlayButtonClick();
								local rPacket = remoteSafehomeRequest:InvokeServer("purchaseSafehome", {SafehomeId=safehomeLib.Id;});
								if rPacket.Data then
									modData.Profile.Safehome = rPacket.Data;
								end

								if rPacket.ReplyCode == 1 then
									promptWindow.Frame.Yes.buttonText.Text = "Purchased!";

								elseif rPacket.ReplyCode == 2 then
									promptWindow.Frame.Yes.buttonText.Text = "Not enough Gold!";
									wait(1);
									promptWindow:Close();
									Interface:OpenWindow("GoldMenu", "GoldPage");
									return;

								else
									promptWindow.Frame.Yes.buttonText.Text = "Please try again!";

								end
								wait(1);
								promptWindow:Close();
								Interface:OpenWindow("Safehome");
								YesClickedSignal:Disconnect();
								NoClickedSignal:Disconnect();
							end);
							NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
								if debounce then return end;
								Interface:PlayButtonClick();
								promptWindow:Close();
								Interface:OpenWindow("Safehome");
								YesClickedSignal:Disconnect();
								NoClickedSignal:Disconnect();
							end);
						end)
						
					elseif safehomeLib.UnlockHint then
						setButton.Text = safehomeLib.UnlockHint;
						setButton.BackgroundTransparency = 1;
						setButton.AutoButtonColor = false;
						
					end

					inspectButton.MouseButton1Click:Connect(function()
						Interface:PlayButtonClick();
						local rPacket = remoteSafehomeRequest:InvokeServer("inspectSafehome", {SafehomeId=safehomeLib.Id;});
					end)

				end

				new.Parent = scrollFrame;
			end

		elseif page == "Customize Safehome" then

			for _, obj in pairs(scrollFrame:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj:Destroy();
				end
			end
			
			local customizationData = homesData.Customization;
			
			local safehomeCustomizableFolder = workspace.Environment:FindFirstChild("Customizable");
			if safehomeCustomizableFolder then
				
				for _, obj in pairs(safehomeCustomizableFolder:GetChildren()) do
					local groupId = obj.Name;
					local groupName = obj:GetAttribute("Name");
					local defaultColor = obj:GetAttribute("DefaultColor");
					
					if groupName and defaultColor then
						local groupData = customizationData and customizationData[groupId]
						local savedColor = groupData and groupData.Color and Color3.fromHex(groupData.Color) or nil;

						local new = templateAppearanceListing:Clone();
						local titleLabel = new:WaitForChild("Title");
						local colorButton = new:WaitForChild("ColorButton");
						local textureLabel = colorButton:WaitForChild("TextureLabel");
						
						titleLabel.Text = groupName;
						textureLabel.BackgroundColor3 = savedColor or defaultColor;
						
						colorButton.MouseButton1Click:Connect(function()
							Interface:PlayButtonClick();
							Interface.SetPositionWithPadding(colorPickerObj.Frame);
							colorPickerObj.Frame.Visible = true;

							if modConfigurations.CompactInterface then
								colorPickerObj.Frame.Size = UDim2.new(1,0,1,0);
							else
								colorPickerObj.Frame.Size = UDim2.new(0,300,0,300);
							end
							
							function colorPickerObj:OnColorSelect(selectColor)
								Interface:PlayButtonClick();
								textureLabel.BackgroundColor3 = selectColor;
								colorPickerObj.Frame.Visible = false;
								
								local rPacket = remoteSafehomeRequest:InvokeServer("customizeSafehome", {
									GroupId=groupId;
									NewColor=selectColor;
								});
								textureLabel.BackgroundColor3 = rPacket.ReturnColor;
								
							end
						end)
						
						local function resetColor()
							Interface:PlayButtonClick();
							textureLabel.BackgroundColor3 = defaultColor;
							
							local rPacket = remoteSafehomeRequest:InvokeServer("customizeSafehome", {
								GroupId=groupId;
								NewColor=defaultColor;
							});
							textureLabel.BackgroundColor3 = rPacket.ReturnColor;
							
						end
						
						colorButton.TouchLongPress:Connect(resetColor)
						colorButton.MouseButton2Click:Connect(resetColor)
						
						new.Parent = scrollFrame;
					end
				end
			end
			
		elseif page == "Safehome Stats" then
			for _, obj in pairs(scrollFrame:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj:Destroy();
				end
			end
			local newPage = templateStatsPage:Clone();

			spawn(function()
				fetchSafehomeData();

				local foodbar = newPage:WaitForChild("FoodStat"):WaitForChild("Foodbar");
				local foodLabel = newPage:WaitForChild("FoodStat"):WaitForChild("foodLabel");

				if safehomeData.FoodSupply then
					local alpha = safehomeData.FoodSupply/safehomeData.MaxFoodSupply;

					foodbar.Size = UDim2.new(alpha, 0, 1, 0);
					foodbar.Visible = alpha > 0;
					foodLabel.Text = safehomeData.FoodSupply .. "/" .. safehomeData.MaxFoodSupply;
				else
					foodbar.Visible = false;
				end
			end)

			newPage.Parent = scrollFrame;

		elseif page == "Survivors" then
			--templateSurvivorsListing
			for _, obj in pairs(scrollFrame:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj:Destroy();
				end
			end

			task.defer(function()
				fetchSafehomeData();
				local npcsData = safehomeData.Npc;

				local newCapcity = templateNpcCapacity:Clone();
				newCapcity.Parent = scrollFrame;
				local capBar = newCapcity:WaitForChild("bar");
				local capLabel = newCapcity:WaitForChild("label");

				local activeCount = 0;
				for name, data in pairs(npcsData) do
					if data.Active == nil then continue end;
					activeCount = activeCount +1;
					local new = templateSurvivorsListing:Clone();
					local viewportFrame = new:WaitForChild("ViewportFrame");

					local npcPrefab = workspace.Entity:FindFirstChild(name);
					if npcPrefab then
						npcPrefab = npcPrefab:Clone();
						local camera = Instance.new("Camera");
						npcPrefab.Parent = viewportFrame;
						camera.Parent = viewportFrame;
						viewportFrame.CurrentCamera = camera;

						local rCframe = npcPrefab:GetPrimaryPartCFrame();
						local origin = rCframe.p + Vector3.new(0, 2, 0);
						camera.CFrame = CFrame.lookAt(origin + rCframe.LookVector*3.5, origin);
					end

					local titleLabel = new:WaitForChild("Title");
					local statsLabel = new:WaitForChild("Stats");

					local npcLib = modNpcProfileLibrary:Find(name);
					local npcLevel = data.Level or 0;

					titleLabel.Text = name;
					statsLabel.Text = "Class: "..npcLib.Class.."\n"
						.."Level: ".. tostring(npcLevel) .."\n"
						.."Happiness: ".. tostring(data.Happiness) or ":)";

					local inspectButton = new:WaitForChild("InspectButton");
					inspectButton.MouseButton1Click:Connect(function()
						Interface:PlayButtonClick();
						modInterface:OpenWindow("NpcWindow", name);
					end)
					
					local kickButton = new:WaitForChild("KickButton");
					kickButton.MouseButton1Click:Connect(function()
						Interface:PlayButtonClick();

						local promptWindow = Interface:PromptQuestion(
							"Kick Survivor", 
							"Are you sure you want to kick "..name.." from the safehome?"
						);
						local YesClickedSignal, NoClickedSignal;

						YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
							if debounce then return end;
							debounce = true;
							Interface:PlayButtonClick();
							local rPacket = remoteSafehomeRequest:InvokeServer("kickSurvivor", {Name=name;});
							if rPacket.Data then
								modData.Profile.Safehome = rPacket.Data;
							end

							if rPacket.ReplyCode == 1 then
								promptWindow.Frame.Yes.buttonText.Text = "Kicked!";

							else
								promptWindow.Frame.Yes.buttonText.Text = "Please try again!";

							end
							wait(1);
							promptWindow:Close();
							Interface:OpenWindow("Safehome");
							YesClickedSignal:Disconnect();
							NoClickedSignal:Disconnect();
						end);
						NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
							if debounce then return end;
							Interface:PlayButtonClick();
							promptWindow:Close();
							Interface:OpenWindow("Safehome");
							YesClickedSignal:Disconnect();
							NoClickedSignal:Disconnect();
						end);
					end)

					new.Parent = scrollFrame;
				end

				local capAlpha = activeCount/5;
				if capAlpha > 0 then
					capBar.Visible = true;
					capBar.Size = UDim2.new(math.clamp(capAlpha, 0, 1), 0, 1, 0);
				else
					capBar.Visible = false;
				end
				capLabel.Text = "Safehome Capacity: "..activeCount.."/5";
			end)
		end
	end

	function remoteSafehomeRequest.OnClientInvoked(rPacket)
		modData.Profile.Safehome = rPacket.Data;
		return;
	end
	
	return Interface;
end;

return Interface;