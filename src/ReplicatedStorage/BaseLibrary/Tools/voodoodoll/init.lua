local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="RoleplayTool";
	Animations={
		Core={Id=4843250039;};
		Use={Id=4706454123};
	};
}; 


function toolPackage.NewToolLib(handler)
	local toolLib = {};
	toolLib.IsActive = false;

	function toolLib:OnEquip()
		self.CustomAssets = {};
		
		local character = self.Prefabs[1];
		Debugger.Expire(character:FindFirstChild("Shirt"), 0);
		Debugger.Expire(character:FindFirstChild("Pants"), 0);
	end
	
	function toolLib:OnPrimaryFire(isActive)
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
				local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);

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
	
	toolLib.__index = toolLib;
	setmetatable(toolLib, handler);
	return toolLib;
end

return toolPackage;