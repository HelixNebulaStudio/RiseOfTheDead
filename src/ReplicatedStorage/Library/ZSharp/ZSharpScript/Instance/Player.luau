return {
	Class={
		UserId = 0;
	};
	Unique=function(zss, instance)
		for obj, _ in pairs(zss.Instances) do
			if obj.ClassName == instance.ClassName and obj.UserId == instance.UserId then
				return obj;
			end
		end
		return;
	end
}