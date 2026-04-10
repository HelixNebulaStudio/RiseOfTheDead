local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryRotd);
local modComponents = shared.require(game.ReplicatedStorage.Library.UI.Components);
local modRadialImage = shared.require(game.ReplicatedStorage.Library.UI.RadialImage);
local modUIUtil = shared.require(game.ReplicatedStorage.Library.UI.UIUtil);
local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);

local buttonRadialConfig = '{"version":1,"size":128,"count":256,"columns":8,"rows":8,"images":["rbxassetid://4744240077", "rbxassetid://4744242814", "rbxassetid://4744244749", "rbxassetid://4744244960"]}';

local interfacePackage = {
    Type = "Character";

    SigilChars = {
        Greek = {"Δ"; "Ψ"; "Θ"; "Ω"; "Φ"; "Σ"; "β"; "Π";};
    };
};
interfacePackage.SigilChars.Default = interfacePackage.SigilChars.Greek;
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
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

	local window: InterfaceWindow = interface:NewWindow("OfferingsWindow", windowFrame);
    window.BoolStringWhenActive = {String="!CharacterHud"; Priority=2;};
	window.CompactFullscreen = true;
    window.CloseWithInteract = true;
    window.DisableInteractables = true;
	window:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0), UDim2.new(0.5, 0, 0.5, 0));

    mainFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
        interface:PlayButtonClick();
        window:Close();
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

    local binds = window.Binds;
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
                local TierColors = {
                    Color3.fromRGB(255, 255, 255);
                    Color3.fromRGB(0, 145, 255);
                    Color3.fromRGB(85, 0, 255);
                    Color3.fromRGB(212, 0, 255);
                    Color3.fromRGB(255, 0, 0);
                    Color3.fromRGB(255, 170, 0);
                };
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
            priceLabel.Text = rewardInfo.Price and interface.beautifyNumber(rewardInfo.Price) or "?";
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
                window:Close();
                modAudio.Play("Purchase",  windowFrame);
                interface:ToggleWindow("Inventory", true);

            else
                Debugger:Warn("Failed to accept offering", rPacket);
                window:Close();
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
                window:Close();
            end
            modAudio.Play("ConcreteSmash", windowFrame).PlaybackSpeed = 1.5;
            task.delay(0.15, function()    
                modAudio.Play("FireBallBurst", windowFrame);
            end)
            itemOfferSlot.Visible = false;
            binds.RemoteInvoke("offeringsdeny", storageItem, storageItem.ID);
        end
    end


    --MARK: OnToggle
    window.OnToggle:Connect(function(visible, storageItem)
        if visible then
            if openSnd == nil then
                modAudio.Preload("HaloSpawn");
                modAudio.Preload("GrandOpen");
                modAudio.Preload("ConcreteSmash");
                modAudio.Preload("FireBallBurst");
                modAudio.Preload("Purchase");
                modAudio.Preload("IntenseWooshImpact", 5);
                openSnd = modAudio.Get("IntenseWooshImpact"):Clone();
                openSnd.Parent = windowFrame;
            end
            interface:HideAll{[window.Name]=true;};

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
                binds.CurPriceLabel.Label.Text = interface.beautifyNumber(storageItem.Values.R.Price);
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
                window:Close();
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

    modAudio.Preload("IntenseWooshImpact");
end

return interfacePackage;

