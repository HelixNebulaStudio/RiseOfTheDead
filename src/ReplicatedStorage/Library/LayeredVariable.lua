local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);

--==
local LayeredVariable = {
	ClassName = "LayeredVariable";

	Table = {};
	Dirty = false;
	Changed = modEventSignal.new();
};
LayeredVariable.__index = LayeredVariable;
export type LayeredVariable = typeof(LayeredVariable);

function LayeredVariable.new(defaultValue) : LayeredVariable
	local self = setmetatable({}, LayeredVariable);
	self.Table = {};
	self.Dirty=false;
	self.Changed = modEventSignal.new("LayeredVariableChanged");

	self:Set("default", defaultValue, 0);
	
	return self;
end

function LayeredVariable:Destroy()
	self.Changed:Destroy();
	for k,_ in pairs(self.Table) do
		self.Table[k] = nil;
	end
end

function LayeredVariable:Remove(id)
	local changed = false;
	
	for a=#self.Table, 1, -1 do
		if self.Table[a].Id == id then
			table.remove(self.Table, a);
			changed = true;
		end
	end
	
	if changed then
		self.Dirty=true;
	end
	self.Changed:Fire();
end

function LayeredVariable:GetTable()
	if self.Dirty then
		for a=#self.Table, 1, -1 do
			if self.Table[a].Expire and tick() > self.Table[a].Expire then
				table.remove(self.Table, a);
			end
		end

		table.sort(self.Table, function(a, b) return a.Order > b.Order; end);
		self.Dirty = false;
	end
	return #self.Table > 0 and self.Table[1] or nil;
end

function LayeredVariable:Has(id)
	for a=1, #self.Table do
		if self.Table[a].Id == id then
			return self.Table[a];
		end
	end
	return;
end

function LayeredVariable:Find(id)
	for a=1, #self.Table do
		if self.Table[a].Id == id then
			return self.Table[a];
		end
	end
	return;
end

function LayeredVariable:Get()
	local t = self:GetTable();
	if t == nil then return nil end;

	if t.Expire and tick() > t.Expire then
		self.Dirty = true;
		t = self:GetTable();
		if t == nil then return nil end;
	end

	return t.Value;
end

function LayeredVariable:Set(id, value, priority, expireDuration)
	local exist = false;
	
	--if expireDuration then task.delay(expireDuration, function() self.Dirty = true; end); end
	
	for a=1, #self.Table do
		local tab = self.Table[a];
		if tab.Id ~= id then continue end;
		
		if tab.Value ~= value then
			tab.Value = value;
			self.Dirty = true;
		end;
		
		if priority and tab.Order ~= priority then 
			tab.Order = priority or 0;
			self.Dirty = true; 
		end;
		
		if expireDuration then
			local newExpire = tick()+expireDuration;
			if tab.Expire ~= newExpire then self.Dirty = true; end;
			tab.Expire = newExpire;
		end
		
		exist = true;
		return;
	end
	
	if not exist then
		table.insert(self.Table, {Id=id; Value=value; Order=priority or 0; Expire=(expireDuration and tick()+expireDuration or nil);});
		self.Dirty=true;
	end
	
	self.Changed:Fire();
end

return LayeredVariable;