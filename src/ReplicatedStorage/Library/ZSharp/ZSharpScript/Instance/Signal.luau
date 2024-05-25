return {
	Class={};

	Link=function(zss, func, private)
		private.OnDestroy = func;

		local new = newproxy(true);
		local meta = getmetatable(new);
		meta.__index = private;
		meta.__newindex = private;
		return new;
	end;

	Constructor=function(zss, public, private, func)
		private.OnDestroy = func;
    end;
}
