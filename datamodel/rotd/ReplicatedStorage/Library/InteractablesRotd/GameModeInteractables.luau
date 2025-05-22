local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local SoundService = game:GetService("SoundService");

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
	local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
	local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
	local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
	
	local remoteGameModeLobbies = modRemotesManager:Get("GameModeLobbies");
	local remoteGameModeExit = modRemotesManager:Get("GameModeExit");

	-- MARK: GameModeEnter
	local GameModeEnter = {
		Name = "GameModeEnter";
        Type = "GameModeEnter";
    };

    function GameModeEnter.new(interactable: InteractableInstance, mode: string?, stage: string?, label: string?)
        local scr: ModuleScript = interactable.Script;
		mode = mode or (scr:GetAttribute("Mode") :: string);
		stage = stage or (scr:GetAttribute("Stage") :: string);
		label = label or (scr:GetAttribute("Label") :: string);

        interactable.CanInteract = true;
        interactable.Label = `Enter {mode}: {stage}`;

        interactable.Values.Mode = mode;
		interactable.Values.Stage = stage;
		
		if stage == "Random" then
			interactable.Values.Random = true;
		end
    end

    -- When interacting with interactable.
    function GameModeEnter.ActionEvent(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionTypes.ClientInteract then return end;

        local interface = info.ClientInterface;
        if interface == nil then return end;

		task.delay(1, function()
			interface:ToggleGameBlinds(true, 0.5);
		end)
		interface:ToggleGameBlinds(false, 0.5);

		local timelaspe = tick();
		local lobbyData = remoteGameModeLobbies:InvokeServer(
			interactable.Object,
			interactable.Script,
			{
				StageSelect = interactable.Values.Random and interactable.Values.Stage or nil;
			}
		);
		task.wait(math.clamp(0.5-(tick()-timelaspe), 0, 0.5));

		if lobbyData == nil or info.ClientData == nil then return end;
		info.ClientData.LobbyInterfaceRequest(lobbyData);
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

    function GameModeEnter.PromptEvent(interactable: InteractableInstance, info: InteractInfo)
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
	
    super.register(GameModeEnter);
	

	-- MARK: GameModeExit
    local GameModeExit = {
		Name = "GameModeExit";
        Type = "GameModeExit";
    };

    function GameModeExit.new(interactable: InteractableInstance, mode: string?, stage: string?, label: string?)
        interactable.CanInteract = true;
        interactable.Label = label or "Exit";

        interactable.Values.Mode = mode;
		interactable.Values.Stage = stage;
    end

    -- When interacting with interactable.
    function GameModeExit.ActionEvent(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionTypes.ClientInteract then return end;

        local interface = info.ClientInterface;
        if interface == nil or interface:IsVisible("Dialogue") then return end;
		
		local mode = interactable.Values.Mode;
		if mode == "Raid" and workspace:GetAttribute("GameModeComplete") == true then
			GameModeEnter.ActionEvent(interactable, info);
		end 
		
		local worldName = modBranchConfigs.GetWorldDisplayName(modBranchConfigs.WorldName);
		interface:PromptDialogBox({
			Title=`Leave {worldName}?`;
			Desc=`Are you sure you want to leave?`;
			Buttons={
				{
					Text="Leave";
					Style="Confirm";
					OnPrimaryClick=function(promptDialogFrame, textButton)
						interface:ToggleGameBlinds(false, 3);
						
						local characterVars = info.CharacterVars;
						characterVars.CharacterProperties.CanMove = false;
						characterVars.CharacterProperties.CanInteract = false;

						local success = remoteGameModeExit:InvokeServer(interactable.Object, interactable.Script);
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
    
    super.register(GameModeExit);
end

return interactablePackage;