local LibraryManager = {};
LibraryManager.__index = LibraryManager;

function LibraryManager:SetOnAdd(func)
	self.OnAdd = func;
end

function LibraryManager:Add(data)
	if self.Library[data.Id] ~= nil then error("Library>>  Id alerady exist for ("..data.Id..")"); end;
	
	if self.OnAdd then self.OnAdd(data); end
	
	self.Library[data.Id] = data;
	self.Size = self.Size +1;
	self.Index[self.Size] = self.Library[data.Id];
	self.Keys[self.Size] = data.Id;
	
	return self.Library[data.Id];
end

function LibraryManager:Set(id, key, value)
	if self.Library[id] == nil then
		error("Library>> Id ".. id .." does not exist.");
		return;
	end
	self.Library[id][key] = value;
	return self.Library[id];
end

function LibraryManager:Replace(id, new)
	if self.Library[id] == nil then
		new.Id = id;
		return self:Add(new);
	end
	
	table.clear(self.Library[id]);
	for k,v in pairs(new) do
		self.Library[id][k] = v;
	end
	return self.Library[id];
end

function LibraryManager:Find(id)
	return self.Library[id];
end

function LibraryManager:FindByKeyValue(key, value)
	for k, v in pairs(self.Library) do
		if self.Library[k] and self.Library[k][key] == value then
			return self.Library[k];
		end
	end
end

function LibraryManager:ListByKeyValue(key, valueOrFunc)
	local list = {};
	for k, v in pairs(self.Library) do
		if self.Library[k] and ((typeof(valueOrFunc) == "function" and valueOrFunc(self.Library[k][key]) == true) or self.Library[k][key] == valueOrFunc) then
			table.insert(list, self.Library[k]);
		end
	end
	return list;
end

function LibraryManager:GetKeys()
	return self.Keys;
end

function LibraryManager:GetAll()
	return self.Library;
end

function LibraryManager:Sort(f)
	self.Sorted = {};
	for k, v in pairs(self.Library) do
		table.insert(self.Sorted, self.Library[k]);
	end
	table.sort(self.Sorted, f);
end

function LibraryManager:GetSorted()
	return self.Sorted;
end

function LibraryManager:GetIndexList()
	return self.Index;
end

function LibraryManager:GetRandom()
	return self.Index[math.random(1, self.Size)];
end

function LibraryManager.new()
	local self = {
		Sorted = {};
		Index = {};
		Library = {};
		Keys = {};
		Size = 0;
	};
	
	setmetatable(self, LibraryManager)
	return self;
end

return LibraryManager;
