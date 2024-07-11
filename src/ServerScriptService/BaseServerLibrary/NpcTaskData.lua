local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);
local modNpcTasksLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcTasksLibrary);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);

local modColorPicker = require(game.ReplicatedStorage.Library.UI.ColorPicker);

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modAnalyticsService = require(game.ServerScriptService.ServerLibrary.AnalyticsService);

local remoteNpcData = modRemotesManager:Get("NpcData");

local NpcTaskData = {};
NpcTaskData.__index = NpcTaskData;

type NpcTaskDataObject = {
	Name: string?;
	Functions: {[number]: (...any)->(...any)};
}
type NpcTaskDataMeta = {
    Player: Player;
    __index: NpcTaskDataMeta;
};

local npcTaskDataObject = setmetatable({} :: NpcTaskDataObject, {} :: NpcTaskDataMeta);
export type NpcTaskData = typeof(setmetatable( npcTaskDataObject , NpcTaskData));
--==

function NpcTaskData:NewTask(npcName, taskPacket)
    local profile = shared.modProfile:Get(self.Player);
    local inventory = profile.ActiveInventory;

    local npcData = self:GetNpcData(npcName);
    local npcTasks = self:GetTasks(npcName);
    local maxTasks = 1;

    local rPacket = {};
    if #npcTasks >= maxTasks then 
        rPacket.FailMsg = "Npc tasks full.";
        return rPacket;
    end;

    local taskId = taskPacket.Id;
    local taskLib = modNpcTasksLibrary:Find(taskId);
    if taskLib == nil then 
        rPacket.FailMsg = "Invalid task id.";
        return rPacket;
    end;

    for a=1, #npcTasks do
        if npcTasks[a].Id == taskId then
            rPacket.FailMsg = "Task already exist.";
            return rPacket;
        end
    end

    if modNpcTasksLibrary.NpcTasks[npcName] == nil then
        rPacket.FailMsg = "Invalid npc task.";
        return rPacket;
    end

    local npcTaskExist = false;
    for a=1, #modNpcTasksLibrary.NpcTasks[npcName] do
        if modNpcTasksLibrary.NpcTasks[npcName][a].Id == taskId then
            npcTaskExist = true;
            break;
        end
    end
    if not npcTaskExist then
        rPacket.FailMsg = "Invalid npc task.";
        return rPacket;
    end
    
    -- Check task requirements;
    for a=1, #taskLib.Requirements do
        local requireData = taskLib.Requirements[a];

        if requireData.Type == "Mission" then
            local missionData = modMission:GetMission(self.Player, requireData.Id);
            if requireData.Completed and (missionData == nil or missionData.Type ~= 3) then
                rPacket.FailMsg = "Failed requirements.";
                return rPacket;
            end

        elseif requireData.Type == "Stat" then
            if npcData == nil then
                rPacket.FailMsg = "Failed requirements.";
                return rPacket;
            end

            if requireData.Id == "Happiness" and npcData.Happiness < requireData.Value then
                rPacket.FailMsg = "Failed requirements.";
                return rPacket;

            elseif requireData.Id == "Hunger" and npcData.Hunger < requireData.Value then
                rPacket.FailMsg = "Failed requirements.";
                return rPacket;
            end
            
        elseif requireData.Type == "Item" then
            local itemId = requireData.ItemId;
            local amount = requireData.Amount;

            local itemLib = modItemsLibrary:Find(itemId);
            
            local total,_ = inventory:ListQuantity(itemId, amount);
            if total <= 0 then
                rPacket.FailMsg = `Requires {itemLib.Name} ({amount}).`;
                return rPacket;
            end
        end
    end

    -- Check task values;
    local inputValues =  taskPacket.Values;
    local taskValues = {};

    for key, valueData in pairs(taskLib.Values) do
        if inputValues[key] == nil and valueData.CanNil ~= true then
            rPacket.FailMsg = "Missing task value.";
            return rPacket;
        end

        local inputValue = inputValues[key];

        if valueData.Type == "ColorPicker" then
            local color = modColorPicker.GetColor(inputValue);
            if color == nil then
                rPacket.FailMsg = "Invalid task value.";
                return rPacket;
            end

            taskValues[key] = color:ToHex();
        end
    end

    local duration = taskLib.Duration;

    taskPacket.Values = taskValues;
    taskPacket.StartTime = os.time();
    taskPacket.EndTime = os.time() + duration;
    table.insert(npcTasks, taskPacket);

    for a=1, #taskLib.Requirements do
        local requireData = taskLib.Requirements[a];

       if requireData.Type == "Item" then
            local itemId = requireData.ItemId;
            local amount = requireData.Amount;

            local itemLib = modItemsLibrary:Find(itemId);
            
            local _, itemList = inventory:ListQuantity(itemId, amount);
            if itemList then
                for a=1, #itemList do
                    inventory:Remove(itemList[a].ID, itemList[a].Quantity);
                    shared.Notify(self.Player, `{itemLib.Name} ({ amount}) removed from your Inventory.`, "Negative");
                end
            end
        end
    end

    rPacket.Success = true;
    return rPacket;
end

function NpcTaskData:GetTasks(npcName)
    local npcLib = modNpcProfileLibrary:Find(npcName);
    if npcLib == nil then return end;

    if self.Npc[npcName] == nil then
        self.Npc[npcName] = {};
    end

    return self.Npc[npcName];
end

function NpcTaskData:GetTask(npcName, taskId)
    local activeTasks = self:GetTasks(npcName);

    for a=1, #activeTasks do
        if activeTasks[a].Id == taskId then
            return activeTasks[a], a;
        end
    end

    return;
end

function NpcTaskData:Load(rawData)
    rawData = rawData or {};

	for k, v in pairs(rawData) do
		self[k] = v;
	end

	return self;
end

function NpcTaskData:GetNpcData(npcName)
    local profile = shared.modProfile:Get(self.Player);
    local safehomeData = profile.Safehome;
    
    return safehomeData:GetNpc(npcName);
end

function NpcTaskData.new(player) : NpcTaskData
	local meta = {
		Player = player;
	};
	meta.__index = meta;
	
	local self = {
        Npc={};
    };
	
	setmetatable(meta, NpcTaskData);
	setmetatable(self, meta);
	return self;
end

function remoteNpcData.OnServerInvoke(player: Player, action: string, npcName: string, packet: any)
    if remoteNpcData:Debounce() then return end;

    local profile = shared.modProfile:Get(player);
    local playerSave = profile:GetActiveSave();

	local traderProfile = profile.Trader;
    local safehomeData = profile.Safehome;
    local npcTaskData = profile.NpcTaskData;
	local playerInventory = profile.ActiveInventory;

    local npcData = safehomeData:GetNpc(npcName);

    local rPacket = {};

    if action == "assigntask" then
        local newTaskRPacket = npcTaskData:NewTask(npcName, {
            Id=packet.Id;
            Values=packet.Values;
        });

        if newTaskRPacket.Success then
            rPacket.Success = true;
            rPacket.Data = npcTaskData:GetTasks(npcName);

            return rPacket;
        else

            return newTaskRPacket;
        end

    elseif action == "completetask" then
        local taskData, taskIndex = npcTaskData:GetTask(npcName, packet.Id);

        if taskData == nil then
            rPacket.FailMsg = "Task not active.";
            return rPacket;
        end

        local taskLib = modNpcTasksLibrary:Find(taskData.Id);

        if taskLib == nil then
            rPacket.FailMsg = "Task does not exist.";
            return rPacket;
        end
         
        if os.time() < taskData.EndTime then
            rPacket.FailMsg = "Task is not complete.";
            return rPacket;
        end

        -- Check fail factors;
        local taskFailed = nil;
        for a=1, #taskLib.FailFactors do
            local failFactor = taskLib.FailFactors[a];

            if failFactor.Type == "Stat" then
                if failFactor.Id == "Hunger" and npcData.Hunger < failFactor.Value then
                    taskFailed = "Failed due to Hunger";
                    break;
                end
            end
        end
        if taskFailed then
            table.remove(npcTaskData.Npc[npcName], taskIndex);
        
            rPacket.Success = true;
            rPacket.TaskFailed = taskFailed;
            rPacket.Data = npcTaskData:GetTasks(npcName);
    
            return rPacket;
        end
        
        -- MARK: Task Succeed
        local list = {};
		for a=1, #taskLib.Rewards do
			local rewardData = taskLib.Rewards[a];
			if rewardData.Type == "Item" then
                local qty = rewardData.Quantity or 1;
                local itemValues = {};
                rewardData.SetItemValues(itemValues, taskData);
				table.insert(list, {ItemId=rewardData.ItemId; Data={Quantity=qty; Values=itemValues;};});

            elseif rewardData.Type == "ItemDrop" then
                local rewardsList = modRewardsLibrary:Find(rewardData.RewardId);
                local rewardsData = modDropRateCalculator.RollDrop(rewardsList, player);

                for a=1, #rewardsData do
                    local rewardInfo = rewardsData[a];

                    Debugger:StudioWarn("rewardInfo", rewardInfo);
                    table.insert(list, {ItemId=rewardInfo.ItemId; Data={Quantity=rewardInfo.DropQuantity; Values={};};});
                end
			end
		end

        local hasSpace = playerInventory:SpaceCheck(list);
        if not hasSpace then
            rPacket.FailMsg = "Inventory full!";
            return rPacket;
        end

        if #list > 0 then
            for a=1, #list do
                local addItem = list[a];

                local itemLibrary = modItemsLibrary:Find(addItem.ItemId);
                playerInventory:Add(
                    addItem.ItemId, 
                    addItem.Data, 
                    function(queueEvent, storageItem)
                        local itemTxt = `{itemLibrary.Name} ({addItem.Data.Quantity})`;
                        shared.Notify(player, `You recieved {itemTxt} from {npcName}.`, "PickUp");
                        shared.modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
                    end
                );

                Debugger:StudioWarn("Reward:", addItem);
            end
        end


        table.remove(npcTaskData.Npc[npcName], taskIndex);
        
        rPacket.Success = true;
        rPacket.Data = npcTaskData:GetTasks(npcName);

        return rPacket;

    elseif action == "canceltask" then
        local taskData, taskIndex = npcTaskData:GetTask(npcName, packet.Id);

        if taskData == nil then
            rPacket.FailMsg = "Task not active.";
            return rPacket;
        end

        local taskLib = modNpcTasksLibrary:Find(taskData.Id);

        if taskLib == nil then
            rPacket.FailMsg = "Task does not exist.";
            return rPacket;
        end
        
        if os.time() >= taskData.EndTime or taskData.EndTime-os.time() <= 10 then
            rPacket.FailMsg = "Task is already complete.";
            return rPacket;
        end

        local itemsList = {};
        for a=1, #taskLib.Requirements do
            local requireData = taskLib.Requirements[a];
    
           if requireData.Type == "Item" then
                local itemId = requireData.ItemId;
                local amount = requireData.Amount;
    
				table.insert(itemsList, {ItemId=itemId; Data={Quantity=amount; Values={};};});
            end
        end

        local hasSpace = playerInventory:SpaceCheck(itemsList);
        if not hasSpace then
            rPacket.FailMsg = "Inventory full to retrieve requirement items!";
            return rPacket;
        end
        
        for a=1, #itemsList do
            local itemId = itemsList[a].ItemId;
            local itemLib = modItemsLibrary:Find(itemId);

            playerInventory:Add(itemId, itemsList[a].Data, function()
                shared.Notify(player, `{itemLib.Name} ({itemsList[a].Data.Quantity}) has been returned to your Inventory.`, "PickUp");
            end);
        end

        table.remove(npcTaskData.Npc[npcName], taskIndex);
        
        rPacket.Success = true;
        rPacket.Data = npcTaskData:GetTasks(npcName);

        return rPacket;

    elseif action == "skiptask" then
        local taskData, taskIndex = npcTaskData:GetTask(npcName, packet.Id);

        if taskData == nil then
            rPacket.FailMsg = "Task not active.";
            return rPacket;
        end

        local taskLib = modNpcTasksLibrary:Find(taskData.Id);

        if taskLib == nil then
            rPacket.FailMsg = "Task does not exist.";
            return rPacket;
        end
         
        if taskData.EndTime and (taskData.EndTime-os.time()) <= 10 then
            rPacket.FailMsg = "Task about to be complete.";
            return rPacket;
        end

        local currency = packet.Currency or "Perks";
        if currency == "Perks" then
            local perkCost = taskLib.SkipCost.Perks;
            if playerSave:GetStat(currency) < perkCost then
                rPacket.FailMsg = "Insufficient Perks";
              return rPacket;
            end

            playerSave:AddStat("Perks", -perkCost);
            modAnalytics.RecordResource(player.UserId, perkCost, "Sink", "Perks", "Gameplay", "SkipTask");

            modAnalyticsService:Sink{
                Player=player;
                Currency=modAnalyticsService.Currency.Perks;
                Amount=perkCost;
                EndBalance=playerSave:GetStat("Perks");
                ItemSKU=`SkipTask:{taskLib.Id}`;
            };

        elseif currency == "Gold" then
            local goldCost = taskLib.SkipCost.Gold;
            if traderProfile.Gold < goldCost then
                rPacket.FailMsg = "Insufficient Gold";
              return rPacket;
            end

			traderProfile:AddGold(-goldCost);
			modAnalytics.RecordResource(player.UserId, goldCost, "Sink", "Gold", "Gameplay", "SkipTask");

            modAnalyticsService:Sink{
                Player=player;
                Currency=modAnalyticsService.Currency.Gold;
                Amount=goldCost;
                EndBalance=traderProfile.Gold;
                ItemSKU=`SkipTask:{taskLib.Id}`;
            };

        end

        taskData.EndTime = os.time();

        rPacket.Success = true;
        rPacket.Data = npcTaskData:GetTasks(npcName);

        return rPacket;
    end

    return;
end

return NpcTaskData;
