local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--

--
local ZSharp = {};

function ZSharp.Load(ZSharpScript, zEnv)
	zEnv.ZInstance = ZSharpScript.ZInstance;
	zEnv.new = ZSharpScript.newZInstance;
end

function ZSharp.Init(ZSharpScript)
	local Classes = {};
	ZSharpScript.Classes = Classes;
	local InstanceLink = {};
	ZSharpScript.InstanceLink = InstanceLink;
	
	
	local ZInstanceMeta = {};
	ZInstanceMeta.__index = ZInstanceMeta;
	ZInstanceMeta.__metatable = "The metatable is locked";

	ZInstanceMeta.hintGet = "Get an existing instance.";
	ZInstanceMeta.descGet= [[Get an existing instance by name.
		<b>ZInstance:Get</b>(name: <i>string</i>): <i>ZInstance</i>
	]];

	ZInstanceMeta.hintList = "Get a list of instances.";
	ZInstanceMeta.descList = [[Get a list of instances by name or matching name patterns.
		if search is false, pattern is be used to matche instances name. 
		if search is true, pattern will be used in string.match to match instance names.
		<b>ZInstance:List</b>(pattern: <i>string?</i>, search: boolean?): <i>ZInstance</i>
	]];
	
	local ZInstance = setmetatable({}, ZInstanceMeta);
	ZInstance.ClassName = "ZInstance";
	ZInstance.ClassList = {};
	
	function ZInstance:Get(name: string)
		for obj, inst in pairs(ZSharpScript.Instances) do
			if obj.Name == name then
				return obj;
			end
		end
		return nil;
	end
	
	function ZInstance:List(pattern: string?, search: boolean?)
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
	
	function ZInstance:DestroyList(pattern: string, search: boolean)
		local r = self:List(pattern, search);
		for a=1, #r do
			r[a]:Destroy();
		end
	end
	
	---
	local ZSound = {
		ClassName = "ZSound";
		SoundId = "";
		Volume = 0.5;
		PlaybackSpeed = 1;
		
		Play = function(instance: Sound)
			instance:Play();
		end;
		Stop = function(instance: Sound)
			instance:Stop();
		end;
	};
	
	ZSharpScript.Classes.ZSound = ZSound;

	function InstanceLink.ZSound(sound: Sound)
		if sound == nil then
			sound = Instance.new("Sound");
		end
		return sound;
	end
	
	
	---
	for key, _ in pairs(ZSharpScript.Classes) do
		local proxy = newproxy(true);
		local meta = getmetatable(proxy);
		meta.__metatable = "The metatable is locked";
		meta.ClassName = key;
		
		ZInstance.ClassList[key] = proxy;
	end
	
	
	ZSharpScript.ZInstance = ZInstance;
	ZSharpScript.newZInstance = function(className: string, instance: Instance)
		if className == nil then
			error("Missing class name for new()");
		end
		if ZSharpScript.Classes[className] == nil then
			error("Class name does not exist for new(".. className ..")");
		end
		if getfenv(1).Instance == nil and instance then
			instance = nil;
			Debugger:Warn("Attempt to preset Instance");
		end
		ZSharpScript.InstanceCounter = ZSharpScript.InstanceCounter+1;
		
		local class = ZSharpScript.Classes[className];
		instance = InstanceLink[className](instance);
		
		local new = newproxy(true);
		local meta = getmetatable(new);
		local private = {
			ClassName = className;
			Name = className.."#"..ZSharpScript.InstanceCounter;
		};
		
		meta.__metatable = "The metatable is locked";
		
		--for k, v in pairs(class) do
		--	private[k] = v;
		--end
		for k, func in pairs(class) do
			if typeof(func) ~= "function" then continue end;
			
			private[k] = function(...)
				return func(instance, ...);
			end
		end
		
		function private.Destroy()
			Debugger.Expire(instance, 0);
			ZSharpScript.Instances[new] = nil;
		end
		
		
		function meta.__index(_, k)
			local class = ZSharpScript.Classes[private.ClassName];
			
			if private[k] then
				return private[k];
			end
			if class[k] == nil then
				error(k.." is not a valid member of "..class.ClassName);
			end

			return instance[k];
		end;

		function meta.__newindex(_, k, v)
			local class = ZSharpScript.Classes[private.ClassName];
			if class[k] == nil then
				error(k.." is not a valid member of "..class.ClassName);
			end
			if k == "Id" or k == "ClassName" then
				error("Can not modify Instance ".. k ..".");
			end
			
			instance[k] = v;
		end;

		function meta.__tostring(_)
			return private.ClassName;
		end;

		function meta.__call(_, ...)
			local properties = ...;

			if typeof(properties) ~= "table" then
				error("Invalid initialize for ".. private.ClassName);
				return;
			end

			for k, v in pairs(properties) do
				new[k] = v;
			end
			
			return new;
		end;
		
		instance.Destroying:Connect(function()
			new:Destroy();
		end)
		ZSharpScript.Instances[new] = instance;
		return new;
	end;
end

return ZSharp;