local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");

local localPlayer = game.Players.LocalPlayer;
local modData = require(localPlayer:WaitForChild("DataModule"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modSettings = require(game.ReplicatedStorage.Library.Settings);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local modComponents = require(game.ReplicatedStorage.Library.UI.Components);

local remoteRequestResetData = modRemotesManager:Get("RequestResetData");

local windowFrameTemplate = script:WaitForChild("SettingsMenu");
local templateHotkeyOption = script:WaitForChild("HotkeyOption");
local tempateResetData = script:WaitForChild("ResetData");
local templateAutoPickupMenu = script:WaitForChild("AutoPickupMenu");
local templateAutoPickupMenuListing = script:WaitForChild("AutoPickupMenuListing");
local templateLabel = script:WaitForChild("label");

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;
	
	local mainframe = windowFrame:WaitForChild("Frame");
	local window = Interface.NewWindow("Settings", windowFrame);
	window:SetConfigKey("DisableSettingsMenu");
	
	local titleFrame = windowFrame:WaitForChild("TitleFrame");
	titleFrame:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("Settings");
	end)

	modKeyBindsHandler:SetDefaultKey("KeyWindowSettings", Enum.KeyCode.F2);
	local quickButton = Interface:NewQuickButton("Settings", "Settings", "rbxassetid://3256270626");
	quickButton.LayoutOrder = 20;
	modInterface:ConnectQuickButton(quickButton, "KeyWindowSettings");
	
	
	if modConfigurations.CompactInterface then
		windowFrame.Size = UDim2.new(1, 0, 1, 0);
		windowFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20);
		
		mainframe.Size = UDim2.new(1, 0, 1, -30);

		titleFrame.Size = UDim2.new(1, 0, 0, 30);
		titleFrame.BackgroundTransparency = 0.1;
		
		game.Debris:AddItem(windowFrame:FindFirstChild("UIGradient"), 0);
	end
	
	modSettings.DefaultConfigInterface:ClearAll();
	
	
	window.CompactFullscreen = true;
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	window.OnWindowToggle:Connect(function(visible)
		if visible then
			modSettings.DefaultConfigInterface:SetMenu(mainframe);
			Interface.Update();
			
		else
			modData.modInterface.DisableHotKeys = false;

			modData:UpdateSettings(function()
			end)
			modData:SaveSettings();

			Debugger:Warn("Saving settings..");
			
		end
	end)
	
	function Interface.LoadSettings()
		for k, v in pairs(modData.Settings) do
			if modKeyBindsHandler.DefaultKeybind[k] then
				modKeyBindsHandler:SetKey(k, modData.Settings[k]);
			end
		end;
		
		Interface.CinematicModeRefresh();
		Interface.UpdateKeybindHints();
		modData.UpdatePickupCache();
	end
	
	function Interface.CinematicModeRefresh()
		local cinematicMode = modData.Settings.CinematicMode == 1;
		localPlayer:SetAttribute("CinematicMode", cinematicMode);
		localPlayer:SetAttribute("DisableHud", cinematicMode);
	end
	
	function Interface.UpdateKeybindHints()
		local hotkeyHintSize = 18;
		for id, _ in pairs(modKeyBindsHandler.DefaultKeybind) do
			local keyText = modKeyBindsHandler:ToString(id);
			
			local key1, key2 = id:find("KeyWindow");
			local windowId = key2 and id:sub(key2+1, #id) or nil;

			task.spawn(function()
				local windowObj = windowId and Interface.Windows[windowId]
				local quickButton = windowObj and windowObj.QuickButton;
				if quickButton == nil then return end;
				
				pcall(function()
					--quickButton:WaitForChild("hotKey"):WaitForChild("button")
					quickButton.hotKey.button.Text = keyText;
					quickButton.hotKey.Size = UDim2.new(0, hotkeyHintSize+(#keyText-1)*8, 0, hotkeyHintSize);

					if windowObj.CloseButtonLabel then
						windowObj.CloseButtonLabel.Text = keyText;
						windowObj.CloseButtonLabel.Parent.Size = UDim2.new(0, hotkeyHintSize+(#keyText-1)*8, 0, hotkeyHintSize);
					end
				end)
			end)
			
		end
	end
	
	function Interface.Update()
		modSettings.DefaultConfigInterface:Render(Interface);
		
		local elements = modSettings.DefaultConfigInterface.Elements;
		
		for _, elementInfo in pairs(elements) do
			local elementInst = elementInfo.Instance;
			
			local config = elementInfo.Config;
			
			if elementInst and elementInst:GetAttribute("Init") == nil then
				elementInst:SetAttribute("Init", true);
				
				if elementInfo.TemplateName == "Page" then
					
					if config.Type == "Keybinds" then
						local controlsTable = {
							{Type="Desc"; Text="To change key binds, select an option and press the key you want to set or click anywhere else to reset to default."};
							{Type="Border"; Text="Character"};

							{Type="Option"; Id="KeySprint"; Text="Sprint"; };
							{Type="Option"; Id="KeyCrouch"; Text="Crouch"; };
							{Type="Option"; Id="KeyWalk"; Text="Walk"; };
							{Type="Option"; Id="KeyCamSide"; Text="Switch Camera Side"; };
							{Type="Option"; Id="KeyInteract"; Text="Interact"; };

							{Type="Border"; Text="Tools & Weapons"};
							{Type="Option"; Id="KeyFire"; Text="Primary Fire"; };
							{Type="Option"; Id="KeyFocus"; Text="Focus/ADS"; };
							{Type="Option"; Id="KeyReload"; Text="Reload"; };
							{Type="Option"; Id="KeyInspect"; Text="Inspect"; };
							
							{Type="Option"; Id="KeyToggleSpecial"; Text="Toggle/Trigger Special"; };
							{Type="Option"; Id="KeyTogglePat"; Text="Toggle Portable Auto Turret"; };
							

							{Type="Border"; Text="Interfaces"};
							{Type="Option"; Id="KeyWindowInventory"; Text="Inventory"; };
							{Type="Option"; Id="KeyWindowFactionsMenu"; Text="Factions Menu"; };
							{Type="Option"; Id="KeyWindowMissions"; Text="Missions Menu"; };
							{Type="Option"; Id="KeyWindowSocialMenu"; Text="Social Menu"; };
							{Type="Option"; Id="KeyWindowMasteryMenu"; Text="Mastery Menu"; };
							{Type="Option"; Id="KeyWindowEmotes"; Text="Emotes Menu"; };
							{Type="Option"; Id="KeyWindowMapMenu"; Text="Map Menu"; };
							{Type="Option"; Id="KeyWindowGoldMenu"; Text="Gold Menu"; };
							{Type="Option"; Id="KeyWindowWorkbench"; Text="Portable Workbench"; Gamepass="PortableWorkbench";};
							{Type="Option"; Id="KeyWindowSafehome"; Text="Safehome Menu"; };

							{Type="Option"; Id="KeyHideHud"; Text="Toggle Hud"; Default=modKeyBindsHandler:ToString("KeyHideHud");};
						};

						local changingKeys = false;
						
						for a=1, #controlsTable do
							local info = controlsTable[a];
							
							if info.Type == "Desc" then
								local new = templateHotkeyOption:Clone();
								new:WaitForChild("Desc").Text = info.Text;
								new.Desc.Position = UDim2.new(0, 0, 0, 0);
								new.Desc.Size = UDim2.new(1, 0, 0, 30);
								
								new:WaitForChild("Frame").Visible = false;
								new:WaitForChild("Button").Visible = false;
								 
								new:WaitForChild("Title").Visible = false;

								new.LayoutOrder = a;
								new.Parent = elementInst;
								
							elseif info.Type == "Border" then
								local new = templateHotkeyOption:Clone();
								game.Debris:AddItem(new:WaitForChild("Desc"), 0);
								new:WaitForChild("Button").Visible = false;
								new:WaitForChild("Title").Text = info.Text;
								new.Title.TextSize = 16;
								
								new.LayoutOrder = a;
								new.Parent = elementInst;
								
							elseif info.Type == "Option" then
								if info.Gamepass == nil or modData.Profile and modData.Profile.GamePass and modData.Profile.GamePass[info.Gamepass] then
									local new = templateHotkeyOption:Clone();
									local title = new:WaitForChild("Title");
									title.Text = info.Text;
									title.Position = UDim2.new(0, 20, 0, 0);

									local desc = new:WaitForChild("Desc");
									desc.Text = info.Desc or "";

									local resetButton = new:WaitForChild("ResetButton");
									resetButton.Visible = true;
									
									local defaultKey = modKeyBindsHandler:ToString(info.Id, true);
									
									local button = new:WaitForChild("Button");
									button.Text = modKeyBindsHandler:ToString(info.Id);--modData.Settings[info.Id] or info.Default;

									Interface.UpdateKeybindHints();
									
									resetButton.MouseButton1Click:Connect(function()
										button.Text = defaultKey;
										
										modData.Settings[info.Id] = nil;
										modKeyBindsHandler:SetKey(info.Id, nil);
										Interface.UpdateKeybindHints();
									end)
									
									button.MouseButton1Click:Connect(function()
										if changingKeys then return end;
										changingKeys = true;
										
										modData.modInterface.DisableHotKeys = true;
										
										local oldText = button.Text;
										button.Text = "Press any key..";
										local inputObj = UserInputService.InputBegan:Wait();

										local list;
										if inputObj.UserInputType == Enum.UserInputType.MouseButton1
											or inputObj.UserInputType == Enum.UserInputType.MouseButton2
											or inputObj.UserInputType == Enum.UserInputType.MouseButton3 then
											list = tostring(inputObj.UserInputType):split(".");

											if info.Id == "KeyHideHud" then
												list = {"Escape"};
											end

										else
											list = tostring(inputObj.KeyCode):split(".");

										end
										if list then
											if #list > 0 then
												if info.Id ~= "KeyInteract" and modKeyBindsHandler:Match(inputObj, "KeyInteract") then
													Debugger:Warn("That key is used for interacting.");
													Interface:PromptWarning("That key is used for interacting.");
													
													button.Text = oldText;
													task.wait(0.1);
													modData.modInterface.DisableHotKeys = false;
													changingKeys = false;
													return;
												end

												local selectedKey = list[#list];
												if selectedKey ~= defaultKey and selectedKey ~= "Escape" and selectedKey ~= "Backspace" and selectedKey ~= "Unknown" then
													modKeyBindsHandler:SetKey(info.Id, selectedKey);
													modData.Settings[info.Id] = modKeyBindsHandler:ToString(info.Id);
													button.Text = modData.Settings[info.Id];
													
												else
													button.Text = defaultKey;
													modData.Settings[info.Id] = nil;
													modKeyBindsHandler:SetKey(info.Id, nil);
												end
											end
										end

										Interface.UpdateKeybindHints();
										task.wait(0.1);
										modData.modInterface.DisableHotKeys = false;
										changingKeys = false;
									end)

									new.LayoutOrder = a;
									new.Parent = elementInst;
								end
							end
						end
						
						
					elseif config.Type == "DataReset" then

						local newResetData = tempateResetData:Clone();
						local textBox = newResetData:WaitForChild("understandInput");
						local resetButton = newResetData:WaitForChild("resetButton");
						
						local debounce = false;
						resetButton.MouseButton1Click:Connect(function()
							if debounce then return end;
							debounce = true;
							Interface:PlayButtonClick();
							
							if textBox.Text:lower() ~= "i understand" then
								resetButton.Text = "Please read the instructions";
								task.wait(2)
								resetButton.Text = "Reset Save Data";
								debounce = false;
								return;
							end;
							
							resetButton.Text = "Resetting Data";
							remoteRequestResetData:FireServer();
							task.wait(0.5);
							Interface:CloseWindow("Settings");
						end)
						
						newResetData.Parent = elementInst;
						
					elseif config.Type == "AutoPickup" then
						
						local newMenu = templateAutoPickupMenu:Clone();
						newMenu.Parent = elementInst;
						
						local contentFrame = newMenu:WaitForChild("ContentFrame");

						local addRemoveFrame = newMenu:WaitForChild("AddRemoveFrame");
						local addButton = addRemoveFrame:WaitForChild("AddButton");
						local delButton = addRemoveFrame:WaitForChild("DelButton");
						local setButton = addRemoveFrame:WaitForChild("SetButton");
						local textBox = addRemoveFrame:WaitForChild("TextBox");
						local suggestionsFrame = textBox:WaitForChild("SuggestionsFrame");

						local activeMode = 1;
						local itemsList = modItemsLibrary.Library:GetIndexList();
						
						local refreshList;
						
						local function delButtonClick(overwriteId)
							suggestionsFrame.Visible = false;
							local autoPickupConfig = modData.Settings.AutoPickupConfig or {};

							local keyword = overwriteId or textBox.Text:lower();
							local isKeyword = keyword:sub(1,1) == "*";
							
							if isKeyword then
								
							else
								local itemLib = modItemsLibrary:Find(keyword);

								if itemLib == nil then
									textBox.Text = keyword;
									textBox.TextColor3 = Color3.fromRGB(200, 100, 100);
									return;
								end
								
							end
							
							local exist = false;
							for a=#autoPickupConfig, 1, -1 do
								if autoPickupConfig[a].Keyword == keyword then
									exist = true;

									table.remove(autoPickupConfig, a);
								end
							end

							if exist then
								modSettings.Set(localPlayer, "AutoPickupConfig", autoPickupConfig);
							end

							refreshList();
							
							modData.UpdatePickupCache();
						end
						
						refreshList = function()
							local autoPickupConfig = modData.Settings.AutoPickupConfig or {};
							
							for _, obj in pairs(contentFrame:GetChildren()) do
								if not obj:IsA("GuiObject") then continue end;
								obj:Destroy();
							end
							
							for a=1, #autoPickupConfig do
								local listItem = autoPickupConfig[a];
								
								local new = templateAutoPickupMenuListing:Clone();
								new.LayoutOrder = a;
								new.Text = listItem.Keyword;

								
								local highlightFrame = new:WaitForChild("highlight");
								
								local function updateHl()
									if listItem.Mode == 1 then
										new.TextXAlignment = Enum.TextXAlignment.Left;
										
										highlightFrame.Position = UDim2.new(0, -15, 0, 0);
										highlightFrame.BackgroundColor3 = Color3.fromRGB(75, 150, 75);
									elseif listItem.Mode == 0 then
										new.TextXAlignment = Enum.TextXAlignment.Right;

										highlightFrame.Position = UDim2.new(1, 5, 0, 0);
										highlightFrame.BackgroundColor3 = Color3.fromRGB(150, 75, 75);

									end
								end
								updateHl();
								
								new.MouseButton1Click:Connect(function()
									if listItem.Mode == 1 then
										listItem.Mode = 0;
									else
										listItem.Mode = 1;
									end

									modSettings.Set(localPlayer, "AutoPickupConfig", autoPickupConfig);
									updateHl();
								end)
								
								local buttonDownTick;
								new.MouseButton1Down:Connect(function()
									buttonDownTick = tick();
									task.delay(0.5, function()
										if buttonDownTick and tick()-buttonDownTick >= 0.5 then
											delButtonClick(listItem.Keyword);
										end
									end)
								end)
								new.MouseButton1Up:Connect(function()
									buttonDownTick = nil;
								end)
								
								new.Parent = contentFrame;
							end
						end
						refreshList();
						
						local function switchType()
							if activeMode == 1 then
								activeMode = 0;
							else
								activeMode = 1;
							end

							setButton.BackgroundColor3 = activeMode == 1 and Color3.fromRGB(200, 255, 200) or Color3.fromRGB(255, 200, 200);
						end
						
						local function addButtonClick()
							suggestionsFrame.Visible = false;
							local autoPickupConfig = modData.Settings.AutoPickupConfig or {};

							local searchText = textBox.Text:lower();
							if #searchText <= 2 then return end;
							
							
							local isKeyword = searchText:sub(1,1) == "*";
							local keyword = searchText;
							
							if isKeyword then
								
							else
								local itemLib = modItemsLibrary:Find(searchText);

								if itemLib == nil then
									textBox.TextColor3 = Color3.fromRGB(200, 100, 100);
									return;
								end
								
								keyword = itemLib.Id;
							end
							
							
							local exist = false;
							for a=1, #autoPickupConfig do
								if autoPickupConfig[a].Keyword == keyword then
									exist = true;
									break;
								end
							end

							if not exist then
								table.insert(autoPickupConfig, {
									Keyword=keyword;
									Mode=activeMode;
								})
								modSettings.Set(localPlayer, "AutoPickupConfig", autoPickupConfig);
							end

							refreshList();
							textBox.Text = "";

							modData.UpdatePickupCache();
						end
						
						textBox.Focused:Connect(function()
							textBox.TextColor3 = Color3.fromRGB(255, 255, 255);
						end)
						textBox.FocusLost:Connect(function(enterPressed)
							suggestionsFrame.Visible = false;
							
							if enterPressed then
								textBox.Text = string.gsub(textBox.Text, "%s+", "");
								
								if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
									delButtonClick();
								else
									addButtonClick();
								end
								textBox:CaptureFocus();
								textBox.Text = "";
							end
						end)
						--textBox.InputBegan:Connect(function(inputObject)
						--	if inputObject.UserInputType == Enum.UserInputType.Keyboard and inputObject.KeyCode == Enum.KeyCode.Tab then
						--		switchType();
						--	end
						--end)
						textBox:GetPropertyChangedSignal("Text"):Connect(function()
							if #textBox.Text < 2 then 
								suggestionsFrame.Visible = false;
								return 
							end;
							
							local searchText = string.lower(textBox.Text);
							searchText = string.gsub(searchText, "%s+", "");
							
							local list = {};
							local hasMore = false;
							for a=1, #itemsList do
								
								local itemLib = itemsList[a];
								local hasMatch = false;

								if string.match(string.lower(itemLib.Id), searchText) then
									hasMatch = true;
								end
								if string.match(string.lower(itemLib.Name), searchText) then
									hasMatch = true;
								end
								if string.match(string.lower(itemLib.Description), searchText) then
									hasMatch = true;
								end

								if hasMatch then
									if #list > 7 then
										hasMore = true;
										break; 
									end;
									table.insert(list, itemLib);
								end
							end
							
							if #list > 0 then

								for _, obj in pairs(suggestionsFrame:GetChildren()) do
									if not obj:IsA("GuiObject") then continue end;
									obj:Destroy();
								end
								if hasMore then
									local new = templateLabel:Clone();
									new.Text = "...";
									new.TextTruncate = Enum.TextTruncate.AtEnd;
									new.Parent = suggestionsFrame;
								end
								for a=1, #list do
									local itemLib = list[a];
									local new = templateLabel:Clone();
									new.Text = "<b>"..itemLib.Id .. "</b>: ".. itemLib.Name;
									new.TextTruncate = Enum.TextTruncate.AtEnd;
									new.Parent = suggestionsFrame;
								end
								
								suggestionsFrame.Visible = true;
							else
								suggestionsFrame.Visible = false;
							end
						end)
						
						addButton.MouseButton1Click:Connect(addButtonClick)
						
						delButton.MouseButton1Click:Connect(delButtonClick)
						
						setButton.MouseButton1Click:Connect(switchType)
						
						local resetButton = newMenu:WaitForChild("Header"):WaitForChild("ResetButton");
						resetButton.MouseButton1Click:Connect(function()
							modSettings.Set(localPlayer, "AutoPickupConfig", nil);
							refreshList();
						end)
						
					end
					
					
				elseif elementInfo.TemplateName == "ToggleOption" then
					local button = elementInst:WaitForChild("Button");
					
					if config.Type:sub(1,6) == "Toggle" then
						local toggleOptions = string.split(config.Type, ";");
						table.remove(toggleOptions, 1);
						
						if #toggleOptions <= 0 then
							toggleOptions = {"Enabled"; "Disabled";};
						end
						
						local function update()
							local settingVal = modData.Settings[config.SettingsKey];
							local settingIndex = tonumber(settingVal) or 0;
							
							button:SetAttribute("SettingIndex", settingIndex);
							button.Text = toggleOptions[settingIndex+1] or "n/a";
							
							if button.Text == "Disabled" then
								button.BackgroundColor3 = Color3.fromRGB(175, 100, 100);
							elseif button.Text  == "Enabled" then
								button.BackgroundColor3 = Color3.fromRGB(100, 175, 100);
							else
								button.BackgroundColor3 = Color3.fromRGB(100, 100, 100);
							end
						end
						update();
						
						button.MouseButton1Click:Connect(function()
							local settingVal = modData.Settings[config.SettingsKey];
							
							local index = button:GetAttribute("SettingIndex");
							if index+1 >= #toggleOptions then
								index = 0;
							else
								index = index +1;
							end
							
							modSettings.Set(localPlayer, config.SettingsKey, index);
							update();
							
							if config.RefreshGraphics then
								modData.CameraEffects:RefreshGraphics()
							end
						end)
					end
					
					
				elseif elementInfo.TemplateName == "InputOption" then
					local textBox = elementInst:WaitForChild("TextBox");

					if config.Type == "Name" then
						local nickName = modData.Settings[config.SettingsKey] or "";
						
						textBox.PlaceholderText = localPlayer.DisplayName;
						textBox.Text = nickName;
						
						textBox.FocusLost:Connect(function(enterPressed, inputObject)
							modSettings.Set(localPlayer, config.SettingsKey, textBox.Text);
							
							nickName = modData.Settings[config.SettingsKey];
							textBox.Text = nickName;
						end)
					end
					
					
				elseif elementInfo.TemplateName == "SliderOption" then
					local button = elementInst:WaitForChild("Button");
					
					local settingVal = modData.Settings[config.SettingsKey];
					
					if config.Type == "SoundGroup" then
						config.SettingsKey = "Snd"..config.SoundGroupKey;
						config.SoundGroup = game.SoundService:FindFirstChild(config.SoundGroupKey);
						
						local rangeInfo = {Min=0; Max=100; Default=(settingVal or 50);};
						modComponents.CreateSlider(Interface, {
							Button=button;
							RangeInfo=rangeInfo;
							SetFunc=function(value)
								if value == rangeInfo.Default then
									config.SoundGroup.Volume = rangeInfo.Default;
									modSettings.Set(localPlayer, config.SettingsKey, nil);
									
								else
									if value >= rangeInfo.Max then
										value = rangeInfo.Max;
									elseif value <= rangeInfo.Min then
										value = rangeInfo.Min;
									end
									modSettings.Set(localPlayer, config.SettingsKey, value);
									config.SoundGroup.Volume = value/100;
								end
								
							end;
						});
						
					else
						local rangeInfo = config.RangeInfo;
						rangeInfo.Default = (settingVal or rangeInfo.Default);
						
						modComponents.CreateSlider(Interface, {
							Button=button;
							RangeInfo=rangeInfo;
							SetFunc=function(value)
								if value == rangeInfo.Default then
									modSettings.Set(localPlayer, config.SettingsKey, nil);

								else
									if value >= rangeInfo.Max then
										value = rangeInfo.Max;
									elseif value <= rangeInfo.Min then
										value = rangeInfo.Min;
									end
									modSettings.Set(localPlayer, config.SettingsKey, value);
								end
							end;
							DisplayValueFunc = rangeInfo.DisplayValueFunc;
						});
						
					end
				end
			end
		end

	end
	
	if Interface.InitRefreshGraphics == nil then
		Interface.InitRefreshGraphics = true;

		modData.CameraEffects:RefreshGraphics();
	end

	Interface.Garbage:Tag(modData.OnDataEvent:Connect(function(action, hierarchyKey, data)
		if action ~= "sync" then return end;

		if hierarchyKey == "Settings" then
			Interface.LoadSettings();
		end
	end));
	Interface.LoadSettings();
	
	return Interface;
end;

return Interface;