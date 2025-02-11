local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=4706449989;};
		Use={Id=4706454123};
	};
	Audio={};
	
	Configurations={};
	Properties={};
};

function toolPackage:OnActionEvent(packet)
	if packet.ActionIndex ~= 1 then return end;
	if self.LastFire ~= nil and tick()-self.LastFire < 1 then return end;
	self.LastFire  = tick();

	for a=1, #self.Prefabs do
		local prefab = self.Prefabs[a];
		
		local chickenScreams = {};
		for _, obj in pairs(prefab.PrimaryPart:GetChildren()) do
			if obj:IsA("Sound") then
				local chance = obj:GetAttribute("Chance") or 1;
				for a=1, chance do
					table.insert(chickenScreams, obj);
				end
			end
		end
		
		local chickenSnd = chickenScreams[math.random(1, #chickenScreams)];
		chickenSnd:SetAttribute("SoundOwner", self.Player and self.Player.Name or nil);
		game:GetService("CollectionService"):AddTag(chickenSnd, "PlayerNoiseSounds");
		
		chickenSnd.PlaybackSpeed = math.random(90, 110)/100;
		chickenSnd:Play();
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
end

return toolPackage;