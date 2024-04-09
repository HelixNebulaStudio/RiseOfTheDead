local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("mission60RepairBanner", "Repair Faction Banner");
button.InteractDuration = 5;
button.Script = script;

local RunService = game:GetService("RunService");
if RunService:IsClient() then
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule"));
	local missionCompleted = false;

	local function localUpdate(self)
		local factionTag = script.Parent:GetAttribute("FactionTag");
		if script.Parent:GetAttribute("Repaired") == true then
			self.CanInteract = false;
			self.Label = script.Parent.Name .." [".. factionTag .."]";
			return;
		end
		
		if modData.GameSave and modData.GameSave.Missions then
			local missionsList = modData.GameSave.Missions;
			for a=1, #missionsList do
				local missionData = missionsList[a];
				if missionData.Id == 60 then
					if missionData.ProgressionPoint == 2 then
						missionCompleted = true;

					elseif missionData.Type == 1 then
						self.CanInteract = true;
						
						local saveData = missionData.SaveData;
						local modItemLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
						local itemLib = modItemLibrary:Find(saveData.RepairItemId);
						
						self.Label = "Repair Faction Banner with ".. saveData.RepairCost .." ".. itemLib.Name ..".";
						
					end
					break;
				end
			end
		end
	end

	button.OnSync = function(self, data)
		self.CanInteract = data.CanInteract;
		self.Label = data.Label;
		localUpdate(self);
	end

	button.CanInteract = false;
	button.Object = script.Parent;

	button.OnTrigger = function(self) -- OnMouseOver
		if missionCompleted then 
			self.CanInteract = false;
			localUpdate(self);
			return 
		end;
		localUpdate(self);
	end
end;

return button;