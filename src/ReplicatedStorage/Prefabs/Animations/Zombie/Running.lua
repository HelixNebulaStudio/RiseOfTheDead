local AnimationMeta = {};
AnimationMeta.__index = AnimationMeta;

function AnimationMeta:BindSpeed()
	return math.clamp((math.max(self.Values.CurrentSpeed, 5)/4), 0, 4);
end

return AnimationMeta;