
return {
	keyword = {
		["and"] = true,
		["break"] = true,
		["do"] = true,
		["else"] = true,
		["elseif"] = true,
		["end"] = true,
		["false"] = true,
		["for"] = true,
		["function"] = true,
		["if"] = true,
		["in"] = true,
		["local"] = true,
		["nil"] = true,
		["not"] = true,
		["while"] = true,
		["or"] = true,
		["repeat"] = true,
		["return"] = true,
		["then"] = true,
		["true"] = true,
		["self"] = true,
		["until"] = true,
		["continue"] = true,
		["export"] = true,
	},

	builtin = {
		-- Lua Functions
		["assert"] = false,
		["collectgarbage"] = false,
		["error"] = false,
		["getfenv"] = true,
		["getmetatable"] = false,
		["ipairs"] = true,
		["loadstring"] = false,
		["newproxy"] = false,
		["next"] = true,
		["pairs"] = true,
		["pcall"] = true,
		["print"] = true,
		["rawequal"] = false,
		["rawget"] = false,
		["rawset"] = false,
		["select"] = true,
		["setfenv"] = false,
		["setmetatable"] = false,
		["tonumber"] = true,
		["tostring"] = true,
		["type"] = false,
		["unpack"] = true,
		["xpcall"] = false,

		-- Lua Variables
		["_G"] = false,
		["_VERSION"] = false,

		-- Lua Tables
		["bit32"] = false,
		["coroutine"] = false,
		["debug"] = false,
		["math"] = true,
		["os"] = false,
		["string"] = true,
		["table"] = true,
		["utf8"] = false,

		-- Roblox Functions
		["delay"] = false,
		["elapsedTime"] = false,
		["gcinfo"] = false,
		["require"] = false,
		["settings"] = false,
		["spawn"] = false,
		["tick"] = true,
		["time"] = false,
		["typeof"] = true,
		["UserSettings"] = false,
		["wait"] = false,
		["warn"] = false,
		["ypcall"] = false,

		-- Roblox Variables
		["Enum"] = true,
		["game"] = false,
		["shared"] = false,
		["script"] = false,
		["workspace"] = false,
		["plugin"] = false,

		-- Roblox Tables
		["Axes"] = false,
		["BrickColor"] = false,
		["CatalogSearchParams"] = false,
		["CellId"] = false,
		["CFrame"] = true,
		["Color3"] = false,
		["ColorSequence"] = false,
		["ColorSequenceKeypoint"] = false,
		["DateTime"] = false,
		["DockWidgetPluginGuiInfo"] = false,
		["Faces"] = false,
		["File"] = false,
		["FloatCurveKey"] = false,
		["NumberRange"] = false,
		["NumberSequence"] = false,
		["NumberSequenceKeypoint"] = false,
		["OverlapParams"] = false,
		["PathWaypoint"] = false,
		["PhysicalProperties"] = false,
		["PluginDrag"] = false,
		["Random"] = true,
		["Ray"] = false,
		["RaycastParams"] = false,
		["Rect"] = false,
		["Region3"] = false,
		["Region3int16"] = false,
		["RotationCurveKey"] = false,
		["task"] = true,
		["TextChatMessageProperties"] = false,
		["TweenInfo"] = false,
		["UDim"] = false,
		["UDim2"] = false,
		["Vector2"] = true,
		["Vector2int16"] = false,
		["Vector3"] = false,
		["Vector3int16"] = true,
		
		--ZSharp custom builtin;
		["new"] = true;
		["log"] = true;
		["help"] = true;

		["ScriptName"] = true;
		["Instance"] = true;
		["Sound"] = true;
		["Player"] = true;
		["Signal"] = true;
		["Terminal"] = true;
		["Thread"] = true;

		["Audio"] = true;
		["EventService"] = true;
		["TweenService"] = true;
	},

	libraries = {

		-- Lua Libraries
		math = {
			abs = true,
			acos = true,
			asin = true,
			atan = true,
			atan2 = true,
			ceil = true,
			clamp = true,
			cos = true,
			cosh = true,
			deg = true,
			exp = true,
			floor = true,
			fmod = true,
			frexp = true,
			ldexp = true,
			log = true,
			log10 = true,
			max = true,
			min = true,
			modf = true,
			noise = true,
			pow = true,
			rad = true,
			random = true,
			round = true,
			sinh = true,
			sqrt = true,
			tan = true,
			tanh = true,
			sign = true,
			sin = true,
			randomseed = true,

			huge = true,
			pi = true,
		},

		string = {
			byte = true,
			char = true,
			find = true,
			format = true,
			gmatch = true,
			gsub = true,
			len = true,
			lower = true,
			match = true,
			pack = true,
			packsize = true,
			rep = true,
			reverse = true,
			split = true,
			sub = true,
			unpack = true,
			upper = true,
		},

		table = {
			clear = true,
			concat = true,
			foreach = true,
			foreachi = true,
			freeze = true,
			getn = true,
			insert = true,
			isfrozen = true,
			maxn = true,
			remove = true,
			sort = true,
			find = true,
			pack = true,
			unpack = true,
			move = true,
			create = true,
		},

		debug = {
			dumpheap = true,
			info = true,
			profilebegin = true,
			profileend = true,
			resetmemorycategory = true,
			setmemorycategory = true,
			traceback = true,
		},

		os = {
			time = true,
			date = true,
			difftime = true,
			clock = true,
		},

		coroutine = {
			create = true,
			isyieldable = true,
			resume = true,
			running = true,
			status = true,
			wrap = true,
			yield = true,
		},

		bit32 = {
			arshift = true,
			band = true,
			bnot = true,
			bor = true,
			btest = true,
			bxor = true,
			countlz = true,
			countrz = true,
			extract = true,
			lrotate = true,
			lshift = true,
			replace = true,
			rrotate = true,
			rshift = true,
		},

		utf8 = {
			char = true,
			codepoint = true,
			codes = true,
			graphemes = true,
			len = true,
			nfcnormalize = true,
			nfdnormalize = true,
			offset = true,

			charpattern = true,
		},

		-- Roblox Libraries
		Axes = {
			new = true,
		},

		BrickColor = {
			new = true,
			New = true,
			Random = true,
			Black = true,
			Blue = true,
			DarkGray = true,
			Gray = true,
			Green = true,
			Red = true,
			White = true,
			Yellow = true,
			palette = true,
			random = true,
		},

		CatalogSearchParams = {
			new = true,
		},

		CellId = {
			new = true,
		},

		CFrame = {
			new = true,
			Angles = true,
			fromAxisAngle = true,
			fromEulerAnglesXYZ = true,
			fromEulerAnglesYXZ = true,
			fromMatrix = true,
			fromOrientation = true,
			lookAt = true,
			
			identity = true,
		},

		Color3 = {
			new = true,
			fromRGB = true,
			fromHSV = true,
			fromHex = true,
			toHSV = true,
		},

		ColorSequence = {
			new = true,
		},

		ColorSequenceKeypoint = {
			new = true,
		},

		DateTime = {
			now = true,
			fromIsoDate = true,
			fromLocalTime = true,
			fromUniversalTime = true,
			fromUnixTimestamp = true,
			fromUnixTimestampMillis = true,
		},

		DockWidgetPluginGuiInfo = {
			new = true,
		},

		Faces = {
			new = true,
		},

		FloatCurveKey = {
			new = true,
		},

		Instance = {
			new = true,
		},

		NumberRange = {
			new = true,
		},

		NumberSequence = {
			new = true,
		},

		NumberSequenceKeypoint = {
			new = true,
		},

		OverlapParams = {
			new = true,
		},

		PathWaypoint = {
			new = true,
		},

		PhysicalProperties = {
			new = true,
		},

		PluginDrag = {
			new = true,
		},

		Random = {
			new = true,
		},

		Ray = {
			new = true,
		},

		RaycastParams = {
			new = true,
		},

		Rect = {
			new = true,
		},

		Region3 = {
			new = true,
		},

		Region3int16 = {
			new = true,
		},

		RotationCurveKey = {
			new = true,
		},

		task = {
			wait = true,
			spawn = true,
			delay = true,
			defer = true,
			synchronize = true,
			desynchronize = true,
		},

		TweenInfo = {
			new = true,
		},

		UDim = {
			new = true,
		},

		UDim2 = {
			new = true,
			fromScale = true,
			fromOffset = true,
		},

		Vector2 = {
			new = true,
			
			one = true,
			zero = true,
			xAxis = true,
			yAxis = true,
		},

		Vector2int16 = {
			new = true,
		},

		Vector3 = {
			new = true,
			fromAxis = true,
			fromNormalId = true,
			FromAxis = true,
			FromNormalId = true,
			
			one = true,
			zero = true,
			xAxis = true,
			yAxis = true,
			zAxis = true,
		},

		Vector3int16 = {
			new = true,
		},
	},
}