local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local fulfillColor = Color3.fromRGB(147, 255, 135):ToHex();
local notFulfillColor = Color3.fromRGB(255, 108, 103):ToHex();
--==

local MAXPAGES = 6;
local presetPackage = {
	Id = "Safehouse";
    Name = "Safehouse Storage";
    Configuration = {
        Persistent = true;
        Size = 24;
        MaxSize = 50;
        Expandable = true;
        MaxPages = MAXPAGES;
        PremiumPage = MAXPAGES-1;
    };
    Permissions = {
        CanInteract = true;
    };
};

local PAGEREQUIRE_UNLOCKFLAGS = {
    [3] = {}; -- lvl 50
    [4] = {EventFlag="SafePage4"; Desc="Complete <b>Mission: Spring Killing</b>";};  -- lvl 100
    [5] = {EventFlag="SafePage5"; Desc="Complete <b>Mission: Trimming the Corruption</b>";}; -- lvl 150
    [6] = {EventFlag="SafePage6"; Desc="Complete <b>Mission: Eerie Reflection</b>";}; -- lvl 200
    [7] = {EventFlag="SafePage7"; Desc="Complete <b>Mission: </b>";}; -- lvl 250
    [8] = {EventFlag="SafePage8"; Desc="Complete <b>Mission: </b>";}; -- lvl 300
    [9] = {EventFlag="SafePage9"; Desc="Complete <b>Mission: </b>";}; -- lvl 350
};

local function isLockCheck(player, page)
    local fulfillStates = {};

    local lvlRequired = (page-2) * 50;
    local requiresPremium = page >= presetPackage.Configuration.PremiumPage;
    local unlockFlags = PAGEREQUIRE_UNLOCKFLAGS[page];

    if RunService:IsClient() then
        local modData = shared.require(localPlayer:WaitForChild("DataModule"));
        
        fulfillStates.LevelRequirement = not (modData.GameSave == nil 
                                    or modData.GameSave.Stats.Level == nil 
                                    or modData.GameSave.Stats.Level < lvlRequired);

        if requiresPremium then
            fulfillStates.PremiumRequirement = modData.IsPremium == true;
        end

        if unlockFlags then
            local eventFlag = unlockFlags.EventFlag;

            if eventFlag and modData:GetEvent(eventFlag) == nil then
                fulfillStates.EventFlagRequirement = false;
            end
        end
        

    else
		local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);

        local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;
        local gameSave: GameSaveRotd = profile:GetActiveSave() :: GameSaveRotd;

        fulfillStates.LevelRequirement = gameSave:GetStat("Level") >= lvlRequired;

        if requiresPremium then
            fulfillStates.PremiumRequirement = profile.Premium == true;
        end

        if unlockFlags then
            local eventFlag = unlockFlags.EventFlag;
            if eventFlag and modEvents:GetEvent(player, eventFlag) == nil then
                fulfillStates.EventFlagRequirement = false;
            end
        end

    end

    return fulfillStates;
end

function presetPackage.BindStorageWindowUpdate(window: InterfaceWindow, activeStorageId)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local storage = modData.GetStorage(activeStorageId);

    local storageFrame = window.Frame;
    local lockedFrame = storageFrame:WaitForChild("LockedFrame");
    local lockedLabel = lockedFrame:WaitForChild("TextLabel");
    
    Debugger:Warn(`BindStorageWindowUpdate`, activeStorageId);

    local page = storage.Page or 1;

    local requirementStrs = {};
    local fullStates = isLockCheck(localPlayer, page);

    local lvlRequired = (page-2) * 50;
    
    local lvlFulfillColor = `<font color='#{fullStates.LevelRequirement and fulfillColor or notFulfillColor}'>`;
    table.insert(requirementStrs, `{lvlFulfillColor}• Mastery Level {lvlRequired}+</font>`);

    local requiresPremium = page >= presetPackage.Configuration.PremiumPage;
    if requiresPremium then
        local fulfillColor = `<font color='#{fullStates.PremiumRequirement and fulfillColor or notFulfillColor}'>`;
        table.insert(requirementStrs, `{fulfillColor}• Premium</font>`);
    end

    local unlockFlags = PAGEREQUIRE_UNLOCKFLAGS[page];
    if unlockFlags then

        local eventFlag = unlockFlags.EventFlag;
        if eventFlag then
            local fulfillColor = `<font color='#{fullStates.EventFlagRequirement and fulfillColor or notFulfillColor}'>`;
            table.insert(requirementStrs, `{fulfillColor}• {unlockFlags.Desc}</font>`);
        end
    end

    local isFulfilled = true;
    for _, v in pairs(fullStates) do
        if v == false then
            isFulfilled = false;
        end
    end

    lockedLabel.Text = `Requires:\n`..table.concat(requirementStrs, "\n");
    lockedFrame.Visible = isFulfilled == false;
end

function presetPackage.BindStorageCheck(packet)
    local dragStorage: Storage = packet.DragStorage;
	local dragStorageItem = packet.DragStorageItem;

    local tarStorage: Storage = packet.TargetStorage;
	local targetIndex = packet.TargetIndex;

    local page = tarStorage.Page or 1;
    if dragStorage.Id == tarStorage.Id and dragStorage.Page == page then
        packet.Allowed = true;
        return packet;
    end
    
    local fulfillState = isLockCheck(tarStorage.Player, page);

    local failMsg;
    for k, v in pairs(fulfillState) do
        
        if k == "LevelRequirement" and v ~= true then
            failMsg = `Level requirement not met.`;

        elseif k == "PremiumRequirement" and v ~= true then
            failMsg = `Premium requirement not met.`;

        elseif v ~= true then
            failMsg = `Requirements not met.`;

        end
    end
    
    if failMsg == nil then
        packet.Allowed = true;
        return packet;
    end

    packet.FailMsg = failMsg;
    packet.Allowed = false;
	return packet;
end

function presetPackage.BindInit(storage: Storage)

end



return presetPackage;