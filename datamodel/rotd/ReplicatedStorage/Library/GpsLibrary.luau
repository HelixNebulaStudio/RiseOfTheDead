local RunService = game:GetService("RunService");

local modLibraryManager = shared.require(game.ReplicatedStorage.Library.LibraryManager);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modMapLibrary = shared.require(game.ReplicatedStorage.Library.MapLibrary);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modMissionLibrary = shared.require(game.ReplicatedStorage.Library.MissionLibrary);

--==
local library = modLibraryManager.new();

library.SpawnLocationLibrary = {};

library:BindPreAdd(function(data)
	if data.SetSpawn == nil or data.Locations == nil then return end;

	for a=1, #data.Locations do
		local locationName = data.Locations[a];
		library.SpawnLocationLibrary[locationName] = data.SetSpawn;
	end
end)

function library:GetTravelCost(lastTravelTime, playerProfile)
	local isPremium = playerProfile and playerProfile.Premium;
	local isTravelVip = playerProfile and playerProfile.GamePass and playerProfile.GamePass.VipTraveler;
	
	local timeLapsed = math.clamp(modSyncTime.GetTime() -lastTravelTime, 0, 300);
	local a = math.clamp(math.ceil(timeLapsed/30)/10, 0, 1);

	local price = math.floor(300 + (math.sqrt(1-a) * 4700));
	
	if isTravelVip then -- Vip Traveler
		price = price * 0.25;
		
	elseif isPremium then -- Premium
		price = price * 0.75;
		
	end
	if isTravelVip and isPremium then
		price = 0;
	end

	return price;
end


function library.onRequire()
    if RunService:IsClient() then return end;

    local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
    local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);
    local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);

    local remoteGpsRemote = modRemotesManager:Get("GpsRemote");
    
    function remoteGpsRemote.OnServerInvoke(player, id, action, gpsId)
        local playerClass: PlayerClass = shared.modPlayers.get(player);
        
        local layerName, _layerData = modMapLibrary:GetLayer(playerClass:GetCFrame().Position);
        local gpsLib = library:Find(gpsId);

        local _storageItem, storage = shared.modStorage.FindIdFromStorages(id, player);
        local unlock = storage:GetValues(id, "Gps") or {};
        
        local profile = shared.modProfile:Get(player);
        local activeSave = profile and profile:GetActiveSave();
        local traderProfile = profile and profile.Trader;
        
        local function mission49Check()
            if gpsId == "w1office" and modMission:Progress(player, 49) then
                modMission:Progress(player, 49, function(mission)
                    if profile.Collectibles.vrm then
                        mission.ProgressionPoint = 5;
                    else
                        mission.ProgressionPoint = 4;
                    end
                end)
            end
        end
        
        if action == "setmarker" then
            if gpsId == "w1office" and modMission:Progress(player, 49) then
                modMission:Progress(player, 49, function(mission)
                    if mission.ProgressionPoint == 2 then
                        mission.ProgressionPoint = 3;
                    end;
                end)
            end
            
        elseif action == "unlock" then
            
            if gpsLib and gpsLib.Locations then
                for a=1, #gpsLib.Locations do
                    if gpsLib.Locations[a] == layerName then
                        if unlock[gpsLib.Id] == nil then
                            unlock[gpsLib.Id] = 1;
                            storage:SetValues(id, {Gps=unlock});
                            shared.Notify(player, "Unlocked "..gpsLib.Name.." on GPS.", "Reward");
                            mission49Check();
                            
                        else
                            shared.Notify(player, "Already unlocked "..gpsLib.Name..".", "Negative");
                            
                        end
                        return 0, unlock;
                    end
                end
                -- location mismatch;
                shared.Notify(player, "You are not within the area "..gpsLib.Name.." to unlock it, or you can unlock it with Gold.", "Negative");
            end
            
        elseif action == "unlockGold" then
            if unlock[gpsLib.Id] == nil then
                local playerGold = traderProfile.Gold;
                
                if playerGold >= 100 then
                    unlock[gpsLib.Id] = 1;
                    storage:SetValues(id, {Gps=unlock});
                    traderProfile:AddGold(-100);
                    shared.Notify(player, "Unlocked "..gpsLib.Name.." on GPS.", "Reward");

                    modAnalyticsService:Sink{
                        Player=player;
                        Currency=modAnalyticsService.Currency.Gold;
                        Amount=100;
                        EndBalance=traderProfile.Gold;
                        ItemSKU=`Unlock:gps`;
                    };

                    mission49Check();
                    return 1;
                    
                else
                    return 3;
                    
                end
                
            else
                shared.Notify(player, "Already unlocked "..gpsLib.Name..".", "Negative");
                return 2;
            end
            
        elseif action == "travel" then
            local playerMoney = activeSave:GetStat("Money");
            local cost = library:GetTravelCost(activeSave.LastFastTravel, profile);

            if gpsLib.FreeTravel then
                cost = 0;
            end
            
            local playerMissions = modMission.GetMissions(player.Name);
            if playerMissions then
                for a=1, #playerMissions do
                    local mission = playerMissions[a];
                    if mission.Type == 1 then
                        local library = modMissionLibrary.Get(mission.Id);
                        
                        local fastTravelDisabled = false;

                        if library.CanFastTravelWhenActive == false then
                            fastTravelDisabled = true;
                        end
                        if typeof(library.CanFastTravelWhenActive) == "table" then
                            if table.find(library.CanFastTravelWhenActive, tonumber(mission.ProgressionPoint) or 0) then
                                fastTravelDisabled = true;
                            end
                        end
                        
                        if fastTravelDisabled then
                            shared.Notify(player, ("Can not fast travel when mission \"$missionName\" is active."):gsub("$missionName", library.Name), "Negative");
                            return 2;
                        end
                    end
                end
            end
            
            if unlock[gpsLib.Id] or gpsLib.UnlockedByDefault == true then
                mission49Check();
                if playerMoney < cost then return 1 end;
                
                activeSave.Gps = gpsLib.Id
                activeSave.Spawn = gpsLib.SetSpawn;
                
                if gpsLib.FreeTravel then
                else
                    activeSave.LastFastTravel = modSyncTime.GetTime();
                end
                
                activeSave:AddStat("Money", -cost);
                activeSave:Sync();
                
                shared.Notify(player, "Traveling to "..gpsLib.Name..".", "Reward");

                if modBranchConfigurations.WorldName == gpsLib.WorldName then
                    task.delay(0.5, function()
                        if gpsLib.Position then
                            local newSpawnCFrame = CFrame.new(gpsLib.Position);
                            playerClass:SetCFrame(newSpawnCFrame);
                        end
                    end)
                    return 2;
                else
                    task.spawn(function()
                        repeat
                            modServerManager:Travel(player, gpsLib.WorldName);
                            task.wait(5);
                        until not player:IsDescendantOf(game.Players)
                    end)
                    return 0;
                end
            end
        end

        return;
    end

end


--==
--library:Add{
--	Id="w0test";
--	Name="Test Room";
--	Image="http://www.roblox.com/asset/?id=5954340695";

--	WorldName="BioXResearch";
--	Position=Vector3.new(-50.63, -15.95, -0.12);
--	SetSpawn="warehouse";

--	Locations = {
--		"Room";
--	};
--};

if game:GetService("RunService"):IsStudio() then
	library:Add{
		Id="w0test";
		Name="BioXResearch Lab";
		Image="http://www.roblox.com/asset/?id=5954340695";

		WorldName="BioXResearch";
		Position=Vector3.new(-53.255, -14.355, 0);
		SetSpawn="SpawnLocation";

		Locations = {
			"Room";
		};
		
		FactionBanner=true;
	};

	library:Add{
		Id="w0test2";
		Name="BioXResearch Lab 2";
		Image="http://www.roblox.com/asset/?id=5954340695";

		WorldName="BioXResearch";
		Position=Vector3.new(-53.255, -14.355, 0);
		SetSpawn="SpawnLocation2";

		Locations = {
			"Room";
		};
	};
	
end

library:Add{
	Id="pwsafehome";
	Name="Safehome";
	Image="http://www.roblox.com/asset/?id=7030452840";
	
	WorldName="Safehome";
	UnlockedByDefault=true;
	FreeTravel=true;
	Locations = {};
};

library:Add{
	Id="w1";
	Name="World: W.D. Warehouse";
	WorldName="TheWarehouse";
};

library:Add{
	Id="w1sh1";
	Name="Warehouse Safehouse";
	Image="http://www.roblox.com/asset/?id=5954340695";
	
	WorldName="TheWarehouse";
	Position=Vector3.new(12.16, 58.25, 10.09);
	SetSpawn="warehouse";
	UnlockedByDefault=true;
	
	FreeTravel=true;
	Locations = {
		"Warehouse Bedroom";
		"Warehouse Safehouse";
	};
	
	FactionBanner=true;
};

library:Add{
	Id="w1sh2";
	Name="Sunday's Safehouse";
	Image="http://www.roblox.com/asset/?id=5954371576";

	WorldName="TheWarehouse";
	Position=Vector3.new(636.432, 58.35, -14.34);
	SetSpawn="sundays";

	Locations = {
		"Sunday's Safehouse";
		"Sunday's Second Floor";
		"Sunday's Roof";
	};

	FactionBanner=true;
};

library:Add{
	Id="w1bloxmart";
	Name="Bloxmart";
	Image="http://www.roblox.com/asset/?id=5954369114";

	WorldName="TheWarehouse";
	Position=Vector3.new(300.902, 58.4, 11.538);
	SetSpawn="warehouse";

	Locations = {
		"Bloxmart";
	};
};

library:Add{
	Id="w1park";
	Name="Park";
	Image="http://www.roblox.com/asset/?id=5954370507";

	WorldName="TheWarehouse";
	Position=Vector3.new(352.02, 60.4, 222.46);
	SetSpawn="sundays";

	Locations = {
		"Park";
	};
};

library:Add{
	Id="w1bank";
	Name="Bank";
	Image="http://www.roblox.com/asset/?id=5954372781";

	WorldName="TheWarehouse";
	Position=Vector3.new(632.182, 58.3, 50.988);
	SetSpawn="sundays";

	Locations = {
		"Bank";
	};
};

library:Add{
	Id="w1factory";
	Name="Factory";
	Image="http://www.roblox.com/asset/?id=5954374975";

	WorldName="TheWarehouse";
	Position=Vector3.new(65.672, 58.61, 185.688);
	SetSpawn="factoryExit";

	Locations = {
		"Factory";
	};
};

library:Add{
	Id="w1office";
	Name="Office";
	Image="http://www.roblox.com/asset/?id=5954376382";

	WorldName="TheWarehouse";
	Position=Vector3.new(637.31, 58.35, 255.72);
	SetSpawn="officeExit";

	Locations = {
		"Office";
	};
};

library:Add{
	Id="w2";
	Name="World: W.D. Underground";
	WorldName="TheUnderground";
};

library:Add{
	Id="w2sectorf";
	Name="Sector F";
	Image="http://www.roblox.com/asset/?id=5959080979";

	WorldName="TheUnderground";
	Position=Vector3.new(2.41, 16.5, -78.652);
	SetSpawn="sewerentrance";

	Locations = {
		"Sector F";
	};
};

library:Add{
	Id="w2sh3";
	Name="Underbridge Community";
	Image="http://www.roblox.com/asset/?id=5959082717";

	WorldName="TheUnderground";
	Position=Vector3.new(-94.475, 11.182, 287.995);
	SetSpawn="underbridge";

	Locations = {
		"Underbridge Safehouse";
		"Underbridge Second Floor";
		"Underbridge Top Floor";
	};

	FactionBanner=true;
};

library:Add{
	Id="w2sectore";
	Name="Sector E";
	Image="http://www.roblox.com/asset/?id=5959083723";

	WorldName="TheUnderground";
	Position=Vector3.new(136.217, 12.691, -9.244);
	SetSpawn="SecE";

	Locations = {
		"Sector E";
	};
};

library:Add{
	Id="w2sh4";
	Name="Train Station Safehouse";
	Image="http://www.roblox.com/asset/?id=5959092587";

	WorldName="TheUnderground";
	Position=Vector3.new(251.851, 10.2, -8.623);
	SetSpawn="trainstation";

	Locations = {
		"Train Station Safehouse";
	};

	FactionBanner=true;
};

library:Add{
	Id="w3";
	Name="World: W.D. Mall";
	WorldName="TheMall";
};

library:Add{
	Id="w3sh5";
	Name="Mall Safehouse";
	Image="http://www.roblox.com/asset/?id=5959094120";

	WorldName="TheMall";
	Position=Vector3.new(736.13, 95.575, -672.074);
	SetSpawn="mallshop1";

	Locations = {
		"Mall Safehouse";
	};
};

library:Add{
	Id="w3banditcamp";
	Name="Bandit Camp";
	Image="http://www.roblox.com/asset/?id=5959095409";

	WorldName="TheMall";
	Position=Vector3.new(797.523, 163.268, -728.326);
	SetSpawn="patrick";

	Locations = {
		"Bandit Camp";
	};
};

library:Add{
	Id="w3preschool";
	Name="Preschool";
	Image="http://www.roblox.com/asset/?id=5959096400";

	WorldName="TheMall";
	Position=Vector3.new(440.112, 97.981, -664.022);
	SetSpawn="unToMallKin";

	Locations = {
		"Preschool";
	};
};

library:Add{
	Id="w3sh6";
	Name="Clinic Safehouse";
	Image="http://www.roblox.com/asset/?id=5959098284";

	WorldName="TheMall";
	Position=Vector3.new(525.705, 97.735, -1102.795);
	SetSpawn="hacClinic1";

	Locations = {
		"Clinic Safehouse";
	};

	FactionBanner=true;
};

library:Add{
	Id="w4";
	Name="World: W.D. Residentials";
	WorldName="TheResidentials";
};

library:Add{
	Id="w4sh7";
	Name="Community Safehouse";
	Image="http://www.roblox.com/asset/?id=5959099674";

	WorldName="TheResidentials";
	Position=Vector3.new(1152.655, 57.415, -31.126);
	SetSpawn="communitySh";

	Locations = {
		"Community Safehouse";
	};

	FactionBanner=true;
};

library:Add{
	Id="w4radio";
	Name="Radio Station";
	Image="http://www.roblox.com/asset/?id=5959100518";

	WorldName="TheResidentials";
	Position=Vector3.new(1104.75, 71.233, -481.696);
	SetSpawn="mallToRadio";

	Locations = {
		"Radio Station";
	};
};

library:Add{
	Id="w4insurance";
	Name="Insurance Firm";
	Image="http://www.roblox.com/asset/?id=5959101749";

	WorldName="TheResidentials";
	Position=Vector3.new(878.742, 58.486, 256.586);
	SetSpawn="warehouseToResidential";

	Locations = {
		"Insurance Firm";
	};
};

library:Add{
	Id="w4bunkerinc";
	Name="Bunker Inc. Base";
	Image="http://www.roblox.com/asset/?id=13787134613";

	WorldName="TheResidentials";
	Position=Vector3.new(920.135, 58.327, -88.057);
	SetSpawn="bunkerInc";

	Locations = {
		"Bunker Inc. Base";
	};
};


library:Add{
	Id="w5";
	Name="World: W.D. Harbor";
	WorldName="TheHarbor";
};

library:Add{
	Id="w5harborsafehouse";
	Name="Harbor Safehouse";
	Image="rbxassetid://8816108529";

	WorldName="TheHarbor";
	Position=Vector3.new(-322.035, 81.768, 223.737);
	SetSpawn="harborSh";

	Locations = {
		"Harbor Safehouse";
		"Harbor Safehouse Floor 2";
		"Harbor Safehouse Top Floor";
	};
};

return library;