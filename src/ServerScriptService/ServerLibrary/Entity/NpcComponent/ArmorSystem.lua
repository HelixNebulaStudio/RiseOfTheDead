local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Script;
local ArmorSystem = {};
ArmorSystem.__index = ArmorSystem;

function ArmorSystem.new(Npc)
	local self = {
		BaseArmor = Npc.BaseArmor;
		Armor = Npc.BaseArmor;
		MaxArmor = Npc.BaseArmor;
	};
	
	function self:Refresh()
		Npc.Humanoid:SetAttribute("Armor", self.Armor);
		Npc.Humanoid:SetAttribute("MaxArmor", self.MaxArmor);
	end
	
	function self:AddArmor(amount)
		self.Armor = math.clamp(self.Armor + amount, 0, math.huge);
		self:Refresh();
	end
	
	setmetatable(self, ArmorSystem);
	return self;
end

return ArmorSystem;