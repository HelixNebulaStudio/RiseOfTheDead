return {
	Class={
		Name = "";
		UserId = 0;
	};

	Constructor=function(zss, public, private, instance)
		local staticUserdata = zss.Instance:MatchList(function(userdata)
			local match = userdata.ClassName == private.ClassName and userdata.UserId == instance.UserId;
			local breakSearch = true;
			return match, breakSearch;
		end)[1];
		if staticUserdata then return staticUserdata end;

		public.UserId = instance.UserId;
		public.Name = instance.Name;

		return;
	end;
}