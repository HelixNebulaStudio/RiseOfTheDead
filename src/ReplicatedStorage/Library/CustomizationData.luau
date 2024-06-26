local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local RunService = game:GetService("RunService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modItemSkinsLibrary = require(game.ReplicatedStorage.Library.ItemSkinsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local modColorPicker = require(game.ReplicatedStorage.Library.UI.ColorPicker);
local modLZ4 = require(game.ReplicatedStorage.Library.Util.LZ4);


local remoteCustomizationData = modRemotesManager:Get("CustomizationData") :: RemoteFunction;

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
        Plans={};
        Designs={};
    };
    --[[
        Plans={
            ["aaa"]="lz4compressed";    
        };
        Designs={
            ["p250"]={
                ["aaa"]={
                    Name="name"?;
                    Layers={
                        {N="PartName"; L=0; P="aaa"; PO="123,456,789";};
                    };
                }
            };
        };
    ]]

    setmetatable(self, meta);
    setmetatable(meta, CustomizationData);
    return self;
end

function CustomizationData.GenerateSkin(self, itemId, skinAsckey)
    local itemDesigns = self.Designs[itemId];
    if itemDesigns == nil then return end;

    local itemDesign = itemDesigns[skinAsckey];
    if itemDesign == nil then return end;

    local plansList = {};
    for a=1, #itemDesign.Layers do
        local layerData = itemDesign.Layers[a];

        if self.Plans[layerData.P] then
            plansList[layerData.P] = self.Plans[layerData.P];
        end
    end

    local result = {
        Plans=plansList;
        Design=itemDesign;
    }

    return result;
end

function CustomizationData:Load(rawTable)
    for k, v in pairs(rawTable) do
        if k == "Plans" then
            for valK, valLz4 in pairs(v) do
                local exist = false;
                for planK, planLz4 in pairs(self.Plans) do
                    if planLz4 == valLz4 then
                        self.PlanOverwrites[valK] = planK;
                        exist = true;
                        break;
                    end
                end

                if not exist then
                    self.Plans[valK] = valLz4;
                end
            end

        elseif k == "Designs" then
            --jmp load;

        else
            self[k] = v;
        end
    end

    if rawTable.Designs then
        for itemId, designList in pairs(rawTable.Designs) do
            local loadedDesigns = {};

            for designK, designData in pairs(designList) do
                -- designK base36

                for a=1, #designData.Layers do
                    local layerDesignData = designData.Layers[a];
                    if self.PlanOverwrites[layerDesignData.P] then
                        layerDesignData.P = self.PlanOverwrites[layerDesignData.P];
                    end
                end

                loadedDesigns[designK] = designData;
            end

            self.Designs[itemId] = loadedDesigns;
        end
    end
    
    
    return self;
end

if RunService:IsServer() then
    function remoteCustomizationData.OnServerInvoke(player, action, ...)
        local profile = shared.modProfile:Get(player);
        local customizationData = profile.CustomizationData;

        local returnPacket = {};

        if action == "loadskin" then
            local siid = ...;
            if siid == nil then return end;
            
		    local storageItem, _ = shared.modStorage.FindIdFromStorages(siid, player);
            if storageItem == nil then return end;

            local itemId = storageItem.ItemId;
            local skinAskey = storageItem:GetValues("SkinAskey");
            if skinAskey == nil then return end;

            local skinDesign = customizationData:GenerateSkin(itemId, skinAskey);


        elseif action == "setbaseskin" then
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
--==
local CustomizationPlan = {};
CustomizationPlan.__index = CustomizationPlan;

function CustomizationData.newCustomizationPlan(rawLz4)
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
        PositionOffset=nil;
    };

    setmetatable(self, CustomizationPlan);

    if rawLz4 then
        self:Decompress(rawLz4);
    end

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

function CustomizationPlan:Decompress(rawLz4)
    local valStr = modLZ4.decompress(rawLz4);
    return self:Deserialize(valStr);
end

function CustomizationPlan:Compress()
    local serializedData = self:Serialize();
    return modLZ4.compress(serializedData);
end

function CustomizationPlan:Deserialize(valStr)
    local args = string.split(tostring(valStr), ";");

    if args[1] then -- group
        self.Group = string.gsub(args[1], "[^%w]*", "");
    end
    if args[2] then -- color
        self.Color = modColorPicker.GetColor(args[2], true);
    
    end
    if args[3] then -- skin
        self.Skin = tostring(args[3]);

    end
    if args[4] then -- transparency
        local a = tonumber(args[4]);
        if a then
            self.Transparency = math.clamp(a/100, 0, 1);
        end

    end
    if args[5] then -- skin {color, offset, scale, transparency}
        local patArgs = string.split(args[5], ",");
        
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
    if args[6] then -- part mat
        local mat = nil;
        pcall(function()
            mat = Enum.Material[args[6]];
        end)

        self.Material = mat;

    end
    if args[7] then -- part reflectance
        local a = tonumber(args[7]);
        if a then
            self.Reflectance = math.clamp(a/100, 0, 1);
        end

    end
    if args[8] then -- part offset;
        local vec3Args = string.split(args[8], ",");

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

    if self.Group then
        buildStr = buildStr..(string.gsub(self.Group, "[^%w]*", "")); 
    end
    buildStr = buildStr..";";


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

return CustomizationData;