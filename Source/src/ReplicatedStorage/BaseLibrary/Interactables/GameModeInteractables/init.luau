local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local SoundService = game:GetService("SoundService");

local localPlayer = game:GetService("Players").LocalPlayer;
--==
local InteractableHandler = {};
InteractableHandler.__index = InteractableHandler;

function InteractableHandler.init(super: Interactables) -- Server/Client
	local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);
	local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
	local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
	
	local remoteGameModeLobbies = modRemotesManager:Get("GameModeLobbies");
	local remoteGameModeExit = modRemotesManager:Get("GameModeExit");

	function super.GameMode()
		Debugger:Warn("Deprecated interactable.", debug.traceback());
		return super.new();
	end

    function super.GameModeEnter(src: ModuleScript, prefab: (Model | Actor)?, mode: string?, stage: string?, label: string?): Interactable
		mode = mode or (src:GetAttribute("Mode") :: string);
		stage = stage or (src:GetAttribute("Stage") :: string);
		label = label or (src:GetAttribute("Label") :: string);

		local new: Interactable, meta: InteractableMeta = super.new(src, prefab);

		meta.CanInteract = true;
		meta.Label = label or `Enter {mode}: {stage}`;

		new.Type = "GameModeEnter";
		new.Mode = mode;
		new.Stage = stage;
		if stage == "Random" then
			new.Random = true;
		end

		function new:OnSync(data)
			self.Label = data.Label or self.Label;
			
			self.CanInteract = data.CanInteract or self.CanInteract;
			self.InspectMode = data.InspectMode or self.InspectMode;
		end

		function new:OnTrigger()
			if self.Random == true and (self.LastRandom == nil or tick()-self.LastRandom > 1) then
				self.LastRandom = tick();
				
				local list = {};
				for k, v in pairs(modGameModeLibrary.GameModes.Boss.Stages) do
					if v.IsExtreme ~= true then
						table.insert(list, {Index=(v.Index or 999); Key=k;});
					end
				end
				table.sort(list, function(a, b) return a.Index < b.Index; end);
				
				if self.SelectIndex == nil or self.SelectIndex >= #list then
					self.SelectIndex = 1;
					
				else
					self.SelectIndex = self.SelectIndex +1;
					
				end
				
				stage = list[self.SelectIndex].Key;
				self.Stage = stage;
				
				self.CanInteract = true;
				self.Label = `Enter {mode}: {stage}`;
			end
			
			local stageLib = modGameModeLibrary.GameModes[mode] and modGameModeLibrary.GameModes[mode].Stages[stage];
			if self.Random == true then
			elseif stageLib == nil or modGameModeLibrary.GameModes[mode].Stages[stage].Disabled then
				if RunService:IsStudio()
				and modGameModeLibrary.GameModes[mode]
				and modGameModeLibrary.GameModes[mode].Stages[stage]
				and modGameModeLibrary.GameModes[mode].Stages[stage].Disabled then
					Debugger:Log("Work In Progress");
					return;
				end
				self.CanInteract = false;
				self.Label = "Work In Progress";
				
			else
				if stageLib.IsExtreme then
					meta.Label = `Enter Extreme Boss: {stage}`;
				end
				
			end
		end

		function new:OnInteracted()
			local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
			local modInterface = modData:GetInterfaceModule();

			task.delay(1, function()
				modInterface:ToggleGameBlinds(true, 0.5);
			end)
			modInterface:ToggleGameBlinds(false, 0.5);
			
			local timeLapse = tick();
			local lobbyData = remoteGameModeLobbies:InvokeServer(self.Object, self.Script, {StageSelect=self.Random == true and self.Stage or nil;});
			task.wait(math.clamp(0.5-(tick()-timeLapse), 0, 0.5));
	
			if lobbyData == nil then return; end
			modData.LobbyInterfaceRequest(lobbyData);
		end

		return new;
    end
	
    function super.GameModeExit(src: ModuleScript, prefab: (Model | Actor)?, mode: string?, stage: string?, label: string?): Interactable
		local new: Interactable, meta: InteractableMeta = super.new(src, prefab);

		meta.CanInteract = true;
		meta.Label = label or `{mode}: {stage}`;

		new.Type = "GameModeExit";
		new.Mode = mode;
		new.Stage = stage;

		function new:OnInteracted()
			local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
			local modInterface = modData:GetInterfaceModule();
			local modCharacter = modData:GetModCharacter();

			if mode == "Raid" and workspace:GetAttribute("GameModeComplete") == true then
				task.delay(0.5, function()
					modInterface:ToggleGameBlinds(true, 0.5);
				end)
				modInterface:ToggleGameBlinds(false, 0.5);

				local timeLapse = tick();
				local lobbyData = remoteGameModeLobbies:InvokeServer(self.Object, self.Script, {StageSelect=self.Random == true and self.Stage or nil;});
				task.wait(math.clamp(0.5-(tick()-timeLapse), 0, 0.5));
				
				if lobbyData == nil then return; end
				modData.LobbyInterfaceRequest(lobbyData);
				return;
			end 
			
			local worldName = modBranchConfigs.GetWorldDisplayName(modBranchConfigs.WorldName);
			modInterface:PromptDialogBox({
				Title=`Leave {worldName}?`;
				Desc=`Are you sure you want to leave?`;
				Buttons={
					{
						Text="Leave";
						Style="Confirm";
						OnPrimaryClick=function(promptDialogFrame, textButton)
							modInterface:ToggleGameBlinds(false, 3);
							
							modCharacter.CharacterProperties.CanMove = false;
							modCharacter.CharacterProperties.CanInteract = false;

							local success = remoteGameModeExit:InvokeServer(self.Object, self.Script);
							if success then
								SoundService:SetListener(Enum.ListenerType.CFrame, CFrame.new(0, 1000, 0));

							else
								modInterface:ToggleGameBlinds(true, 1);
								SoundService:SetListener(Enum.ListenerType.ObjectCFrame, modCharacter.RootPart);
								modCharacter.CharacterProperties.CanMove = true;
								modCharacter.CharacterProperties.CanInteract = true;
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

		return new;
	end
end

return InteractableHandler;
