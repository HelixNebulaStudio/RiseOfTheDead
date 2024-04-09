local AnimationMeta = {};
AnimationMeta.__index = AnimationMeta;

function AnimationMeta:UpdateTrackChance()
	local npcModule = self.Values;
	
	if npcModule.JointsDestroyed == nil then return end;
	
	if self.Name == "LeftArmAttack" and npcModule.JointsDestroyed.LeftShoulder then
		self.Chance = 0;
		
	elseif self.Name == "RightArmAttack" and npcModule.JointsDestroyed.RightShoulder then
		self.Chance = 0;
		
	elseif self.Name == "BothArmAttack" and npcModule.JointsDestroyed.LeftShoulder and npcModule.JointsDestroyed.RightShoulder then
		self.Chance = 0;
		
	end
	
end

return AnimationMeta;