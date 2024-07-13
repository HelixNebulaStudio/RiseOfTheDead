local ShowcaseObject = {}

local modItemSkinsLibrary = require(game.ReplicatedStorage.Library.ItemSkinsLibrary);
local modCustomizationData = require(game.ReplicatedStorage.Library.CustomizationData);

function ShowcaseObject.new(interface, parent, library)
	if library == nil then return end;

    local itemId = library.ItemId;
    local skinLib = modItemSkinsLibrary:Find(itemId);
    if skinLib == nil then return end;

    local self = {};

    local itemViewportObject = interface.ItemViewport.new();
    itemViewportObject:SetZIndex(3);
    local frame = itemViewportObject.Frame :: Frame;

    frame.Destroying:Connect(function()
        itemViewportObject:Destroy();
    end)

    frame.Parent = parent;
    frame.Size = UDim2.new(1, 0, 1, 0);
    frame.Visible = true;

    local baseCustomPlan = modCustomizationData.newCustomizationPlan();
    baseCustomPlan.BaseSkin = modCustomizationData.GetBaseSkinFromActiveId(itemId, itemId);

    local customPlans = {
        ["[All]"]=baseCustomPlan;
    }

    local randomPreviewTool = {"m4a4"; "sr308"; "rec21"; "machete";}
    itemViewportObject:SetDisplay({
        ItemId=randomPreviewTool[math.random(1, #randomPreviewTool)];
        Values={
            ActiveSkin = itemId;
        };
        PhantomValues={
            _Customs=modCustomizationData.Serialize(customPlans);
        };
    });

    return self;
end

return ShowcaseObject;