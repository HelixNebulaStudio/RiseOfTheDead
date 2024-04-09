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
			chickenSnd.PlaybackSpeed = math.random(90, 110)/100;
			chickenSnd:Play();
		end
	end

	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;