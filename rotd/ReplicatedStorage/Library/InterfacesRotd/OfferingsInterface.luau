local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryRotd);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);

local modComponents = shared.require(game.ReplicatedStorage.Library.UI.Components);
local modRadialImage = shared.require(game.ReplicatedStorage.Library.UI.RadialImage);
local modUIUtil = shared.require(game.ReplicatedStorage.Library.UI.UIUtil);
local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modStorageInterface = shared.require(game.ReplicatedStorage.Library.UI.StorageInterface);

local buttonRadialConfig = '{"version":1,"size":128,"count":256,"columns":8,"rows":8,"images":["rbxassetid://4744240077", "rbxassetid://4744242814", "rbxassetid://4744244749", "rbxassetid://4744244960"]}';

local interfacePackage = {
    Type = "Character";

    SigilChars = {
        Greek = {"Δ"; "Ψ"; "Θ"; "Ω"; "Φ"; "Σ"; "β"; "Π";};
    };
};
interfacePackage.SigilChars.Default = interfacePackage.SigilChars.Greek;

local TierColors = {
    Color3.fromRGB(255, 255, 255);
    Color3.fromRGB(0, 145, 255);
    Color3.fromRGB(85, 0, 255);
    Color3.fromRGB(212, 0, 255);
    Color3.fromRGB(255, 0, 0);
    Color3.fromRGB(255, 170, 0);
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local remoteShopService = modRemotesManager:Get("ShopService");
    local swivelTemplate = script:WaitForChild("swivelTemplate");
    local priceFrameTemplate = script:WaitForChild("priceFrameTemplate");

	local windowFrame = script:WaitForChild("OfferingsWindow"):Clone();
	windowFrame.Parent = interface.ScreenGui;
    
    local mainFrame = windowFrame:WaitForChild("Frame");
    local pivotOptions = mainFrame:WaitForChild("OptionsPivot");
    local flashDecal = mainFrame:WaitForChild("Flash");
    local bkgroundItem = mainFrame:WaitForChild("BackgroundItem");
    local itemOfferSlot = mainFrame:WaitForChild("ItemOfferSlot");
    itemOfferSlot.Visible = false;
    local titleLabel = mainFrame:WaitForChild("TitleFrame"):WaitForChild("Title");

	local offeringsWindow: InterfaceWindow = interface:NewWindow("OfferingsWindow", windowFrame);
    offeringsWindow.BoolStringWhenActive = {String="!CharacterHud"; Priority=2;};
	offeringsWindow.CompactFullscreen = true;
    offeringsWindow.CloseWithInteract = true;
    offeringsWindow.DisableInteractables = true;
	offeringsWindow:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0), UDim2.new(0.5, 0, 0.5, 0));

    mainFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
        interface:PlayButtonClick();
        offeringsWindow:Close();
    end)

    local acceptButtonObj = modComponents.CreateHoldDownButton(interface, {
       Name = "AcceptButton";
       Text = "Purchase Offer";
       Color = Color3.fromRGB(50, 100, 50);
    });
    local acceptButtonObjButton = acceptButtonObj.Button;
    acceptButtonObjButton.Visible = false;
    acceptButtonObjButton.AnchorPoint = Vector2.new(0.5, 0);
    acceptButtonObjButton.Position = UDim2.new(0.5, 0, 1, 60);
    acceptButtonObjButton.Size = UDim2.new(1, 0, 0, 30);
    acceptButtonObjButton.Parent = mainFrame;
    local denyButtonObj = modComponents.CreateHoldDownButton(interface, {
        Name = "DenyButton";
        Text = "Deny Offer";
        Color = Color3.fromRGB(100, 50, 50);
    });
    local denyButtonObjButton = denyButtonObj.Button;
    denyButtonObjButton.Visible = false;
    denyButtonObjButton.AnchorPoint = Vector2.new(0.5, 0);
    denyButtonObjButton.Position = UDim2.new(0.5, 0, 1, 95);
    denyButtonObjButton.Size = UDim2.new(1, 0, 0, 30);
    denyButtonObjButton.Parent = mainFrame;


    local openSnd: Sound = nil;

    local binds = offeringsWindow.Binds;
    binds.Colors = setmetatable({}, {__index={
        Base = Color3.fromRGB(128, 0, 0);
        Ground = Color3.fromRGB(80, 0, 0);
        Bright = Color3.fromRGB(100, 0, 0);
        Burnt = Color3.fromRGB(30);
    }});
    binds.Options = {};

    local function animateOpen(offerIndex)
        local optionInfo = binds.Options[offerIndex];
        if optionInfo == nil then return end;

        local button = optionInfo.Button;
        button.AutoButtonColor = false;
        button.Interactable = false;

        local buttonText = button:WaitForChild("TextLabel") :: TextLabel;

        local radialObj = optionInfo.Radial;
        radialObj.Break = true;
        radialObj.ImageLabel.Visible = true;
        radialObj:UpdateLabel(1);

        local tween: Tween = TweenService:Create(radialObj.ImageLabel, TweenInfo.new(0.2), {
            ImageColor3 = Color3.fromRGB(255, 166, 0);
        });
        TweenService:Create(buttonText, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(255, 166, 0);
        }):Play();
        tween.Completed:Once(function(status)
            TweenService:Create(radialObj.ImageLabel, TweenInfo.new(3), {
                ImageColor3 = binds.Colors.Burnt;
            }):Play();
            TweenService:Create(buttonText, TweenInfo.new(3), {
                TextColor3 = binds.Colors.Burnt;
            }):Play();
        end)
        tween:Play();
    end

    local function animateFlash()
        flashDecal.Size = UDim2.new(0, 0, 0, 0);
        flashDecal.BackgroundTransparency = 0.25;
        flashDecal.Visible = true;
        local tween: Tween = TweenService:Create(flashDecal, TweenInfo.new(0.2), {
            Size = UDim2.new(1.2, 0, 1.2, 0);
            BackgroundTransparency = 0.75;
        });
        tween.Completed:Once(function(status)
            TweenService:Create(flashDecal, TweenInfo.new(0.3), {
                Size = UDim2.new(1.6, 0, 1.6, 0);
                BackgroundTransparency = 1;
            }):Play();
        end)
        tween:Play();
    end

    local function clearItemOffer()
        for _, guiObj in ipairs(itemOfferSlot:GetChildren()) do
            if not guiObj:IsA("GuiObject") then continue end;
            guiObj:Destroy();
        end
        binds.CurPriceLabel = nil;
    end
    local function animateReward(storageItem)
        if storageItem.Values.R == nil then return end;
        local rewardInfo = storageItem.Values.R;
        Debugger:Warn("Reward Info", rewardInfo);

        local itemLib = modItemsLibrary:Find(rewardInfo.ItemId);
        if itemLib == nil then 
            Debugger:Warn("Missing item lib for reward", rewardInfo.ItemId);
            return
        end;

        clearItemOffer();
        itemOfferSlot.Size = UDim2.new(0.1, 0, 0.1, 0);
        itemOfferSlot.Visible = true;

        local offersLeft = storageItem:GetValues("OL") or 0;

        local tween: Tween = TweenService:Create(itemOfferSlot, TweenInfo.new(0.3), {
            Size = UDim2.new(0.5, 0, 0.5, 0);
        });
        tween.Completed:Connect(function()
            local itemButtonObj = modItemInterface.newItemButton(rewardInfo.ItemId);

            itemButtonObj.ImageButton.AnchorPoint = Vector2.new(0.5, 0.5);
            itemButtonObj.ImageButton.Position = UDim2.new(0.5, 0, 0.5, 0);
            itemButtonObj.ImageButton.Size = UDim2.new(1, 0, 1, 0);
            itemButtonObj.ImageButton.Parent = itemOfferSlot;
            itemButtonObj:Update();

            local newGlowImage = modItemInterface.newGlowEffect();
            newGlowImage.Name = "ClaimGlow"
            newGlowImage.ImageColor3 = Color3.fromRGB(255, 255, 255);
            newGlowImage.ImageTransparency = 0.2;
            local raysImage = newGlowImage:WaitForChild("Rays");
            raysImage.Size = UDim2.new(2, 0, 2, 0);
            if rewardInfo.Tier then
                local tC = TierColors[rewardInfo.Tier];
                local th, ts, tv = tC:ToHSV();
                raysImage.ImageColor3 = tC;
                newGlowImage.ImageColor3 = Color3.fromHSV(th, ts*0.5, tv);
            end
            newGlowImage.ImageTransparency = 0.5;
            newGlowImage.Size = UDim2.new(3, 0, 3, 0);
            newGlowImage.Parent = itemOfferSlot;
            modAudio.Play("HaloSpawn", windowFrame);
            
	        TweenService:Create(
                newGlowImage, 
                TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, true), 
                {Size=UDim2.new(3.3, 0, 3.3, 0)}
            ):Play();


            local newPrice = priceFrameTemplate:Clone();
            newPrice.Position = UDim2.new(0.5, 0, 1, 40);
            newPrice.BackgroundTransparency = 1;
            local priceLabel = newPrice:WaitForChild("priceLabel");
            local priceStr = rewardInfo.Price and interface.beautifyNumber(rewardInfo.Price) or "?";
            priceLabel.Text = priceStr == "0" and "Free!" or priceStr;
            binds.CurPriceLabel = {Siid=storageItem.ID, Label=priceLabel};
            
            priceLabel.TextTransparency = 1;
            priceLabel.TextStrokeTransparency = 1;
            local symbolLabel = newPrice:WaitForChild("symbol");
            symbolLabel.ImageTransparency = 1;
            newPrice.Parent = itemOfferSlot;
            newPrice.Visible = true;

            TweenService:Create(newPrice, TweenInfo.new(0.2), {
                Position = UDim2.new(0.5, 0, 1, 20);
                BackgroundTransparency = 0.2;
            }):Play();
            TweenService:Create(priceLabel, TweenInfo.new(0.1), {
                TextTransparency = 0;
                TextStrokeTransparency = 0.9;
            }):Play();
            TweenService:Create(symbolLabel, TweenInfo.new(0.1), {
                ImageTransparency = 0;
            }):Play();

            acceptButtonObjButton.BackgroundTransparency = 1;
            acceptButtonObjButton.TextTransparency = 1;
            acceptButtonObjButton.Visible = true;

            if offersLeft <= 0 then
                denyButtonObjButton.Text = `Deny Final Offer`;
            else
                denyButtonObjButton.Text = `Deny Offer`;
            end
            denyButtonObjButton.BackgroundTransparency = 1;
            denyButtonObjButton.TextTransparency = 1;
            denyButtonObjButton.Visible = true;
            TweenService:Create(acceptButtonObjButton, TweenInfo.new(1), {
                BackgroundTransparency = 0;
                TextTransparency = 0;
            }):Play();
            TweenService:Create(denyButtonObjButton, TweenInfo.new(1), {
                BackgroundTransparency = 0;
                TextTransparency = 0;
            }):Play();

            task.spawn(function()
                local refreshTick = tick();
                local refreshCount = 1;
                while binds.CurPriceLabel and binds.CurPriceLabel.Label.Text == `?` do
                    task.wait(1);
                    if refreshCount >= 5 then break; end;
                    if tick()-refreshTick > (refreshCount^2) then
                        refreshCount += 1;
                        binds.RemoteInvoke("offeringssync", storageItem, storageItem.ID);
                    end
                end
                Debugger:StudioLog(`EndRefresh loop`);
            end)
        end)
        tween:Play();
        modAudio.Play("GrandOpen", windowFrame);
    end

    function binds.RemoteInvoke(action, storageItem, ...)
        local rPacket = remoteShopService:InvokeServer(action, ...);
        if rPacket and rPacket.Success then
            if rPacket.Values then
                for key, value in pairs(rPacket.Values) do
                    storageItem:SetValues(key, value);
                end
            end
        end
        return rPacket;
    end

    function binds.ActivateOffer(storageItem, offerIndex)
        local optionInfo = binds.Options[offerIndex];
        if optionInfo == nil or optionInfo.Activated then return end;
        optionInfo.Activated = true;

        local rPacket = binds.RemoteInvoke("offeringsactivate", storageItem, storageItem.ID, offerIndex);
        if rPacket == nil or rPacket.Fail then
            Debugger:Warn("Failed to activate offering", rPacket);
            return;
        end

        animateOpen(offerIndex);
        animateFlash();
        animateReward(storageItem);
        
        acceptButtonObj.OnHoldDownConfirm = function()
            if storageItem.Values.R == nil or storageItem.Values.R.Price == nil then return end;
            if binds.CurPriceLabel == nil or binds.CurPriceLabel.Label.Text == `?` then
                binds.RemoteInvoke("offeringssync", storageItem, storageItem.ID);
                return;
            end;
            Debugger:Warn(`Accept offer`);
            clearItemOffer();
            denyButtonObjButton.Visible = false;
            acceptButtonObjButton.Visible = false;

            local rPacket = binds.RemoteInvoke("offeringsaccept", storageItem, storageItem.ID);
            if rPacket.Success then
                offeringsWindow:Close();
                modAudio.Play("Purchase",  windowFrame);
                interface:ToggleWindow("Inventory", true);

            else
                Debugger:Warn("Failed to accept offering", rPacket);
                offeringsWindow:Close();
                if rPacket.Fail == 5 then
                    Debugger:Warn("Insufficient gold");
                    interface:ToggleWindow("GoldMenu", true, "GoldPage");

                elseif rPacket.Fail == 6 then
                    Debugger:Warn("Inventory full");
                    interface:ToggleWindow("Inventory", true);

                end
            end
        end
        denyButtonObj.OnHoldDownConfirm = function()
            Debugger:Warn(`Deny offer`);
            clearItemOffer();
            denyButtonObjButton.Visible = false;
            acceptButtonObjButton.Visible = false;
            if storageItem.Values.OL <= 0 then
                offeringsWindow:Close();
            end
            modAudio.Play("ConcreteSmash", windowFrame).PlaybackSpeed = 1.5;
            task.delay(0.15, function()    
                modAudio.Play("FireBallBurst", windowFrame);
            end)
            itemOfferSlot.Visible = false;
            binds.RemoteInvoke("offeringsdeny", storageItem, storageItem.ID);
        end
    end

    local function preload()
        if openSnd == nil then
            modAudio.Preload("HaloSpawn");
            modAudio.Preload("GrandOpen");
            modAudio.Preload("ConcreteSmash");
            modAudio.Preload("FireBallBurst");
            modAudio.Preload("Purchase");
            modAudio.Preload("IntenseWooshImpact", 5);
            openSnd = modAudio.Get("IntenseWooshImpact"):Clone();
            openSnd.Parent = interface.ScreenGui;
        end
    end

    --MARK: OnToggle
    offeringsWindow.OnToggle:Connect(function(visible, storageItem)
        if visible then
            preload();
            interface:HideAll{[offeringsWindow.Name]=true;};

            local itemLib = storageItem.Library;
            titleLabel.Text = `{itemLib.Name}`;
            Debugger:StudioWarn(visible, storageItem);

            acceptButtonObjButton.Visible = false;
            denyButtonObjButton.Visible = false;
            itemOfferSlot.Visible = false;
            
            clearItemOffer();
            
            if binds.LastHookSyncId then
                pcall(function()     
                    modItemInterface.ItemValueSync[binds.LastHookSyncId].offeringPriceUpdate = nil;
                end)
            end
            modItemInterface.HookValueSync(storageItem.ID, "offeringPriceUpdate", function(storageItem, funcKey)
                if interface.IsDestroyed then return end;
                if binds.CurPriceLabel == nil or binds.CurPriceLabel.Siid ~= storageItem.ID then return end;
                if storageItem.Values.R == nil or storageItem.Values.R.Price == nil then return end;
                local priceStr = interface.beautifyNumber(storageItem.Values.R.Price);
                binds.CurPriceLabel.Label.Text = priceStr == "0" and "Free!" or priceStr;
            end)
            binds.LastHookSyncId = storageItem.ID;

            bkgroundItem.Image = itemLib.Icon;
            table.clear(binds.Colors);

            local libColor = itemLib.FrameColor;
            local libColorH, libColorS, _libColorV = libColor:ToHSV();
            binds.Colors.Base = libColor;
            binds.Colors.Ground = Color3.fromHSV(libColorH, libColorS, 80/255);
            binds.Colors.Bright = Color3.fromHSV(libColorH, libColorS, 100/255);
            binds.Colors.Burnt = Color3.fromHSV(libColorH, libColorS, 30/255);

            mainFrame.BackgroundColor3 = binds.Colors.Burnt;
            mainFrame.UIStroke.Color = binds.Colors.Burnt;
            flashDecal.BackgroundColor3 = binds.Colors.Base;
            itemOfferSlot.BackgroundColor3 = binds.Colors.Bright;
            itemOfferSlot.UIStroke.Color = binds.Colors.Base;

            pivotOptions:ClearAllChildren();
            table.clear(binds.Options);

            local itemValues = storageItem.Values;

            local offerCount = itemValues.O;
            if offerCount == nil then
                Debugger:Warn(`Offering not properly initialized`);
                offeringsWindow:Close();
                return;
            end

            local sigils = itemLib.SigilType or "Default";
            local sigilChars = interfacePackage.SigilChars[sigils] or interfacePackage.SigilChars.Default;

            local r = 360/offerCount;
            local activeButtonIndex = 0;
            for a=1, offerCount do
                local newOptionSwivel: Frame = swivelTemplate:Clone();
                newOptionSwivel.Parent = pivotOptions;

                newOptionSwivel.Rotation = (a-1) * r;

                local slot: Frame = newOptionSwivel:WaitForChild("Slot") :: Frame;
                slot.Rotation = -newOptionSwivel.Rotation;

                local button: TextButton = slot:WaitForChild("TextButton") :: TextButton;
                button.BackgroundColor3 = binds.Colors.Ground;
                local buttonText = button:WaitForChild("TextLabel") :: TextLabel;
                buttonText.TextColor3 = binds.Colors.Base;
                buttonText.Text = `{sigilChars[a]}`;

                local progressRadialBar = button:WaitForChild("processBar") :: ImageLabel;
                progressRadialBar.ImageColor3 = binds.Colors.Base;
                local radialObj = modRadialImage.new(buttonRadialConfig, progressRadialBar);
                radialObj:UpdateLabel(0);
                progressRadialBar.Visible = true;

                button.MouseButton1Down:Connect(function()
                    if activeButtonIndex ~= 0 then return end
                    activeButtonIndex = a;

                    task.spawn(function()
                        while activeButtonIndex ~= 0 do
                            task.wait();
                            if radialObj.Alpha >= 0.65 and openSnd.IsPlaying ~= true then
                                openSnd:Play();
                            end
                            if radialObj.Alpha >= 1 then
                                radialObj.Break = true;
                                binds.ActivateOffer(storageItem, a);
                                break;
                            end
                            if not interface.Properties.PrimaryInputDown or not modUIUtil.IsMouseOver(button) then
                                if radialObj.Break ~= true then
                                    openSnd:Stop();
                                end
                                activeButtonIndex = 0;
                                break;
                            end
                        end
                        activeButtonIndex = 0;
                    end)
                end)
                task.spawn(function()
                    local alpha = 0;
                    while button.Parent do
                        local d = task.wait();
                        if radialObj.Break then break; end;
                        if button.Parent == nil then return end;

                        if itemOfferSlot.Visible then
                            button.AutoButtonColor = false;
                            button.Interactable = false;
                            continue;
                        end
                        button.AutoButtonColor = true;
                        button.Interactable = true;

                        if activeButtonIndex == a then
                            alpha += d;
                        else
                            alpha -= d;
                        end
                        alpha = math.clamp(alpha, 0, 1);
                        radialObj:UpdateLabel(alpha);
                    end
                end)

                binds.Options[a] = {
                    Button = button;
                    Radial = radialObj;
                };
            end

            if itemValues.OO then
                for _, oi in ipairs(itemValues.OO) do
                    animateOpen(oi);
                end
            end
            if itemValues.R then
                openSnd:Play();
                animateFlash();
                animateReward(storageItem);
            end

        else
            pivotOptions:ClearAllChildren();
            table.clear(binds.Options);

        end
    end)



    --MARK: TradeUp
	local tradeUpWindowFrame = script:WaitForChild("OfferingsWindow"):Clone();
    tradeUpWindowFrame.Name = `TradeUpWindow`;
	tradeUpWindowFrame.Parent = interface.ScreenGui;
    
    local tradeUpFrame = tradeUpWindowFrame:WaitForChild("Frame");
    local tradeUpStroke = tradeUpFrame:WaitForChild("UIStroke");

    local tradeUpPivotOptions = tradeUpFrame:WaitForChild("OptionsPivot");
    local tradeUpFlashDecal = tradeUpFrame:WaitForChild("Flash");
    local tradeUpBkgroundItem = tradeUpFrame:WaitForChild("BackgroundItem");
    tradeUpBkgroundItem.Visible = false;
    local tradeUpInfoFrame = tradeUpFrame:WaitForChild("TradeUpInfo");
    tradeUpInfoFrame.Visible = true;
    local tradeUpGlowContainer = tradeUpInfoFrame:WaitForChild("GlowContainer");
    local tradeUpCounterLabel = tradeUpInfoFrame:WaitForChild("TradeUpCounter");
    local descLabel = tradeUpInfoFrame:WaitForChild("Desc");
    local tradeUpItemOfferSlot = tradeUpFrame:WaitForChild("ItemOfferSlot");
    tradeUpItemOfferSlot.Visible = false;
    local tradeUpTitleLabel = tradeUpFrame:WaitForChild("TitleFrame"):WaitForChild("Title");
    
	local tradeUpWindow: InterfaceWindow = interface:NewWindow("SkinTradeUp", tradeUpWindowFrame);
    tradeUpWindow.BoolStringWhenActive = {String="!CharacterHud"; Priority=2;};
	tradeUpWindow.CompactFullscreen = true;
    tradeUpWindow.CloseWithInteract = true;
    tradeUpWindow.DisableInteractables = true;
	tradeUpWindow:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0), UDim2.new(0.5, 0, 0.5, 0));

    tradeUpFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
        interface:PlayButtonClick();
        tradeUpWindow:Close();
    end)

    local lockInButton = tradeUpInfoFrame:WaitForChild("LockInButton");
    local lockInStroke = lockInButton:WaitForChild("UIStroke");

    --MARK: OnToggle
    binds.TradeUpList = {};
    binds.TradeUpTier = 1;

    binds.TradeUpPacket = nil;

    local optionButtonsList = {};
    local lockInAlpha = 0;
    local lockInLoop = false;

    function binds.SubmitTradeUp()
        local tradeUpPacket = binds.TradeUpPacket;
        local tradeUpTier = binds.TradeUpTier;
        binds.TradeUpPacket = nil;

        task.spawn(function()
            local rPacket = remoteShopService:InvokeServer("skintradeup", tradeUpPacket);
            if rPacket == 5 then return end;

            if rPacket and rPacket.Success then
                local outputItemId = rPacket.OutputItemId;
                if tradeUpWindow.Visible == false then return end;

                local itemButtonObj = modItemInterface.newItemButton(outputItemId);
                local itemImgButton = itemButtonObj.ImageButton;
                itemImgButton.Name = "OutputItem";
                itemImgButton.AnchorPoint = Vector2.new(0.5, 0.5);
                itemImgButton.Position = UDim2.new(0.5, 0, 0.5, 0);
                itemImgButton.Size = UDim2.new(0.8, 0, 0.8, 0);
                local uiAspect = Instance.new("UIAspectRatioConstraint");
                uiAspect.Parent = itemImgButton;

                tradeUpGlowContainer:ClearAllChildren();
                local newGlowImage = modItemInterface.newGlowEffect();
                newGlowImage.Name = "ClaimGlow"
                newGlowImage.ImageColor3 = Color3.fromRGB(255, 255, 255);
                newGlowImage.ImageTransparency = 0.2;
                local raysImage = newGlowImage:WaitForChild("Rays");
                raysImage.Size = UDim2.new(2, 0, 2, 0);
                if tradeUpTier then
                    local tC = TierColors[tradeUpTier+1] or Color3.fromRGB(0, 255, 0);
                    local th, ts, tv = tC:ToHSV();
                    raysImage.ImageColor3 = tC;
                    newGlowImage.ImageColor3 = Color3.fromHSV(th, ts*0.5, tv);
                end
                newGlowImage.ImageTransparency = 0.5;
                newGlowImage.Size = UDim2.new(3, 0, 3, 0);
                newGlowImage.Parent = tradeUpGlowContainer;
                modAudio.Play("HaloSpawn", windowFrame);
                
                TweenService:Create(
                    newGlowImage, 
                    TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, true), 
                    {Size=UDim2.new(3.3, 0, 3.3, 0)}
                ):Play();

                for _, button in pairs(optionButtonsList) do
                    button:WaitForChild("ItemIcon").ImageColor3 = Color3.fromRGB(150, 150, 150);
                end

                itemImgButton.MouseButton1Click:Connect(function()
                    table.clear(binds.TradeUpList);
                    binds.TradeUpPacket = nil;

                    itemImgButton:Destroy();
                    newGlowImage:Destroy();

                    binds.TradeUpTier = nil;

                    local invStorageInterface = modStorageInterface.getByName("DefaultInterface");
                    if invStorageInterface then
                        invStorageInterface:Update();
                    end
                    local premStorageInterface = modStorageInterface.getByName("PremiumInterface");
                    if premStorageInterface then
                        premStorageInterface:Update();
                    end

                    binds.RefreshTradeUpScreen();
                end)

                itemImgButton.Parent = tradeUpInfoFrame;
                itemButtonObj:Update();
            end
        end)
    end

    lockInButton.MouseButton1Down:Connect(function()
        interface:PlayButtonClick();

        if lockInLoop == false then
            lockInLoop = true;

            task.spawn(function()
                while lockInButton.Parent do
                    local d = task.wait();
                    if lockInButton.Parent == nil then return end;

                    if interface.Properties.PrimaryInputDown == false then
                        lockInAlpha -= d;
                    end

                    lockInAlpha = math.clamp(lockInAlpha, 0, 1);
                    
                    lockInStroke.Thickness = math.clamp((1-lockInAlpha) * 0.5, 0, 0.5);
                end
            end)
        end
        
        task.spawn(function()
            while lockInButton.Visible do
                local d = task.wait();

                lockInAlpha += d*2;

                if lockInAlpha >= 0.65 and openSnd.IsPlaying ~= true then
                    openSnd:Play();
                end
                if lockInAlpha >= 1 then
                    lockInButton.Visible = false;
                    
                    binds.TradeUpPacket = {
                        Ids = binds.TradeUpList;
                    };

                    --MARK: Trade Up Animation
                    local preFire = false;
                    task.spawn(function()
                        local radialObjsList = {};

                        for _, button in pairs(optionButtonsList) do
                            button.AutoButtonColor = false;

                            local progressRadialBar = button:WaitForChild("processBar") :: ImageLabel;
                            local radialObj = modRadialImage.new(buttonRadialConfig, progressRadialBar);
                            radialObj:UpdateLabel(0);
                            progressRadialBar.Visible = true;

                            table.insert(radialObjsList, radialObj);
                        end

                        for a=0, 1, 1/60 do
                            task.wait();

                            local alpha = TweenService:GetValue(a, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
                            for b=1, #radialObjsList do
                                local rObj = radialObjsList[b];
                                rObj:UpdateLabel(alpha);
                            end
                            if tradeUpWindow.Visible == false then break; end;

                            if a > 0.75 and preFire ~= true then
                                preFire = true;

                                modAudio.Play("FireBallBurst", windowFrame);
                                binds.SubmitTradeUp();
                            end
                        end
                    end)

                    if not preFire then
                        task.wait(0.89);
                        binds.SubmitTradeUp();
                    end

                    break;
                end
                if not interface.Properties.PrimaryInputDown or not modUIUtil.IsMouseOver(lockInButton) then
                    openSnd:Stop();
                    break;
                end

            end
        end)
    end)


    function binds.AddToTradeUp(siid)
        if #binds.TradeUpList >= 5 then return end;

        local storageItem = modData.GetItemById(siid);
        if storageItem == nil then
            Debugger:Warn(`Attempt to add non-existent item`, siid);
            return;
        end

        local collectionRewardId = storageItem.Library.CollectionRewardId;
        if collectionRewardId == nil then
            Debugger:Warn(`Attempt to add non-tradeup-able.`, siid);
            return;
        end

        local rewardLib = modRewardsLibrary:Find(collectionRewardId);
        if rewardLib == nil then
            Debugger:Warn(`Missing reward lib`);
            return;
        end

        local firstTier = binds.TradeUpList[1];
        if firstTier == nil then
            binds.TradeUpTier = nil;
        end

        local tierInCollection = storageItem.Library.CollectionTier;
        if binds.TradeUpTier and tierInCollection ~= binds.TradeUpTier then
            Debugger:Warn(`Tier mismatch`, siid);
            shared.Notify(localPlayer, "You can only add matching skin tiers to the upgrade.", "Negative");
            return;
        end
        if tierInCollection >= rewardLib.MaxCollectionTier then
            shared.Notify(localPlayer, `{storageItem.Library.Name} is already max tier.`, "Negative");
            return;
        end

        binds.TradeUpTier = tierInCollection;


        local maxQty = storageItem.Quantity;
        local countExist = 0;
        for a=1, #binds.TradeUpList do
            if binds.TradeUpList[a] == siid then
                countExist += 1;
            end
        end
        if countExist >= maxQty then
            Debugger:StudioWarn(`Attempt to add more {siid}`);
            return;
        end

        tradeUpGlowContainer:ClearAllChildren();
        table.insert(binds.TradeUpList, siid);


        local invStorageInterface = modStorageInterface.getByName("DefaultInterface");
        if invStorageInterface then
            invStorageInterface:Update();
        end
        local premStorageInterface = modStorageInterface.getByName("PremiumInterface");
        if premStorageInterface then
            premStorageInterface:Update();
        end

        Debugger:Warn(`Add to trade:`, siid);
    end

    local function updateBind(storageInterface)
        for id, buttonTable in pairs(storageInterface.Buttons) do
            local itemLib = buttonTable.Item.Library;
            
            local isValid = false;
            if itemLib.CollectionRewardId
            and (binds.TradeUpTier == nil or itemLib.CollectionTier == binds.TradeUpTier) then
                local rewardLib = modRewardsLibrary:Find(itemLib.CollectionRewardId);
                if rewardLib and itemLib.CollectionTier < rewardLib.MaxCollectionTier then
                    isValid = true;
                end
            end

            buttonTable.ItemButtonObject.DimOut = not isValid;
            buttonTable.ItemButtonObject:Update(buttonTable.Item);
        end
    end

    local function bindItemClick(_, slot)
        interface:PlayButtonClick();

        local slotId = (slot and slot.ID or 0);
        if slot.ItemButtonObject.DimOut ~= true then
            binds.AddToTradeUp(slotId);
            binds.RefreshTradeUpScreen();
        end
    end

    function binds.BindInvUpdateReact()
        local invStorageInterface = modStorageInterface.getByName("DefaultInterface");
        if invStorageInterface then
            invStorageInterface:HookUpdateBind(updateBind);
            invStorageInterface:Update();
        end

        local premStorageInterface = modStorageInterface.getByName("PremiumInterface");
        if premStorageInterface then
            premStorageInterface:HookUpdateBind(updateBind);
            premStorageInterface:Update();
        end

        local clothingStorageInterface = modStorageInterface.getByName("ClothingInterface");
        if clothingStorageInterface then
            clothingStorageInterface:HookUpdateBind(updateBind);
            clothingStorageInterface:Update();
        end
        
        for a=1, #interface.StorageInterfaces do
            local storageInterface: StorageInterface? = interface.StorageInterfaces[a];
            if storageInterface == nil or storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
                continue;
            end
            storageInterface.OnItemButton1Click = bindItemClick;
        end
    end

    function binds.UnbindInvUpdateReact()
        local invStorageInterface = modStorageInterface.getByName("DefaultInterface");
        if invStorageInterface then
            invStorageInterface:UnhookUpdateBind(updateBind);
            invStorageInterface:Update();
        end

        local premStorageInterface = modStorageInterface.getByName("PremiumInterface");
        if premStorageInterface then
            premStorageInterface:UnhookUpdateBind(updateBind);
            premStorageInterface:Update();
        end

        local clothingStorageInterface = modStorageInterface.getByName("ClothingInterface");
        if clothingStorageInterface then
            clothingStorageInterface:UnhookUpdateBind(updateBind);
            clothingStorageInterface:Update();
        end
        
        for a=#interface.StorageInterfaces, 1, -1 do
            local storageInterface: StorageInterface = interface.StorageInterfaces[a];
            if storageInterface == nil then continue end;
            if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
                continue;
            end
            storageInterface.OnItemButton1Click = storageInterface.BeginDragItem;

            for id, buttonTable in pairs(storageInterface.Buttons) do
                local itemLib = buttonTable.Item.Library;
                
                buttonTable.ItemButtonObject.DimOut = false;
                buttonTable.ItemButtonObject:Update(buttonTable.Item);
            end

        end
    end

    function binds.RefreshTradeUpScreen()
        tradeUpPivotOptions:ClearAllChildren();
        table.clear(optionButtonsList);

        for _, obj in pairs(tradeUpInfoFrame:GetChildren()) do
            if obj.Name ~= "OutputItem" then continue end;
            obj:Destroy();
        end

        
        local tradeUpTier = binds.TradeUpTier or 1;
        
        local tierColor = modItemsLibrary.TierColors[tradeUpTier];
        local tcH, tcS, tcV = tierColor:ToHSV();

        tradeUpStroke.Color = Color3.fromHSV(tcH, tcS, 20/255);
        tradeUpFrame.BackgroundColor3 = tradeUpStroke.Color;

        local startRot = 180;
        for a=#binds.TradeUpList, 1, -1 do
            local siid = binds.TradeUpList[a];

            local newOption = swivelTemplate:Clone();
            newOption.LayoutOrder = a;
            newOption.Rotation = startRot + (a * 72);
            newOption.Size = UDim2.new(0, 10, 1, 40);
            
            local storageItem = modData.GetItemById(siid);
            if storageItem == nil or storageItem.Quantity <= 0 then
                table.remove(binds.TradeUpList, a);
                continue;
            end

            local slotFrame = newOption:WaitForChild("Slot");
            slotFrame.Rotation = -newOption.Rotation;
            local button = slotFrame:WaitForChild("TextButton");
            table.insert(optionButtonsList, button);

            local itemLib = storageItem.Library;
            local itemIcon = button:WaitForChild("ItemIcon");
            itemIcon.Image = itemLib.Icon;
            itemIcon.Visible = true;

            newOption.Parent = tradeUpPivotOptions;
            button.MouseButton1Click:Connect(function()
                if binds.TradeUpPacket then return end;

                interface:PlayButtonClick();

                for a=#binds.TradeUpList, 1, -1 do
                    if binds.TradeUpList[a] == siid then
                        table.remove(binds.TradeUpList, a);
                        break;
                    end
                end

                if #binds.TradeUpList <= 0 then
                    binds.TradeUpTier = nil;

                    local invStorageInterface = modStorageInterface.getByName("DefaultInterface");
                    if invStorageInterface then
                        invStorageInterface:Update();
                    end
                    local premStorageInterface = modStorageInterface.getByName("PremiumInterface");
                    if premStorageInterface then
                        premStorageInterface:Update();
                    end
                end

                Debugger:StudioWarn(`binds.TradeUpList`, binds.TradeUpList);
                binds.RefreshTradeUpScreen();
            end)

            button.BackgroundColor3 = Color3.fromHSV(tcH, tcS, 50/255);
            button:WaitForChild("processBar").ImageColor3 = Color3.fromHSV(tcH, tcS, 0.5);
        end

        if #binds.TradeUpList < 5 then
            local addButtonFrame = swivelTemplate:Clone();
            addButtonFrame.Name = `AddToTradeUp`;
            addButtonFrame.LayoutOrder = 0;
            addButtonFrame.Rotation = 180;
            addButtonFrame.Size = UDim2.new(0, 10, 1, 40);
            addButtonFrame.Parent = tradeUpPivotOptions;

            local slotFrame = addButtonFrame:WaitForChild("Slot");
            slotFrame.Rotation = -180;
            local button = addButtonFrame:WaitForChild("Slot"):WaitForChild("TextButton");

            button.MouseButton1Click:Connect(function()
                interface:PlayButtonClick();
                interface:ToggleWindow("Inventory", true);

                binds.BindInvUpdateReact();

                Debugger:StudioWarn(`binds.TradeUpList`, binds.TradeUpList);
                binds.RefreshTradeUpScreen();
            end)

            button.BackgroundColor3 = Color3.fromHSV(tcH, tcS, 50/255);

            local addPlusDecor = button:WaitForChild("AddPlus");
            addPlusDecor.Visible = true;
            addPlusDecor.BackgroundColor3 = Color3.fromHSV(tcH, tcS, 20/255);
            addPlusDecor:WaitForChild("Frame").BackgroundColor3 = Color3.fromHSV(tcH, tcS, 20/255);
        end
        
        tradeUpCounterLabel.Visible = #binds.TradeUpList < 5;
        tradeUpCounterLabel.Text = `{#binds.TradeUpList}/5`;
        descLabel.Visible = #binds.TradeUpList < 5;

        lockInButton.BackgroundColor3 = Color3.fromHSV(tcH, tcS, 20/255);
        lockInButton:WaitForChild("UIStroke").Color = Color3.fromHSV(tcH, tcS, 100/255);
        lockInButton.Visible = #binds.TradeUpList >= 5;
    end
 
    tradeUpWindow.OnToggle:Connect(function(visible, storageItem)
        if visible then
            preload();

            if storageItem then
                binds.AddToTradeUp(storageItem.ID);
                binds.BindInvUpdateReact();
            end
            binds.RefreshTradeUpScreen();

        else
            tradeUpGlowContainer:ClearAllChildren();
            tradeUpPivotOptions:ClearAllChildren();
            binds.UnbindInvUpdateReact();

        end
    end)




    modAudio.Preload("IntenseWooshImpact");
end

return interfacePackage;

