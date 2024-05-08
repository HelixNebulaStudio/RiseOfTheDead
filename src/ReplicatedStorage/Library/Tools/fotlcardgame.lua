local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");

local modCardGame = require(game.ReplicatedStorage.Library.CardGame);

function shufflePrefabCards(self)
	local prefab = self.Prefabs[1];
	if RunService:IsClient() then return end;
	
	local textures = {};
	for _, cardInfo in pairs(modCardGame.Cards) do
		table.insert(textures, cardInfo.Texture);
	end

	for _, obj in pairs(prefab:GetChildren()) do
		if obj:IsA("MeshPart") and obj.Name == "Card" then
			obj.TextureID = textures[math.random(1, #textures)];
		end
	end
end

return function()
	local Tool = {};
	Tool.IsActive = false;
	
	function Tool:OnEquip()
		shufflePrefabCards(self);
		
		if self.MockItem then
			local prefab = self.Prefabs[1];
			if prefab then
				Debugger.Expire(prefab:FindFirstChild("Interactable"), 0);
			end
			
			return 
		end;

		task.spawn(function()
			local profile = shared.modProfile:Get(self.Player);
			local statsFlag = profile.Flags:Get("cardgamestats") or {Id="cardgamestats";};

			statsFlag.Wins = (statsFlag.Wins or 0);
			statsFlag.Loses = (statsFlag.Loses or 0);
			
			local str = statsFlag.Wins .." Wins, ".. statsFlag.Loses .." Loses";
			profile.ActiveInventory:SetValues(self.StorageItem.ID, {CardGameStats=str;});
		end)
		
		local lobby = modCardGame.GetLobby(self.Player);
		if lobby then
			lobby:Changed(true);
		else
			modCardGame.NewLobby(self.Player);
		end;
	end
	
	function Tool:OnPrimaryFire(isActive)
		self.IsActive = isActive;

		shufflePrefabCards(self)
	end

	function Tool:ClientEquip()
		if self.MockItem then return end;
		
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
		local modInterface = modData:GetInterfaceModule();

		modInterface:OpenWindow("CardGameWindow");
	end
	
	return Tool;
end;