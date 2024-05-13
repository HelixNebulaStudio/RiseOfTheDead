return {
    Class={
		UserId = 0;
    };
	
    Link=function(zss, t, private)
		local m = {};
		for k, v in pairs(t) do
			m[zss.Sandbox(k)] = zss.Sandbox(v);
		end

		local new = newproxy(true);
		local meta = getmetatable(new);
		meta.__index = m;
		return new;
    end
};