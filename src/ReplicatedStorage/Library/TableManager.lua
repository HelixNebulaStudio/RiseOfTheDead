local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TableManager = {};
TableManager.__index = TableManager;


function TableManager.CloneTable(tb)
	if tb == nil then return end;
	if typeof(tb) ~= "table" then return tb end;

	local n = table.clone(tb);

	for k, v in pairs(n) do
		n[k] = TableManager.CloneTable(v);
	end

	return n;
end


function TableManager.GetDataHierarchy(data, hierarchyKey, createEmptyIfNil)
	local rData;
	
	local s, e = pcall(function()
		if data == nil then return end;
		if hierarchyKey == nil then rData = data; return; end;

		local keys = string.split(hierarchyKey, "/");
		rData = data;

		for a=1, #keys do
			local dir = rData;
			rData = dir[keys[a]];

			if rData == nil then
				if createEmptyIfNil == true then
					dir[keys[a]] = {};
					rData = dir[keys[a]];
					continue;
				end
				break;
			end
		end
	end)
	if not s then
		Debugger:Warn("Failed to get data hierachy for key chain:", hierarchyKey, e, debug.traceback());
	end
	
	return rData;
end


function TableManager.SetDataHierarchy(rootData, dataValue, hierarchyKey, createEmptyIfNil)
	local keys = string.split(hierarchyKey, "/");
	local dataKey = table.remove(keys, #keys);
	
	local newHierarchyKey = #keys > 0 and table.concat(keys, "/") or nil;
	local parentData = TableManager.GetDataHierarchy(rootData, newHierarchyKey, createEmptyIfNil);
	if parentData then
		parentData[dataKey] = dataValue;
		
	else
		Debugger:Warn("Fail to index: rootData", rootData);
		error("Fail to index:"..newHierarchyKey.."/ "..dataKey);
	end
	
	return dataKey;
end


return TableManager;
