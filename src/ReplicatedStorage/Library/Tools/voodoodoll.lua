local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local modNpcProfileLibrary = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("NpcProfileLibrary"));

return function()
	local Tool = {};
	Tool.IsActive = false;
	
	function Tool:OnEquip()
		self.CustomAssets = {};
		
		local character = self.Prefabs[1];
		Debugger.Expire(character:FindFirstChild("Shirt"), 0);
		Debugger.Expire(character:FindFirstChild("Pants"), 0);
	end
	
	function Tool:OnPrimaryFire(isActive)
		if isActive then
			local character = self.Prefabs[1];
			
			for _, obj in pairs(self.CustomAssets) do
				obj:Destroy();
			end
			self.CustomAssets = {};
			
			local new;
			
			local players = game.Players:GetPlayers();
			table.insert(players, "npc");
			local pick = players[math.random(1, #players)];
			
			if pick == "npc" or pick:FindFirstChild("Appearance") == nil then
				local npcName = modNpcProfileLibrary:GetRandom().Id;
				local npcPrefabs = game.ServerStorage.PrefabStorage.Npc;
				new = npcPrefabs:FindFirstChild(npcName) and npcPrefabs[npcName]:Clone();
				
			else
				pick.Character.Archivable = true;
				new = pick.Character:Clone();
				
			end
			
			if new then
				for _, obj in pairs(new:GetChildren()) do
					if obj:IsA("BasePart") then
						if character:FindFirstChild(obj.Name) then
							local charPart = character[obj.Name];
							charPart.Color = obj.Color;
							charPart.Material = obj.Material;
						end
						
					elseif obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") then
						obj.Parent = character;
						table.insert(self.CustomAssets, obj);
					end
				end
				new:Destroy();
			end
		end
	end
	
	return Tool;
end;