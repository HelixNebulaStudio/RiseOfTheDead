local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local DEFAULT_NOTIFICATION_DURATION = 10;
local tweenInfo = TweenInfo.new(0.5);

local interfacePackage = {
    Name = script.Name;
    Type = "Player";
    LoadOrder = 2;
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local branchColor: Color3 = interface.Colors.Branch;

    local templateNewNotifications = script:WaitForChild("NewNotifications");
    local templateBaseListing = script:WaitForChild("BaseListing");

    local proxyFrame = Instance.new("Frame");
    proxyFrame.BackgroundTransparency = 1;
    proxyFrame.Size = UDim2.new(0, 0, 0, 0);

    local graceTick = nil;

    local QBNotifications = {};
    QBNotifications.Visible = true;
    QBNotifications.Frame = proxyFrame;
    QBNotifications.QueueList = {};

    function QBNotifications.refresh()
        if graceTick and tick()-graceTick < tweenInfo.Time then return end;

        local activeItem = QBNotifications.QueueList[1];
        if activeItem == nil then return end;

        local qbName = activeItem.QbName;
        local qbWindow = interface.Windows[qbName];
        local quickButton = qbWindow and qbWindow.QuickButton;

        if quickButton == nil then
            modTables.moveToLast(QBNotifications.QueueList, 1);
            return;
        end;

        local curTick = tick();
        local startTime = math.max(activeItem.LastUpdate, activeItem.StartTime or 0);
        
        local showLapsed = curTick-startTime;

        local notificationDuration = DEFAULT_NOTIFICATION_DURATION;
        local durationSetting = modData:GetSetting("QBNotificationDuration");
        if durationSetting ~= nil then
            notificationDuration = durationSetting;
        end

        if showLapsed > notificationDuration then
            table.remove(QBNotifications.QueueList, 1);

            local oldFrame = activeItem.Frame;
            if oldFrame then
                activeItem.Frame = nil;

                task.spawn(function()
                    TweenService:Create(oldFrame, tweenInfo, {
                        Size = UDim2.new(0, 0, 0, 0);
                    }):Play();
                    task.wait(tweenInfo.Time);
                    graceTick = tick();
                    oldFrame:Destroy();
                end)
            end

        else
            local newFrame = activeItem.Frame;
            if newFrame == nil then
                newFrame = templateNewNotifications:Clone();
                newFrame.Position = UDim2.new(0.5, 0, 1, modConfigurations.CompactInterface and 15 or 30);
                newFrame.Parent = quickButton;
                activeItem.Frame = newFrame;

                for _, des in pairs(newFrame:GetDescendants()) do
                    if des:IsA("UIGradient") then
                        des.Color = ColorSequence.new(branchColor);
                    end
                end
            end

            if activeItem.HasNewItem then
                local listFrame = newFrame:WaitForChild("List");

                for _, obj in pairs(listFrame:GetChildren()) do
                    if not obj:IsA("GuiObject") then continue end;
                    obj:Destroy();
                end

                for _, itemInfo in ipairs(activeItem.Items) do
                    itemInfo.Listing = nil;
                end

                local ySize = #activeItem.Items * (modConfigurations.CompactInterface and 50 or 70);

                for a=1, #activeItem.Items do
                    local itemInfo = activeItem.Items[a];
                    local newListing = templateBaseListing:Clone();
                    newListing.Size = UDim2.new(0, 0, 0, modConfigurations.CompactInterface and 40 or 60);
                    newListing.Parent = listFrame;
                    itemInfo.Listing = newListing;

                    local iconLabel = newListing:WaitForChild("iconLabel");
                    iconLabel.Image = itemInfo.Icon;

                    local descLabel = newListing:WaitForChild("descLabel");
                    descLabel.Text = itemInfo.Desc;
                end

                TweenService:Create(newFrame, tweenInfo, {
                    Size = UDim2.new(0, 100, 0, ySize);
                }):Play();

                activeItem.StartTime = tick();
                activeItem.HasNewItem = false;
            end

            newFrame.Visible = QBNotifications.Visible;
        end
    end

    function QBNotifications.queueNotify(qbName, notificationItems)
        local itemList = notificationItems;
        if typeof(itemList) ~= "table" or #itemList <= 0 then return end;

        if itemList.Icon ~= nil and itemList[1] == nil then
            itemList = { itemList };
        end

        local existItem = nil;

        for a=#QBNotifications.QueueList, 1, -1 do
            if QBNotifications.QueueList[a].QbName == qbName then
                existItem = QBNotifications.QueueList[a];
                break;
            end
        end

        if existItem == nil then
            existItem = {
                QbName = qbName;
                Items = {};
            };
        end

        for _, itemInfo in ipairs(itemList) do
            if typeof(itemInfo) == "table" then
                table.insert(existItem.Items, itemInfo);
            end
        end

        existItem.HasNewItem = true;
        existItem.LastUpdate = tick();

        if table.find(QBNotifications.QueueList, existItem) == nil then
            table.insert(QBNotifications.QueueList, existItem);
        end

        QBNotifications.refresh();
    end

    local uiElement: InterfaceElement = interface:GetOrDefaultElement(interfacePackage.Name, QBNotifications);
    uiElement.Layers = {"CharacterHud"; "CompactHidden";};

    interface.Scheduler.OnStepped:Connect(function(tickData)
        if tickData.ms100 ~= true then return end;
        QBNotifications.refresh();
    end)
end

return interfacePackage;