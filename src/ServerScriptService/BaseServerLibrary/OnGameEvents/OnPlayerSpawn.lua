local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);

--==
return function(player)
	local profile = shared.modProfile:Get(player);
	local classPlayer = shared.modPlayers.Get(player);
	
	local humanoid = classPlayer.Humanoid;
	
	humanoid.Touched:Connect(function(touchPart: BasePart)
		if not classPlayer.IsAlive then return end; 

		local objectModel = touchPart.Parent and touchPart.Parent:IsA("Model") and touchPart.Parent or nil;
		local interactObject = objectModel and objectModel.PrimaryPart or nil;
		local interactModule = objectModel and objectModel:FindFirstChild("Interactable");

		if interactObject and interactModule and interactModule:IsA("ModuleScript") then
			local interactData = require(interactModule);
			interactData.Object = interactObject;
			interactData.Script = interactModule;

			if interactData == nil or interactData.TouchInteract ~= true then return end;
			if interactData.TouchPickUp == false then return end;
			
			if interactData.Type == modInteractables.Types.Pickup then
				local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
				modOnGameEvents:Fire("OnResourceGatherers", player, interactData);
			end
		end
		
	end)
end;