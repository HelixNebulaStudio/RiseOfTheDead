local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modDropRateCalculator = shared.require(game.ReplicatedStorage.Library.DropRateCalculator);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

if RunService:IsServer() then
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

end

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local VendingMachine = {
		Name = "VendingMachine";
        Type = "Button";
    };

    function VendingMachine.new(interactable: InteractableInstance, player: Player)
        
    end

    function VendingMachine.destroy(interactable: InteractableInstance, player: Player)
        Debugger:Warn(`destroying i`, interactable, `p`, player);
    end

    function VendingMachine.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        interactable.TypePackage.BindInteract(interactable, info);
        if info.Action ~= "Server" then return end;

        local player = info.Player;
        if player == nil then return end;

        local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;
        local gameSave: GameSaveRotd = profile:GetActiveSave() :: GameSaveRotd;
        local inventory: Storage = gameSave.Inventory;

        Debugger:Warn(`Server interact`, player, info.Values);

        local event = modEvents:GetEvent(player, "VendingMachine1");
        local lastVending = event and event.Time;
        
        if lastVending and workspace:GetServerTimeNow() < lastVending then
            return;
        end
        
        local playerMoney = gameSave:GetStat("Money");
        if playerMoney < 500 then
            shared.Notify(player, "You do not have enough money.", "Negative");
            return;
        end

        local rewardsLib = modRewardsLibrary:Find("t1Vending");
        local reward = modDropRateCalculator.RollDrop(rewardsLib, player);
        local itemId = reward[1].ItemId;
        local hasSpace = inventory:SpaceCheck{
            {ItemId=itemId; Data={Quantity=1;}};
        };
        
        modEvents:NewEvent(player, {Id="VendingMachine1"; Time=modSyncTime.GetTime()+60;}, true);
        gameSave:AddStat("Money", -500);
        
        modAnalyticsService:Sink{
            Player=player;
            Currency=modAnalyticsService.Currency.Money;
            Amount=500;
            EndBalance=gameSave:GetStat("Money");
            ItemSKU=`t1Vending`;
        };

        modAudio.Play("VendingMachine", interactable.Object);
        
        if hasSpace then
            local itemLib = modItemsLibrary:Find(itemId);
            inventory:Add(itemId, nil, function(queueEvent, storageItem)
                if storageItem and storageItem.Quantity > 0 then
                    shared.modStorage.OnItemSourced:Fire(nil, storageItem, storageItem.Quantity);
                end
            end);
            shared.Notify(player, "You have recieved a "..itemLib.Name..".", "Reward");
            
        else
            shared.Notify(player, "You do not have enough inventory space.", "Negative");
            
        end
        
            
    end
    
    -- When interactable pops up on screen.
    function VendingMachine.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        if RunService:IsServer() then return end;
        
        local clientData = info.ClientData;
        if clientData == nil then return end;

		local event = clientData:GetEvent("VendingMachine1");
		local lastTime = event and event.Time or nil;
		if lastTime == nil or workspace:GetServerTimeNow() >= lastTime then
			interactable.CanInteract = true;
			interactable.Label = "Insert $500 into vending machine and see what you get.";
			
		else
			interactable.CanInteract = false;
			local timeLapsed = modSyncTime.ToString(math.clamp(lastTime-workspace:GetServerTimeNow(), 0, 60))
			interactable.Label = `Cooldown: {timeLapsed}`;
			
		end
    end


    super.registerPackage(VendingMachine);

end

return interactablePackage;

