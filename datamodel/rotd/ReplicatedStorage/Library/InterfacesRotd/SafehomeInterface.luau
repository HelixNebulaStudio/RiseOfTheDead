local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modSafehomesLibrary = shared.require(game.ReplicatedStorage.Library.SafehomesLibrary);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);


local interfacePackage = {
    Type = "Character";
};
--==

function interfacePackage.onRequire()
	modKeyBindsHandler:SetDefaultKey("KeyWindowSafehome", Enum.KeyCode.U);
end

function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local remoteSafehomeRequest = modRemotesManager:Get("SafehomeRequest");

    local templateListing = script:WaitForChild("safehomeListing");
    local templateStatsPage = script:WaitForChild("StatsPage");
    local templateSurvivorsListing = script:WaitForChild("survivorsListing");
    local templateNpcCapacity = script:WaitForChild("NpcCapacity");
    local templateAppearanceListing = script:WaitForChild("AppearanceListing");

    local colorPickerObj = interface.ColorPicker;

	local windowFrame = script:WaitForChild("Safehome"):Clone();
	windowFrame.Parent = interface.ScreenGui;

	local window: InterfaceWindow = interface:NewWindow("Safehome", windowFrame);
    window.CloseWithInteract = true;
    window.DisableInteractables = true;
	window:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0), UDim2.new(0.5, 0, 0.5, 0));
    interface:BindConfigKey("DisableSafehomeMenu", {window});

	local quickButton = interface:NewQuickButton("Safehome", "Safehome", "rbxassetid://7045405631");
	quickButton.LayoutOrder = 10;
	interface:ConnectQuickButton(quickButton, "KeyWindowSafehome");

	windowFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		window:Close();
	end)

    local binds = window.Binds;
    binds.Page = "Safehome Stats";

    --MARK: OnToggle
	window.OnToggle:Connect(function(visible)
		if visible then
			modData:RequestData("Safehome");

			interface:HideAll{[window.Name]=true};
            window:Update();

		else
			colorPickerObj.Frame.Visible = false;

		end
	end)

	local optionsScrollList = windowFrame:WaitForChild("OptionsScroll");
	local scrollFrame = windowFrame:WaitForChild("ScrollingFrame");

	for _, obj in pairs(optionsScrollList:GetChildren()) do
		if obj:IsA("TextButton") then
			local page = obj.Text;

			obj.MouseButton1Click:Connect(function()
				interface:PlayButtonClick();

				binds.Page = page;
				window:Update();
			end)
		end
	end

	local factionTag = workspace:GetAttribute("FactionHeadquarters");
	if factionTag then
		modConfigurations.Set("DisableSafehomeMenu", true);
	end
	
	
	interface.Garbage:Tag(workspace:GetAttributeChangedSignal("SafehomeMap"):Connect(function()
		if windowFrame.Visible then
			window:Update();
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
		end
	end

	local debounce = false;
    --MARK: OnUpdate
    window.OnUpdate:Connect(function()
		safehomeData = modData and modData.Profile and modData.Profile.Safehome;
		if safehomeData == nil then return end;
		local homesData = safehomeData.Homes;
		local page = binds.Page;

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
						window:Update();
					end)

				else
					if safehomeLib.Price then
						setButton.Text = modFormatNumber.Beautify(safehomeLib.Price).." Gold";
						setButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100);

						setButton.MouseButton1Click:Connect(function()
							interface:PlayButtonClick();

                            modClientGuis.promptDialogBox({
                                Title = `Purchase Safehome`;
                                Desc = `Are you sure you want to purchase ({safehomeLib.Name}) for {modFormatNumber.Beautify(safehomeLib.Price)} Gold?`;
                                Icon = safehomeLib.Image;
                                Buttons={
                                    {
                                        Text="Purchase";
                                        Style="Gold";
                                        OnPrimaryClick=function(dialogWindow)
                                            local statusLabel = dialogWindow.Binds.StatusLabel;
                                            statusLabel.Text = "Purchasing<...>";

                                            local rPacket = remoteSafehomeRequest:InvokeServer("purchaseSafehome", {
                                                SafehomeId=safehomeLib.Id;
                                            });
                                            if rPacket.Data then
                                                modData.Profile.Safehome = rPacket.Data;
                                            end

                                            if rPacket.ReplyCode == 1 then
                                                statusLabel.Text = "Purchased!";

                                            elseif rPacket.ReplyCode == 2 then
                                                statusLabel.Text = "Not enough Gold!";
                                                task.wait(1);
                                                interface:ToggleWindow("GoldMenu", true, "GoldPage");
                                                return;

                                            else
                                                statusLabel.Text = "Please try again!";

                                            end
                                            task.wait(2);
                                            
                                        end;
                                    };
                                    {
                                        Text="Cancel";
                                        Style="Cancel";
                                    };
                                }
                            });

						end)
						
					elseif safehomeLib.UnlockHint then
						setButton.Text = safehomeLib.UnlockHint;
						setButton.BackgroundTransparency = 1;
						setButton.AutoButtonColor = false;
						
					end

					inspectButton.MouseButton1Click:Connect(function()
						interface:PlayButtonClick();
						local _rPacket = remoteSafehomeRequest:InvokeServer("inspectSafehome", {
                            SafehomeId=safehomeLib.Id;
                        });
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
							interface:PlayButtonClick();
							interface.setPositionWithPadding(colorPickerObj.Frame);
							colorPickerObj.Frame.Visible = true;

							if modConfigurations.CompactInterface then
								colorPickerObj.Frame.Size = UDim2.new(1,0,1,0);
							else
								colorPickerObj.Frame.Size = UDim2.new(0,300,0,300);
							end
							
							function colorPickerObj:OnColorSelect(selectColor)
								interface:PlayButtonClick();
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
							interface:PlayButtonClick();
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

					local statsText = {};
					table.insert(statsText, `Level: {tostring(npcLevel)}`);
					table.insert(statsText, `Hunger: { string.format("%.1f", math.clamp(data.Hunger or 0, 0, 1) *100) }%`);
					table.insert(statsText, `Happiness: { string.format("%.1f", math.clamp(data.Happiness or 0, 0, 1) *100) }%`);

					statsLabel.Text = "Class: "..npcLib.Class.."\n"..table.concat(statsText, "\n");

					local inspectButton = new:WaitForChild("InspectButton");
					inspectButton.MouseButton1Click:Connect(function()
						interface:PlayButtonClick();
                        interface:ToggleWindow("NpcWindow", true, name);
					end)
					
					local kickButton = new:WaitForChild("KickButton");
					kickButton.MouseButton1Click:Connect(function()
						interface:PlayButtonClick();

                        modClientGuis.promptDialogBox({
                            Title = `Kick Survivor`;
                            Desc = `Are you sure you want to kick {name} from the safehome?`;
                            Buttons={
                                {
                                    Text="Kick";
                                    Style="Confirm";
                                    OnPrimaryClick=function(dialogWindow)
                                        local statusLabel = dialogWindow.Binds.StatusLabel;
                                        statusLabel.Text = "Kicking<...>";

                                        local rPacket = remoteSafehomeRequest:InvokeServer("kickSurvivor", {
                                            Name=name;
                                        });
                                        if rPacket.Data then
                                            modData.Profile.Safehome = rPacket.Data;
                                        end

                                        if rPacket.ReplyCode == 1 then
                                            statusLabel.Text = "Kicked!";

                                        else
                                            statusLabel.Text = rPacket.FailMsg or "Please try again!";

                                        end
                                        
                                        task.wait(2);
                                        
                                    end;
                                };
                                {
                                    Text="Cancel";
                                    Style="Cancel";
                                };
                            }
                        });
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
	end)

	function remoteSafehomeRequest.OnClientInvoke(rPacket)
		modData.Profile.Safehome = rPacket.Data;
		return;
	end

end

return interfacePackage;

