local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then
    modSafehomeService = shared.require(game.ServerScriptService.ServerLibrary.SafehomeService);
    modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
    modFactions = shared.require(game.ServerScriptService.ServerLibrary.Factions);
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new();

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
	
	Debugger:Log("Host data Safehome activeSafehomeId", activeSafehomeId);

end

function WorldCore.onRequire()
    if RunService:IsServer() then

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
        end, 999);

    end
end


return WorldCore;