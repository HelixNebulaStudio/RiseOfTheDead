local modVector = require(script.Parent.Vector);

local Physics = {};
--==

function Physics.WaitForSleep(basePart: BasePart, packet)
	local threshold: number = packet and packet.Threshold or 0.1;
	local rate: number = packet and packet.Rate or 0.2;
	local timeout: number = packet and packet.Timeout or 5;
	local sleepTicks: number = packet and packet.SleepTicks or (0.6/rate);
	
	local partSleepCount = 0;
	for a=0, timeout, rate do
		task.wait(rate);
		if not workspace:IsAncestorOf(basePart) then
			break;
		end
		
		if modVector:InCenter(basePart.AssemblyLinearVelocity, Vector3.zero, threshold) then
			partSleepCount = partSleepCount +1;
		else
			partSleepCount = 0;
		end
		if partSleepCount >= sleepTicks then
			break;
		end
	end
end

return Physics;