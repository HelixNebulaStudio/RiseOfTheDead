local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modMarkers = shared.require(game.ReplicatedStorage.Library.Markers);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interfacePackage = {
    Type = "Player";
};
--==

function interfacePackage.onRequire()
	if RunService:IsStudio() then
		shared.modCommandsLibrary.bind{
			["gamemodehud"]={
				Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
				Description = [[GameModeHud commands.
				/gamemodehud test
				]];

				RequiredArgs = 0;
				UsageInfo = "/gamemodehud test";
				Function = function() end;
				ClientFunction = function(player, args)
					local interface = modClientGuis.ActiveInterface;
					local window: InterfaceWindow = interface:GetWindow("GameModeHud");

					local action = args[1];
					if action == "test" then
						window.Binds.HudActionHandler{
							Action = "Open";
							Type = "Survival";
							Stage = "Swamplands";
							WavePass = {
								TimeLeft = math.random(0, 30);
								Players = {
									["16170943"] = {
										HasVoted = math.random(1, 2) == 1;
										VotePick = math.random(1, 2);
										RewardPick = math.random(1, 3);
									};
									["123321123"] = {
										HasVoted = math.random(1, 2) == 1;
										VotePick = math.random(1, 2);
										RewardPick = math.random(1, 3);
									};
									["1212121212"] = {
										HasVoted = math.random(1, 2) == 1;
										VotePick = math.random(1, 2);
										RewardPick = math.random(1, 3);
									};
								};
								Rewards = {
									{ItemId="p250"; Quantity=math.random(1, 32);};
									{ItemId="tacticalbow"; Quantity=1;};
									{ItemId="minigun"; Quantity=1;};
								};
							};
						}
					end
				end;
			};
		};
	end
end

function interfacePackage.newInstance(interface: InterfaceInstance)
    local remoteGameModeExit = modRemotesManager:Get("GameModeExit");
    local remoteGameModeHud = modRemotesManager:Get("GameModeHud");

	local hudData = {};
	local gameHudObjects = {};
	
	local windowFrame = script:WaitForChild("GameModeHud"):Clone();
	windowFrame.Parent = interface.ScreenGui;

    --MARK: Window
	local window: InterfaceWindow = interface:NewWindow("GameModeHud", windowFrame);
	window.IgnoreHideAll = true;
	window.ReleaseMouse = false;
	window:SetClosePosition(UDim2.new(0, 0, -1.1, 0), UDim2.new(0, 0, 0, 0));
	
    local binds = window.Binds;

	function binds.FireServer(action, ...)
		remoteGameModeHud:FireServer(action, ...);
	end

	function binds.HudActionHandler(data)
		for k, _ in pairs(data) do
			hudData[k] = data[k];
		end

		local action = data.Action;
		if action == "Open" then
			window:Open();
            window:Update();

		elseif action == "Close" then
			window:Close();
			
			for k, hudObject in pairs(gameHudObjects) do
				hudObject:SetActive(false);
			end
			modMarkers.ClearMarker("GameModeWaypoint");

		elseif action == "SetMarker" then
			if data.ClearMarker == true then
				modMarkers.ClearMarker("GameModeWaypoint");

			elseif data.Marker then
				modMarkers.SetMarker("GameModeWaypoint", data.Marker.Target, data.Marker.Label or "", data.Marker.MarkType);
				modMarkers.SetColor("GameModeWaypoint", Color3.fromRGB(255, 255, 255));
			end

		end
		
		binds.UpdateGameHud();
	end
	interface.Garbage:Tag(remoteGameModeHud.OnClientEvent:Connect(binds.HudActionHandler));
	
    interface.Scheduler.OnStepped:Connect(function(tickData: TickData)
        if tickData.ms1000 ~= true then return end;
        binds.UpdateGameHud();
    end)

	interface.Garbage:Tag(function()
		for k, hudObject in pairs(gameHudObjects) do
			hudObject:SetActive(false);
		end
	end)

    --MARK: OnToggle
    local hudModules = nil;
    window.OnToggle:Connect(function(visible)
        if visible then
            if hudModules == nil then
                hudModules = {};
                local modeHudClass = script:WaitForChild("ModeHudClass");
                for _, modeModule in pairs(modeHudClass:GetChildren()) do
					if not modeModule:IsA("ModuleScript") then continue end;
                    hudModules[modeModule.Name] = shared.require(modeModule);
                end
            end
        end
    end)
	
    --MARK: OnUpdate
    window.OnUpdate:Connect(function()
        if not windowFrame.Visible then return end;
		
		local activeMode = hudData.Type;
		
		for _, frame in pairs(windowFrame:GetChildren()) do
			if frame.Name ~= activeMode then

				local currentHudObject = gameHudObjects[frame.Name];
				if currentHudObject then
					currentHudObject:SetActive(false);
				end
				frame.Visible = false;
				
				continue;
			end
			
			frame.Visible = true;

			local currentHudObject = gameHudObjects[activeMode];
			if currentHudObject == nil and hudModules[activeMode] then
				gameHudObjects[activeMode] = hudModules[activeMode](interface, window, frame); -- new modeHud Object;
			end
			currentHudObject = gameHudObjects[activeMode];

			if currentHudObject then
				currentHudObject:SetActive(true);
				currentHudObject:Update(hudData);
			end
		end
    end)

	function binds.UpdateGameHud()
		local activeMode = hudData.Type;
		local currentHudObject = gameHudObjects[activeMode];
		if currentHudObject == nil then return end;

		if not currentHudObject.Active then return end;
		currentHudObject:Update(hudData);
	end

	interface.OnReady:Once(function()
    	local spectatorUIElement: InterfaceElement = interface:GetOrDefaultElement("SpectatorScreenElement");
		spectatorUIElement.SpectatorLeaveClick = function() 
			local worldName = modBranchConfigurations.GetWorldDisplayName(modBranchConfigurations.WorldName);

			modClientGuis.promptDialogBox({
				Title=`Leave {worldName}?`;
				Desc=`Are you sure you want to leave?`;
				Buttons={
					{
						Text="Leave";
						Style="Confirm";
						OnPrimaryClick=function(dialogWindow)
							interface:ToggleGameBlinds(false, 3);
							
							local success = remoteGameModeExit:InvokeServer();
							if success then
								
							else
								interface:ToggleGameBlinds(true, 1);
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
end

return interfacePackage;

