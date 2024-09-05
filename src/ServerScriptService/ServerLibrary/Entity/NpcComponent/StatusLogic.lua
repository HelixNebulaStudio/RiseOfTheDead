local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

--== Script;
local StatusLogic = {};
StatusLogic.__index = StatusLogic;

function StatusLogic.new(self)
	self.StatusLogicIsOnFire = function()
		if self.EntityStatus:GetOrDefault("FlameMod") then
			return true;
		end
		if self.EntityStatus:GetOrDefault("liquidFlame") then
			return true;
		end
		return false;
	end
	
	return function()
		local entityStatus = self.EntityStatus;
		
		local ragdollStatus, hijackedStatus, stunStatus;
		local slowValue, slowPercent;
		
		for k, v in pairs(entityStatus.List) do
			local status = v;
			
			if k == "Ragdoll" then
				ragdollStatus = status;
			elseif k == "Hijacked" then
				hijackedStatus = status;
			elseif k == "Stun" then
				stunStatus = status;
			end
			
			if typeof(v) ~= "table" then continue end;

			if status.SlowValue and (slowValue == nil or status.SlowValue < slowValue) then
				slowValue = status.SlowValue;
			end
			if status.SlowPercent and (slowPercent == nil or status.SlowPercent > slowPercent) then
				slowPercent = status.SlowPercent 
			end
			if status.Ragdoll then
				ragdollStatus = status;
			end
			if status.Hijacked then
				hijackedStatus = status;
			end
		end
		
		--==
		
		if slowPercent and slowPercent > 0 then
			self.Move.MoveSpeedPercent = 1-math.clamp(slowPercent, 0, 1);
		else
			if self.Move.MoveSpeedPercent ~= 1 then
				self.Move.MoveSpeedPercent = 1;
				self.Move:SetMoveSpeed("update");
			end
			self.Move.MoveSpeedPercent = 1;
		end
		
		if slowValue then
			self.SlowFlag = true;
			self.Move:SetMoveSpeed("set", "slow", slowValue, 18);
			
		else
			if self.SlowFlag == true then
				self.SlowFlag = nil;
				self.Move:SetMoveSpeed("remove", "slow");
			end

		end
		
		if ragdollStatus then
			if self.Humanoid:GetAttribute("Ragdoll") ~= true then
				self.Humanoid:SetAttribute("Ragdoll", true);
				self.Move:SetMoveSpeed("set", "ragdoll", 0, 20);
				self.Humanoid.PlatformStand = true;
				
			end
			
			return modLogicTree.Status.Success;
			
		else
			if self.Humanoid:GetAttribute("Ragdoll") == true then
				self.Humanoid:SetAttribute("Ragdoll", false);
				self.Move:SetMoveSpeed("remove", "ragdoll");
				self.Humanoid.PlatformStand = false;
				
			end
			
		end
		
		if hijackedStatus then
			return modLogicTree.Status.Success;
		end
		
		if stunStatus then
			if self.StunFlag == nil then
				self.StunFlag = true;
				self.Move:SetMoveSpeed("set", "stun", 0, 19);
			end
			return modLogicTree.Status.Success;
			
		else
			if self.StunFlag == true then
				self.StunFlag = nil;
				self.Move:SetMoveSpeed("remove", "stun");
			end
			
		end
		

		if self.Disabled == true then
			self.Move:Stop();
			return modLogicTree.Status.Success;
		end
		return modLogicTree.Status.Failure;
	end
end

return StatusLogic;