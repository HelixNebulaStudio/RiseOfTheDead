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

return Tables;