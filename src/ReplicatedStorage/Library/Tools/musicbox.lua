local tracks = {
	{Id=4707123430; Chance=0.8};
	{Id=4707094762; Chance=1};
};

return function()
	local Tool = {};
	Tool.IsActive = false;
	
	function Tool:OnPrimaryFire(isActive)
		for a=1, #self.Prefabs do
			local prefab = self.Prefabs[a];
			
			local music = prefab.PrimaryPart:FindFirstChild("musicBox");
			if music then
				if isActive then
					local roll = math.random(1, 100)/100;
					local id = tracks[1].Id;
					for a=1, #tracks do
						if roll < tracks[a].Chance then
							id = tracks[a].Id;
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
	end
	
	return Tool;
end;
