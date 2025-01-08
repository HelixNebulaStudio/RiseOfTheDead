local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UserInputService = game:GetService("UserInputService");

local localPlayer = game.Players.LocalPlayer;

local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);

--==
local ModeHud = {};
ModeHud.__index = ModeHud;

function ModeHud.new(modInterface, mainFrame)
	local self = {
		Interface = modInterface;
		MainFrame = mainFrame;
		
		Active = false;
		Garbage = modGarbageHandler.new();
		
		Update = function() end;-- override;
		
		-- Spectate;
		CurrentSpectate = nil;
		SpectateIndex = 1;
	}

	setmetatable(self, ModeHud);
	return self;
end

function ModeHud:SetActive(val)
	self.Active = val;
	
	if self.Active then
		self.Garbage:Tag(UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
			if gameProcessed then return end;
			if not self:IsSpectating() then return end;

			local function changeSpectate(add)
				local aliveCharacters = self:GetAlive();

				if add then
					if self.SpectateIndex+1 > #aliveCharacters then
						self.SpectateIndex = 1;
					else
						self.SpectateIndex = self.SpectateIndex +1;
					end
				else
					if self.SpectateIndex-1 < 1 then
						self.SpectateIndex = #aliveCharacters;
					else
						self.SpectateIndex = self.SpectateIndex -1;
					end
				end
				self:Spectate(aliveCharacters[self.SpectateIndex]);
			end

			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
				changeSpectate(true);

			elseif inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
				changeSpectate(false);

			end
		end))
		
	else
		self.CurrentSpectate = nil;
		self.SpectateIndex = 1;
		self.Garbage:Destruct();
		
	end
end

--== Spectator;
function ModeHud:GetAlive()
	local aliveCharacters = {};
	for _, player in pairs(game.Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local humanoid = player.Character.Humanoid;
			if humanoid.Health > 0 then
				table.insert(aliveCharacters, player.Character);

				if self.CurrentSpectate == player.Character then
					self.SpectateIndex = #aliveCharacters;
				end
			end
		end
	end
	return aliveCharacters;
end

function ModeHud:IsSpectating()
	local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	local modCharacter = modData:GetModCharacter();

	if modCharacter then
		return modCharacter.CharacterProperties.IsSpectating;
	end
	return false;
end

function ModeHud:Spectate(character)
	if character == nil then
		local aliveCharacters = self:GetAlive();
		if #aliveCharacters > 0 then
			character = aliveCharacters[math.random(1, #aliveCharacters)];
		end
	end

	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid");
	if humanoid then
		self.CurrentSpectate = character;
	end
end

return ModeHud;