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
			local func = data;
			if instanceCast then
				return ZSharpScript.newInstance(instanceCast, function(...)
					local args = ZSharpScript.Sandbox({...});
					return func(unpack(args or {}));
				end);
			end

			return function(...)
				local args = ZSharpScript.Sandbox({...});
				return func(unpack(args or {}));
			end;

		elseif typeof(data) == "table" then
			local n = {};
			for k, v in pairs(data) do
				local newK = ZSharpScript.Sandbox(k);
				if newK == nil then continue end;
				n[newK] = ZSharpScript.Sandbox(v);
			end

			if instanceCast then
				n.ClassName = instanceCast;
				return ZSharpScript.newInstance(instanceCast, n);
			end

			return n;

		elseif (typeof(data) == "userdata" or typeof(data) == "Instance") and data.ClassName then
			local class = ZSharpScript.Classes[data.ClassName];
			if class == nil then
				return nil;
			end

			return ZSharpScript.newInstance(data.ClassName, data);

		elseif typeof(data) == "string" or typeof(data) == "number" or typeof(data) == "boolean"  then
			return data;

		end

		return nil;
	end

	ZSharpScript.UnSandbox = function(data)
		if typeof(data) == "userdata" or typeof(data) == "Instance" then
			if data.ClassName == "Player" then
				local player = game:GetService("Players"):GetPlayerByUserId(data.UserId);
				return player;
			end

		elseif typeof(data) == "table" then
			local n = {};
			for k, v in pairs(data) do
				local nK = ZSharpScript.UnSandbox(k);
				if nK == nil then continue end;
				
				n[nK] = ZSharpScript.UnSandbox(v);
			end
			
		elseif typeof(data) == "string" or typeof(data) == "number" or typeof(data) == "boolean"  then
			return data;

		end

		return nil;
	end
end

function ZSharp.Init(ZSharpScript)
	local Classes = {};
	ZSharpScript.Classes = Classes;

	local Constructors = {};
	ZSharpScript.Constructors = Constructors;
	
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
		for id, userdata in pairs(ZSharpScript.Instances) do
			if userdata.Name == name then
				return userdata;
			end
		end
		return nil;
	end
	

	InstanceMeta.hintList = "Get a list of instances by name.";
	InstanceMeta.descList = [[Get a list of instances by name or matching name patterns.
		if search is false, pattern is be used to match instances name. 
		if search is true, pattern will be used in string.match to match instance names.
		<b>Instance:List</b>(pattern: <i>string?</i>, search: boolean?): <i>Instance</i>
	]];
	function Instance:List(pattern: string?, search: boolean?)
		local r = {};
		
		for id, userdata in pairs(ZSharpScript.Instances) do
			local add = false;
			if pattern == nil then
				add = true;
			elseif search == true and string.match(userdata.Name, pattern) then
				add = true;
			elseif userdata.Name == pattern then
				add = true;
			end
			
			if add then
				table.insert(r, userdata);
			end
		end
		
		table.sort(r, function(a, b)
			return (a.Name or a.ClassName) > (b.Name or a.ClassName);
		end)
		return r;
	end
	

	InstanceMeta.hintMatchList = "Get an existing instance by matching.";
	InstanceMeta.descMatchList= [[Get an existing instance by matching property key and values. Match function should return one or two booleans. First boolean is for a match, second boolean is to break search loop.
		<b>Instance:MatchList</b>(matchFunc: <i>(instance: Instance) -> boolean, boolean</i>): <i>{Instance}</i>
	]];
	function Instance:MatchList(func: (any)->boolean)
		local r = {};
		for id, userdata in pairs(ZSharpScript.Instances) do
			local isMatch, breakRequest = func(userdata);
			if isMatch == true then
				table.insert(r, userdata);
			end
			if breakRequest == true then
				break;
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

		zInstance.Class.Name = className;
		zInstance.Class.ClassName = className;

		ZSharpScript.Classes[className] = zInstance.Class;
		if zInstance.Constructor then
			Constructors[className] = zInstance.Constructor;
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
		if getfenv(1).Instance == nil and instance then -- instance should be nil in sandbox.
			instance = nil;
		end

		if className == nil then
			error("Missing class name for new()");
		end

		local baseClass = ZSharpScript.Classes[className];
		if baseClass == nil then
			error(`Class name does not exist for new({className})`);
		end

		if Constructors[className] == nil then
			error(`Class {className} does not have a constructor.`);
		end

		--==
		ZSharpScript.InstanceCounter = ZSharpScript.InstanceCounter+1;
		local id = ZSharpScript.InstanceCounter;


		local userdata = newproxy(true);
		local public = getmetatable(userdata);
		local private = {
			Id = id;
			ClassName = className;
			__instance = instance;
		};

		local staticUserdata = Constructors[className](ZSharpScript, public, private, instance);
		if staticUserdata then
			return staticUserdata;
		end

		for k, func in pairs(baseClass) do
			if typeof(func) ~= "function" then continue end;
			
			private[k] = function(...)
				return func(rawget(private, "__instance"), ...);
			end
		end

		function public.__call(_, ...) -- instance being called. 
			local properties = ...;

			if typeof(properties) ~= "table" then
				error(`Invalid initialize for {className}`);
				return;
			end

			for k, v in pairs(properties) do
				public[k] = v;
			end
			
			return userdata;
		end;

		function public.__index(_, k)
			if k == "__instance" then
				error(`{k} is not a valid member of {className}`);
			end

			if public[k] then
				return public[k];
			end
			if private[k] then
				return private[k];
			end

			if baseClass[k] == nil then
				error(`{k} is not a valid member of {className}`);
			end

			return instance and instance[k];
		end;
	
		function public.__newindex(_, k, v)
			if k == "__instance" or k == "Id" or k == "ClassName" then
				error(`Can not modify Instance.{k}.`);
			end

			if baseClass[k] == nil then
				error(`{k} is not a valid member of {className} to set.`);
			end
			
			if instance then
				instance[k] = v;
			end
		end;

		local toStringUserdata = tostring(userdata)
		function public.__tostring(_)
			return (string.gsub(toStringUserdata, "userdata", className));
		end;

		function private.Destroy()
			if private.OnDestroy then
				private.OnDestroy();
			end
			if instance then
				Debugger.Expire(instance);
			end
			ZSharpScript.Instances[id] = nil;
		end

		if RunService:IsStudio() then
			function public.KeyValues()
				local keyValues = {};
				for k, v in pairs(baseClass) do
					keyValues[k] = public[k] or private[k] or instance and instance[k];
				end
				
				return keyValues;
			end
		end

		if instance and instance.Destroying then
			instance.Destroying:Connect(function()
				userdata:Destroy();
			end)
		end

		public.__metatable = "The metatable is locked";
		
		ZSharpScript.Instances[id] = userdata;
		return userdata;

	end;
end

return ZSharp;