local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local MusicTracks = {
	{Id=4707123430; Chance=0.8};
	{Id=4707094762; Chance=1};
};

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

function toolPackage.OnActionEvent(handler, packet)
	local isActive = packet.IsActive;
	local prefab = handler.Prefabs[1];
			
	local music = prefab.PrimaryPart:FindFirstChild("musicBox");
	if music then
		if isActive then
			local roll = math.random(1, 100)/100;
			local id = MusicTracks[1].Id;
			for a=1, #MusicTracks do
				if roll < MusicTracks[a].Chance then
					id = MusicTracks[a].Id;
					break;
				end
			end
			music.SoundId =  "rbxassetid://"..id;
			music:Play();
		else
			music:Stop();
		end
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
end

return toolPackage;