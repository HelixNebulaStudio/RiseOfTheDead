local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="RoleplayTool";
	Animations={
		Core={Id=14471065189;};
		Use={Id=14471085942};
	};
};

local baseInteractable = script:WaitForChild("Interactable");

function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.UseViewmodel = false;
	
	function Tool:OnEquip()
		local weaponModel = self.Prefabs[1];
		local handle = weaponModel.Handle;
		
		self.InteractScript = baseInteractable:Clone();
		self.InteractScript.Parent = handle;
	end

	function Tool:OnPrimaryFire(isActive, ...)
		self.IsActive = isActive;

	end
	
	Tool.ItemPromptHint = " to use tablet.";

	function Tool:ClientItemPrompt()
		local localPlayer = game.Players.LocalPlayer;
		local classPlayer = shared.modPlayers.Get(localPlayer);

		local storageItem = self.StorageItem;
		
		local prefab = self.Prefab;
		local primaryPart = prefab.PrimaryPart;
		local interactableModule = primaryPart:FindFirstChild("Interactable");
		
		local modData = require(localPlayer:WaitForChild("DataModule"));
		modData.InteractRequest(interactableModule, primaryPart);
	end
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;