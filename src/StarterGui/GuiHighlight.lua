local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local GuiHighlight = {}

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modComponents = require(game.ReplicatedStorage.Library.UI.Components);

local localPlayer = game.Players.LocalPlayer;
local playerGui = localPlayer.PlayerGui;
local mainInterface = playerGui:WaitForChild("MainInterface");

local templateHighlighter = script:WaitForChild("UIHighlight");
local activeHighlighter = nil;

local childConns = {};
local visConns = {};


local function disconnectAllConnections()
	pcall(function() RunService:UnbindFromRenderStep("GuiHighlight"); end)
	
	for obj, objConns in pairs(childConns) do
		for a=1, #objConns.Conns do
			if objConns.Conns[a] then
				objConns.Conns[a]:Disconnect();
			end
		end
	end
	childConns = {};

	for a=1, #visConns do
		if visConns[a] then
			visConns[a]:Disconnect();
		end
	end
	visConns = {};
end

local tweeninfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0);

local frameObjects = {};

local ObjectFrame = {};
ObjectFrame.__index = ObjectFrame;
function ObjectFrame.new(object, size)
	local self = {
		Object=object;
		Size=size;
	}
	
	local frame = Instance.new("Frame");
	frame.AnchorPoint = Vector2.new(0.5, 0.5);
	frame.Visible = false;
	frame.BackgroundTransparency = 1;
	frame.Name = object.Name;
	frame.Parent = mainInterface;
	
	self.Frame = frame;
	
	setmetatable(self, ObjectFrame);
	return self;
end

function ObjectFrame:Update()
	if not self.Object:IsDescendantOf(workspace) then return end
	
	local camera = workspace.CurrentCamera;
	local screenPoint, onScreen = camera:WorldToViewportPoint(self.Object.Position);
	
	if onScreen and screenPoint.Z >= 16 then
		self.Frame.Visible = true;
		self.Frame.Position = UDim2.new(0, screenPoint.X, 0, screenPoint.Y);
		self.Frame.Size = UDim2.new(0, screenPoint.Z, 0, screenPoint.Z);
		
	else
		self.Frame.Visible = false;
	end
	
end

local isBindedFrames = false;
local function refreshGuiObjectFrames()
	if not isBindedFrames then
		isBindedFrames = true;
		RunService:BindToRenderStep("GuiObjectFrames", Enum.RenderPriority.Last.Value, function()
			if #frameObjects <= 0 then
				isBindedFrames = false;
				RunService:UnbindFromRenderStep("GuiObjectFrames");
				return;
			end
			
			for a=#frameObjects, 1, -1 do
				local objectFrame = frameObjects[a];
				if objectFrame.Object:IsDescendantOf(workspace) then
					objectFrame:Update();
				else
					table.remove(frameObjects, a);
				end
			end
		end)
	end
end

function GuiHighlight.FrameWorldObject(object, size)
	table.insert(frameObjects, ObjectFrame.new(object, size));
	refreshGuiObjectFrames();
end

function GuiHighlight.Set(...)
	local player = game.Players.LocalPlayer;
	local playerGui = player.PlayerGui;
	
	disconnectAllConnections();
	local params = {...};
	if #params <= 0 then
		if activeHighlighter then
			activeHighlighter:Destroy();
			activeHighlighter = nil;
		end
		
	else
		local parent = playerGui and playerGui:FindFirstChild(params[1]) or nil;
		if activeHighlighter == nil or activeHighlighter.Parent == nil then activeHighlighter = templateHighlighter:Clone(); end
		
		local interface = {};
		interface.Pages = {};
		
		interface.RefreshAll = function()
			for a=1, #interface.Pages do
				interface.Pages[a].Refresh();
			end
			Debugger:Log("interface.Pages", interface.Pages);
		end

		local function search(page, index, path)
			local directory = page.Directory;

			for a=index, #directory do
				local name = directory[a];
				local guiObject = path and path:FindFirstChild(name) or nil;
				
				if guiObject == nil and name:sub(1,7) == "search:" then
					local searchName = name:sub(8, #name);
					local searchGuiObject = path and path:FindFirstChild(searchName, true) or nil;

					if searchGuiObject then
						name = searchGuiObject.Name;
						directory[a] = name;
						guiObject = searchGuiObject.Parent;
					end
				end

				local parentPath = path;

				if childConns[parentPath] == nil then
					local objConns = {
						Seek={};
						Conns={};
					}
					childConns[parentPath] = objConns;

					table.insert(objConns.Conns, parentPath.ChildAdded:Connect(function(c)
						--task.wait(0.1);

						local seekInfo = objConns.Seek[c.Name];
						if seekInfo then
							--Debugger:Log("Found ", c.Name, "parent",parentPath," ", seekInfo);
							search(seekInfo.Page, seekInfo.Index, parentPath);
						end
					end));
					table.insert(objConns.Conns, parentPath.ChildRemoved:Connect(function(c)
						local seekInfo = objConns.Seek[c.Name];
						if seekInfo then
							search(seekInfo.Page, seekInfo.Index, parentPath);
						end
					end))
				end

				childConns[parentPath].Seek[name] = {Page=page; Index=a;};

				if guiObject then
					if guiObject:IsA("GuiObject") then
						table.insert(visConns, guiObject:GetPropertyChangedSignal("Visible"):Connect(interface.RefreshAll))
						
						page.GuiObjects[a] = guiObject;
						if not guiObject.Visible then page.Visible = false; end;

						if a == #directory then
							page.GuiObject = guiObject;
						end
					end
					path = guiObject;

					interface.RefreshAll();
				else
					break;
				end
			end
		end
		
		local function set(...)
			local page = {Visible=true;};
			
			page.GuiObjects = {};
			page.Directory = {...};
			
			if typeof(page.Directory[#page.Directory]) == "boolean" then
				table.remove(page.Directory, #page.Directory);
				page.Required = true;
			end
			
			page.Refresh = function()
				local v = true;
				
				if page.GuiObject == nil then
					v = false;
					
				else
					for k, guiObj in pairs(page.GuiObjects) do
						if guiObj == nil then continue end

						if guiObj:IsDescendantOf(playerGui) and guiObj:IsA("GuiObject") then
							if not modComponents.IsTrulyVisible(guiObj) then 
								v = false;
								break;
							end;
						else
							page.GuiObjects[k] = nil;
						end
					end
					
				end
				
				page.Visible = v;
			end
			
			--.Set("MainInterface", "Inventory", "MainList", "search:gps", "gps");
			--.Next("MainInterface", "GpsInterface", "ScrollingFrame", "w1office", "guideButton");
			
			table.insert(interface.Pages, page);
			search(page, 1, playerGui);
		end
		
		set(...);
		interface.Next = set;
		
		activeHighlighter.Parent = parent;
		activeHighlighter.ImageColor3 = Color3.fromRGB(130, 20, 20);
		
		if GuiHighlight.HideBackground then
			for _, obj in pairs(activeHighlighter:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj.Visible = false;
				end
			end
		end
		
		TweenService:Create(activeHighlighter, tweeninfo, {ImageColor3=Color3.fromRGB(255, 200, 200)}):Play();
		RunService:BindToRenderStep("GuiHighlight", Enum.RenderPriority.Last.Value, function()
			if activeHighlighter ~= nil then
				local visibleExist = false;
				
				if #interface.Pages > 0 then
					local guiObject = interface.Pages[#interface.Pages].GuiObject;
					local currentObj = guiObject;
					
					if currentObj then
						while currentObj:IsDescendantOf(playerGui) do
							currentObj = currentObj.Parent;

							if currentObj:IsA("ScrollingFrame") then
								local diff = guiObject.AbsolutePosition.Y-currentObj.AbsolutePosition.Y;
								if math.abs(diff) >= 6 then
									currentObj.CanvasPosition = currentObj.CanvasPosition + Vector2.new(0, diff/3);
								end
							end

						end
					end
				end

				for a=1, #interface.Pages do
					if interface.Pages[a].Required == true and not interface.Pages[a].Visible then
						
						for b=1, #interface.Pages do
							if b > a then
								interface.Pages[b].Visible = false;
							end
						end
						
						break;
					end
				end
				
				for a=#interface.Pages, 1, -1 do
					local visible, guiObject = interface.Pages[a].Visible, interface.Pages[a].GuiObject;
					
					if visible and guiObject and guiObject:IsDescendantOf(playerGui) then
						visibleExist = true;
						activeHighlighter.Visible = visible;
						activeHighlighter.Size = UDim2.new(0, guiObject.AbsoluteSize.X+24, 0, guiObject.AbsoluteSize.Y+24);
						activeHighlighter.Position = UDim2.new(0, guiObject.AbsolutePosition.X-12, 0, guiObject.AbsolutePosition.Y+23);
						
						break;
					end
				end
				if not visibleExist then
					activeHighlighter.Visible = false;
				end
			end
		end)
		
		return interface;
	end
end

return GuiHighlight;