local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local RunService = game:GetService("RunService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modItemSkinsLibrary = require(game.ReplicatedStorage.Library.ItemSkinsLibrary);

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
                        {N="PartName"; L=0; P="aaa"};
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

        if action == "get" then
            local siid = ...;
            if siid == nil then return end;
            
		    local storageItem, _ = shared.modStorage.FindIdFromStorages(siid, player);
            if storageItem == nil then return end;

            local itemId = storageItem.ItemId;
            local skinAskey = storageItem:GetValues("SkinAskey");
            if skinAskey == nil then return end;

            local skinDesign = customizationData:GenerateSkin(itemId, skinAskey);

        end

        return;
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
        Color=nil;
        Skin=nil;
        Transparency=nil;
        PatternData=nil;
        PositionOffset=nil;
        Material=nil;
        Reflectance=nil;
    };

    setmetatable(self, CustomizationPlan);

    if rawLz4 then
        self:Decompress(rawLz4);
    end

    return self;
end

function CustomizationData:Apply(obj)
    obj.Color = self.Color or obj.Color;
    obj.Transparency = self.Transparency or obj.Transparency;
    obj.Material = self.Material or obj.Material;
    obj.Reflectance = self.Reflectance or obj.Reflectance;
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

    if args[1] then -- color
        self.Color = modColorPicker.GetColor(args[1], true);
    
    end
    if args[2] then -- skin
        if modItemSkinsLibrary:Find(tostring(args[2])) then
            self.Skin = tostring(args[2]);
        end

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
    if args[5] then -- part offset;
        local vec3Args = string.split(args[5], ",");

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


    if self.PositionOffset then
        buildStr = buildStr..math.round(self.PositionOffset.X *1000);
        buildStr = buildStr..",";
        buildStr = buildStr..math.round(self.PositionOffset.Y *1000);
        buildStr = buildStr..",";
        buildStr = buildStr..math.round(self.PositionOffset.Z *1000);

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

    return buildStr;
end

return CustomizationData;