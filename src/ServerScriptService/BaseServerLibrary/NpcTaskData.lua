local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);
local modNpcTasksLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcTasksLibrary);

local modColorPicker = require(game.ReplicatedStorage.Library.UI.ColorPicker);

local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

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
        return;
    end;

    for a=1, #npcTasks do
        if npcTasks[a].Id == taskId then
            rPacket.FailMsg = "Task already exist.";
            return rPacket;
        end
    end

    if table.find(taskLib.NpcsList, npcName) == nil then
        rPacket.FailMsg = "Invalid npc task.";
        return rPacket;
    end

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

        local list = {};
		for a=1, #taskLib.Rewards do
			local rewardData = taskLib.Rewards[a];
			if rewardData.Type == "Item" then
                local qty = rewardData.Quantity or 1;
                local itemValues = {};
                rewardData.SetItemValues(itemValues, taskData);
				table.insert(list, {ItemId=rewardData.ItemId; Data={Quantity=qty; Values=itemValues;};});
			end
		end
		local hasSpace = playerInventory:SpaceCheck(list);
		if not hasSpace then
			rPacket.FailMsg = "Inventory full!";
            return rPacket;
		end

		for a=1, #taskLib.Rewards do
			local rewardData = taskLib.Rewards[a];
			if rewardData.Type == "Item" then
                local qty = rewardData.Quantity or 1;
                local itemValues = {};
                rewardData.SetItemValues(itemValues, taskData);
                
                local itemLibrary = modItemsLibrary:Find(rewardData.ItemId);
                playerInventory:Add(
                    rewardData.ItemId, 
                    {Quantity=qty; Values=itemValues}, 
                    function(queueEvent, storageItem)
                        shared.Notify(player, `You recieved {(qty > 1 and qty.." "..itemLibrary.Name or "a "..itemLibrary.Name)} from {npcName}.`, "Reward");
                        shared.modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
                    end
                );

                Debugger:StudioWarn("Reward:", rewardData.ItemId, "itemValues", itemValues);
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

        elseif currency == "Gold" then
            local goldCost = taskLib.SkipCost.Gold;
            if traderProfile.Gold < goldCost then
                rPacket.FailMsg = "Insufficient Gold";
              return rPacket;
            end

			traderProfile:AddGold(-goldCost);
			modAnalytics.RecordResource(player.UserId, goldCost, "Sink", "Gold", "Gameplay", "SkipTask");

        end

        taskData.EndTime = os.time();

        rPacket.Success = true;
        rPacket.Data = npcTaskData:GetTasks(npcName);

        return rPacket;
    end

    return;
end

return NpcTaskData;
