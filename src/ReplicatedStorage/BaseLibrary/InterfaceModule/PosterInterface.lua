local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");
local MarketplaceService = game:GetService("MarketplaceService");

local localPlayer = game.Players.LocalPlayer;
local modData = require(localPlayer:WaitForChild("DataModule"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modPlayers = require(game.ReplicatedStorage.Library.Players);

local remotes = game.ReplicatedStorage.Remotes;
local remoteSetPoster = modRemotesManager:Get("SetPoster");
	
local windowFrameTemplate = script:WaitForChild("PosterWindow");
local templateListingButton = script:WaitForChild("listedButton");

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;

	windowFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("PosterWindow");
	end)
	
	local templateDecals = {
		{Title="Poster"; ImageId="9242720986"};
		{Title="MrPigZ's meme"; ImageId="9242497901"};
		{Title="WaySide Ad"; ImageId="11347301232"};
		{Title="FissionBay Ad"; ImageId="12475719198"};
		{Title="RoofTops Ad"; ImageId="12475719198"};
		{Title="FBI Plushie Ad"; ImageId="15326098335"};
	};
	local savedDecals = {};

	local leftFrame = windowFrame:WaitForChild("LeftFrame");

	local inputBox = leftFrame:WaitForChild("InputFrame"):WaitForChild("TextBox");
	local decalLabel = leftFrame:WaitForChild("TestDecal");

	local rightScrollFrame = windowFrame:WaitForChild("RightScrollFrame");
	
	local window = Interface.NewWindow("PosterWindow", windowFrame);
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	window:AddCloseButton(windowFrame);
	
	local function reloadHistory()
		task.spawn(function()
			local rPacket = remoteSetPoster:InvokeServer("fetchhistory");
			if rPacket and rPacket.List then
				for a=1, #rPacket.List do
					local item = rPacket.List[a];

					local productInfo = {} :: any;
					pcall(function()
						productInfo = MarketplaceService:GetProductInfo(item.ImageId, Enum.InfoType.Asset);
					end)

					table.insert(savedDecals, {Title=productInfo.Name; ImageId=item.ImageId;});
				end
			end

			for _, obj in pairs(rightScrollFrame:GetChildren()) do
				if obj.Name == "new" then
					game.Debris:AddItem(obj, 0);
				end
			end

			for a=1, #savedDecals do
				if rightScrollFrame:FindFirstChild(savedDecals[a].ImageId) then continue end;
				
				local new = templateListingButton:Clone();
				new.Name = savedDecals[a].ImageId;
				new.Text = (savedDecals[a].Title or "").." (".. savedDecals[a].ImageId ..")";

				new.MouseMoved:Connect(function()
					decalLabel.Image = "rbxassetid://".. savedDecals[a].ImageId;
				end)
				new.MouseButton1Click:Connect(function()
					if Interface.Object then
						Interface:PlayButtonClick();
						local rPacket = remoteSetPoster:InvokeServer("set", {Poster=Interface.Object.Parent; DecalId=savedDecals[a].ImageId;});
						reloadHistory();
					end
				end)
				
				new.LayoutOrder = #templateDecals + 10 + a;

				new.Parent = rightScrollFrame;
			end
		end)
	end
	
	window.OnWindowToggle:Connect(function(visible, toolHandler)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			Interface:ToggleInteraction(false);
			reloadHistory();
			spawn(function()
				repeat until not window.Visible or Interface.Object == nil or not Interface.Object:IsDescendantOf(workspace) or Interface.modCharacter.Player:DistanceFromCharacter(Interface.Object.Position) >= 16 or not wait(0.5);
				Interface:ToggleWindow("PosterWindow", false);
			end)
		else
			task.delay(0.3, function()
				Interface:ToggleInteraction(true);
			end)
		end
	end)

	leftFrame:WaitForChild("playButton").MouseButton1Click:Connect(function()
		if Interface.Object then
			Interface:PlayButtonClick();
			local rPacket = remoteSetPoster:InvokeServer("set", {Poster=Interface.Object.Parent; DecalId=inputBox.Text;});
			reloadHistory();
		end
	end)

	local lastChange = tick();
	Interface.Garbage:Tag(inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		lastChange = tick();
		local text = inputBox.Text;

		if #text >= 5 then
			task.delay(1, function()
				if tick()-lastChange >= 0.9 then
					decalLabel.Image = "";
					local rPacket = {Success=true;} --remoteSetPoster:InvokeServer("test", {Poster=Interface.Object; DecalId=inputBox.Text;});
					if rPacket and rPacket.Success then
						local decalId = inputBox.Text
						decalLabel.Image = "rbxassetid://"..decalId;
						
					else
						decalLabel.Image = "rbxassetid://9242720986";
						
					end

				end
			end)
		end
	end));

	for a=1, #templateDecals do
		if rightScrollFrame:FindFirstChild(templateDecals[a].ImageId) then continue end;

		local new = templateListingButton:Clone();
		new.Name = templateDecals[a].ImageId;
		new.LayoutOrder = a;
		new.Text = templateDecals[a].Title.." (".. templateDecals[a].ImageId ..")";
		
		new.MouseMoved:Connect(function()
			decalLabel.Image = "rbxassetid://".. templateDecals[a].ImageId;
		end)
		new.MouseButton1Click:Connect(function()
			if Interface.Object then
				Interface:PlayButtonClick();
				local rPacket = remoteSetPoster:InvokeServer("set", {Poster=Interface.Object.Parent; DecalId=templateDecals[a].ImageId;});
				reloadHistory();
			end
		end)
		
		new.Parent = rightScrollFrame;
	end
	--Interface.Garbage:Tag();
	
	return Interface;
end;

return Interface;