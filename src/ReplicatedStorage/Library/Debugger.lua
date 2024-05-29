--[[
	--== Summary
	Debugger Debugger.new( String name )
	void Debugger:Log( Tuple ... )
	void Debugger:Warn( Tuple ... )
	void Debugger:Print( Tuple ... )
	String Debugger:FormatTable( Table t )
	void Debugger:Display( Table data, Table whitelist )
	BasePart Debugger:Ray( Ray ray , Vector3 rayHit , Vector3 rayPoint , Vector3 rayNormal)
]]

--== Configurations;
local TupleSeperator = " "; -- Try: "/" "\t" "\n"

--== Script;
local Print=print; local Warn=warn; local String=tostring; local Type=typeof; local Pairs=pairs; local random = Random.new(); local Http = game:GetService("HttpService"); local RunService = game:GetService("RunService"); local TextService = game:GetService("TextService");
local GuiDataRemote; local ClientLogRemote; local ClientReadyBind; local IsClientReady = false; local rayInfo, rayInstance; local colorsList = {Color3.fromRGB(196, 40, 28); Color3.fromRGB(13, 105, 172); Color3.fromRGB(245, 205, 48); Color3.fromRGB(75, 151, 75); Color3.fromRGB(170, 0, 170); Color3.fromRGB(218, 133, 65); Color3.fromRGB(18, 238, 212);};
local Debugger = {}; 
Debugger.__index = Debugger;


Debugger.ClientFps = 60;
Debugger.AcquirerModule = nil;
Debugger.DevId = 16170943;
Debugger.Friends = {};

local function concat(c, useKey, level)
	level = level or 0;
	if level > 4 then return tostring(c) end;
	
	local d="";
	local index = 1;
	for i, b in Pairs(c) do
		local bName;
		pcall(function() 
			if typeof(b) == "Instance" then
				bName = b.Name; 
			end
		end)
		d=d..(index==1 and "" or (TupleSeperator or " "))..(useKey and (
			Type(i) == "string" and '"'..i..'"' or String(i))..":" or "")..(
			Type(b)=="table" and "{"..concat(b, true, level+1).."}" or 
			Type(b)=="boolean" and String(b) or 
			Type(b)=="userdata" and ((bName or typeof(b)).." "..String(b)) or 
			String(b or "nil"))
		index = index +1;
	end;
	return d;
end

function Debugger.AwaitShared(key)
	local awaitStart = tick();
	local c = 0;
	while shared[key] == nil do
		task.wait();
		if tick()-awaitStart >= 10 then
			awaitStart = tick();
			c = c +1;
			Debugger:Warn("AwaitShared", key, c);
		end
	end
end

function Debugger.Expire(obj: Instance, t: number?)
	if obj == nil or typeof(obj) ~= "Instance" then return end;
	task.delay(t or 0, function()
		if game:IsAncestorOf(obj) then
			obj:Destroy();
		end
	end)
end

--[[**
	Requires modules with timeout;
	@param module ModuleScript
**--]]
local requireCache = {};
local requireCount = 0;
function Debugger:Require(module, printStat)
	local moduleName = module.Name;
	local printLoadLoaded = script:GetAttribute("PrintOnRequire") == true;
	
	local requireTimeLapsed;
	local successful = false;
	
	local s, e;
	if requireCache[moduleName] == nil then
		local debugTracing = debug.traceback();
		delay(5, function()
			if not successful then
				self:Warn("Module("..module.Name..") require timed out. ".. (not s and e or ""),"\n",debugTracing);
			end 
		end)
	end
	
	local r;
	s, e = pcall(function()
		local sTick = tick();
		r = require(module);
		successful = true;
		requireTimeLapsed = tick()-sTick;

		if printStat and module:GetAttribute("Debug") == true then
			Debugger:Log(self.Name, " (",module.Name,") loaded. Took: ".. math.round((tick()-sTick)*1000)/1000 .." s");
		end
	end)
	--if not s then
	--	task.spawn(function()
	--		error(module.Name..">> "..e);
	--	end)
	--end
	
	if requireCache[moduleName] == nil then
		requireCache[moduleName] = {LoadTime=requireTimeLapsed;};
		requireCount = requireCount +1;
		
		if self.Script and printLoadLoaded then
			--if not self.Script:IsA("ModuleScript") then
			if RunService:IsStudio() then
				print("[Studio] :Require-".. requireCount..">>  "..moduleName);
			end
			--end
		end
	end
	
	return r;
end

function Debugger.PrintLoadTimes()
	local sortList = {};
	for srcName, data in pairs(requireCache) do
		if data.LoadTime <= 0.005 then continue end;
		table.insert(sortList, {Name=srcName; Time=data.LoadTime;});
	end
	table.sort(sortList, function(a, b) return a.Time > b.Time; end);
	
	local str = "Sorted Load Times:";
	for a=1, #sortList do
		local item = sortList[a];
		str = str.."\n"..a..": ".. item.Name .. " (".. math.round(item.Time * 1000)/1000 .."s)";
	end
	print(str);
end

--[[**
	Enable Debugger on to script.
	@param name string
	
	Name of the script or name of the output title.
	@returns Debugger
	
	Returns Debugger instance with properties Name and Disabled. Setting "Debugger.Disabled = true" will disable logging.
**--]]
function Debugger.new(src)
	if typeof(src) == "string" then
		warn("Deprecated parameter: "..debug.traceback())
	end
	
	local srcName = tostring(src);
	
	local self = {
		Name=srcName; 
		Script=(typeof(src) == "Instance" and src or nil); 
		Disabled=true;
	};
	
	if Debugger.AcquirerModule == nil then
		Debugger.AcquirerModule = src;
	end
	
	return setmetatable(self, Debugger);
end

--[[**
	Visualize a ray. If rayHit is nil, the shown ray will be greyed out.
	@param ray Ray
	
	Ray object. (e.g. Ray.new());
	@param rayHit BasePart
	
	The object the ray hits. (Optional)
	@param rayPoint Vector3
	
	The end point of the ray. (Optional)
	@param rayNormal Vector3
	
	The normal of the end point of the ray. (Optional)
**--]]
function Debugger:Ray(ray, rayHit, rayPoint, rayNormal)
	if rayInstance == nil then
		local A = Instance.new("Part"); A.Name = "A";
		A.Anchored = true;
		A.CanCollide = false;
		A.Material = Enum.Material.Neon;
		A.TopSurface = Enum.SurfaceType.Smooth;
		A.BottomSurface = Enum.SurfaceType.Smooth;
		A.Locked = true;
		A.Size = Vector3.new(0.2, 0.2, 0.2);
		A.Shape = Enum.PartType.Ball;
		local B = Instance.new("Part"); B.Name = "B";
		B.Anchored = true;
		B.CanCollide = false;
		B.Material = Enum.Material.Neon;
		B.TopSurface = Enum.SurfaceType.Smooth;
		B.BottomSurface = Enum.SurfaceType.Smooth;
		B.Locked = true;
		B.Size = Vector3.new(0.4, 0.4, 0.1);
		--B.Shape = Enum.PartType.Cylinder;
		B.Parent = A;
		local C = Instance.new("Part"); C.Name = "C";
		C.Anchored = true;
		C.CanCollide = false;
		C.Material = Enum.Material.Neon;
		C.TopSurface = Enum.SurfaceType.Smooth;
		C.BottomSurface = Enum.SurfaceType.Smooth;
		C.Locked = true;
		--C.Shape = Enum.PartType.Cylinder;
		C.Parent = B;
		A.Parent = script;
		rayInstance = A;
	end
	if rayInfo == nil then
		rayInfo = script:FindFirstChild("RayDebug");
		if rayInfo == nil then
			rayInfo = Instance.new("BillboardGui");
			rayInfo.Parent = script;
			rayInfo.AlwaysOnTop = true;
			rayInfo.Name = "RayDebug";
			rayInfo.Size = UDim2.new(2, 0, 0.6, 0);
			local infoTag = Instance.new("TextLabel");
			infoTag.Name = "InfoTag";
			infoTag.Parent = rayInfo;
			infoTag.BackgroundTransparency = 1;
			infoTag.Size = UDim2.new(1, 0, 1, 0);
			infoTag.TextColor3 = Color3.fromRGB(255, 255, 255);
			infoTag.TextSize = 14;
			infoTag.TextStrokeTransparency = 0.5;
			infoTag.TextXAlignment = Enum.TextXAlignment.Center;
			infoTag.TextYAlignment = Enum.TextYAlignment.Center;
		end
	end
	if ray then
		local rayA = rayInstance:Clone();
		local rayB = rayA:WaitForChild("B");
		local rayC = rayB:WaitForChild("C");
		
		local rayOrigin, rayDirection = ray.Origin, ray.Direction;
		rayA.CFrame = CFrame.new(rayOrigin);
		if rayPoint == nil then rayPoint = rayOrigin+rayDirection; end
		rayB.CFrame = CFrame.new(rayPoint, rayPoint+(rayNormal or Vector3.new()));
		
		local distance = (rayPoint-rayOrigin).Magnitude;
		rayC.Size = Vector3.new(0.06, 0.06, distance);
		rayC.CFrame = CFrame.new(rayPoint-(rayPoint-rayOrigin)/2, rayPoint);
		
		local hud = rayInfo:Clone();
		local label = hud:WaitForChild("InfoTag");
		label.Text = "Distance: "..math.floor(distance*100+0.5)/100;
		hud.Adornee = rayB;
		hud.Parent = rayB;
		
		if rayHit then
			local color = colorsList[random:NextInteger(1, #colorsList)];
			rayA.Color = color;
			rayB.Color = color;
			rayC.Color = color;
			--rayB.Shape = Enum.PartType.Cylinder;
		else
			local color = Color3.fromRGB(180, 180, 180);
			rayA.Color = color;
			rayB.Color = color;
			rayC.Color = color;
			rayB.Shape = Enum.PartType.Ball;
		end
		rayA.Parent = workspace.CurrentCamera;
		rayA.Archivable = false;
		rayB.Archivable = false;
		rayC.Archivable = false;
		return rayA;
	end
	return;
end

function Debugger:Point(point: CFrame | Vector3, parent)
	local a = Instance.new("Attachment");
	a.WorldCFrame = typeof(point) == "CFrame" and point or CFrame.new(point :: Vector3);
	a.Parent = parent or workspace.Terrain;
	
	return a;
end

function Debugger:PointPart(point: CFrame | Vector3)
	if point then
		local A = Instance.new("Part");
		A.Name = "A";
		A.Anchored = true;
		A.CanCollide = false;
		A.CanQuery = false;
		A.Material = Enum.Material.Neon;
		--A.TopSurface = Enum.SurfaceType.Smooth;
		--A.BottomSurface = Enum.SurfaceType.Smooth;
		--A.Locked = true;
		A.Size = Vector3.new(0.3, 0.3, 0.3);
		A.Shape = Enum.PartType.Ball;
		A.Color = colorsList[random:NextInteger(1, #colorsList)];
		A.CFrame = typeof(point) == "CFrame" and point or CFrame.new(point :: Vector3);
		A.Archivable = false;
		A.Parent = workspace;
		return A;
	end
	return;
end

function Debugger:HudPrint(position, text)
	local att = self:Point(CFrame.new(position) * CFrame.new(math.random(-10,10)/10, math.random(-10,10)/10, math.random(-10,10)/10));
	
	local new = script.HudPrint:Clone();
	local label = new:WaitForChild("textLabel");
	label.Text = text;
	
	new.Parent = att;
	new.Adornee = att;
	
	return att;
end

function Debugger:Region(cframe, size)
	if self:CheckDisable() then return end;
	if cframe and size then
		local A = Instance.new("Part"); A.Name = "A";
		A.Anchored = true;
		A.CanCollide = false;
		A.Material = Enum.Material.SmoothPlastic;
		A.TopSurface = Enum.SurfaceType.Smooth;
		A.BottomSurface = Enum.SurfaceType.Smooth;
		A.Locked = true;
		A.Size = size;
		A.Color = colorsList[random:NextInteger(1, #colorsList)];
		A.CFrame = cframe;
		A.Archivable = false;
		A.Parent = workspace;
		return A;
	end
	return;
end


function Debugger:CheckDisable(highPiority)
	if self.Script == nil then return true; end;
	if highPiority ~= true and self.Script:GetAttribute("Debug") ~= true then return true end;
	return false;
end
--[[
	Log message;
	@param ... Tuple
	
	Message of the log. Example: Debugger:Log("Hello", "Again");
]]
function Debugger:Log(...)
	if self:CheckDisable() then return end;
	local a = (self.Name or script.Name)..">>  ";
	if RunService:IsStudio() then
		local args = {...};
		print(a, unpack(args));
		
	else
		if #{...} <= 0 then
			a=a.."nil"
		else
			a=a..concat({...});
		end;
		Print(a);
		
	end
end

Debugger.Print = Debugger.Log;
function Debugger:StudioLog(...)
	if not RunService:IsStudio() then return end;
	self:Log("[Studio]", ...);
end


--[[
	Log warning;
	@param ... Tuple
	
	Message of the warning. Example: Debugger:Warn("Oh no!", "404");
]]
function Debugger:Warn(...)
	if self:CheckDisable(true) then return end;	
	local a = (self.Name or script.Name)..">>  ";
	if #{...} <= 0 then
		a=a.."nil"
	else
		a=a..concat({...});
	end;
	
	Warn(a);
	
	if RunService:IsClient() then return end;
	if workspace:GetAttribute("IsDev") ~= true then return end;
	
	task.spawn(function()
		local players = {};
		for _, player in pairs(game.Players:GetPlayers()) do
			if Debugger.Friends[player] == nil then
				pcall(function()
					Debugger.Friends[player] = player:IsFriendsWith(Debugger.DevId);
				end)
			end
			if Debugger.Friends[player] == true then
				table.insert(players, player);
			end
		end
		self:WarnClient(players, a);
	end)
end

function Debugger:StudioWarn(...)
	if not RunService:IsStudio() then return end;
	self:Warn("[Studio]", ...);
end

--[[**
	Stringify message;
	@param ... Tuple
	
	Stringify a message.
**--]]
function Debugger:Stringify(...)
	local a = "";
	if #{...} <= 0 then
		a=a.."nil"
	else
		a=a..concat({...});
	end;
	return a;
end

--[[**
	Log warning to client console;
	@param player/table Player or list of players
	
	@param ... Tuple
	
	Message of the warning. Example: Debugger:WarnClient(player/{player; player2}, "Oh no!", "404");
**--]]
function Debugger:WarnClient(players, ...)
	if RunService:IsClient() then Debugger:Log("WarnClient() can only be called by server."); return end;
	if self:IsParallel() then Debugger:Warn("Not called from main thread.", self.Script:GetFullName()); return end;
	
	local tuple = {...};
	spawn(function()
		if not IsClientReady then ClientReadyBind.Event:Wait(); end
		local a = "";
		if #tuple <= 0 then
			a=a.."nil"
		else
			a=a..concat(tuple);
		end;
		
		players = type(players) == "table" and players or {players};
		for _, player in pairs(players) do
			if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent == nil then return end;
			ClientLogRemote:FireClient(player, a);
		end
	end);
end

function Debugger:RefTest(name, data, timeout)
	local ref = setmetatable({data}, {__mode="v"});
	local dbtb = debug.traceback();
	coroutine.wrap(function()
		local d = false;
		for a=0, timeout or 2, 0.1 do
			if ref[1] == nil then
				d = true;
				Debugger:Log("Reference (",name,") GCed.");
				break;
			end
			wait(0.1);
		end
		if not d then
			Debugger:Log("Reference (",name,")", "Still not GCed. Trace:",dbtb);
		end
	end)()
	data = nil;
end

function Debugger:YieldDir(parent, name, timeOut)
	local moduleScript = parent:FindFirstChild(name);
	
	local timeOutTick = tick();
	while moduleScript == nil do
		task.wait();
		moduleScript = parent:FindFirstChild(name);
		if timeOut == nil or tick()-timeOutTick > timeOut then break end;
	end
	
	return moduleScript;
end

--[[**
	Format table into string;
	@param input table
	
	Table that you want to format into a string.
	@returns string
	
	Returns the formatted table in string.
**--]]
function Debugger:FormatTable(input)
	local cache = {};
	local function extract(t, index)
		local syntax = string.rep("    ", index);
		for key, value in pairs(t) do
			if type(value) == "table" then
				table.insert(cache, {Key=syntax..(type(key) == "string" and ('["$Var"]'):gsub("$Var", key) or ('[$Var]'):gsub("$Var", key)); Value="{";});
				extract(value, index+1);
				table.insert(cache, {Key=syntax; Value="}";});
			else
				table.insert(cache, {Key=syntax..key; Value=(value or "nil");});
			end
		end
	end
	local function indentifier(v)
		local r = String(v);
		if type(v) == "string" then
			return ('"$Var"'):gsub("$Var", r);
		elseif type(v) == "boolean" then
			return ("[$Var]"):gsub("$Var", r);
		elseif type(v) == "userdata" then
			return ("($Var)"):gsub("$Var", r);
		end
		return r;
	end
	extract(input, 0);
	local output = "";
	for a=1, #cache do
		local linkSyntax = " = ";
		local key = cache[a].Key;
		local value = cache[a].Value;
		if String(cache[a].Value) == "}" then
			linkSyntax = "";
		elseif String(cache[a].Value) == "{" then
		else
			value = indentifier(cache[a].Value);
		end
		output = output..key..linkSyntax..value.."\n"
	end
	return output;
end

--[[**
	Display debug;
	@param data table
	
	Table of data to display.
	@param whitelist Player/Players
	
	Player or a table of players to display debug data to. Leaving this null will display debug to all players.
**--]]
local UpdateDebuggerGui;
function Debugger:Display(data, whitelist)
	task.defer(function()
		whitelist = whitelist and type(whitelist) ~= "table" and {whitelist} or whitelist;
		if RunService:IsServer() then
			if not IsClientReady then return end;
			if whitelist then
				for a=1, #whitelist do
					if whitelist[a]:IsA("Player") then
						GuiDataRemote:FireClient(whitelist[a], self.Name, data and Http:JSONEncode(data));
					end
				end
			else
				GuiDataRemote:FireAllClients(self.Name, Http:JSONEncode(data));
			end
		else
			UpdateDebuggerGui(self.Name, Http:JSONEncode(data));
		end
	end)
end


function Debugger:TimeTest()
	local timeTest = {
		Tick=tick();
	};
	
	function timeTest.Start()
		timeTest.Tick = tick();
	end
	
	function timeTest.Stop(_, str)
		local timelapse = tick()-timeTest.Tick;
		timelapse = math.round(timelapse*1000)/1000;
		
		if str then
			self:Warn(string.format(str, timelapse));
		end
		return timelapse;
	end
	
	return timeTest;
end


function Debugger:ThreadTest(timeout, id)
	local thread = coroutine.running();
	delay(timeout or 1, function()
		Debugger:Log("Thread Test:",id, coroutine.status(thread));
	end);
end

function Debugger:CFrameLinkPart(targetPart: BasePart)
	local part: Part = self:PointPart(targetPart.CFrame);
	part.Shape = Enum.PartType.Block;
	part.CanQuery = false;
	part.Anchored = false;
	part.Size = Vector3.new(1, 1, 1);
	
	local rootAtt = Instance.new("Attachment");
	rootAtt.Name = "LinkRoot";
	rootAtt.Parent = part;
	
	local alignPosition = Instance.new("AlignPosition");
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment;
	alignPosition.RigidityEnabled = true;
	alignPosition.Attachment0 = rootAtt;
	alignPosition.Parent = part;
	
	local alignOrientation = Instance.new("AlignOrientation");
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment;
	alignOrientation.RigidityEnabled = true;
	alignOrientation.Attachment0 = rootAtt;
	alignOrientation.Parent = part;

	task.spawn(function()
		local active = true;
		
		targetPart.Destroying:Connect(function()
			active = false;
		end)
		
		part.Destroying:Connect(function()
			active = false;
		end)
		
		while active do
			alignPosition.Position = targetPart.CFrame.Position;
			alignOrientation.CFrame = targetPart.CFrame;
			
			RunService.Stepped:Wait();
			if not active then break; end;
		end
		
		part:Destroy();
	end)
	
	return part;
end

function Debugger:IsParallel()
	return self.MainThread ~= true;
end

function Debugger:InitMainThread()
	Debugger.MainThread = true;

	if RunService:IsClient() then
		local fpsCounter, lastTick =0, tick();
		local function getFps()
			fpsCounter = fpsCounter +1;
			local lapse = (tick()-lastTick);
			if lapse >= 1 then
				Debugger.ClientFps = math.floor(fpsCounter / lapse);
				lastTick = tick();
				fpsCounter = 0;
			end
		end
		game:GetService("RunService").Heartbeat:Connect(getFps);
		
		local DebuggerGui = nil;
		local ListFrame = nil;

		local ListSizeMin = Vector2.new(300, 600);
		local ListSizeMax = Vector2.new(1000, 1600);
		UpdateDebuggerGui = function(scriptName, data)
			DebuggerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("DebuggerGui");
			ListFrame = DebuggerGui and DebuggerGui:FindFirstChild("ListFrame");
			if DebuggerGui == nil then
				DebuggerGui = Instance.new("ScreenGui");
				DebuggerGui.Name = "DebuggerGui";
				DebuggerGui.Parent = game.Players.LocalPlayer.PlayerGui;
				DebuggerGui.DisplayOrder = 10;

				ListFrame = Instance.new("ScrollingFrame");
				ListFrame.Name = "ListFrame";
				ListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35);
				ListFrame.BackgroundTransparency = 1;
				ListFrame.BorderSizePixel = 0;
				ListFrame.Position = UDim2.new(0, 50, 0, 50);
				ListFrame.Size = UDim2.new(0, ListSizeMin.X, 0, 0);
				ListFrame.ScrollBarThickness = 2;
				ListFrame.Parent = DebuggerGui;

				local listLayout = Instance.new("UIListLayout");
				listLayout.Padding = UDim.new(0, 10);
				listLayout.Parent = ListFrame;

				local listSizeConstraint = Instance.new("UISizeConstraint");
				listSizeConstraint.MinSize = ListSizeMin;
				listSizeConstraint.MaxSize = ListSizeMax;

				local hintLabel = Instance.new("TextLabel");
				hintLabel.BackgroundTransparency = 1;
				hintLabel.Name = "Hint";
				hintLabel.Size = UDim2.new(0, ListSizeMin.X, 0, 10);
				hintLabel.Position = UDim2.new(0, 60, 0, 35);
				hintLabel.TextColor3 = Color3.fromRGB(35, 35, 35);
				hintLabel.TextXAlignment = Enum.TextXAlignment.Left;
				hintLabel.TextYAlignment = Enum.TextYAlignment.Top;
				hintLabel.Font = Enum.Font.Code;
				hintLabel.TextSize = 10;
				hintLabel.Text = "Debug Log (Press [F2] to hide)"
				hintLabel.Parent = DebuggerGui;

				listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					RunService.Heartbeat:Wait();
					ListFrame.Size = UDim2.new(0, listLayout.AbsoluteContentSize.X, 0, listLayout.AbsoluteContentSize.Y);
					ListFrame.CanvasSize = UDim2.new(0, listLayout.AbsoluteContentSize.X, 0, listLayout.AbsoluteContentSize.Y);
				end)
			end

			if ListFrame then
				local frame = ListFrame:FindFirstChild(scriptName);
				local label = frame and frame:FindFirstChild("Label");
				if frame == nil then
					frame = Instance.new("Frame");
					frame.Name = scriptName;
					frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35);
					frame.BackgroundTransparency = 0.15;
					frame.BorderSizePixel = 0;
					frame.Size = UDim2.new(1, 0, 0, 0);
					frame.Parent = ListFrame;

					local labelPadding = Instance.new("UIPadding");
					labelPadding.PaddingTop = UDim.new(0, 10);
					labelPadding.PaddingLeft = UDim.new(0, 10);
					labelPadding.Parent = frame;

					label = Instance.new("TextLabel");
					label.BackgroundTransparency = 1;
					label.Name = "Label";
					label.Size = UDim2.new(1, 0, 1, 0);
					label.TextColor3 = Color3.fromRGB(255, 255, 255);
					label.TextXAlignment = Enum.TextXAlignment.Left;
					label.TextYAlignment = Enum.TextYAlignment.Top;
					label.Font = Enum.Font.Code;
					label.TextSize = 14;
					label.Parent = frame;
				end

				if label ~= nil then
					if data ~= nil then
						local raw = Http:JSONDecode(data);
						label.Text = Debugger:FormatTable(raw);
						local textBounds = TextService:GetTextSize(label.Text, label.TextSize, label.Font, ListSizeMax);
						frame.Size = UDim2.new(0, textBounds.X+20, 0, textBounds.Y+10);
					else
						frame:Destroy();
						if #ListFrame:GetChildren() <= 1 then
							DebuggerGui.Enabled = false;
						end
					end
				end
			end
		end

		local UserInputService = game:GetService("UserInputService");

		UserInputService.InputBegan:Connect(function(inputObject, eventType)
			if (inputObject.KeyCode == Enum.KeyCode.F2 or inputObject.KeyCode == Enum.KeyCode.F4) and DebuggerGui then
				DebuggerGui.Enabled = not DebuggerGui.Enabled;
			end
		end)

		spawn(function()
			local waitForTick = tick();
			repeat GuiDataRemote = script:FindFirstChild("GuiDataRemote"); until GuiDataRemote ~= nil or tick()-waitForTick >= 5 or not RunService.Heartbeat:Wait();
			if GuiDataRemote then
				GuiDataRemote.OnClientEvent:Connect(UpdateDebuggerGui);
				waitForTick = tick();
			end
			repeat ClientLogRemote = script:FindFirstChild("ClientLogRemote"); until ClientLogRemote ~= nil or tick()-waitForTick >= 5 or not RunService.Heartbeat:Wait();
			if ClientLogRemote then
				Debugger.LogRemote = ClientLogRemote;
				ClientLogRemote.OnClientEvent:Connect(function(message)
					warn("From Server>>  ",message);
					if Debugger:IsParallel() then
						warn("Not MainThread>>", Debugger.AcquirerModule and Debugger.AcquirerModule:GetFullName());
					end
				end);
				ClientLogRemote:FireServer();
			end
		end);
	else
		-- IsServer;
		ClientReadyBind = Instance.new("BindableEvent", script);
		ClientReadyBind.Name = "ClientReady";
		GuiDataRemote = Instance.new("RemoteEvent", script);
		GuiDataRemote.Name = "GuiDataRemote";
		ClientLogRemote = Instance.new("RemoteEvent", script);
		ClientLogRemote.Name = "ClientLogRemote";
		ClientLogRemote.OnServerEvent:Connect(function(player)
			IsClientReady = true;
			ClientReadyBind:Fire();
		end)

		game.Players.PlayerRemoving:Connect(function()
			if RunService:IsStudio() then return end;
			for player, isFriend in pairs(Debugger.Friends) do
				if not game.Players:IsAncestorOf(player) then
					Debugger.Friends[player] = nil;
				end
			end
		end)
	end
end

return Debugger;