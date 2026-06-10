local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local SoundService = game:GetService("SoundService");

local localPlayer = game.Players.LocalPlayer;

local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
	local remoteGameModeLobbies = modRemotesManager:Get("GameModeLobbies");
	local remoteGameModeExit = modRemotesManager:Get("GameModeExit");

	-- MARK: GameModeEnter
	local GameModeEnter = super.newPackage{
		Name = "GameModeEnter";
        Type = "GameModeEnter";
    };

    function GameModeEnter.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;
		local mode = config:GetAttribute("Mode") :: string;
		local stage = config:GetAttribute("Stage") :: string;
		local label = config:GetAttribute("Label") :: string;

        interactable.CanInteract = true;

        interactable.Values.Mode = mode;
		interactable.Values.Stage = stage;
		
		if RunService:IsServer() then
			if config:GetAttribute("_CycleRandom") == true then
				interactable.Values.Random = true;

				task.spawn(function()
					task.wait(1);
					local list = {};
					for k, v in pairs(modGameModeLibrary.GameModes.Boss.Stages) do
						if v.IsExtreme ~= true then
							table.insert(list, {Index=(v.Index or 999); Key=k;});
						end
					end
					table.sort(list, function(a, b) return a.Index < b.Index; end);

					local index = 0;
					while true do
						index = index +1;
						if index > #list then index = 1; end;

						local stage = list[index].Key;
						interactable.Values.Stage = stage;

						interactable:Sync();

						task.wait(5);
					end
				end)
			end
		end
    end

    -- When interacting with interactable.
    function GameModeEnter.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;
		
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
    function GameModeEnter.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
		if RunService:IsServer() then return end;

		local clientData = info.ClientData;
		if clientData == nil then return end;

		interactable.CanInteract = true;

		local mode = interactable.Values.Mode;
		local stage = interactable.Values.Stage;

		local stageLib = modGameModeLibrary.GameModes[mode] and modGameModeLibrary.GameModes[mode].Stages[stage];
		if stageLib == nil or modGameModeLibrary.GameModes[mode].Stages[stage].WIP then
			if RunService:IsStudio()
			and modGameModeLibrary.GameModes[mode]
			and modGameModeLibrary.GameModes[mode].Stages[stage]
			and modGameModeLibrary.GameModes[mode].Stages[stage].WIP then
				interactable.Label = `Enter {mode}: {stage} (Studio Only WIP)`;
				return;
			end
			interactable.CanInteract = false;
			interactable.Label = "Work In Progress";
			
		else
			if stageLib.IsExtreme then
				interactable.Label = `Enter Extreme Boss: {stage}`;
			else
        		interactable.Label = `Enter {mode}: {stage}`;
			end
			
		end
    end
	
    super.registerPackage(GameModeEnter);
	

	-- MARK: GameModeExit
    local GameModeExit = super.newPackage{
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

		if interactable.Values.Mode == nil then
			interactable.Values.Mode = shared.gameConfig.GameMode;
		end
		if interactable.Values.Stage == nil then
			interactable.Values.Stage = shared.gameConfig.GameStage;
		end
		if workspace:GetAttribute("GameModeComplete") == true then
			GameModeEnter.BindInteract(interactable, info);
		end 
		
		local worldName = modBranchConfigurations.GetWorldDisplayName(modBranchConfigurations.WorldName);

		local hasClaimedRewards = interactable.Config:GetAttribute("ClaimedRewards") == true;

        local interface: Interface = modClientGuis.ActiveInterface;
		modClientGuis.promptDialogBox({
			Title=`Leave {worldName}?`;
			Desc=`Are you sure you want to leave?{hasClaimedRewards == false and ` Unclaimed rewards will be forfeited!` or ""}`;
			Buttons={
				{
					Text="Leave";
					Style="Confirm";
					OnPrimaryClick=function(dialogWindow)
						interface:ToggleGameBlinds(false, 3);
						modClientGuis.toggleWindow("GameRoom", false);
						
						local characterVars = shared.modPlayers.get(localPlayer).CharacterVars;
						characterVars.CharacterProperties.CanMove = false;
						characterVars.CharacterProperties.CanInteract = false;

						local success = remoteGameModeExit:InvokeServer("lobbyexitgame");
						if success then
							SoundService:SetListener(Enum.ListenerType.CFrame, CFrame.new(0, 1000, 0));

						else
							interface:ToggleGameBlinds(true, 1);
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

	
	-- MARK: BossExit
    local BossExit = super.newPackage{
		Name = "BossExit";
        Type = "BossExit";
    };

    function BossExit.new(interactable: InteractableInstance)
		local config = interactable.Config;
		
		interactable:SetPermissions("CanInteract", true);
	end

    function BossExit.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        local config: Configuration = interactable.Config;

        if info.Action == "Client" then 
            if info.Player == nil then return end;
            interactable:InteractServer("interact", info.Values);
            return;
        end 
        if RunService:IsClient() then return end;
        --MARK: Server

        if interactable.Values.ExitFunc then
            interactable.Values.ExitFunc(info.Player);
        end
    end

	function BossExit.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        if RunService:IsServer() then return end;
		local config = interactable.Config;

		local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
        if playerClass.Properties.InBossBattle then
            interactable.CanInteract = false;
            interactable.Label = `Door's locked until you defeat {config:GetAttribute("Stage")}`;
            return;
        end

		interactable.CanInteract = true;
		interactable.Label = "Exit";
	end

    super.registerPackage(BossExit);

end

return interactablePackage;