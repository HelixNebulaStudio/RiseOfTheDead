local ZSharp = {};

function ZSharp.Load(zSS, zEnv)
	zEnv.Enum = Enum;
	
	zEnv.math = math;
	zEnv.table = table;
	zEnv.string = string;
	zEnv.pcall = pcall;
	zEnv.task = {
		wait = task.wait;
		defer = task.defer;
		spawn = task.spawn;
		delay = task.delay;
	}

	zEnv.getfenv = function()
		return zEnv;
	end
	
	zEnv.pairs = pairs;
	zEnv.ipairs = ipairs;
	zEnv.next = next;
	zEnv.select = select;
	zEnv.tonumber = tonumber;
	zEnv.tostring = tostring;
	zEnv.unpack = unpack;
	zEnv.typeof = typeof;
	
	zEnv.tick = tick;
	zEnv.Vector2 = Vector2;
	zEnv.Vector3 = Vector3;
	zEnv.CFrame = CFrame;
	
end

return ZSharp;