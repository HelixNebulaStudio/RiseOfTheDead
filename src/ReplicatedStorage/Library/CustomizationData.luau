local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modItemSkinsLibrary = require(game.ReplicatedStorage.Library.ItemSkinsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modBaseNumber = require(game.ReplicatedStorage.Library.Util.BaseNumber);

local modColorPicker = require(game.ReplicatedStorage.Library.UI.ColorPicker);


local remoteCustomizationData = modRemotesManager:Get("CustomizationData") :: RemoteFunction;
local itemPrefabs = game.ReplicatedStorage.Prefabs:WaitForChild("Items");

--==
local CustomizationData = {};
CustomizationData.__index = CustomizationData;

function CustomizationData.new(player)
    local meta = {};
    meta.__index = meta;
    meta.Player = player;
    meta.PlanOverwrites = {};

    local self = {
        Index=0;
    };

    setmetatable(self, meta);
    setmetatable(meta, CustomizationData);
    return self;
end

function CustomizationData:NextAscKey()
    self.Index = self.Index +1;
    return modBaseNumber.ToBase(self.Index, #modBaseNumber.Symbols);
end

function CustomizationData:Load(rawTable)
    for k, v in pairs(rawTable) do
        self[k] = v;
    end

    return self;
end

function CustomizationData.Serialize(customPlans, partGroups)
    local r = {
        Layers={};
        Plans={};
    };

    for groupKey, list in pairs(partGroups) do
        local newStr = table.concat(list, ",");
        r.Layers[groupKey] = newStr;
    end

    for planKey, customPlan in pairs(customPlans) do
        local planSerial = customPlan:Serialize();

        r.Plans[planKey] = planSerial;
    end

    return HttpService:JSONEncode(r);
end

function CustomizationData.Deserialize(rawJson)
    local r = {Layers={}; Plans={};};
    local s, e = pcall(function()
        r = HttpService:JSONDecode(rawJson);
    end)
    if not s then 
        Debugger:Warn("Failed to load customizations JSON.",e); 
        return r;
    end;

    local partGroups = {};

    for groupKey, list in pairs(r.Layers) do
        partGroups[groupKey] = string.split(list, ",");
    end

    local customPlans = {};
    for planKey, rawPlan in pairs(r.Plans) do
        customPlans[planKey] = CustomizationData.newCustomizationPlan();
        customPlans[planKey]:Deserialize(rawPlan);
    end

    r.Layers = partGroups;
    r.Plans = customPlans;

    return r;
end

function CustomizationData.GetBaseSkinFromActiveId(itemId, skinId)
    if skinId == nil then return end;
		
    local skinLib = modItemSkinsLibrary:Find(skinId);
    if skinLib == nil then
        skinLib = modItemSkinsLibrary:FindByKeyValue("OldId", skinId);
    end
    
    local variantId = nil;
    if skinLib.Type == modItemSkinsLibrary.SkinType.Pattern then
        variantId = "v1";
    else
        variantId = itemId..skinLib.Id;
    end

    return `{skinLib.Id}_{variantId}`;
end

function CustomizationData.LoadCustomization(packet)
    local itemId = packet.ItemId;
    local serializedCustomization = packet.CustomizationData;
    local skinId = packet.SkinId;
    local toolModels = packet.ToolModels;

    local customPlansCache = packet.CustomPlansCache or {};
    local partDataList = packet.PartDataList or {};
    ---

    local designPacket = CustomizationData.Deserialize(serializedCustomization);
    local baseSkin = CustomizationData.GetBaseSkinFromActiveId(itemId, skinId);
    
    local basePrefab = itemPrefabs:FindFirstChild(itemId);

    for planId, customPlan in pairs(designPacket.Plans) do
        customPlansCache[planId] = customPlan;
        customPlansCache[planId].BaseSkin = baseSkin;
    end


    if toolModels then
        for a=1, #toolModels do
            local toolModel = toolModels[a];
    
            local weldName = toolModel:GetAttribute("Grip");
            local prefix = "";
            if weldName == "LeftToolGrip" then
                prefix = "Left";
            elseif weldName == "RightToolGrip" then
                prefix = "Right";
            end
    
            for _, basePart in pairs(toolModel:GetChildren()) do
                if not basePart:IsA("BasePart") then continue end;
        
                local predefinedGroup = basePart:GetAttribute("CustomizationGroup");
                predefinedGroup = predefinedGroup and `[{predefinedGroup}]` or nil;
        
                if toolModel and basePrefab then
                    local defaultPartName = basePart.Name;
                    local defaultPart = basePrefab:FindFirstChild(defaultPartName);
                    
                    basePart:SetAttribute("DefaultColor", defaultPart.Color);
                    basePart:SetAttribute("DefaultTransparency", defaultPart.Transparency);
                    basePart:SetAttribute("DefaultMaterial", defaultPart.Material);
                    basePart:SetAttribute("DefaultReflectance", defaultPart.Reflectance);
                end
        
                local newPartData = {
                    Key=prefix..basePart.Name;
                    Part=basePart;
                    Group = predefinedGroup;
                    PredefinedGroup = predefinedGroup;
                };
        
                table.insert(partDataList, newPartData);
            end
        end
    end

    for a=1, #partDataList do
        local partData = partDataList[a];

        for groupKey, list in pairs(designPacket.Layers) do
            if table.find(list, partData.Key) then
                partData.Group = groupKey;
                break;
            end
        end
    end
    
    if toolModels then
        CustomizationData.ApplyCustomPlans(customPlansCache, partDataList);
    end
end

--== MARK: CustomizationPlan;
local CustomizationPlan = {};
CustomizationPlan.__index = CustomizationPlan;

function CustomizationData.newCustomizationPlan()
    local self = {
        BaseSkin=nil;
        Group=nil;
        Color=nil;
        Skin=nil;
        Transparency=nil;
        PatternData={
            Color = nil;
            Offset = nil;
            Scale = nil;
            Transparency = nil;
        };
        Material=nil;
        Reflectance=nil;

        -- can't be copied
        PositionOffset=nil;
    };

    setmetatable(self, CustomizationPlan);
    return self;
end

function CustomizationPlan:Copy(customPlan, onlyReplaceNil)
    onlyReplaceNil = onlyReplaceNil == true;

    self.Color = onlyReplaceNil and self.Color or customPlan.Color;
    self.Skin = onlyReplaceNil and self.Skin or customPlan.Skin;
    self.Transparency = onlyReplaceNil and self.Transparency or customPlan.Transparency;

    self.PatternData.Color = onlyReplaceNil and self.PatternData.Color or customPlan.PatternData.Color;
    self.PatternData.Offset = onlyReplaceNil and self.PatternData.Offset or customPlan.PatternData.Offset;
    self.PatternData.Scale = onlyReplaceNil and self.PatternData.Scale or customPlan.PatternData.Scale;
    self.PatternData.Transparency = onlyReplaceNil and self.PatternData.Transparency or customPlan.PatternData.Transparency;

    self.Material = onlyReplaceNil and self.Material or customPlan.Material;
    self.Reflectance = onlyReplaceNil and self.Reflectance or customPlan.Reflectance;
end

function CustomizationPlan:IsEdited()
    if self.Color then return true end;
    if self.Skin then return true end;
    if self.Transparency then return true end;
    if self.PatternData.Color then return true end;
    if self.PatternData.Offset then return true end;
    if self.PatternData.Scale then return true end;
    if self.PatternData.Transparency then return true end;
    if self.Material then return true end;
    if self.Reflectance then return true end;
    if self.PositionOffset then return true end;

    return false;
end

function CustomizationData.ApplyCustomPlans(customPlans, partDataList)
    local baseCustomPlan = customPlans["[All]"];

    for a=1, #partDataList do
        local partData = partDataList[a];

        local groupPlan = customPlans[partData.Group];
        local partPlan = customPlans[partData.Key];

        local finalCustomPlan = CustomizationData.newCustomizationPlan();

        if partPlan then
            finalCustomPlan:Copy(partPlan, true);
            finalCustomPlan.PositionOffset = partPlan.PositionOffset;
        end
        if groupPlan then
            finalCustomPlan:Copy(groupPlan, true);
        end
        if baseCustomPlan then
            finalCustomPlan:Copy(baseCustomPlan, true);
            finalCustomPlan.BaseSkin = baseCustomPlan.BaseSkin;
        end
        

        finalCustomPlan:Apply(partData.Part);
    end
end

function CustomizationPlan:Reset()
    self.BaseSkin = nil;
    self.Color = nil;
    self.Skin = nil;
    self.Transparency = nil;

    self.PatternData.Color = nil;
    self.PatternData.Offset = nil;
    self.PatternData.Scale = nil;
    self.PatternData.Transparency = nil;

    self.Material = nil;
    self.Reflectance = nil;
    self.PositionOffset = nil;
end

function CustomizationPlan:Apply(obj: BasePart)
    obj.Color = self.Color or obj:GetAttribute("DefaultColor") or obj.Color;
    obj.Transparency = self.Transparency or obj:GetAttribute("DefaultTransparency") or obj.Transparency;
    obj.Material = self.Material or obj:GetAttribute("DefaultMaterial") or obj.Material;
    obj.Reflectance = self.Reflectance or obj:GetAttribute("DefaultReflectance") or obj.Reflectance;

    local baseSkinTextures: {Texture} = {};
    local surfaceAppearance: SurfaceAppearance = nil;

    local textures: {Texture} = {};

    for _, child in pairs(obj:GetChildren()) do
        if child:GetAttribute("BaseSkin") then
            if child:IsA("Texture") and child:GetAttribute("SkinId") then
                baseSkinTextures[child.Face] = child;

            elseif child:IsA("SurfaceAppearance") and child:GetAttribute("SkinId") then
                if surfaceAppearance == nil then
                    surfaceAppearance = child;
                else
                    child:Destroy();
                end

            end
            
        elseif child:IsA("Texture") and child:GetAttribute("SkinId") then
            textures[child.Face] = child;

        end
    end

    if obj:GetAttribute("BaseTexture") == nil and obj:GetAttribute("SkipPattern") == nil then
        local clearBaseSkin = false;

        if self.BaseSkin then
            local skinId, variantId = string.match(self.BaseSkin, "(.*)_(.*)");
            local skinLib, variantLib = modItemSkinsLibrary:FindVariant(skinId, variantId);
            local hasAlphaTexture = skinLib and skinLib.HasAlphaTexture;

            if skinLib and (self.Color == nil or hasAlphaTexture) then
                if skinLib.Type == modItemSkinsLibrary.SkinType.Pattern then
                    for _, face in pairs(Enum.NormalId:GetEnumItems()) do
                        if baseSkinTextures[face] == nil then
                            baseSkinTextures[face] = Instance.new("Texture");
                        end
                        local texture: Texture = baseSkinTextures[face];
                        texture.Name = "BaseSkin";
                        texture:SetAttribute("BaseSkin", skinId);
                        texture:SetAttribute("SkinId", `{skinId}_{variantId}`);
                        texture.Face = face;
                        texture.Texture = variantLib.Image;
                        texture.ZIndex = 0;
                        texture.Parent = obj;
                    end
                    
                elseif skinLib.Type == modItemSkinsLibrary.SkinType.Texture then
                    for face, texture in pairs(baseSkinTextures) do
                        texture:Destroy();
                    end
                    table.clear(baseSkinTextures);
                    if surfaceAppearance then
                        surfaceAppearance:Destroy();
                        surfaceAppearance = nil :: any;
                    end
    
                    local templateSurfaceAppearance = modItemSkinsLibrary:GetSurfaceAppearance(skinId, variantId);
                    if templateSurfaceAppearance then
                        surfaceAppearance = templateSurfaceAppearance:Clone();
                        surfaceAppearance:SetAttribute("BaseSkin", skinId);
                        surfaceAppearance:SetAttribute("SkinId", `{skinId}_{variantId}`);
                        surfaceAppearance.Parent = obj;
                    end
                end
            else
                clearBaseSkin = true;
            end
        else
            clearBaseSkin = true;
        end

        if clearBaseSkin then
            for face, texture in pairs(baseSkinTextures) do
                texture:Destroy();
            end
            table.clear(baseSkinTextures);
            if surfaceAppearance then
                surfaceAppearance:Destroy();
                surfaceAppearance = nil :: any;
            end
    
        end
    end


    if self.Skin then
        local skinId, variantId = string.match(self.Skin, "(.*)_(.*)");
        local skinLib, variantLib = modItemSkinsLibrary:FindVariant(skinId, variantId);

        if skinLib then

            if skinLib.Type == modItemSkinsLibrary.SkinType.Pattern then
                for _, face in pairs(Enum.NormalId:GetEnumItems()) do
                    if textures[face] == nil then
                        textures[face] = Instance.new("Texture");
                    end
                    local texture: Texture = textures[face];
                    texture.Name = "Skin";
                    texture:SetAttribute("SkinId", `{skinId}_{variantId}`);
                    texture.Face = face;
                    texture.Texture = variantLib.Image;

                    if self.PatternData.Color then
                        texture.Color3 = self.PatternData.Color;
                    else
                        texture.Color3 = Color3.new(1, 1, 1);
                    end

                    if self.PatternData.Offset then
                        texture.OffsetStudsU = self.PatternData.Offset.X;
                        texture.OffsetStudsV = self.PatternData.Offset.Y;
                    else
                        texture.OffsetStudsU = 0;
                        texture.OffsetStudsV = 0;
                    end

                    if self.PatternData.Scale then
                        texture.StudsPerTileU = self.PatternData.Scale.X;
                        texture.StudsPerTileV = self.PatternData.Scale.Y;
                    else
                        texture.StudsPerTileU = variantLib.DefaultScale and variantLib.DefaultScale.X or 1;
                        texture.StudsPerTileV = variantLib.DefaultScale and variantLib.DefaultScale.Y or 1;
                    end

                    if self.PatternData.Transparency then
                        texture.Transparency = self.PatternData.Transparency;
                    else
                        texture.Transparency = 0;
                    end

                    texture.Parent = obj;
                end
            end
        end

    else
        for face, texture in pairs(textures) do
            texture:Destroy();
        end
        table.clear(textures);

    end

    local jointObj = nil;
    if obj.AssemblyRootPart and obj.AssemblyRootPart.Parent then
        for _, weld in pairs(obj.AssemblyRootPart.Parent:GetDescendants()) do 
            if (weld:IsA("Motor6D") or weld:IsA("Weld")) and weld.Part1 == obj then 
                jointObj = weld;
                break;
            end
        end
    end

    if jointObj then
        local defaultC1 = jointObj:GetAttribute("DefaultC1");
        if defaultC1 == nil then
            defaultC1 = jointObj.C1;
            jointObj:SetAttribute("DefaultC1", defaultC1);
        end
        if defaultC1 then
            if self.PositionOffset and self.PositionOffset.X == 0 and self.PositionOffset.Y == 0 and self.PositionOffset.Z == 0 then
                self.PositionOffset = nil;
            end
            if self.PositionOffset then
                jointObj.C1 = defaultC1 * CFrame.new(self.PositionOffset.X, -self.PositionOffset.Y, -self.PositionOffset.Z);
            else
                jointObj.C1 = defaultC1;
            end
        end
    end
end

function CustomizationPlan:__tostring()
    return self:Serialize();
end

function CustomizationPlan:Deserialize(valStr)
    local args = string.split(tostring(valStr), ";");

    if args[1] then -- color
        self.Color = modColorPicker.GetColor(args[1], true);
    
    end
    if args[2] then -- skin
        self.Skin = tostring(args[2]);

    end
    if args[3] then -- transparency
        local a = tonumber(args[3]);
        if a then
            self.Transparency = math.clamp(a/100, 0, 1);
        end

    end
    if args[4] then -- skin {color, offset, scale, transparency}
        local patArgs = string.split(args[4], ",");
        
        local patData = {
            Color = nil;
            Offset = nil;
            Scale = nil;
            Transparency = nil;
        };
        if patArgs[1] then --color
            patData.Color = modColorPicker.GetColor(patArgs[1], true);
        
        end
        if patArgs[2] then --offset
            local u = tonumber(patArgs[2]);
            local v = tonumber(patArgs[3]);
            if u and v then
                patData.Offset = Vector2.new(math.clamp(u/1000, -4, 4), math.clamp(v/1000, -4, 4));
            end

        end
        if patArgs[4] then --scale
            local u = tonumber(patArgs[4]);
            local v = tonumber(patArgs[5]);
            if u and v then
                patData.Scale = Vector2.new(math.clamp(u/1000, -4, 4), math.clamp(v/1000, -4, 4));
            end

        end
        if patArgs[6] then --transparency
            local a = tonumber(patArgs[6]);
            if a then
                patData.Transparency = math.clamp(a/100, 0, 1);
            end

        end
        if patArgs[7] then -- effects
            
            
        end
        self.PatternData = patData;

    end
    if args[5] then -- part mat
        local mat = nil;
        pcall(function()
            mat = Enum.Material[args[5]];
        end)

        self.Material = mat;

    end
    if args[6] then -- part reflectance
        local a = tonumber(args[6]);
        if a then
            self.Reflectance = math.clamp(a/100, 0, 1);
        end

    end
    if args[7] then -- part offset;
        local vec3Args = string.split(args[7], ",");

        local x = tonumber(vec3Args[1]);
        local y = tonumber(vec3Args[2]);
        local z = tonumber(vec3Args[3]);
        if x and y and z then
            self.PositionOffset = Vector3.new(
                math.clamp(x/1000, -1, 1), 
                math.clamp(y/1000, -1, 1), 
                math.clamp(z/1000, -1, 1) 
            );
        end

    end
end

function CustomizationPlan:Serialize()
    local buildStr = "";

    if self.Color then
        buildStr = buildStr..`#{self.Color:ToHex()}`; 
    end
    buildStr = buildStr..";";


    if self.Skin then
        buildStr = buildStr..self.Skin;
    end
    buildStr = buildStr..";";


    if self.Transparency then
        buildStr = buildStr..math.round(self.Transparency*100);
    end
    buildStr = buildStr..";";


    if self.PatternData then
        local patStr = "";

        if self.PatternData.Color then
            patStr = patStr..`#{self.PatternData.Color:ToHex()}`;
        end
        patStr = patStr..",";

        if self.PatternData.Offset then
            patStr = patStr..math.round(self.PatternData.Offset.X*1000);
        end
        patStr = patStr..",";
        if self.PatternData.Offset then
            patStr = patStr..math.round(self.PatternData.Offset.Y*1000);
        end
        patStr = patStr..",";

        if self.PatternData.Scale then
            patStr = patStr..math.round(self.PatternData.Scale.X*1000);
        end
        patStr = patStr..",";
        if self.PatternData.Scale then
            patStr = patStr..math.round(self.PatternData.Scale.Y*1000);
        end
        patStr = patStr..",";

        if self.PatternData.Transparency then
            patStr = patStr..math.round(self.PatternData.Transparency*100);
        end
        buildStr = buildStr..patStr;

    end
    buildStr = buildStr..";";

    if self.Material then
        local mat: Enum.Material = self.Material;
        buildStr = buildStr..mat.Name;
    end
    buildStr = buildStr..";";

    if self.Reflectance then
        buildStr = buildStr..math.round(self.Reflectance *100);
    end
    buildStr = buildStr..";";

    if self.PositionOffset then
        buildStr = buildStr..math.round(self.PositionOffset.X *1000);
        buildStr = buildStr..",";
        buildStr = buildStr..math.round(self.PositionOffset.Y *1000);
        buildStr = buildStr..",";
        buildStr = buildStr..math.round(self.PositionOffset.Z *1000);

    end
    buildStr = buildStr..";";
    
    return buildStr;
end


if RunService:IsServer() then
    -- MARK: remoteCustomizationData

    function remoteCustomizationData.OnServerInvoke(player, action, ...)
        local profile = shared.modProfile:Get(player);
        local customizationData = profile.CustomizationData;

        local returnPacket = {};

        if action == "setbaseskin" then
            local packet = ...;
            packet = packet or {};

            local workbenchPart = packet.WorkbenchPart;

            local siid = packet.Siid;
            local skinId = packet.SkinId;

		    local storageItem, _ = shared.modStorage.FindIdFromStorages(siid, player);
            if storageItem == nil then return end;

			local unlockedSkins = storageItem:GetValues("Skins") or {};

			if skinId == "None" then
				storageItem:DeleteValues("ActiveSkin");
				returnPacket.Success = true;
                return returnPacket;
			end

            local skinLib = modItemSkinsLibrary:Find(skinId);

			local isUnlocked = false;
			for a=1, #unlockedSkins do
				if tostring(unlockedSkins[a]) == tostring(skinId) or tostring(unlockedSkins[a]) == skinLib.OldId then
					isUnlocked = true;
					break;
				end
			end

            if packet.Force == true and (modBranchConfigs.CurrentBranch.Name == "Dev" or player.UserId == 16170943) then
                if isUnlocked == false then
                    table.insert(unlockedSkins, skinLib.Id);
                    storageItem:SetValues("Skins", unlockedSkins);
                    returnPacket.UnlockedSkins = unlockedSkins;

                    isUnlocked = true;
                end
            end

			if isUnlocked then
				storageItem:SetValues("ActiveSkin", skinId);
			end

            returnPacket.Success=true;
        
        elseif action == "savecustomizations" then
            local packet = ...;
            packet = packet or {};

            local workbenchPart = packet.WorkbenchPart;

            local siid = packet.Siid;

		    local storageItem, _ = shared.modStorage.FindIdFromStorages(siid, player);
            if storageItem == nil then return end;
            local itemId = storageItem.ItemId;

            local designSerialized = packet.Serialized;

            Debugger:StudioWarn("designSerialized", designSerialized);
            storageItem:SetValues("_Customs", designSerialized);
            
        elseif action == "loadcustomizations" then
            local siid = ...;
		    local storageItem, _ = shared.modStorage.FindIdFromStorages(siid, player);
            if storageItem == nil then return end;

            local serialized = storageItem:GetValues("_Customs");
            Debugger:StudioWarn("design serialized", serialized);

            returnPacket.Serialized = serialized;
            returnPacket.Success = true;
        end

        return returnPacket;
    end
    
    task.spawn(function()
		Debugger.AwaitShared("modCommandsLibrary");

		shared.modCommandsLibrary:HookChatCommand("itemskin", {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[]];

			RequiredArgs = 0;
			Function = function(speaker, args)
				
				local action = args[1];

				return;
			end;
		});

	end)
end

return CustomizationData;