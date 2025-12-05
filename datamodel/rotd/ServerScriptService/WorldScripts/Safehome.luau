local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

if RunService:IsServer() then
    modSafehomeService = shared.require(game.ServerScriptService.ServerLibrary.SafehomeService);
    modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
    modFactions = shared.require(game.ServerScriptService.ServerLibrary.Factions);
    modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

WorldCore.FactionGroupCache = nil;
WorldCore.SafehomeClass = nil;
--==

function WorldCore.loadSafehome(player: Player)
    if WorldCore.SafehomeClass then return end;
    
    local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
    if profile == nil then return end;

    local safehomeData = profile.Safehome;
    
    local lastActive = safehomeData.LastActive or os.time();
    local activeSafehomeId = safehomeData.ActiveId;

    local safehomeClass = modSafehomeService.SafehomeClass.new(player);
    WorldCore.SafehomeClass = safehomeClass;
    safehomeData:SetMetaSafehomeClass(safehomeClass);

    safehomeClass:ChangeMap(activeSafehomeId);
    Debugger:StudioLog(`loadSafehome`, safehomeClass);
    
    local npcNamesList = {};
    for npcName, npcData in pairs(safehomeData.Npc) do
        if npcData == nil or npcData.Active == nil then continue end;
        table.insert(npcNamesList, npcName);
    end
    safehomeClass:LoadNpcs(npcNamesList);

    local homeData = safehomeData.Homes[activeSafehomeId];
    safehomeClass:LoadCustomization(homeData);
end

function WorldCore.loadFactionSafehome(headquarterData)
    if WorldCore.SafehomeClass then return end;

    local factionTag: string = headquarterData.FactionTag;
    if factionTag == nil then return end;

    Debugger:Warn("Loading faction headquarter", headquarterData);
    workspace:SetAttribute("FactionHeadquarters", factionTag);

	local factionGroup = modFactions.Get(factionTag);
	if factionGroup == nil then Debugger:Warn("Failed to load faction group"); return end;
	
	WorldCore.FactionGroupCache = factionGroup;
	
	local ownerPlayer = game.Players:GetPlayerByUserId(tonumber(factionGroup.Owner));
	local factionColor = Color3.fromHex(factionGroup.Color);
	
	local activeSafehomeId = factionGroup.SafehomeId or "default";
    
    local safehomeClass = modSafehomeService.SafehomeClass.new();
    safehomeClass.FactionTag = factionTag;
    WorldCore.SafehomeClass = safehomeClass;
	
	Debugger:Log("Host data Safehome activeSafehomeId", activeSafehomeId);

end

function WorldCore.onRequire()
    if RunService:IsServer() then
        remoteSafehomeRequest = modRemotesManager:Get("SafehomeRequest");

        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            if WorldCore.SafehomeClass ~= nil then return end;

            local joinData = player:GetJoinData();
            local teleportData = joinData.TeleportData;

            local headquarterData = teleportData and teleportData.FactionHeadquarter or nil;
            
            if headquarterData == nil and workspace:GetAttribute("TestFactionHq") == true and RunService:IsStudio() then
                headquarterData = {
                    FactionTag = "test";
                    FactionOwnerId = "16170943";
                    SafehomeId = "default";
                };
            end
            
            if headquarterData then
                WorldCore.loadFactionSafehome(headquarterData);
                return;
            end

            repeat 
                Debugger:Log("Waiting for private world creator."); 
                task.wait(1) 
            until modServerManager.PrivateWorldCreator ~= nil;
            local ownerPlayer = modServerManager.PrivateWorldCreator;
            local isOwner = player == ownerPlayer;
            
            if not isOwner then Debugger:Warn(`Player ({player.Name}) is not the safehome owner`); return; end;

            WorldCore.loadSafehome(player);
            
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

            local gameSave: GameSaveRotd = profile:GetActiveSave() :: GameSaveRotd;
            if gameSave == nil then return end;

            local safehomeData = profile.Safehome;
            safehomeData:Init();
            
            if gameSave.Storages and gameSave.Storages.Freezer == nil then
                gameSave.Storages.Freezer = shared.modStorage.new("Freezer", "Freezer", player);
            end

            if gameSave.Storages.Freezer then
                local freezerStorage = gameSave.Storages.Freezer;
                freezerStorage.OnChanged:Connect(safehomeData.UpdateFoodSupply);
                task.delay(5, function()
                    safehomeData.UpdateFoodSupply();
                end)
                
                pcall(function() remoteSafehomeRequest:InvokeClient(player, safehomeData); end)
            end

        end, 999);

    end
end


return WorldCore;