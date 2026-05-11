local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId = script.Name;
	Class = "Clothing";
	
	GroupName = "HeadGroup";
	
	Configurations = {};
	Properties = {};
};

function attirePackage.onRequire()
	if RunService:IsClient() then return end;

	task.spawn(function()
		Debugger.AwaitShared("modNpcs");
		shared.modNpcs.OnNpcSpawn:Connect(function(npcClass: NpcClass)
			if npcClass.Name ~= "Zombie" then return end;
			if not RunService:IsStudio() and math.random(1, 5) ~= 1 then return end;
			
			local playersHasNekronMask = {};

			for _, player in pairs(game.Players:GetPlayers()) do
				local playerClass: PlayerClass = shared.modPlayers.get(player);
				if playerClass.Configurations.NekronMask then
					table.insert(playersHasNekronMask, playerClass);
				end
			end
			if #playersHasNekronMask <= 0 then return end;

			local playerClass: PlayerClass = playersHasNekronMask[math.random(1, #playersHasNekronMask)];
			if playerClass == nil or playerClass.HealthComp.IsDead then return end;
			
			local playerAppearance = playerClass:GetInstance():FindFirstChild("Appearance");
			if playerAppearance == nil then return end;

			local npcChar = npcClass.Character;

			for _, clothingItem in pairs(playerAppearance:GetChildren()) do
				if not clothingItem:IsA("Shirt")
				and not clothingItem:IsA("Pants")
				and not clothingItem:IsA("Accessory")
				and not clothingItem:IsA("BodyColors") then continue end;

				if clothingItem:IsA("Shirt") then
					pcall(function()
						npcChar.UpperTorso.TextureID = clothingItem.ShirtTemplate;
						npcChar.RightUpperArm.TextureID = clothingItem.ShirtTemplate;
						npcChar.LeftUpperArm.TextureID = clothingItem.ShirtTemplate;
					end)

				elseif clothingItem:IsA("Pants") then
					pcall(function()
						npcChar.RightUpperLeg.TextureID = clothingItem.PantsTemplate;
						npcChar.LeftUpperLeg.TextureID = clothingItem.PantsTemplate;
					end)

				elseif clothingItem:IsA("BodyColors") then
					clothingItem:Clone().Parent = npcChar;

				elseif clothingItem:IsA("Accessory") and clothingItem:FindFirstChild("Handle") then
					local att = clothingItem.Handle:FindFirstChildWhichIsA("Attachment");
					if att then
						local charAtt = npcChar:FindFirstChild(att.Name, true);
						if charAtt then
							local new = clothingItem:Clone();
							new.Parent = npcChar;
							local handle = new:WaitForChild("Handle");
							handle.CanQuery = false;
						end
					end

				end
			end
		end)
	end)
end

function attirePackage.OnAccesorySpawn(playerClass: PlayerClass, storageItem: StorageItem, newAccessoryPrefabs)
	if storageItem == nil then return end;
	
	local maskAccessory = newAccessoryPrefabs[1];
	if maskAccessory == nil then return end;

	local handle = maskAccessory:FindFirstChild("Handle");
	if handle and storageItem.ItemId ~= attirePackage.ItemId then
		handle.Color = Color3.fromRGB(58, 44, 40);
		return;
	end
	if storageItem.ItemId ~= attirePackage.ItemId then return end;

	local expireTime = storageItem:GetValues("Expire");
	if expireTime == nil then
		local duration = shared.Const.OneDaySecs;
		
		storageItem:SetValues("ExpireLength", duration);
		storageItem:SetValues("Expire", workspace:GetServerTimeNow() + duration);
		storageItem:Sync();
	end
end

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);
	
	equipmentClass:AddBaseModifier("NekronMask", {
		SetValues = {
			NekronMask = true;
		};
		ArrayValues = {
			PassiveModifiers = "Nekron Mask";
		};
	}); 
	
	return equipmentClass;
end

return attirePackage;