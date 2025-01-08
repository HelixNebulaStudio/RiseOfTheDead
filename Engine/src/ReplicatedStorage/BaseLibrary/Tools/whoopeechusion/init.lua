local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="RoleplayTool";
	Animations={
		Core={Id=4706449989;};
		Use={Id=4706454123};
	};
};


function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.IsActive = false;

	function Tool:OnPrimaryFire()
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

	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;