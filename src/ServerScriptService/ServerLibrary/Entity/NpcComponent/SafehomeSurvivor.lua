local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modNpcProfileLibrary = require(game.ReplicatedStorage.Library.NpcProfileLibrary);

local Human = {};

function Human.new(self)
	if shared.modSafehomeService == nil then return end;
	
	repeat until shared.modProfile ~= nil;
	
	local player = self.Owner;
	if player == nil then Debugger:Log("Missing owner."); return end;
	
	local profile = shared.modProfile:Get(player);
	local safehomeData = profile.Safehome;
	
	local npcLib = modNpcProfileLibrary:Find(self.Name);

	local npcData = safehomeData:GetNpc(self.Name);
	
	self:AddComponent("ObjectScan");
	
	self.NpcData = npcData;
	
	shared.modSafehomeService.RefreshNpcStats();
	
	Debugger:Log("load npcData", npcData);
	
	if npcData.Active then
		local npcSpot = shared.modSafehomeService.GetNpcSpot(self.Name);

		self.Actions:Teleport(npcSpot.WorldCFrame);
	end
	
	while true do
		task.wait(1);
		
		local checkPoints = workspace:FindFirstChild("Spawns");
		if npcData.Active == nil or checkPoints == nil then
			continue;
		end;
		
		if npcData.Level == 0 then --======================= LEVEL 0
			local npcSpot = shared.modSafehomeService.GetNpcSpot(self.Name);
			
			self.Movement:Move(npcSpot.WorldPosition):Wait();
			task.wait(0.1);
			self.Movement:Face(self.RootPart.Position + npcSpot.WorldCFrame.LookVector);
			self.Chat(game.Players:GetPlayers(), "shelter_new");
			
			npcData:SetLevel(1);
			
		elseif npcData.Level == 2 then --======================= LEVEL 2
			
			if npcLib.Class == "Medic" then
				local unlockTime = npcData.LevelUpTime+60;
				
				if os.time() < unlockTime then
					if self.Wield.ToolModule == nil then
						self.Wield.Equip("medkit");
						
						if self.Wield.ToolModule and self.Wield.ToolModule.Animations then
							local animations = self.Wield.ToolModule.Animations;
							if animations.Use then animations.Use:Play(); end
							self.AvatarFace:Set("Welp");
						end
					end
					delay(unlockTime-os.time(), function()
						if self.Wield.ToolModule then
							self.Wield.Unequip();
							self.AvatarFace:Set();
						end
					end)
				end
			end
			
		elseif npcData.Level == 3 then --======================= LEVEL 3
			
			if npcLib.Class == "Medic" then
				if self.Wield.ToolModule then
					self.Wield.Unequip();
				end
				
			end
		end
	end
end

return Human;