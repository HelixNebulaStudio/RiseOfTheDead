local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");

--
local ZSharp = {};

function ZSharp.Load(ZSharpScript, zEnv)
	zEnv.Instance = ZSharpScript.Instance;
	zEnv.new = ZSharpScript.newInstance;

	ZSharpScript.Sandbox = function(data, instanceCast)
		if typeof(data) == "function" then
			if instanceCast then
				return ZSharpScript.newInstance(instanceCast, function(...)
					local args = ZSharpScript.Sandbox({...});
					return data(args);
				end);
			end

			return function(...)
				local args = ZSharpScript.Sandbox({...});
				return data(unpack(args));
			end;

		elseif typeof(data) == "table" then
			local n = table.clone(data);
			for k, v in pairs(n) do
				n[ZSharpScript.Sandbox(k)] = ZSharpScript.Sandbox(v);
			end

			if instanceCast then
				n.ClassName = instanceCast;
				return ZSharpScript.newInstance(instanceCast, n);
			end

			return n;

		elseif typeof(data) == "userdata" and data.ClassName then
			local class = ZSharpScript.Classes[data.ClassName];
			return class and ZSharpScript.newInstance(data.ClassName, data) or nil;

		elseif typeof(data) == "string" or typeof(data) == "number" or typeof(data) == "boolean"  then
			return data;

		end

		return nil;
	end
end

function ZSharp.Init(ZSharpScript)
	local Classes = {};
	ZSharpScript.Classes = Classes;
	local InstanceLink = {};
	ZSharpScript.InstanceLink = InstanceLink;
	
	
	local InstanceMeta = {};
	InstanceMeta.__index = InstanceMeta;
	InstanceMeta.__metatable = "The metatable is locked";

	local Instance = setmetatable({}, InstanceMeta);
	Instance.ClassName = "Instance";
	Instance.ClassList = {};
	

	InstanceMeta.hintGet = "Get an existing instance.";
	InstanceMeta.descGet= [[Get an existing instance by name.
		<b>Instance:Get</b>(name: <i>string</i>): <i>Instance</i>
	]];
	function Instance:Get(name: string)
		for obj, inst in pairs(ZSharpScript.Instances) do
			if obj.Name == name then
				return obj;
			end
		end
		return nil;
	end
	

	InstanceMeta.hintList = "Get a list of instances.";
	InstanceMeta.descList = [[Get a list of instances by name or matching name patterns.
		if search is false, pattern is be used to match instances name. 
		if search is true, pattern will be used in string.match to match instance names.
		<b>Instance:List</b>(pattern: <i>string?</i>, search: boolean?): <i>Instance</i>
	]];
	function Instance:List(pattern: string?, search: boolean?)
		local r = {};
		
		for obj, inst in pairs(ZSharpScript.Instances) do
			local add = false;
			if pattern == nil then
				add = true;
			elseif search == true and string.match(obj.Name, pattern) then
				add = true;
			elseif obj.Name == pattern then
				add = true;
			end
			
			if add then
				table.insert(r, obj);
			end
		end
		
		return r;
	end
	

	InstanceMeta.hintDestroyList = "Destroy a list of instances.";
	InstanceMeta.descDestroyList = [[Destroy a list of instances by name or matching name patterns.
		if search is false, pattern is be used to match instances name. 
		if search is true, pattern will be used in string.match to match instance names.
		<b>Instance:List</b>(pattern: <i>string?</i>, search: boolean?): <i>Instance</i>
	]];
	function Instance:DestroyList(pattern: string, search: boolean)
		local r = self:List(pattern, search);
		for a=1, #r do
			r[a]:Destroy();
		end
	end
	

	for _, obj in pairs(script:GetChildren()) do
		if not obj:IsA("ModuleScript") then continue end;
		local zInstance = require(obj);
		local className = obj.Name;

		zInstance.Class.ClassName = className;
		ZSharpScript.Classes[className] = zInstance.Class;
		if zInstance.Link then
			InstanceLink[className] = zInstance.Link;
		end
	end

	for key, _ in pairs(ZSharpScript.Classes) do
		local proxy = newproxy(true);
		local meta = getmetatable(proxy);
		meta.__metatable = "The metatable is locked";
		meta.ClassName = key;
		
		Instance.ClassList[key] = proxy;
	end

	ZSharpScript.Instance = Instance;
	ZSharpScript.newInstance = function(className: string, instance: Instance?)
		if className == nil then
			error("Missing class name for new()");
		end
		if ZSharpScript.Classes[className] == nil then
			error(`Class name does not exist for new({className})`);
		end
		if getfenv(1).Instance == nil and instance then
			instance = nil;
			Debugger:Warn("Attempt to preset Instance");
		end
		ZSharpScript.InstanceCounter = ZSharpScript.InstanceCounter+1;
		
		local new = newproxy(true);
		local meta = getmetatable(new);
		local private = {
			ClassName = className;
			Name = className.."#"..ZSharpScript.InstanceCounter;
		};

		local class = ZSharpScript.Classes[className];
		instance = InstanceLink[className] and InstanceLink[className](ZSharpScript, instance, private) or instance;
		assert(typeof(instance) == "userdata", `Invalid instance for {className}`);

		if instance.Name and instance.Name ~= instance.ClassName then
			private.Name = `{instance.Name}#{ZSharpScript.InstanceCounter}`;
		end
		
		meta.__metatable = "The metatable is locked";
		
		for k, func in pairs(class) do
			if typeof(func) ~= "function" then continue end;
			
			private[k] = function(...)
				return func(instance, ...);
			end
		end
		
		function private.Destroy()
			if private.OnDestroy then
				private.OnDestroy();
			end
			Debugger.Expire(instance);
			ZSharpScript.Instances[new] = nil;
		end
		
		function private.KeyValues()
			local keyValues = {};
			for k, v in pairs(class) do
				keyValues[k] = instance[k];
			end
			for k, v in pairs(private) do
				keyValues[k] = v;
			end
			return keyValues;
		end
		
		function meta.__index(_, k)
			local class = ZSharpScript.Classes[private.ClassName];
			
			if private[k] then
				return private[k];
			end
			if class[k] == nil then
				error(`{k} is not a valid member of {class.ClassName}`);
			end

			return instance[k];
		end;

		function meta.__newindex(_, k, v)
			local class = ZSharpScript.Classes[private.ClassName];
			if class[k] == nil then
				error(`{k} is not a valid member of {class.ClassName}`);
			end
			if k == "Id" or k == "ClassName" then
				error(`Can not modify Instance {k}.`);
			end
			
			instance[k] = v;
		end;

		function meta.__tostring(_)
			return private.ClassName;
		end;

		function meta.__call(_, ...)
			local properties = ...;

			if typeof(properties) ~= "table" then
				error(`Invalid initialize for {private.ClassName}`);
				return;
			end

			for k, v in pairs(properties) do
				new[k] = v;
			end
			
			return new;
		end;
		
		if instance.Destroying then
			instance.Destroying:Connect(function()
				new:Destroy();
			end)
		end
		ZSharpScript.Instances[new] = instance;
		return new;
	end;
end

return ZSharp;