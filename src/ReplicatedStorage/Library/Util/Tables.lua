--!strict
local Tables = {};

--[[
    Tables.Shuffle(t, seed)

    @param t table
    @param seed Seed
]]
function Tables.Shuffle(t, seed)
    if t == nil then return end;
    local n = #t;

    local random;
    if seed then
        random = Random.new(seed);
    end

    for i=1, n-1 do
        local l = random and random:NextInteger(i, n) or math.random(i, n);
        t[i], t[l] = t[l], t[i];
    end
end

--[[
    Tables.Reverse(t)

    @param t table
]]
function Tables.Reverse(t)
    for i = 1, math.floor(#t/2) do
        local j = #t - i + 1
        t[i], t[j] = t[j], t[i];
    end
end

--[[
    Tables.DeepClone(t)

    Deeply clones table.

    @param t table
]]
function Tables.DeepClone(t)
	if t == nil then return end;
	if typeof(t) ~= "table" then return t end;
	
	local n = table.clone(t);
	
	for k, v in pairs(n) do
		n[k] = Tables.DeepClone(v);
	end
	
	return n;
end


--[[
    Tables.DeepClean(t)

    Empties every tables within the table.

    @param t table
]]
function Tables.DeepClean(t)
	if t == nil then return end;
	for k, v in pairs(t) do
		if type(v) == "table" then
			Tables.DeepClean(v);
        else
            t[k] = nil;
		end
	end
end

function Tables.Truncate(t, amt, direction: number?)
    direction = direction or 1;

    for a=1, amt do
        if #t <= 0 then break; end;
        if direction == 1 then
            table.remove(t, 1);
        elseif direction == -1 then
            table.remove(t, #t);
        end
    end
end

function Tables.Mold(t, template)
    for k, v in pairs(template) do
        if t[k] == nil then
            if typeof(v) == "table" then
                t[k] = Tables.DeepClone(v);
            else
                t[k] = v;
            end
        elseif typeof(t[k]) == "table" then
            t[k] = Tables.Mold(t[k], v);
        end
    end

    return t :: (typeof(template) | typeof(t));
end

function Tables.HasChanged(old, new)
    if typeof(old) ~= "table" then return true; end;
    if typeof(new) ~= "table" then return true end;

    local keys = {};
    for k, _ in pairs(old) do
        table.insert(keys, k);
    end
    for k, _ in pairs(new) do
        table.insert(keys, k);
    end

    for a=1, #keys do
        local oldV = old[keys[a]];
        local newV = new[keys[a]];

        if typeof(oldV) ~= typeof(newV) then
            return true;
        elseif typeof(oldV) == "table" and Tables.HasChanged(oldV, newV) then
            return true;
        elseif (oldV :: any) ~= (newV :: any) then
            return true;
        end
    end
    
    return false;
end

function Tables.CollapseValues(t)
    local existList = {};
    for a=#t, 1, -1 do
        local v = t[a];

        if existList[v] == nil then
            existList[v] = true;
            continue;
        end

        table.remove(t, a);
    end
end

return Tables;