return {
	Class={};

	Link=function(zss, func, private)
		private.OnDestroy = func;

		local new = newproxy(true);
		local meta = getmetatable(new);
		meta.__index = {};
		return new;
	end;
}
