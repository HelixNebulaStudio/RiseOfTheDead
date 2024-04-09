local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();


local templateOverheadDispalyGui = script:WaitForChild("OverHeadDisplay");

--== Script;
local Component = {};
Component.__index = Component;

function Component.new(Npc)
	local self = {
		Gui = templateOverheadDispalyGui:Clone();
	};
	
	self.Gui.Parent = Npc.Prefab;
	self.Gui.Adornee = Npc.RootPart;
	
	self.StatusDot = self.Gui:WaitForChild("StatusEffects"):WaitForChild("Alert");
	self.StatusDot.ImageColor3 = Color3.fromRGB(154, 86, 86);
	
	setmetatable(self, Component);
	return self;
end

return Component;