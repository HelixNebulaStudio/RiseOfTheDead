local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");

local localPlayer = game.Players.LocalPlayer;
local modData = require(localPlayer:WaitForChild("DataModule"));

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modEmotes = require(game.ReplicatedStorage.Library.EmotesLibrary);
local modFacesLibrary = require(game.ReplicatedStorage.Library.FacesLibrary);

local remoteSetPlayerFace = modRemotesManager:Get("SetPlayerFace");

local windowFrameTemplate = script:WaitForChild("EmotesMenu");
local templateEmoteListing = script:WaitForChild("EmoteListing");
local templateFaceListing = script:WaitForChild("FaceListing");

local ValidBindKeys = {"A"; "B"; "C"; "D"; "E"; "F"; "G"; "H"; "I"; "J"; "K"; "L"; "M"; "N"; "O"; "P"; "Q"; "R"; "S"; "T"; "U"; "V"; "W"; "X"; "Y"; "Z"; 
	"One"; "Two"; "Three"; "Four"; "Five"; "Six"; "Seven"; "Eight"; "Nine"; "Zero"};

local numWordToInt = {
	One = 1;
	Two = 2;
	Three = 3;
	Four = 4;
	Five = 5;
	Six = 6;
	Seven = 7;
	Eight = 8;
	Nine = 9;
	Zero = 0;
}
--== Script;

local function matchDigits(strA, strB)
	return string.match(strA, "%d+") == string.match(strB, "%d+")
end

function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;

	local templateHotKey = modInterface.Script:WaitForChild("hotKeyButton");
	local emoteContentList = windowFrame:WaitForChild("EmotesList");
	local faceContentList = windowFrame:WaitForChild("FaceList");
	
	local window = Interface.NewWindow("Emotes", windowFrame);

	if modConfigurations.CompactInterface then
		windowFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton").Visible = true;
		windowFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
			window:Close();
		end)
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0, 0), UDim2.new(0.5, 0, -1, 0));
		
	else
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0, 70), UDim2.new(0.5, 0, -1, 70));
		
	end

	local playerFace;
	
	window.OnWindowToggle:Connect(function(visible)
		Interface.CurrentButton = nil;
		if visible then
			if playerFace == nil or not workspace:IsAncestorOf(playerFace) then
				local classPlayer = shared.modPlayers.Get(localPlayer);
				local character = classPlayer.Character;
				local humanoid = character:WaitForChild("Humanoid");

				playerFace = character:WaitForChild("Head"):WaitForChild("face");

				local function onFaceUpdate()
					local faceTexture = playerFace.Texture;

					if playerFace:GetAttribute("Default") == nil and #faceTexture > 0 then
						playerFace:SetAttribute("Default", faceTexture);

						Interface:AddFaceButton("default", {
							Name = "Default";
							Icon = faceTexture;
							LayoutOrder = 0;
						});
					end

					for faceId, faceButtonObj in pairs(Interface.FaceButtons) do
						local button = faceButtonObj.Button;

						button.BackgroundColor3 = matchDigits(faceButtonObj.Icon, playerFace.Texture) and Color3.fromRGB(205, 255, 205) or Color3.fromRGB(255, 255, 255);
					end
				end

				playerFace:GetPropertyChangedSignal("Texture"):Connect(onFaceUpdate);
				onFaceUpdate();
			end
			
			modInterface.DisableGameplayBinds = true;
			Interface:HideAll{[window.Name]=true; ["Dialogue"]=true;};
			
		else
			modInterface.DisableGameplayBinds = false;
			
		end
	end)
	modKeyBindsHandler:SetDefaultKey("KeyWindowEmotes", Enum.KeyCode.C);
	local quickButton = Interface:NewQuickButton("Emotes", "Emotes", "rbxassetid://3256270450");
	quickButton.LayoutOrder = 3;
	modInterface:ConnectQuickButton(quickButton, "KeyWindowEmotes");
	
	window:SetConfigKey("DisableEmotes");
	window.FocusWindowKeyDown = true;

	if modConfigurations.CompactInterface then
		window.CompactFullscreen = true;
		windowFrame.Size = UDim2.new(1, 0, 1, 0);
		
	end
	
	
	Interface.CurrentButton = nil;
	

	Interface.FaceButtons = {};

	function Interface:GetFaceKeyName(keyName)
		for faceId, obj in pairs(Interface.FaceButtons) do
			if obj.KeyBind == keyName then
				return obj;
			end
		end
	end

	function Interface:AddFaceButton(faceId, param)
		param = param or {};

		local buttonObj = {
			Button = templateFaceListing:Clone();

			Name = param.Name or "NoName";
			LayoutOrder = param.LayoutOrder or 9999;
			Icon = param.Icon or "";
		}


		local button = buttonObj.Button;
		button.LayoutOrder = buttonObj.LayoutOrder;

		local nameTag = button:WaitForChild("NameTag");
		nameTag.Text = buttonObj.Name;

		local previewImageLabel = button:WaitForChild("Preview");
		previewImageLabel.Image = buttonObj.Icon;

		local function setFace()
			if matchDigits(playerFace.Texture, buttonObj.Icon) then
				remoteSetPlayerFace:FireServer(nil);
				--playerFace.Texture = playerFace:GetAttribute("Default") or "";
				
			else
				remoteSetPlayerFace:FireServer(faceId);
				
			end

			if modConfigurations.CompactInterface then
				window:Close();
			end
		end

		button.MouseButton1Click:Connect(setFace)
		button.MouseButton2Click:Connect(function() setFace(true); end)
		button.MouseMoved:Connect(function()
			Interface.CurrentButton = buttonObj;
		end)
		button.MouseLeave:Connect(function()
			Interface.CurrentButton = nil;
		end)

		if buttonObj.SetFace == nil then
			buttonObj.SetFace = setFace;
		end

		button.Parent = faceContentList;

		Interface.FaceButtons[faceId] = buttonObj;
	end
	
	for layoutOrder, faceInfo in pairs(modFacesLibrary:GetIndexList()) do
		if faceInfo.Locked == true then continue end
		Interface:AddFaceButton(faceInfo.Id, {
			Name = faceInfo.Name;
			Icon = faceInfo.Texture;
			LayoutOrder = layoutOrder;
		});
	end
	
	Interface.EmoteButtons = {};
	
	function Interface:GetEmoteKeyName(keyName)
		for emoteId, obj in pairs(Interface.EmoteButtons) do
			if obj.KeyBind == keyName then
				return obj;
			end
		end
	end
	
	function Interface:AddEmoteButton(emoteId, param)
		param = param or {};
		
		if Interface.EmoteButtons[emoteId] then
			Interface:RemoveEmoteButton(emoteId);
		end
		
		local buttonObj = {
			Button = templateEmoteListing:Clone();
			
			Name = param.Name or "NoName";
			LayoutOrder = param.LayoutOrder or 9999;
			EmoteLib = param.EmoteLib;
			Track = param.Track;
			
			PlayEmote = param.PlayEmote;
		}
		
		local button = buttonObj.Button;
		button.LayoutOrder = buttonObj.LayoutOrder;

		local nameTag = button:WaitForChild("NameTag");
		nameTag.Text = buttonObj.Name;
		
		local previewImageLabel = button:WaitForChild("Preview");
		previewImageLabel.Image = buttonObj.Icon or "";
		

		local function playEmote(looped)
			local character = localPlayer.Character;
			local remotePlayEmote = character and character:FindFirstChild("PlayEmote", true);
			if remotePlayEmote then
				if buttonObj.Track then
					remotePlayEmote:Invoke(buttonObj.Track, looped);
					
				elseif buttonObj.EmoteLib then
					remotePlayEmote:Invoke(emoteId, looped);

				else
				end
			else
				Debugger:Warn("Missing remote for emotes.");
			end

			if modConfigurations.CompactInterface then
				window:Close();
			end
		end

		button.MouseMoved:Connect(function()
			Interface.CurrentButton = buttonObj;
		end)
		button.MouseLeave:Connect(function()
			Interface.CurrentButton = nil;
		end)
		
		if buttonObj.PlayEmote == nil then
			buttonObj.PlayEmote = playEmote;
		else
			playEmote = buttonObj.PlayEmote;
		end
		
		button.MouseButton1Click:Connect(playEmote)
		button.MouseButton2Click:Connect(function() playEmote(true); end)
		
		button.Parent = emoteContentList;
		
		Interface.EmoteButtons[emoteId] = buttonObj;
	end
	
	function Interface:RemoveEmoteButton(emoteId)
		local emoteButtonObj = Interface.EmoteButtons[emoteId];
		if emoteButtonObj then
			game.Debris:AddItem(emoteButtonObj.Button, 0);
			Interface.EmoteButtons[emoteId] = nil;
		end
	end
	
	for emoteId, emoteLib in pairs(modEmotes:GetAll()) do
		Interface:AddEmoteButton(emoteId, {
			EmoteLib = emoteLib;
			Name = emoteLib.Name;
			Icon = emoteLib.Thumbnail;
			LayoutOrder = emoteLib.LayoutOrder;
		})
	end

	Interface:AddEmoteButton("fallover", {
		Name="Fall Over";
		LayoutOrder=0;
		PlayEmote = function()
			local classPlayer = shared.modPlayers.Get(localPlayer);
			
			Debugger:Warn("Fall over", classPlayer.Properties.Ragdoll);
			
			if classPlayer.Properties.Ragdoll == 1 then return end;

			local modCharacter = modData:GetModCharacter();
			modCharacter.CharacterProperties.Ragdoll = not modCharacter.CharacterProperties.Ragdoll;
			remoteSetPlayerFace:FireServer("ragdollEmote", modCharacter.CharacterProperties.Ragdoll and 2);
		end
	});
	
	local modCharacter = modData:GetModCharacter();
	Interface.Garbage:Tag(modCharacter.OnAnimationsChanged:Connect(function(emoteId, track)
		if track == nil then
			Interface:RemoveEmoteButton(emoteId);
			
			return;
		end

		Interface:AddEmoteButton(emoteId, {
			Name=emoteId;
			Track=track;
			LayoutOrder=1;
		});
	end));

	local movementKeys = {
		Enum.KeyCode.W;
		Enum.KeyCode.A;
		Enum.KeyCode.S;
		Enum.KeyCode.D;
		Enum.KeyCode.LeftShift;
		Enum.KeyCode.LeftControl;
	}
	
	Interface.IsEmoteMenuKeyDown = false;
	Interface.Garbage:Tag(UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
		if modKeyBindsHandler:Match(inputObject, "KeyWindowEmotes") then
			Interface.IsEmoteMenuKeyDown = true;
			
		else
			if Interface.IsEmoteMenuKeyDown then
				local emoteButtonObj = Interface:GetEmoteKeyName(inputObject.KeyCode.Name);
				if emoteButtonObj then
					emoteButtonObj.PlayEmote();
					Debugger:Warn("Play emote", emoteButtonObj.Name);

					window:Close();
					task.defer(function()
						window:Close();
					end)
					task.delay(0, function()
						window:Close();
					end)
				end
				
				local faceButtonObj = Interface:GetFaceKeyName(inputObject.KeyCode.Name);
				if faceButtonObj then
					faceButtonObj.SetFace();
					Debugger:Warn("Set face", faceButtonObj.Name);

					window:Close();
					task.defer(function()
						window:Close();
					end)
					task.delay(0, function()
						window:Close();
					end)
				end
				
			elseif windowFrame.Visible then
				if Interface.CurrentButton == nil then return end;
				if gameProcessedEvent then return end;
				if inputObject.UserInputType ~= Enum.UserInputType.Keyboard then return end;
				
				for a=1, #movementKeys do
					if movementKeys[a].Name == inputObject.KeyCode.Name then
						return;
					end
				end
				
				local buttonObj = Interface.CurrentButton;

				local keyName = inputObject.KeyCode.Name;
				--if not Interface.IsEmoteMenuKeyDown then return end;
				
				local keyNameMatchBind = (buttonObj.KeyBind == keyName);
				
				if buttonObj.PlayEmote then
					for _, obj in pairs(Interface.EmoteButtons) do
						if obj.KeyBind == keyName then
							game.Debris:AddItem(obj.HotKeyTag, 0);
							obj.KeyBind = nil;
						end
					end
					
				else
					for _, obj in pairs(Interface.FaceButtons) do
						if obj.KeyBind == keyName then
							game.Debris:AddItem(obj.HotKeyTag, 0);
							obj.KeyBind = nil;
						end
					end
					
				end

				if keyNameMatchBind then
					return;
					
				elseif buttonObj.KeyBind ~= nil then
					game.Debris:AddItem(buttonObj.HotKeyTag, 0);
					buttonObj.KeyBind = nil;
					
				end
				
				buttonObj.KeyBind = keyName;

				local newHotkeyTag = templateHotKey:Clone();
				newHotkeyTag.Name = "HotkeyTag";

				local hintLabel = newHotkeyTag:WaitForChild("Hint");
				hintLabel.Visible = false;

				local buttonLabel = newHotkeyTag:WaitForChild("button");
				buttonLabel.Text = tostring(keyName)
				
				if numWordToInt[keyName] then
					buttonLabel.Text = tostring(numWordToInt[keyName]);
				end
				
				newHotkeyTag.Position = UDim2.new(0, 2, 0, 2);
				newHotkeyTag.Size = UDim2.new(0, 15, 0, 15);

				newHotkeyTag.Parent = buttonObj.Button;
				buttonObj.HotKeyTag = newHotkeyTag;
			end
		end
	end));
	
	Interface.Garbage:Tag(UserInputService.InputEnded:Connect(function(inputObject, gameProcessedEvent)
		if modKeyBindsHandler:Match(inputObject, "KeyWindowEmotes") then
			Interface.IsEmoteMenuKeyDown = false;
		end
	end));

	return Interface;
end;

return Interface;