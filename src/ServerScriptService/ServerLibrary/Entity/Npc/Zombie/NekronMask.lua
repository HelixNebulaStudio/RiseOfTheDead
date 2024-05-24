local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local Zombie = {};

function Zombie.new(self)
	return function()
		task.spawn(function()
			if self.NekronAppearance == nil then
				local appearanceFolders = {};
				for name, classPlayer in pairs(modPlayers.Players) do
					local hasNekronMask = classPlayer.Properties and classPlayer.Properties.BodyEquipments and classPlayer.Properties.BodyEquipments.NekronMask == true;
					if hasNekronMask then
						local playerInstance = classPlayer:GetInstance();
						local appearanceFolder = playerInstance:FindFirstChild("Appearance");
						if appearanceFolder then
							table.insert(appearanceFolders, appearanceFolder);
						end
					end
				end

				local appearanceFolder = appearanceFolders[random:NextInteger(1, #appearanceFolders)];
				local rollSuccess = random:NextInteger(1, 100) <= math.clamp(#appearanceFolders*5, 5, 25);
				if RunService:IsStudio() and math.random(1, 2) == 1 then
					rollSuccess = true;
				end
				if appearanceFolder and rollSuccess then
					self.NekronAppearance = appearanceFolder;
				end
			end

			if self.NekronAppearance then
				local atLeastThree = 0;
				for _, obj in pairs(self.NekronAppearance:GetChildren()) do
					if obj.Name ~= "Nekron Mask"
						and obj.Name ~= "face"
						and (self.FullNekron == true or atLeastThree <= 3 or random:NextInteger(1, 2) == 1) then
						if obj:IsA("Shirt") then
							self.PresetShirt = {Id=obj.ShirtTemplate};
							if self.Prefab:FindFirstChildWhichIsA("Shirt") then
								self.Prefab:FindFirstChildWhichIsA("Shirt").ShirtTemplate = obj.ShirtTemplate;
							end

						elseif obj:IsA("Pants") then
							self.PresetPants = {Id=obj.PantsTemplate};
							if self.Prefab:FindFirstChildWhichIsA("Pants") then
								self.Prefab:FindFirstChildWhichIsA("Pants").PantsTemplate = obj.PantsTemplate;
							end

						elseif obj:IsA("Accessory") then
							local newAccessory = obj:Clone();

							local accAttachmentType = newAccessory:GetAttribute("Attachment");
							if accAttachmentType ~= nil then
								for _, obj in pairs(self.Prefab:GetChildren()) do
									if obj:IsA("Accessory") and obj:GetAttribute("Attachment") == newAccessory:GetAttribute("Attachment") then
										obj:Destroy();
									end
								end
							end

							newAccessory.Parent = self.Prefab;
						end
						atLeastThree = atLeastThree +1;
					end
				end

				self:UpdateClothing();
			end
		end)
	end
end

return Zombie;