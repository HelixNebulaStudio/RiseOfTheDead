local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);

--== Script;
local ArmorSystem = {};
ArmorSystem.__index = ArmorSystem;

function ArmorSystem.new(Npc)
	local self = {
		BaseArmor = Npc.BaseArmor;
		Armor = Npc.BaseArmor;
		MaxArmor = Npc.BaseArmor;

		OnArmorChanged = modEventSignal.new("OnArmorChanged");
	};
	
	function self:Refresh()
		local oldArmor = Npc.Humanoid:GetAttribute("Armor");
		local oldMaxArmor = Npc.Humanoid:GetAttribute("MaxArmor");
		Npc.Humanoid:SetAttribute("Armor", self.Armor);
		Npc.Humanoid:SetAttribute("MaxArmor", self.MaxArmor);

		self.OnArmorChanged:Fire(oldArmor, oldMaxArmor);
	end
	
	function self:AddArmor(amount)
		self.Armor = math.clamp(self.Armor + amount, 0, math.huge);
		self:Refresh();
	end
	
	Npc.Garbage:Tag(function()
		self.OnArmorChanged:Destroy();
	end);
	setmetatable(self, ArmorSystem);

	self:Refresh();
	return self;
end

return ArmorSystem;