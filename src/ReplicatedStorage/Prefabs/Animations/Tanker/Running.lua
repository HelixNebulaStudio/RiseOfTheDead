local AnimationMeta = {};
AnimationMeta.__index = AnimationMeta;

function AnimationMeta:BindSpeed()
	return math.clamp(self.Values.CurrentSpeed, 3, 10)/4;
end

return AnimationMeta;