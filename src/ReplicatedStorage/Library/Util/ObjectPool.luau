local DISTANT_CF = CFrame.new(0, 0, 1_000_000);
local ObjectPool = {};

function ObjectPool.new(object: Instance, initialAmount: number?)
    local Pool = {
		Object = object:Clone();
		Available = {};
	}
    
	for i = 1, initialAmount or 1 do
		Pool.Available[i] = Pool.Object:Clone()
	end

    function Pool:Get()
		local i = #Pool.Available;
		local obj = Pool.Available[i];
		if obj then
			table.remove(Pool.Available, i);
			return obj;
		else
			return Pool.Object:Clone();
		end
	end

	function Pool:Return(obj: BasePart)
		obj.CFrame = DISTANT_CF;
		table.insert(Pool.Available, obj);
	end

	return Pool;
end

return ObjectPool;