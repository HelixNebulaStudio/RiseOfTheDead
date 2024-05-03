local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local CustomizeAppearance = {};
local modAppearanceLibrary = require(game.ReplicatedStorage.Library.AppearanceLibrary);
local modItemUnlockablesLibrary = require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
local CollectionService = game:GetService("CollectionService");

function weldAttachments(attach1, attach2)
	if not attach1:IsDescendantOf(workspace) then
		attach2.Parent.CFrame = attach1.WorldCFrame * attach2.CFrame:Inverse();
	end
	
    local weld = Instance.new("Weld")
	weld.Name = "CustomizeAppearanceWeld";
    weld.Part0 = attach1.Parent
    weld.Part1 = attach2.Parent
    weld.C0 = attach1.CFrame
	weld.C1 = attach2.CFrame
	
    weld.Parent = attach2.Parent
    return weld
end

local function buildWeld(weldName, parent, part0, part1, c0, c1)
	if not part0:IsDescendantOf(workspace) then
		part1.CFrame = c0.WorldCFrame * c1:Inverse();
	end
	
    local weld = Instance.new("Weld")
    weld.Name = weldName
    weld.Part0 = part0
    weld.Part1 = part1
    weld.C0 = c0
	weld.C1 = c1
	
    weld.Parent = parent
    return weld
end

local function findFirstMatchingAttachment(model, name)
    for _, child in pairs(model:GetChildren()) do
        if child:IsA("Attachment") and child.Name == name then
			return child
			
        elseif not child:IsA("Accoutrement") and not child:IsA("Tool") then
            local foundAttachment = findFirstMatchingAttachment(child, name)
            if foundAttachment then
                return foundAttachment
			end
			
        end
    end
end

function CustomizeAppearance.ToggleAccessory(character, name, visible)
	local hiddenFolder = character:FindFirstChild("Hidden");
	if hiddenFolder == nil then
		hiddenFolder = Instance.new("Folder");
		hiddenFolder.Name = "Hidden";
		hiddenFolder.Parent = character;
	end
	if visible == nil then
		local accessory = hiddenFolder:FindFirstChild(name);
		if accessory then
			accessory.Parent = character;
		end
	else
		local accessory = character:FindFirstChild(name);
		if accessory then
			accessory.Parent = hiddenFolder;
		end
	end
end

function CustomizeAppearance.AttachAccessory(character, accessoryPrefab, accessoryData, accessoryGroup, storageItem)
	local _player = game.Players:GetPlayerFromCharacter(character);
	
	local itemValues = storageItem and storageItem.Values or {};
	local clothingStyle = itemValues.StyleIndex or 1;

	local isInvisible = character:GetAttribute("IsInvisible") == true;
	
	local function attach(accessory)
		if accessory:GetAttribute("StyleSet") and accessory:GetAttribute("StyleSet") ~= clothingStyle then
			accessory:Destroy();
			return;
		end
		
		accessory.Parent = character;
		if accessory:GetAttribute("ClothingJoint") == nil then
			accessory:SetAttribute("ClothingJoint", accessory.Name);
		end
		
		if storageItem then
			accessory:SetAttribute("StorageItemId", storageItem.ID);
			accessory:SetAttribute("StorageIndex", storageItem.Index);
			accessory:SetAttribute("ItemId", storageItem.ItemId);
			
			if storageItem.Vanity then
				accessory:SetAttribute("VanityId", storageItem.Vanity);
			end
		end
		accessory.Name = accessoryPrefab.Name;
		
	    local handle = accessory:FindFirstChild("Handle");
	    if handle then
	        local accessoryAttachment = handle:FindFirstChildOfClass("Attachment");
	        if accessoryAttachment then
	            local characterAttachment = findFirstMatchingAttachment(character, accessoryAttachment.Name);
	            if characterAttachment then
					local originalSize = handle:FindFirstChild("OriginalSize");
					if originalSize then handle.Size = originalSize.Value; end
	                weldAttachments(characterAttachment, accessoryAttachment);
					
					if not isInvisible then
						if accessoryData then
							if accessoryData.HideHair then --HairAttachment
								for _, obj in pairs(character:GetChildren()) do
									local att = obj:IsA("Accessory") and obj:FindFirstChild("HairAttachment", true);
									if att then
										att.Parent.Transparency = 1;
										
										local tag = Instance.new("ObjectValue");
										tag.Name = "HideHair";
										tag.Value = att.Parent;
										tag.Parent = accessory;
									end
								end
								
							elseif accessoryData.HideFacewear then --FaceFrontAttachment
								for _, obj in pairs(character:GetChildren()) do
									local att = obj:IsA("Accessory") and obj:FindFirstChild("FaceFrontAttachment", true);
									if att then
										att.Parent.Transparency = 1;
										
										local tag = Instance.new("ObjectValue");
										tag.Name = "HideFacewear";
										tag.Value = att.Parent;
										tag.Parent = accessory;
									end
								end

							elseif accessoryData.HideHands then
								for _, obj in pairs(character:GetChildren()) do
									if obj:GetAttribute("HandGroup") then
										obj.Transparency = 1;
										obj:SetAttribute("HideHands", true);

										local tag = Instance.new("ObjectValue");
										tag.Name = "HideHands";
										tag.Value = obj;
										tag.Parent = accessory;
									end
								end

							end
							
						end
					end
	            end
	        else
	            local head = character:FindFirstChild("Head");
	            if head then
	                local attachmentCFrame = CFrame.new(0, 0.5, 0);
	                local hatCFrame = accessory.AttachmentPoint;
	                buildWeld("HeadWeld", head, head, handle, attachmentCFrame, hatCFrame);
	            end
			end
			
			if storageItem then
				if storageItem.VanityMeta then
					modItemUnlockablesLibrary.UpdateSkin(accessory, storageItem.VanityMeta);
					
				elseif storageItem.Values and storageItem.Values.ActiveSkin then
					local unlockableItemLib = modItemUnlockablesLibrary:Find(storageItem.Values.ActiveSkin);

					if unlockableItemLib and unlockableItemLib.ItemId == storageItem.ItemId then
						modItemUnlockablesLibrary.UpdateSkin(accessory, storageItem.Values.ActiveSkin);
					end
					
				else
					modItemUnlockablesLibrary.UpdateSkin(accessory, storageItem.ItemId);
					
				end
			end
			
	    end
	end
	
	if (accessoryPrefab:IsA("Folder") or accessoryPrefab:IsA("ModuleScript")) and accessoryPrefab.Name ~= "Hidden" then
		local prefabs = accessoryPrefab:GetChildren();
		for a=1, #prefabs do
			attach(prefabs[a]);
		end
	else
		attach(accessoryPrefab);
	end
end

function CustomizeAppearance.RemoveAccessory(character, accessoryName)
	local player = game.Players:GetPlayerFromCharacter(character);
	local parts = character:GetChildren();
	
	local isInvisible = character:GetAttribute("IsInvisible") == true;
	
	for b=1, #parts do
		local accessory = parts[b];
		if accessory.Name == accessoryName then
			
			local attachment = accessory:FindFirstChildWhichIsA("Attachment", true);
			local attachmentName = attachment and attachment.Name or nil;
			
			if not isInvisible then
				for _, obj in pairs(accessory:GetChildren()) do
					if obj.Name == "HideHair" or obj.Name == "HideFacewear" or obj.Name == "HideHands" then
						obj.Value.Transparency = 0;
						obj.Value:SetAttribute("HideHands", nil);
					end
				end
			end
			
			parts[b]:Destroy();
			if attachmentName then
				if not isInvisible then
					local characterAttachment = character:FindFirstChild(attachmentName, true);
					if characterAttachment then
						if characterAttachment.Parent:IsA("BasePart") then
							characterAttachment.Parent.Transparency = 0;
						end
					end
				end
			end

		end
	end
	
end

function CustomizeAppearance.RefreshIndex(character)
	local accessoryPrefabs = {};
	local clothing = {};
	
	for _, obj in pairs(character:GetChildren()) do
		if not obj:IsA("Accessory") then continue end;
		if obj:GetAttribute("StorageItemId") then
			local storageItemID = obj:GetAttribute("StorageItemId");
			if accessoryPrefabs[storageItemID] == nil then
				accessoryPrefabs[storageItemID] = {};
			end
			table.insert(accessoryPrefabs[storageItemID], obj);
		end
		if obj:GetAttribute("StorageIndex") then
			local jointId = obj:GetAttribute("ClothingJoint");
			
			if jointId == nil then
				error(obj.Name.." has nil jointId.");
			end
			
			if clothing[jointId] == nil then
				clothing[jointId] = {};
			end
			
			table.insert(clothing[jointId], {
				Prefab=obj;
				Index=obj:GetAttribute("StorageIndex");
			})
		end
	end
	
	local isInvisible = character:GetAttribute("IsInvisible") == true;
	
	for class, clothingList in pairs(clothing) do
		table.sort(clothingList, function(a, b) return a.Index < b.Index end);
		
		local firstListing;
		for j=1, #clothingList do
			local prefab = clothingList[j].Prefab;
			local handle = prefab and prefab:WaitForChild("Handle");
			
			if j == 1 then
				handle.Transparency = 0;
				firstListing = clothingList[j];
				handle:SetAttribute("HiddenByOrder", nil);
				
			elseif firstListing and firstListing.Prefab:GetAttribute("IgnoreIndex") == true and clothingList[j].Index-firstListing.Index == 1 then
				handle.Transparency = 0;
				handle:SetAttribute("HiddenByOrder", nil);
				
			else
				handle.Transparency = 1;
				handle:SetAttribute("HiddenByOrder", j);
				
			end
			
			if handle.Transparency == 0 then
				local activeWeld = nil;
				for _, obj in pairs(handle:GetChildren()) do
					if obj:IsA("Weld") and obj.Active then activeWeld = obj; break; end;
				end
				if activeWeld then
					local bodyPart = activeWeld.Part0.Parent == character and activeWeld.Part0 or activeWeld.Part1;
					
					if prefab:GetAttribute("HideOverlap") == true then
						bodyPart.Transparency = 1;
						prefab:SetAttribute("HideBodyPart", bodyPart.Name);
						
					else
						bodyPart.Transparency = 0;
						
					end
				end
			end
		end
	end
	
	return accessoryPrefabs;
end

function CustomizeAppearance.LoadAccessory(data)
	if data == nil then return {} end;
	local accessories = {};
	
	local prefab = game.ReplicatedStorage.Prefabs.Cosmetics:FindFirstChild(data.Name);

	if prefab then
		if data.Attachments == nil then
			local new = prefab:Clone();
			table.insert(accessories, new);
			
		else
			for a=1, #data.Attachments do
				local attachmentData = data.Attachments[a];
				
				local newAttachment = Instance.new("Attachment");
				newAttachment.Name = attachmentData.Name;
				newAttachment.Orientation = attachmentData.Orientation;
				newAttachment.Position = attachmentData.Position;
				
				local new;
				if data.Attachments[a].PrefabName then
					new = prefab:FindFirstChild(data.Attachments[a].PrefabName):Clone();
					
					if new == nil then
						warn("CustomizeAppearance>>  Could not find attachment prefab named: "..data.Attachments[a].PrefabName);
					end
					new.Name = prefab.Name;
					
				else
					new = prefab:Clone();
				end
				
				if newAttachment.Name == "LeftFootAttachment" then
					new:SetAttribute("ClothingJoint", "LF");
				elseif newAttachment.Name == "RightFootAttachment" then
					new:SetAttribute("ClothingJoint", "RF");
				elseif newAttachment.Name == "LeftLowerLegAttachment" then
					new:SetAttribute("ClothingJoint", "LLL");
				elseif newAttachment.Name == "RightLowerLegAttachment" then
					new:SetAttribute("ClothingJoint", "RLL");
				end
				
				newAttachment.Parent = new:FindFirstChild("Handle");
				table.insert(accessories, new);
			end
		end
	else
		warn("CustomizeAppearance>>  Could not find accessory named: "..(data.Name or "nil"));
	end
	
	return accessories;
end

function CustomizeAppearance.AddAccessory(character, accessoryName, accessoryGroup)
	local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);

	local clothingLib = modClothingLibrary:Find(accessoryName);
	local accessoryData = clothingLib.AccessoryData[accessoryName];
	
	local newAccessories = CustomizeAppearance.LoadAccessory(accessoryData);
	CustomizeAppearance.RemoveAccessory(character, accessoryName);
	
	for a=1, #newAccessories do
		CustomizeAppearance.AttachAccessory(character, newAccessories[a], accessoryData, accessoryName);
	end
end

function CustomizeAppearance.ClientAddAccessory(character, accessoryData, accessoryGroup)
	local newAccessories = CustomizeAppearance.LoadAccessory(accessoryData);
	CustomizeAppearance.RemoveAccessory(character, accessoryData.Name);
	
	for a=1, #newAccessories do
		CustomizeAppearance.AttachAccessory(character, newAccessories[a], accessoryData, accessoryData.Name);
	end
end

return CustomizeAppearance;