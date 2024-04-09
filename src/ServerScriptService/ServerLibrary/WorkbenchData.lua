local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local WorkbenchData = {};
WorkbenchData.__index = WorkbenchData;
WorkbenchData.ProcessTypes = {
	Building = 1;
	DeconstructMod = 2;
	DeconstructWeapon = 3;
	PolishItem = 4;
};
-- New process types needs to be added to Interface.GetProcesses();

function WorkbenchData:GetBenchSize()
	local profile = shared.modProfile:Get(self.Player);
	return profile.Premium and 10 or 5;
end

function WorkbenchData:CanNewProcess()
	return #self.Processes < self:GetBenchSize();
end

function WorkbenchData:NewProcess(processData)
	table.insert(self.Processes, processData);
	
	task.spawn(function()
		if processData.PlayProcessSound == true then
			local classPlayer = shared.modPlayers.Get(self.Player);
			if classPlayer and classPlayer.RootPart then
				local modAudio = require(game.ReplicatedStorage.Library.Audio);
				modAudio.Play("WorkbenchProcess", classPlayer.RootPart);
			end
		end
	end)
	
	self:Sync();
end

function WorkbenchData:GetProcess(index)
	return self.Processes[index];
end

function WorkbenchData:RemoveProcess(index)
	table.remove(self.Processes, index);
	self:Sync();
end

function WorkbenchData:Load(rawData)
	for k, v in pairs(rawData or {}) do
		if k == "Processes" and type(v) == "table" then
			for a=1, #v do
				if v[a].ItemId == "riflehypderdamagemod" then
					v[a].ItemId = "riflehyperdamagemod";
				end
			end
		end
		self[k] = v;
	end
	return self;
end

function WorkbenchData.new(player, syncFunc)
	local meta = {
		Player = player;
		Sync = syncFunc;
	};
	meta.__index = meta;
	
	local self = {
		Processes = {};
	};
	
	setmetatable(meta, WorkbenchData);
	setmetatable(self, meta);
	return self;
end

return WorkbenchData;
