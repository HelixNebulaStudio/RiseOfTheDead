local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;
local modData = shared.require(localPlayer:WaitForChild("DataModule")) :: ModuleScript;
local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local remoteLiveFeedRemote = modRemotesManager:Get("LiveFeedRemote") :: UnreliableRemoteEvent;

local hudTemplate = script:WaitForChild("LiveFeedHud");

local templateGenericListing = script:WaitForChild("genericListing");
local templateRightAvatarLabel = script:WaitForChild("RightAvatarLabel");
local templateLeftAvatarLabel = script:WaitForChild("LeftAvatarLabel");
local templateAdditionalAvatarLabel = script:WaitForChild("additionalAvatarLabel");
local templateSymbolLabel = script:WaitForChild("symbolLabel");

local ContTypes = {
	RAvatarLabel = templateRightAvatarLabel;
	LAvatarLabel = templateLeftAvatarLabel;
	AddAva = templateAdditionalAvatarLabel;

	KillSym = templateSymbolLabel;
	Icon = templateSymbolLabel;
}

local maxFeedCount = 5;
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local windowFrame = hudTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;

	local window = Interface.NewWindow("StatusWindow", windowFrame);
	window.IgnoreHideAll = true;
	window.ReleaseMouse = false;
	window:SetOpenClosePosition(UDim2.new(0.02, 0, 0.2, 0), UDim2.new(0.02, 0, -1.1, 0));
	
	Interface.Garbage:Tag(remoteLiveFeedRemote.OnClientEvent:Connect(function(packet)
		window:Open();

		packet = packet or {};

		local expireDuration = packet.Sec or 6;

		local content = packet.Content or {};
		if #content <= 0 then return end;

		local preset = packet.Preset or {};

		local newListing = templateGenericListing:Clone();
		local uiPadding = newListing:WaitForChild("UIPadding");

		for a=1, #content do
			local contData = content[a];

			local contType = contData.Type;
			if contType == nil then
				if a == 1 then
					contType = "RAvatarLabel";
				elseif a == #content then
					contType = "LAvatarLabel";
				end
			end

			local contTypeTemplate = ContTypes[contType];
			if contTypeTemplate == nil then continue end;

			local new = contTypeTemplate:Clone() :: Frame;
			
			if contType == "RAvatarLabel" or contType == "LAvatarLabel" then
				local txtLabel = new:WaitForChild("TextLabel");
				local avaLabel = new:WaitForChild("AvatarLabel");

				txtLabel.Text = contData.Text;

				if contData.Avatar then
					avaLabel.Image = `https://www.roblox.com/headshot-thumbnail/image?userId={contData.Avatar}&width=420&height=420&format=png`;
				elseif contData.Image then
					avaLabel.Image = contData.Image;
				end

				if preset.Type == "Kill" then
					if preset.Killer ~= localPlayer.Name and contType == "RAvatarLabel" then
						new.BackgroundColor3 = Color3.fromRGB(106, 57, 57);
						txtLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
					elseif preset.Victim ~= localPlayer.Name and contType == "LAvatarLabel" then
						new.BackgroundColor3 = Color3.fromRGB(106, 57, 57);
						txtLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
					end
				end

			elseif contType == "Icon" then
				local iconLabel = new:WaitForChild("ImageLabel");
				iconLabel.Image = contData.Icon or "";

			elseif contType == "KillSym" then
			end

			new.LayoutOrder = a;
			new.Parent = newListing;
		end
		
		newListing:SetAttribute("Time", tick());
		newListing.Parent = windowFrame;
		Debugger.Expire(newListing, expireDuration);

		TweenService:Create(uiPadding, TweenInfo.new(0.5), {PaddingLeft=UDim.new(0, 15)}):Play();

		local orderedListing = {};
		for _, obj in pairs(windowFrame:GetChildren()) do
			local t = obj:GetAttribute("Time");
			if t == nil then continue end;

			table.insert(orderedListing, {Obj=obj; T=t;});
		end
		table.sort(orderedListing, function(a, b)
			return a.T < b.T;
		end)

		while #orderedListing > maxFeedCount do
			local tObj = table.remove(orderedListing, 1);
			if tObj == nil then break; end;
			game.Debris:AddItem(tObj.Obj, 0);
		end
	end));
	
	return Interface;
end;

return Interface;