local StatusClass = {};
StatusClass.__index = StatusClass;

function StatusClass.new()
	local self = {};

	setmetatable(self, StatusClass);
	return self;
end

return StatusClass;
