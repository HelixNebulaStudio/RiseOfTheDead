
--==

local Math = {};


function Math.GetFactors(num)
	local r = {}
	
	for a=1, math.sqrt(num), 1 do
		local remainder = num % a;
		
		if remainder == 0 then
			local f, fpair = a, num/a
			table.insert(r, f)
			if f ~= fpair then
				table.insert(r, fpair);
			end
		end
	end
	
	table.sort(r);
	return r;
end


function Math.NumberToBinStr(x, fitString)
	local r = "";
	
	while x ~= 1 and x ~= 0 do
		r = tostring(x%2) ..r;
		x = math.modf(x/2);
	end
	
	r = tostring(x)..r;
	
	if fitString and #fitString > #r then
		local rep = #fitString - #r;
		
		r = string.rep("0", rep)..r;
	end
	
	return r;
end


function Math.MapNum(x, inMin, inMax, outMin, outMax, clampOutput)
	local v = (x - inMin)*(outMax - outMin)/(inMax - inMin) + outMin
	if clampOutput then
		v = outMax > outMin and math.clamp(v, outMin, outMax) or math.clamp(v, outMax, outMin);
	end
	return v
end


function Math.Lerp(a, b, t, snap: number?)
	snap = snap or 0.001;
	local c = a * (1-t) + (b*t);
	-- if math.abs(b-a) <= snap then
	-- 	if b > a then
	-- 		c = b;
	-- 	else
	-- 		c = a;
	-- 	end
	-- end
	return c;
end

--[[
	Used instead of Lerp for delta sensitive lerping.
	
	@param decay number range [1,25] slow to fast
]]
function Math.DeltaLerp(a, b, decay, delta, snap: number?)
	snap = snap or 0.001;
	local c = b+(a-b)*math.exp(-decay*delta);
	-- if math.abs(b-a) <= snap then
	-- 	if b > a then
	-- 		c = b;
	-- 	else
	-- 		c = a;
	-- 	end
	-- end
	return c;
end


function Math.CFrameSpread(direction, maxSpreadAngle)
	maxSpreadAngle = math.clamp(maxSpreadAngle, 0, 90);

	local cf = CFrame.new(Vector3.new(), direction);

	
	local spreadRollStart = (math.random(0,1000)/1000)*2*math.pi;
	local deflection = math.rad(maxSpreadAngle) * (math.random(0,1000)/1000)^2;
	
	cf = cf * CFrame.Angles(0, 0, spreadRollStart); -- roll
	cf = cf * CFrame.Angles(deflection, 0, 0); -- pitch
	
	return cf.lookVector;
end

function Math.GaussianRandom() -- ~ -2.5 to ~ 2.5;
	return math.sqrt(-2*math.log(1 - math.random()))*math.cos(2*math.pi*math.random());
end

return Math;