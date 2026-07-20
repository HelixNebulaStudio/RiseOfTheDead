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

function toolPackage.ActionEvent(handler: ToolHandlerInstance, packet)
	if packet.ActionIndex ~= 1 then return end;

	local properties = handler.EquipmentClass and handler.EquipmentClass.Properties;
	if properties.LastFire ~= nil and tick()-properties.LastFire < 1 then return end;
	properties.LastFire = tick();

	local prefab = handler.MainToolModel;
	if not workspace:IsAncestorOf(prefab) then return end;
	
	local fartSound = prefab.PrimaryPart:FindFirstChild("fartsound");
	fartSound:SetAttribute("SoundOwner", handler.CharacterClass.Name);
	game:GetService("CollectionService"):AddTag(fartSound, "PlayerNoiseSounds");
	
	fartSound.PlaybackSpeed = math.random(90, 110)/100;
	fartSound:Play();
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;