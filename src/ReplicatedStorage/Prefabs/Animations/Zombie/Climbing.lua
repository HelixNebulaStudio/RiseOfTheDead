local AnimationMeta = {};
AnimationMeta.__index = AnimationMeta;

function AnimationMeta:BindSpeed()
	return math.clamp((math.max(self.Values.CurrentSpeed, 5)/5), 0, 1);
end

return AnimationMeta;