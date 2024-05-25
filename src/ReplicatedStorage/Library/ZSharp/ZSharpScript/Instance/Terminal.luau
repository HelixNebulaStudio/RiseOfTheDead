return {
    Class={
		UserId = 0;
    };
	
    Link=function(zss, t, private)
		local m = {};
		for k, v in pairs(t) do
			local newK = zss.Sandbox(k);
			if newK == nil then continue end;
			m[newK] = zss.Sandbox(v);
		end

		local new = newproxy(true);
		local meta = getmetatable(new);
		meta.__index = m;
		return new;
    end
};