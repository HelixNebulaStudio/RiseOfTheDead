local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait(); until script.Parent.Enabled == true;

--== Variables;
local RunService = game:GetService("RunService");
local StarterGui = game:GetService("StarterGui");
local GuiService = game:GetService("GuiService");
local UserInputService = game:GetService("UserInputService");
local ContextActionService = game:GetService("ContextActionService");
local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;
local character = localPlayer.Character;

local remotes = game.ReplicatedStorage:WaitForChild("Remotes", 10);

local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations", 10));
local modBranchConfigs = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));

local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = require(character:WaitForChild("CharacterModule") :: ModuleScript);

Debugger:Log("InterfaceModule loading.");
local modInterface = require(script.Parent.InterfaceModule);
modInterface.modCharacter = modCharacter;
modInterface.NavBarFrame = script.Parent:WaitForChild("QuickButtons");
Debugger:Log("InterfaceModule loaded.");

if modConfigurations.AutoOpenBlinds then 
	modInterface:ToggleGameBlinds(true, 3);
end; 

local humanoid = character:WaitForChild("Humanoid");

local modStorageInterface = require(game.ReplicatedStorage.Library.UI.StorageInterface);
modStorageInterface.init();
modStorageInterface.GlobalDescFrame.Parent = script.Parent;

local modLeaderboardInterface = require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);
modLeaderboardInterface.SetModInterface(modInterface);

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modChatInterface = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("ChatInterface"));
local modAudio = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("Audio"));
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);

local branchColor = modBranchConfigs.BranchColor;

local remotePromptWarning = remotes.Interface.PromptWarning;
local remoteContinueScene = remotes.Cutscene.ContinueScene;

local remoteHudNotification = modRemotesManager:Get("HudNotification");

local generalStats = script.Parent:WaitForChild("GeneralStats");
local ProgressionFrame = script.Parent:WaitForChild("ProgressionBar");
local progressionBar = ProgressionFrame:WaitForChild("Bar");
local progressionLabel = ProgressionFrame:WaitForChild("label");
local majorFrame = script:WaitForChild("MajorNoteFrame");

if modConfigurations.CompactInterface then
	generalStats.Position = UDim2.new(0.5, 0, 1, -6);
	generalStats.Size = UDim2.new(0.55, 0, 0, 14);
	
	ProgressionFrame:WaitForChild("UIPadding").PaddingBottom = UDim.new(0, 0);
	ProgressionFrame.UIPadding.PaddingLeft = UDim.new(0, 0);
	ProgressionFrame.UIPadding.PaddingRight = UDim.new(0, 0);
	ProgressionFrame.UIPadding.PaddingTop = UDim.new(0, 0);
	ProgressionFrame.Position = UDim2.new(0.5, 0, 1, -6);
	ProgressionFrame.Size = UDim2.new(0.55, 0, 0, 14);
	progressionLabel.TextSize = 9;
end

local majorNotificitionQueue = {}; local flushingMajorNotifications = false; local displayingMasteryLevel = true;
local hotbarKeyCode = {
	Enum.KeyCode.One;
	Enum.KeyCode.Two;
	Enum.KeyCode.Three;
	Enum.KeyCode.Four;
	Enum.KeyCode.Five;
	Enum.KeyCode.Six;
	Enum.KeyCode.Seven;
	Enum.KeyCode.Eight;
	Enum.KeyCode.Nine;
	Enum.KeyCode.Zero;
}
--== Script;
local function updateOmniLabel()
	local vText = "";
	local upTime = modSyncTime.ToString(os.time()-modSyncTime.GetUpTime());
	
	if modGlobalVars.EngineMode == "RiseOfTheDead" then
		vText = "$fps fps\t"..(upTime.."\tRevived "..modGlobalVars.GameVersion.." Beta "..(modData:IsMobile() and "M" or ""))
	else
		vText = modGlobalVars.ModeVerLabel:gsub("$UpTime", upTime);
	end

	vText = string.gsub(vText, "$fps", Debugger.ClientFps);
	
	local verLabel = script.Parent:WaitForChild("VersionLabel");
	verLabel.Text = vText;
	
	if modConfigurations.VersionLabelSide == "Left" then
		verLabel.TextXAlignment = Enum.TextXAlignment.Left;
	elseif modConfigurations.VersionLabelSide == "Center" then
		verLabel.TextXAlignment = Enum.TextXAlignment.Center;
	else
		verLabel.TextXAlignment = Enum.TextXAlignment.Right;
	end

	if modConfigurations.CompactInterface then
		verLabel.Size = UDim2.new(1, -10, 0, 10);
	end
end
task.spawn(function()
	while script.Parent do
		updateOmniLabel();
		task.wait(0.2);
	end
end)

Debugger:Log("Loading main user interface..");
if modConfigurations.DisableRbxEmotes then
	ContextActionService:UnbindAction("EmotesMenuToggleAction");
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false);
else
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true);
end

CollectionService:GetInstanceAddedSignal("PlayerNameDisplays"):Connect(function()
	modInterface.modSettingsInterface.CinematicModeRefresh();
end)

local function MajorNotification(Type, notificationData)
	local modItemLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
	
	table.insert(majorNotificitionQueue, function(timerOveride)
		if not modConfigurations.DisableMajorNotifications then
			local values = notificationData;
			local displayFrame = majorFrame:Clone();
			local titleImage = displayFrame:WaitForChild("Title");
			local titleLabel = displayFrame:WaitForChild("Label");
			local titleText = "";
			TweenService:Create(titleImage, TweenInfo.new(0), {ImageTransparency=1}):Play();
			TweenService:Create(titleLabel, TweenInfo.new(0), {TextTransparency=1; TextStrokeTransparency=1;}):Play();
			if Type == "Levelup" then
				titleImage.Image = "rbxassetid://2048330360";
				titleText = ("You are now mastery level $Level!"):gsub("$Level", values.Level or "NIL");
				modInterface.modMasteryInterface.Update();
				modAudio.Play("LevelUp");
				
			elseif Type == "Unlocked" then
				titleImage.Image = "rbxassetid://2696762854";
				titleText = ("You have unlocked $Name!"):gsub("$Name", values.Name or "NIL");
				modAudio.Play("Unlocked");
				
			elseif Type == "MissionFail" then
				titleImage.Image = "rbxassetid://3376501069";
				titleText = ("You have failed $Name!"):gsub("$Name", values.Name or "NIL");
				modAudio.Play("MissionFail");
				
			elseif Type == "MissionComplete" then
				titleImage.Image = "rbxassetid://2740686675";
				titleText = ("You have completed $Name!"):gsub("$Name", values.Name or "NIL");
				modAudio.Play("MissionComplete");
				
			elseif Type == "MissionStart" then
				titleImage.Image = "rbxassetid://2741993719";
				titleText = ("You have started $Name!"):gsub("$Name", values.Name or "NIL");
				modAudio.Play("MissionStart");
			
			elseif Type == "HordeAttack" then
				titleImage.Image = "rbxassetid://4473237759";
				titleText = ("The horde is attacking $Name!"):gsub("$Name", values.Name or "NIL");
				modAudio.Play("HordeGrowl");	

			elseif Type == "Breach" then
				titleImage.Image = "rbxassetid://4473237759";
				titleText = "There's a breach in a safehome!";
				modAudio.Play("TerrorAlert");
				
				
			elseif Type == "PremiumAward" then
				titleImage.Image = "rbxassetid://3235348619";
				titleText = ("$PlayerName have been upgrade to Premium!"):gsub("$PlayerName", localPlayer.Name);
				modAudio.Play("Ascended");

			elseif Type == "WeaponLevelup" then
				local storageItem = values.StorageItem;
				
				local itemLib = modItemLibrary:Find(storageItem.ItemId);
				
				titleImage.Image = "rbxassetid://2048330360";
				titleText = itemLib.Name.." leveled up to "..values.Level.."! Weapon mastery+ Weapon damage+"
				modAudio.Play("WeaponLevelUp");
				
			elseif Type == "BattlePassLevelUp" then
				titleImage.Image = "rbxassetid://2048330360";
				titleText = "Event Pass leveled up to ".. values.Level .."!".. (values.HasRewards and " Check your missions menu for rewards!" or "");
				modAudio.Play("Collectible");
				
			elseif Type == "BattlePassComplete" then
				titleImage.Image = "rbxassetid://2740686675";
				titleText = "You have completed Event Pass: ".. values.Title .."!";
				modAudio.Play("Ascended");

				
			end
			
			titleLabel.TextColor3 = branchColor;
			titleLabel.Text = titleText;
			titleImage.Size = UDim2.new(1, 0, 0.4, 0);
			displayFrame.Parent = script.Parent;
			displayFrame.Visible = true;
			titleImage:TweenSize(UDim2.new(1, 0, 0.8, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, timerOveride*3, true);
			TweenService:Create(titleImage, TweenInfo.new(timerOveride, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {ImageTransparency=0}):Play();
			TweenService:Create(titleLabel, TweenInfo.new(timerOveride, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {TextTransparency=0; TextStrokeTransparency=0.7;}):Play();
			wait(timerOveride*5);
			TweenService:Create(titleImage, TweenInfo.new(timerOveride, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {ImageTransparency=1}):Play();
			TweenService:Create(titleLabel, TweenInfo.new(timerOveride, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {TextTransparency=1; TextStrokeTransparency=1;}):Play();
			wait(timerOveride);
			displayFrame.Visible = false;
			game.Debris:AddItem(displayFrame, 0.1);
		end
	end);
	if not flushingMajorNotifications then
		flushingMajorNotifications = true;
		repeat
			majorNotificitionQueue[1](1/#majorNotificitionQueue);
			table.remove(majorNotificitionQueue, 1);
		until #majorNotificitionQueue <= 0;
		flushingMajorNotifications = false;
	end
end
remoteHudNotification.OnClientEvent:Connect(MajorNotification)

UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
	--local modInterface = modData:GetInterfaceModule();
	--if inputEvent then return end;
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		modStorageInterface.Button1Down = true;
		modInterface.Button1Down = true;
		if not gameProcessed then
			modInterface:RefreshVisibility();
		end
	end
	
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
		modInterface.PrimaryInputDown = true;
		modStorageInterface.PrimaryInputDown = true;
	end
	if inputObject.KeyCode == Enum.KeyCode.LeftShift then
		modStorageInterface.LeftShiftDown = true;
	end
	if script.Parent.CutsceneNextButton.Visible and (inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch) then
		remoteContinueScene:FireServer();
		script.Parent.CutsceneNextButton.Visible = false;
	end
	if UserInputService:GetFocusedTextBox() ~= nil then return end;
	

	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
		if not gameProcessed then
			modStorageInterface.CloseOptionMenus();
		end
	end
	
	if script.Parent.Enabled then
		if modInterface.DisableHotKeys then return end;
		if inputObject.KeyCode == Enum.KeyCode.Escape then
			modInterface:HideAll();
			
		elseif modKeyBindsHandler:Match(inputObject, "KeyWindowWorkbench") then
			if not modConfigurations.DisableWorkbench and modData.Profile and modData.Profile.GamePass and modData.Profile.GamePass.PortableWorkbench then
				modInterface:ToggleWindow("Workbench");
			end
			
		elseif inputObject.KeyCode == Enum.KeyCode.F1 then
			modInterface:ToggleWindow("UpdateWindow");
			
		elseif inputObject.KeyCode == Enum.KeyCode.F2 then
			if not modConfigurations.DisableSettingsMenu then
				modInterface:ToggleWindow("Settings");
			end
			
		elseif modKeyBindsHandler:Match(inputObject, "KeyHideHud") then
			if script.Parent.Enabled then
				localPlayer:SetAttribute("DisableHud", true);
				
				local new = script:WaitForChild("tempHiddenHudScript"):Clone();
				local keyTag = new:WaitForChild("Key");
				keyTag.Value = modKeyBindsHandler:ToString("KeyHideHud");
				new.Parent = localPlayer.PlayerGui;
				new.Disabled = false;
				script.Parent.Enabled = false;
				
				modConfigurations.Set("DisableWeaponInterface", true);
			end
			
		elseif inputObject.KeyCode == Enum.KeyCode.F3 and modGlobalVars.EngineMode == "RiseOfTheDead" then
			modInterface:ToggleWindow("ReportMenu");
			
		elseif modKeyBindsHandler:Match(inputObject, "KeyInteract") and not modInterface:IsVisible("Settings") then
			modInterface:HideAll();
			
		else
			if modCharacter.CharacterProperties.IsAlive and modInterface.ActiveWindowsKey == nil then
				for keyName, keyLib in pairs(modKeyBindsHandler.DefaultKeybind) do
					if keyName:sub(1, 9) == "KeyWindow" then
						local windowName = keyName:sub(10, #keyName);
						
						if modKeyBindsHandler:Match(inputObject, keyName) and not modConfigurations["Disable"..windowName] then
							local window = modInterface:GetWindow(windowName);
							if window then

								modInterface:ToggleWindow(windowName);

								if window.FocusWindowKeyDown and inputObject.UserInputType == Enum.UserInputType.Keyboard then
									modInterface.ActiveWindowsKey = inputObject.KeyCode;
								end
							end
							
						end
					end
				end
			end
		end
		
		if modInterface.modInventoryInterface then
			local hotbarSlots = modInterface.modInventoryInterface.HotbarSlotsNum;
			for a=1, math.clamp(hotbarSlots or 5, 1, 10) do
				if inputObject.KeyCode == hotbarKeyCode[a] and modConfigurations.CanQuickEquip 
					and modInterface.ActiveWindowsKey == nil 
					and modInterface.DisableGameplayBinds == false then
					
					modInterface.modInventoryInterface.HotEquip(a);
					modInterface.ActiveEquip = a;
					break;
				end
			end
		
			if inputObject.KeyCode == Enum.KeyCode.ButtonL1 then
				if modInterface.ActiveEquip == nil then modInterface.ActiveEquip = 0; end
				modInterface.ActiveEquip = math.clamp(modInterface.ActiveEquip -1, 1, hotbarSlots);
				modInterface.modInventoryInterface.HotEquip(modInterface.ActiveEquip);
				
			elseif inputObject.KeyCode == Enum.KeyCode.ButtonR1 then
				if modInterface.ActiveEquip == nil then modInterface.ActiveEquip = hotbarSlots+1; end
				modInterface.ActiveEquip = math.clamp(modInterface.ActiveEquip +1, 1, hotbarSlots);
				modInterface.modInventoryInterface.HotEquip(modInterface.ActiveEquip);
				
			end
		end
	end
end);

UserInputService.InputEnded:Connect(function(inputObject, gameProcessed)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		modStorageInterface.Button1Down = false;
		modInterface.Button1Down = false;
	end
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
		modInterface.PrimaryInputDown = false;
		modStorageInterface.PrimaryInputDown = false;
	end
	if inputObject.KeyCode == Enum.KeyCode.LeftShift then
		modStorageInterface.LeftShiftDown = false;
	end
	if modInterface.ActiveWindowsKey == inputObject.KeyCode then
		modInterface.ActiveWindowsKey = nil;
	end
end)

local previousStats = {};

-- !outline: Interface:Bind    UpdateStats
modInterface:Bind("UpdateStats", function()
	if not localPlayer:IsAncestorOf(generalStats) then return; end
	local stats = modData.GameSave and modData.GameSave.Stats;
	if stats then
		generalStats.Visible = not modConfigurations.DisableGeneralStats;
		for key, value in pairs(stats) do
			local label = (key == "Money" and generalStats.moneylabel) or (key == "Perks" and generalStats.perkslabel) or nil;
			if label then
				if previousStats[key] == nil then 
					previousStats[key] = Instance.new("NumberValue", label);
					previousStats[key]:GetPropertyChangedSignal("Value"):Connect(function()
						if label.Name == "moneylabel" then
							label.Text = "Money: "..math.floor(previousStats[key].Value);
						elseif label.Name == "perkslabel" then
							local perks = math.floor(previousStats[key].Value);
							label.Text = perks > 1 and perks.." :Perks" or perks.." :Perk";
						end
					end)
				end;
				if previousStats[key] then
					local duration = 2;
					if value > previousStats[key].Value then
						label.TextColor3=Color3.fromRGB(149, 221, 115);

						TweenService:Create(label, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
							TextColor3=Color3.fromRGB(255, 255, 255);
						}):Play();

						delay(duration+0.02, function() label.TextColor3=Color3.fromRGB(255, 255, 255); end);
					elseif value < previousStats[key].Value then
						label.TextColor3=Color3.fromRGB(147, 49, 49);

						TweenService:Create(label, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
							TextColor3=Color3.fromRGB(255, 255, 255);
						}):Play();

						delay(duration+0.02, function() label.TextColor3=Color3.fromRGB(255, 255, 255); end);
					end
					TweenService:Create(previousStats[key], TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Value=value;
					}):Play();
					delay(duration+0.02, function() 
						previousStats[key].Value = value;
					end)
				end
			end
			if key == "Level" and displayingMasteryLevel then
				progressionLabel.Text = "Mastery Level: ".. tostring(value or 0);
				modInterface.modMasteryInterface.Update();
			end
		end
	else
		generalStats.Visible = false;
	end
end)


local fullShown = false;
modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
	if modSyncTime.GetTime()%3 == 0 then
		local stats = modData.GameSave and modData.GameSave.Stats;
		if stats then
			local money = stats.Money or 0;
			if money >= modGlobalVars.MaxMoney and not fullShown then
				generalStats.moneylabel.Text = "Maxed Money";
				
			else
				generalStats.moneylabel.Text = "Money: "..math.floor(money);
			end
			
			local perks = stats.Perks or 0;
			if perks >= modGlobalVars.MaxPerks and not fullShown then
				generalStats.perkslabel.Text = "Maxed Perks";
				
			else
				generalStats.perkslabel.Text = perks.." :Perks"
			end
			
			fullShown = not fullShown;
		end
	end
end)

local progressionPoint = 0;
function UpdateProgressionBar(progress, labelId, value)
	progress = progress or 0;
	
	displayingMasteryLevel = false;
	if labelId == "Heal" then
		progressionLabel.Text = ("Healing: $value/100%"):gsub("$value", math.ceil(progress*100));
		
	elseif labelId == "Throw" then
		progressionLabel.Text = ("Throw Strength: $value/100%"):gsub("$value", math.ceil(progress*100));
		
	elseif labelId == "Building" then
		progressionLabel.Text = ("Building: $value/100%"):gsub("$value", math.ceil(progress*100));
		
	elseif labelId == "Eating" then
		progressionLabel.Text = ("Consuming: $value/100%"):gsub("$value", math.ceil(progress*100));
		
	elseif labelId == "WeaponLevel" then
		progressionLabel.Text = "Weapon Level: ".. tostring(value or 0);

	elseif labelId == "MeleeStamina" then
		if modData.MeleeStats then
			progressionLabel.Text = "Melee Stamina: "..math.ceil(modData.MeleeStats.Stamina).."/"..math.ceil(modData.MeleeStats.MaxStamina);
		end
		
	else
		displayingMasteryLevel = true;
		progressionLabel.Text = "Mastery Level: ".. tostring(modData.GetStat("Level") or 0);
		
	end
	
	if progress > 0 then progressionBar.BorderSizePixel = 2; end
	progressionPoint = progress;
end

local prevProgressionValue = progressionPoint;
RunService:BindToRenderStep("ProgressionBarRender", Enum.RenderPriority.Last.Value, function(delta)
	prevProgressionValue = math.clamp(prevProgressionValue + 0.1 * (progressionPoint - prevProgressionValue), 0, 1);
	progressionBar.Size = UDim2.new(prevProgressionValue, 0, 1, 0);
	
	if progressionBar.AbsoluteSize.X >= 1 then
		progressionBar.BorderSizePixel = 2;
	else
		progressionBar.BorderSizePixel = 0;
	end
end)

local classPlayer = shared.modPlayers.Get(localPlayer);
classPlayer:OnNotIsAlive(function(character)
	modInterface:HideAll();
end)

function NewConfigSync(key, frame, frames, conditions)
	local function toggle(object, disabled)
		if object == nil then return end;
		local visible = not disabled;
		if conditions then
			visible = visible and conditions()
		end

		if object:IsA("ScreenGui") then
			object.Enabled = visible;
		elseif object:IsA("GuiObject") then
			object.Visible = visible;
		end
	end
	toggle(frame, modConfigurations[key] or false);
	modConfigurations.OnChanged(key, function(oldValue, disabled)
		toggle(frame, disabled);
		if frames then
			for a=1, #frames do
				toggle(frames[a], disabled);
			end
		end
	end)
end

-- NewConfigSync deprecated, use Window:SetConfigKey();
NewConfigSync("DisableCutsceneNext", script.Parent.CutsceneNextButton)
NewConfigSync("DisableExperiencebar", script.Parent.ProgressionBar)
NewConfigSync("DisableGeneralStats", script.Parent.GeneralStats)

remoteContinueScene.OnClientEvent:Connect(function(disabled)
	modConfigurations.Set("DisableCutsceneNext", disabled); 
end)

remotePromptWarning.OnClientEvent:Connect(function(message)
	modInterface:PromptWarning(message);
end)


local soundGroups = game.SoundService:GetChildren();
for a=1, #soundGroups do
	local settingsKey = "Snd"..soundGroups[a].Name;
	local volume = modData.Settings[settingsKey];
	if volume then
		soundGroups[a].Volume = volume/100;
	end
end


game.Players.PlayerAdded:Connect(modInterface.modSocialInterface.Update);
game.Players.PlayerRemoving:Connect(modInterface.modSocialInterface.Update);

modData.UpdateProgressionBar = UpdateProgressionBar;

modInterface:Bind("UpdateProgressionBar", UpdateProgressionBar); UpdateProgressionBar();
modInterface:Bind("UpdateMailbox", modInterface.modMailboxInterface.Update);

local cacheFrame = script.Parent:WaitForChild("Cache");
cacheFrame.Visible = true;
spawn(function() cacheFrame.Visible = false; end);

local oldRbxChat = script.Parent:FindFirstChild("Chat");
if oldRbxChat then oldRbxChat.Enabled = false; end;

if not modConfigurations.DisableUpdateLogs then
	local playerStats = modData.GameSave and modData.GameSave.Stats;
	if playerStats == nil or playerStats.Level <= 20 then Debugger:Log("Skip update logs prompt.") return end;
	
	while modData.GameSave == nil or modData.GameSave.LoadVersion == nil do
		task.wait(1);
	end
	local saveVersion = modData.GameSave and modData.GameSave.LoadVersion
	
	local newVersion = (modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild);
	if saveVersion ~= newVersion then
		modData.GameSave.LoadVersion = newVersion;
		modInterface:ToggleWindow("UpdateWindow", true);
	end
end

local function updateTopbarGuiObjects()
	local height = GuiService.TopbarInset.Height;
	local minX = GuiService.TopbarInset.Min.X;
	modInterface.NavBarFrame.Position = UDim2.new(0, minX+14, 0, 4);
	modInterface.NavBarFrame.Size = UDim2.new(0, 32, 0, height);
end
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(updateTopbarGuiObjects);
updateTopbarGuiObjects();

Debugger:Log("Loaded main user interface..");

modInterface:CallBind("UpdateStats");


script.Parent.CutsceneNextButton.MouseButton1Click:Connect(function()
	remoteContinueScene:FireServer();
	script.Parent.CutsceneNextButton.Visible = false;
end)