local AnimationMeta = {};
AnimationMeta.__index = AnimationMeta;

function AnimationMeta:BindSpeed()
	return math.clamp((math.max(self.Values.CurrentSpeed, 5)/3), 0, 5);
end

return AnimationMeta;