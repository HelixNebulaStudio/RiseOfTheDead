local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local baseInteractable = script:WaitForChild("Interactable");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local remoteGameModeLobbies = modRemotesManager:Get("GameModeLobbies");

local remotes = game.ReplicatedStorage.Remotes;
local bindOpenLobbyInterface = remotes.LobbyInterface.OpenLobbyInterface;

local toolPackage = {
	Type="RoleplayTool";
	Animations={
		Core={Id=8388875136;};
		Use={Id=8388988860};
	};
};

function toolPackage.NewToolLib(handler)
	local Tool = {};

	function Tool:OnEquip()
		self.InteractData = require(self.ToolConfig.InteractScript);
	end
	
	function Tool:OnPrimaryFire(isActive, ...)
		self.IsActive = isActive;

		local weaponModel = self.Prefabs[1];
		local handle = weaponModel.Handle;

		for _, obj in pairs(handle:GetChildren()) do
			if obj.Name == "Interactable" and obj:IsA("ModuleScript") then
				obj:Destroy();
			end
		end

		if self.IsActive then
			local copyInteractable = self.ToolConfig.InteractScript:Clone();
			copyInteractable.Parent = handle;
		end
	end

	Tool.ItemPromptHint = " to use map.";

	function Tool:ClientItemPrompt()
		local player = game.Players.LocalPlayer;
		local classPlayer = shared.modPlayers.Get(player);

		local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
		local modInterface = modData:GetInterfaceModule();
		
		if classPlayer.Properties.InBossBattle or modConfigurations.DisableMapItems  then
			modInterface:HintWarning("Cant use this right now!");
			Debugger:Warn("InBossBattle", tostring(classPlayer.Properties.InBossBattle), "DisableMapItems", tostring(modConfigurations.DisableMapItems));

			return;
		end
		modInterface:ToggleGameBlinds(false, 0.5);
		
		
		local storageItem = self.StorageItem;
		
		local timeLapse = tick();
		local lobbyData = remoteGameModeLobbies:InvokeServer("StorageItem", storageItem.ID);
		wait(math.clamp(0.5-(tick()-timeLapse), 0, 0.5));
		bindOpenLobbyInterface:Fire(lobbyData);
	end
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end;

function toolPackage.Inherit(mode, stage, label)
	toolPackage.__index = toolPackage;
	local ToolInherit = {};
	
	local newInteractable = baseInteractable:Clone();
	newInteractable:SetAttribute("Mode", mode);
	newInteractable:SetAttribute("Stage", stage);
	newInteractable:SetAttribute("Label", label);
	
	function ToolInherit.NewToolLib()
		local self = toolPackage.NewToolLib();

		self.InteractScript = newInteractable;

		return self;
	end
	
	setmetatable(ToolInherit, toolPackage);
	return ToolInherit;
end

return toolPackage;