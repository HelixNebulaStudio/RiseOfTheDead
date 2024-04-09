return function()
	local Tool = {};
	Tool.IsActive = false;
	
	function Tool:OnPrimaryFire(isActive)
	end

	function Tool:ClientUnequip()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule"));
		local modInterface = modData:GetInterfaceModule();
		
		modInterface:CloseWindow("GpsWindow");
	end
	
	function Tool:ClientItemPrompt()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule"));
		local modInterface = modData:GetInterfaceModule();
		
		modInterface:OpenWindow("GpsWindow", self);
	end
	
	return Tool;
end;
