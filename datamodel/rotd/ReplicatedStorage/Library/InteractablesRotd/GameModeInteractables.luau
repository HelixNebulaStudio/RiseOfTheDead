local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local SoundService = game:GetService("SoundService");

local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
	local remoteGameModeLobbies = modRemotesManager:Get("GameModeLobbies");
	local remoteGameModeExit = modRemotesManager:Get("GameModeExit");

	-- MARK: GameModeEnter
	local GameModeEnter = {
		Name = "GameModeEnter";
        Type = "GameModeEnter";
    };

    function GameModeEnter.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;
		local mode = config:GetAttribute("Mode") :: string;
		local stage = config:GetAttribute("Stage") :: string;
		local label = config:GetAttribute("Label") :: string;

        interactable.CanInteract = true;
        interactable.Label = label or `Enter {mode}: {stage}`;

        interactable.Values.Mode = mode;
		interactable.Values.Stage = stage;
		
		if stage == "Random" then
			interactable.Values.Random = true;
		end
    end

    -- When interacting with interactable.
    function GameModeEnter.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;
		
		local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
		task.delay(1, function()
			modClientGuis.toggleGameBlinds(true, 0.5);
		end)

		modClientGuis.toggleGameBlinds(false, 0.5);
		local timelaspe = tick();
		local rPacket = remoteGameModeLobbies:InvokeServer("door", interactable.Config);
		task.wait(math.clamp(0.5-(tick()-timelaspe), 0, 0.5));

		if rPacket and rPacket.Success then 
			modClientGuis.toggleWindow("GameRoom", true, rPacket.LobbyData);
		else
			modClientGuis.promptWarning(rPacket.FailMsg or "Please try again!");
		end;

		task.wait(0.1);
		modClientGuis.toggleGameBlinds(true, 0.5);
    end
    
    -- When interactable pops up on screen.
	local function shuffleRandom(interactable: InteractableInstance)
		if interactable.Values.LastRandom and tick()-interactable.Values.LastRandom <= 1 then return end;
		interactable.Values.LastRandom = tick();

		
		local list = {};
		for k, v in pairs(modGameModeLibrary.GameModes.Boss.Stages) do
			if v.IsExtreme ~= true then
				table.insert(list, {Index=(v.Index or 999); Key=k;});
			end
		end
		table.sort(list, function(a, b) return a.Index < b.Index; end);
	
		if interactable.Values.SelectIndex == nil or interactable.Values.SelectIndex >= #list then
			interactable.Values.SelectIndex = 1;
			
		else
			interactable.Values.SelectIndex = interactable.Values.SelectIndex +1;
			
		end
		
		local stage = list[interactable.Values.SelectIndex].Key;
		interactable.Values.Stage = stage;
		interactable.Label = `Enter {interactable.Values.Mode}: {interactable.Values.Stage}`;
		
	end


    function GameModeEnter.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
		if RunService:IsServer() then return end;

		local clientData = info.ClientData;
		if clientData == nil then return end;

		interactable.CanInteract = true;

		if interactable.Values.Random == true then
			shuffleRandom(interactable);
			return;
		end
		
		local mode = interactable.Values.Mode;
		local stage = interactable.Values.Stage;

		local stageLib = modGameModeLibrary.GameModes[mode] and modGameModeLibrary.GameModes[mode].Stages[stage];
		if stageLib == nil or modGameModeLibrary.GameModes[mode].Stages[stage].Disabled then
			if RunService:IsStudio()
			and modGameModeLibrary.GameModes[mode]
			and modGameModeLibrary.GameModes[mode].Stages[stage]
			and modGameModeLibrary.GameModes[mode].Stages[stage].Disabled then
				Debugger:Log("Work In Progress");
				return;
			end
			interactable.CanInteract = false;
			interactable.Label = "Work In Progress";
			
		else
			if stageLib.IsExtreme then
				interactable.Label = `Enter Extreme Boss: {stage}`;
			end
			
		end
    end
	
    super.registerPackage(GameModeEnter);
	

	-- MARK: GameModeExit
    local GameModeExit = {
		Name = "GameModeExit";
        Type = "GameModeExit";
    };

    function GameModeExit.new(interactable: InteractableInstance)
		local config = interactable.Config;
		local label = config:GetAttribute("Label");
		local mode = config:GetAttribute("Mode");
		local stage = config:GetAttribute("Stage");

        interactable.CanInteract = true;
        interactable.Label = label or "Exit";

        interactable.Values.Mode = mode;
		interactable.Values.Stage = stage;
    end

    -- When interacting with interactable.
    function GameModeExit.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

		local mode = interactable.Values.Mode;
		if mode == "Raid" and workspace:GetAttribute("GameModeComplete") == true then
			GameModeEnter.BindInteract(interactable, info);
		end 
		
		local worldName = modBranchConfigs.GetWorldDisplayName(modBranchConfigs.WorldName);

        local interface: Interface = modClientGuis.ActiveInterface;
		modClientGuis.promptDialogBox({
			Title=`Leave {worldName}?`;
			Desc=`Are you sure you want to leave?`;
			Buttons={
				{
					Text="Leave";
					Style="Confirm";
					OnPrimaryClick=function(dialogWindow)
						interface:ToggleGameBlinds(false, 3);
						modClientGuis.toggleWindow("GameRoom", false);
						
						local characterVars = info.CharacterVars;
						characterVars.CharacterProperties.CanMove = false;
						characterVars.CharacterProperties.CanInteract = false;

						local success = remoteGameModeExit:InvokeServer("lobbyexitgame");
						if success then
							SoundService:SetListener(Enum.ListenerType.CFrame, CFrame.new(0, 1000, 0));

						else
							interface:ToggleGameBlinds(true, 1);
							SoundService:SetListener(Enum.ListenerType.ObjectCFrame, characterVars.RootPart);
							characterVars.CharacterProperties.CanMove = true;
							characterVars.CharacterProperties.CanInteract = true;
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
    
    super.registerPackage(GameModeExit);
end

return interactablePackage;