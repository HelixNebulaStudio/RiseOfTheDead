local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local MarketplaceService = game:GetService("MarketplaceService");

local localPlayer = game.Players.LocalPlayer;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modStrings = shared.require(game.ReplicatedStorage.Library.Util.Strings);
local modComponents = shared.require(game.ReplicatedStorage.Library.UI.Components);

local TEMPLATE_DECALS = {
    {Title="Poster"; ImageId="9242720986"};
    {Title="MrPigZ's meme"; ImageId="9242497901"};
    {Title="WaySide Ad"; ImageId="11347301232"};
    {Title="FissionBay Ad"; ImageId="12475719198"};
    {Title="RoofTops Ad"; ImageId="12475719198"};
    {Title="FBI Plushie Ad"; ImageId="15326098335"};
};
local savedDecals = {};

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local remoteSetPoster = modRemotesManager:Get("SetPoster");

    local templateListingButton = script:WaitForChild("listedButton");

	local windowFrame = script:WaitForChild("PosterWindow"):Clone();
	windowFrame.Parent = interface.ScreenGui;

	local leftFrame = windowFrame:WaitForChild("LeftFrame");
	local inputBox = leftFrame:WaitForChild("InputFrame"):WaitForChild("TextBox");
	local decalLabel = leftFrame:WaitForChild("TestDecal");
	local rightScrollFrame = windowFrame:WaitForChild("RightScrollFrame");

	local window: InterfaceWindow = interface:NewWindow("PosterWindow", windowFrame);
    window.CloseWithInteract = true;
    window.DisableInteractables = true;

	window:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0), UDim2.new(0.5, 0, 0.5, 0));

    local binds = window.Binds;
    binds.Interactable = nil;

	windowFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		window:Close();
	end)

    --MARK: OnToggle
	window.OnToggle:Connect(function(visible, packet)
        if packet then
            if packet.Interactable then
                binds.Interactable = packet.Interactable;
            end
        end

		if visible then
			interface:HideAll{[window.Name]=true;};
            
			binds.reloadHistory();
		else
            
		end
	end)

	local savedListingButtons = {};

	function binds.reloadHistory()
		task.spawn(function()
			local rPacket = remoteSetPoster:InvokeServer("fetchhistory");

			table.clear(savedDecals);
			if rPacket and rPacket.List then
				for a=1, #rPacket.List do
					local item = rPacket.List[a];

					local productInfo = {} :: any;
					pcall(function()
						productInfo = MarketplaceService:GetProductInfo(item.ImageId, Enum.InfoType.Asset);
					end)

					table.insert(savedDecals, {Title=modStrings.FilterNonBasicUtf8(productInfo.Name:sub(1, 20)); ImageId=item.ImageId;});
				end
			end

			for _, obj in pairs(savedListingButtons) do
				if obj and obj.Parent then
					game.Debris:AddItem(obj, 0);
				end
			end
			table.clear(savedListingButtons);

			for a=1, #savedDecals do
				local decalEntry = savedDecals[a];

				local isTemplate = false;
				for b=1, #TEMPLATE_DECALS do
					if TEMPLATE_DECALS[b].ImageId == decalEntry.ImageId then
						isTemplate = true;
						break;
					end
				end
				if isTemplate then continue end;

				local new = templateListingButton:Clone();
				new.Name = decalEntry.ImageId;
				new.Text = (decalEntry.Title or "").." (".. decalEntry.ImageId ..")";

				new.MouseMoved:Connect(function()
					decalLabel.Image = "rbxassetid://".. decalEntry.ImageId;
				end)
				new.MouseButton1Click:Connect(function()
	                   if binds.Interactable == nil then return end;
	                   
	                   interface:PlayButtonClick();
	                   local _rPacket = remoteSetPoster:InvokeServer("set", {
	                       Poster = binds.Interactable.Part.Parent;
	                       DecalId = decalEntry.ImageId;
	                   });
	                   binds.reloadHistory();
				end)

				local removeHoldDownObj = modComponents.CreateHoldDownButton(interface, {
					Text="";
				});
				local removeHoldButton = removeHoldDownObj.Button;
				removeHoldButton.AnchorPoint = Vector2.new(1, 0);
				removeHoldButton.BackgroundColor3 = Color3.fromRGB(120, 57, 57);
				removeHoldButton.Position = UDim2.new(1, -5, 0, 5);
				removeHoldButton.Size = UDim2.new(0, 15, 0, 15);
				removeHoldButton.Parent = new;

				removeHoldDownObj.OnHoldDownConfirm = function()
					local _removePacket = remoteSetPoster:InvokeServer("remove", {
						DecalId = decalEntry.ImageId;
					});

					if _removePacket and _removePacket.Success then
						binds.reloadHistory();
					end
				end;

				new.LayoutOrder = #TEMPLATE_DECALS + 10 + a;

				new.Parent = rightScrollFrame;

				table.insert(savedListingButtons, new);
			end
		end)
	end
	
	leftFrame:WaitForChild("playButton").MouseButton1Click:Connect(function()
        if binds.Interactable == nil then return end;

        interface:PlayButtonClick();
        local _rPacket = remoteSetPoster:InvokeServer("set", {
            Poster = binds.Interactable.Part.Parent;
            DecalId = inputBox.Text;
        });
        binds.reloadHistory();

	end)

	local lastChange = tick();
	interface.Garbage:Tag(inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		lastChange = tick();

		local text = inputBox.Text;
		if #text < 5 then return end;

        task.delay(1, function()
            if tick()-lastChange < 0.9 then return end;

            decalLabel.Image = "";
            local rPacket = {Success=true;};
            if rPacket and rPacket.Success then
                local decalId = inputBox.Text
                decalLabel.Image = "rbxassetid://"..decalId;
                
            else
                decalLabel.Image = "rbxassetid://9242720986";
                
            end
        end)
	end));

	for a=1, #TEMPLATE_DECALS do
		if rightScrollFrame:FindFirstChild(TEMPLATE_DECALS[a].ImageId) then continue end;

		local new = templateListingButton:Clone();
		new.Name = TEMPLATE_DECALS[a].ImageId;
		new.LayoutOrder = a;
		new.Text = TEMPLATE_DECALS[a].Title.." (".. TEMPLATE_DECALS[a].ImageId ..")";
		
		new.MouseMoved:Connect(function()
			decalLabel.Image = "rbxassetid://".. TEMPLATE_DECALS[a].ImageId;
		end)
		new.MouseButton1Click:Connect(function()
            if binds.Interactable == nil then return end;
        
            interface:PlayButtonClick();
            local _rPacket = remoteSetPoster:InvokeServer("set", {
                Poster = binds.Interactable.Part.Parent;
                DecalId = TEMPLATE_DECALS[a].ImageId;
            });
            binds.reloadHistory();
		end)
		
		new.Parent = rightScrollFrame;
	end

end

return interfacePackage;

