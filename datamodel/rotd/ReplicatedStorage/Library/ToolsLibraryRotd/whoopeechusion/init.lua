local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
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

function toolPackage:ActionEvent(packet)
	if packet.ActionIndex ~= 1 then return end;
	if self.LastFire ~= nil and tick()-self.LastFire < 1 then return end;
	self.LastFire  = tick();

	for a=1, #self.Prefabs do
		local prefab = self.Prefabs[a];
		
		local fartSound = prefab.PrimaryPart:FindFirstChild("fartsound");
		fartSound:SetAttribute("SoundOwner", self.Player and self.Player.Name or nil);
		game:GetService("CollectionService"):AddTag(fartSound, "PlayerNoiseSounds");
		fartSound.PlaybackSpeed = math.random(90, 110)/100;
		fartSound:Play();
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;