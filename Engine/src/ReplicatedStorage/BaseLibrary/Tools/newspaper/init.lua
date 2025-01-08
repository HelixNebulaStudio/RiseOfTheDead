local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="RoleplayTool";
	Animations={
		Core={Id=13067320148;};
		Use={Id=13067328329};
	};
};


function toolPackage.NewToolLib(handler)
	local Tool = {};
	
	Tool.IsActive = false;
	Tool.UseViewmodel = false;

	function Tool:ClientUnequip()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule"));
		local modInterface = modData:GetInterfaceModule();

		modInterface:CloseWindow("MarketNewspaper");
	end

	function Tool:ClientItemPrompt()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule"));
		local modInterface = modData:GetInterfaceModule();
		
		modInterface:OpenWindow("MarketNewspaper", self);
	end
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;