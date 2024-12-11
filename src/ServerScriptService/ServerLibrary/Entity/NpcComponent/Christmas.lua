local Christmas = {};

local hairPrefabs = {
	script:WaitForChild("SantaHat");
	script:WaitForChild("Cartoony Santa");
	script:WaitForChild("santahat");
};

function Christmas.new(self)
	return function()
		if self.Prefab.Name == "Mr. Klaws" then return end;
		if self.Prefab.Name == "Wraith" then return end;
		if self.Prefab.Name == "Witherers" then return end;
		if self.Prefab.Name == "Vein Of Nekron" then return end;

		if math.random(1, 10) == 1 then
			local hair = hairPrefabs[math.random(1, #hairPrefabs)]:Clone();
			hair.Parent = self.Prefab;
			if self.Configuration then
				self.Configuration.SantaHat = true;
			end
		end
	end
end

return Christmas;