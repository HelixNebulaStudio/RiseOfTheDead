local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local SkillTree = {};
SkillTree.__index = SkillTree;
--==
local modSkillTreeLibrary = require(game.ReplicatedStorage.Library.SkillTreeLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local remoteSkillTree = modRemotesManager:Get("SkillTree");

--== Script;
delay(5, function()
	local function LoadLibraryTriggers(library)
		for id, lib in pairs(library) do
			local types = lib.Triggers;
			if lib.Triggers == nil then continue end;
			
			for a=1, #types do
				local triggerType = types[a];
				if modSkillTreeLibrary.Triggers[triggerType] == nil then modSkillTreeLibrary.Triggers[triggerType] = {} end;
				if script:FindFirstChild(lib.Name) then
					library[id].Module = require(script[lib.Name]).init(SkillTree, library[id]);
					modSkillTreeLibrary.Triggers[triggerType][id] = library[id];
				end
			end
		end
	end
	LoadLibraryTriggers(modSkillTreeLibrary.Authority.Library);
	LoadLibraryTriggers(modSkillTreeLibrary.Endurance.Library);
	LoadLibraryTriggers(modSkillTreeLibrary.Synergy.Library);
end)

function SkillTree:CalStats(lib, pts)
	return modSkillTreeLibrary:CalStats(lib, pts);
end
	
function SkillTree:NewTree(name)
	table.insert(self.Trees, {Name=name; Data={};});
end

function SkillTree:ClearTrees()
	table.clear(self.Trees);
end

function SkillTree:Load(rawData)
	rawData = rawData or {};
	for key, value in pairs(self) do
		local data = rawData[key] or self[key];
		self[key] = data;
	end
	
	if #self.Trees <= 0 then
		self:NewTree("Default");
	end
	if self.ActiveTree == nil and #self.Trees > 0 then
		self:SetActive(1);
	end
end

function SkillTree:GetSkill(player, id)
	local profile = shared.modProfile:Find(player.Name);
	if profile == nil then return end;
	
	local skillTree = profile and profile.SkillTree;
	local lib = modSkillTreeLibrary:Find(id);
	if lib == nil then return end;
	
	local activeTreeIndex = skillTree.ActiveTree;
	if modConfigurations.DisableMasterySkills then
		activeTreeIndex = 0;
	end

	local tree = activeTreeIndex and skillTree.Trees[activeTreeIndex];
	if tree and tree.Data[id] then
		return {Points=tree.Data[id]; Library=lib};
	end
	
	return {Points=0; Library=lib};
end

function SkillTree:TriggerSkills(player, triggerType, ...)
	local profile = shared.modProfile:Find(player.Name);
	if profile == nil then return end;
	if modConfigurations.DisableMasterySkills then return end;
	
	local skillTree = profile.SkillTree and profile.SkillTree.ActiveTree and profile.SkillTree.Trees[profile.SkillTree.ActiveTree] or nil;
	local triggerTable = modSkillTreeLibrary.Triggers[triggerType];
	if triggerTable == nil then Debugger:Log("Unknown trigger type:",triggerType); return end;
	skillTree = skillTree and skillTree.Data or nil;
	
	if skillTree then
		for id, points in pairs(skillTree) do
			if triggerTable[id] and triggerTable[id].Module then
				local args = {...};
				task.spawn(function()
					triggerTable[id].Module:Trigger(profile, triggerType, points, unpack(args));
				end)
			end
		end
	end
end

function SkillTree:SetActive(index)
	self.ActiveTree = index > 0 and index <= #self.Trees and index or 1;

	local skillTree = self.Trees[self.ActiveTree];

	local profile = shared.modProfile:Find(self.Player.Name);
	if profile == nil then return end;
	
	if profile then
		local activeSave = profile:GetActiveSave();
		local playerLevel = activeSave and activeSave:GetStat("Level") or 0;

		local availablePts = playerLevel;

		local treeData = {};
		for id, points in pairs(skillTree.Data) do
			local lib = modSkillTreeLibrary:Find(id);
			if playerLevel >= lib.Level then
				table.insert(treeData, {Id=id; UpgradeCost=lib.UpgradeCost; Data=skillTree.Data[id];});
			end
		end
		
		table.sort(treeData, function(a, b)
			return a.UpgradeCost < b.UpgradeCost;
		end)
		
		for a=1, #treeData do
			local id = treeData[a].Id;
			local pts = treeData[a].Data;
			
			if availablePts >= pts then
				availablePts = availablePts - pts;
				skillTree.Data[id] = pts;
				
			else
				skillTree.Data[id] = nil;
				
			end
		end
	end
end

function SkillTree.new(player)
	local meta = {
		Player = player;
	};
	meta.__index=meta;
	
	local self = {
		Trees = {};
		ActiveTree = nil;
	};
	
	setmetatable(self, meta);
	setmetatable(meta, SkillTree);
	return self;
end

remoteSkillTree.OnServerEvent:Connect(function(player, data)
	local profile = shared.modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local playerLevel = activeSave:GetStat("Level");
	local skillTree = profile.SkillTree;
	
	if data.Trees and #data.Trees > 0 then
		for a=1, profile.Premium and math.min(#data.Trees, 5) or math.min(#data.Trees, 2) do
			local treeName = data.Trees[a].Name;
			local treeData = data.Trees[a].Data;
			
			skillTree.Trees[a] = {
				Name = treeName:sub(1, math.min(16, #treeName));
				Data = {};
			};
			
			local totalSp = 0;
			for id, pts in pairs(treeData) do
				if pts ~= 0 then
					local lib = modSkillTreeLibrary:Find(id);
					if playerLevel >= lib.Level then
						local spent = math.min(pts, lib.UpgradeCost * lib.MaxLevel);
						if totalSp + spent <= playerLevel and pts % lib.UpgradeCost == 0 then
							skillTree.Trees[a].Data[id] = spent;
							totalSp = totalSp + spent;
						end
					end
				end
			end
		end
	end
	
	skillTree:SetActive(data.ActiveTree or 1);
	
end)

return SkillTree;
