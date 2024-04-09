local AnimationMeta = {};
AnimationMeta.__index = AnimationMeta;

function AnimationMeta:BindSpeed()
	return math.clamp(self.Values.CurrentSpeed, 3, 10)/8;
end

return AnimationMeta;