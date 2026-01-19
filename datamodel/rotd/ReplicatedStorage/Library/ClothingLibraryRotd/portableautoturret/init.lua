local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));

local remoteShopService = modRemotesManager:Get("ShopService");
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="UnoverlappableGroup";
	
	StorageId = "portableautoturret";
	StorageIndexEnums = {
		WeaponSlot = 1;
		BatterySlot = 2;
	};

	Configurations={};
	Properties={};
};

local turretArmPrefab = script:WaitForChild("turretArm");
function attirePackage.OnAccesorySpawn(classPlayer, storageItem, newAccessoryPrefabs)
	local accessory = newAccessoryPrefabs and newAccessoryPrefabs[1];
	if typeof(accessory) ~= "Instance" then return end;
	
	local newArm = turretArmPrefab:Clone();

	local hydraulicAtt = accessory:WaitForChild("Handle"):WaitForChild("HydraulicsRoot");
	local hydraulicConstraint = newArm:WaitForChild("Hydraulics"):WaitForChild("RigidConstraint");
	hydraulicConstraint.Attachment1 = hydraulicAtt;

	local utAtt = accessory:WaitForChild("Handle"):WaitForChild("UpperTorsoAttachment");
	newArm:WaitForChild("LCables"):WaitForChild("RigidConstraint").Attachment1 = utAtt;
	newArm:WaitForChild("LCables2"):WaitForChild("RigidConstraint").Attachment1 = utAtt;
	
	newArm.Parent = accessory;
	
	accessory:WaitForChild("Handle").ChildAdded:Connect(function(surfApp)
		if not surfApp:IsA("SurfaceAppearance") then return end;
		for _, obj in pairs(newArm:GetChildren()) do
			if obj:IsA("BasePart") then
				for _, sf in pairs(obj:GetChildren()) do
					if sf:IsA("SurfaceAppearance") then
						sf:Destroy()
					end
				end

				surfApp:Clone().Parent = obj;
			end
		end
	end)

	task.spawn(function()
		local storage = shared.modStorage.Get(attirePackage.StorageId, classPlayer:GetInstance());
		if storage then
			storage:Changed();
		end
	end)
end

function attirePackage.OnShopSelect(shopInterface, storageItem)
	local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
	local modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
	
	local selectedItem = modData.FindIndexFromStorage(attirePackage.StorageId, attirePackage.StorageIndexEnums.WeaponSlot);
	if selectedItem == nil then return end;

	local weaponClass = modData:GetItemClass(selectedItem.ID);
	local weaponItemLib = modItemsLibrary:Find(selectedItem.ItemId);

	local hasAmmoData = (weaponClass and ((selectedItem.Values.A and selectedItem.Values.A < weaponClass.Configurations.AmmoLimit)
		or (selectedItem.Values.MA and selectedItem.Values.MA < weaponClass.Configurations.MaxAmmoLimit)));
	if hasAmmoData ~= true then return end;

	local modShopLibrary = shared.require(game.ReplicatedStorage.Library.RatShopLibrary);
	local ammoCurrency = modShopLibrary.AmmunitionCurrency or "Money";

	local localplayerStats = modData.GetStats();
	local localplayerCurrency = localplayerStats and localplayerStats[ammoCurrency] or 0;
	local price, mags = modShopLibrary.CalculateAmmoPrice(selectedItem.ItemId, selectedItem.Values, weaponClass.Configurations, localplayerCurrency, modData.Profile.Punishment == modGlobalVars.Punishments.AmmoCostPenalty);
	
	shopInterface.NewListing(function(newListing)
		newListing.Name = "AmmoRefillOption";
		local infoBox = newListing:WaitForChild("infoFrame");
		local descFrame = infoBox:WaitForChild("descFrame");

		local purchaseButton = newListing:WaitForChild("purchaseButton");
		local priceLabel = purchaseButton:WaitForChild("buttonText");
		local iconButton = newListing:WaitForChild("iconButton");
		local iconLabel = iconButton:WaitForChild("iconLabel");
		local titleLabel = descFrame:WaitForChild("titleLabel");
		local labelFrame = descFrame:WaitForChild("labelFrame");
		local descLabel = labelFrame:WaitForChild("descLabel");

		local priceTag = "$"..modFormatNumber.Beautify(price);
		descLabel.Text = "<b>"..weaponItemLib.Name.." (On P.A.T.)</b>: ".."Buy "..mags.." magazine"..(mags > 1 and "s" or "").." = "..priceTag;
		titleLabel.Text = "Refill Ammunition";
		priceLabel.Text = priceTag;
		iconLabel.Image = "rbxassetid://2040144031";

		local purchaseAmmoDebounce = false;
		newListing.MouseButton1Click:Connect(function()
			if purchaseAmmoDebounce then return end;
			purchaseAmmoDebounce = true;

			local serverReply = localplayerStats and (localplayerStats[ammoCurrency] or 0) >= price and 
				remoteShopService:InvokeServer("buyammo", {StoreObj=shopInterface.Object;}, selectedItem.ID, attirePackage.StorageId) or modShopLibrary.PurchaseReplies.InsufficientCurrency;
			if serverReply == modShopLibrary.PurchaseReplies.Success then
				modData.OnAmmoUpdate:Fire(selectedItem.ID);
				
				task.wait();
				newListing:Destroy();

			else
				warn("Ammunition Purchase>> Error Code:"..serverReply);
				descLabel.Text = string.gsub(modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply), "$Currency", ammoCurrency);
			end
			purchaseAmmoDebounce = false;
		end)
	end)
end

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage);
end

return attirePackage;