local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local Markers = {};

local RunService = game:GetService("RunService");
local localplayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local markerIconTemplate = script:WaitForChild("MarkerIcon");
local markersGui = script:WaitForChild("MarkersGui");

local interactables = workspace.Interactables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

Markers.MarkerTypes = {
	Waypoint = 1;
	Object = 2;
	Player = 3;
	Npc = 4;
	Travel = 5;
}

Markers.Colors = {
	Orange = Color3.fromRGB(255, 106, 0);
	Yellow = Color3.fromRGB(255, 219, 79);
	Green = Color3.fromRGB(21, 178, 39);
	Blue = Color3.fromRGB(22, 198, 221);
	Purple = Color3.fromRGB(97, 23, 209);
	Pink = Color3.fromRGB(214, 21, 133);
};

Markers.List = {};

--== Script;
function Markers.GetMarker(id)
	if id == nil then return end;
	for a=1, #Markers.List do
		if Markers.List[a].Id == id then
			return Markers.List[a], a;
		end
	end
end

function Markers.SetMarker(id, target, label, markType)
	if markType == nil then Debugger:Warn("Missing marker type"); return end;
	local icon = Markers.GetMarker(id)
	if icon == nil then
		local valid = false;
		if markType == Markers.MarkerTypes.Waypoint then
			valid = typeof(target) == "Vector3";
			if not valid then
				Debugger:Log("Marker id(",id,") is not valid for Markers.MarkerTypes.Waypoint ",typeof(target));
			end
			
		elseif markType == Markers.MarkerTypes.Npc or markType == Markers.MarkerTypes.Object then
			if typeof(target) == "Instance" and target:IsA("Model") then
				target = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart");
			end
			
			valid = typeof(target) == "Instance" and target:IsA("BasePart");
			if not valid then
				Debugger:Log("Marker id(",id,") is not valid for Markers.MarkerTypes.Player/Npc/Object ",typeof(target));
			end
			
		elseif markType == Markers.MarkerTypes.Travel or markType == Markers.MarkerTypes.Player then
			valid = typeof(target) == "string";
		end
		if valid then
			Debugger:Log("Creating marker id(",id,")");
			local icon = markerIconTemplate:Clone();
			local mouseSense = icon:WaitForChild("MouseSense");
			icon.Name = id;
			icon.Visible = false;
			icon.Parent = markersGui;
			
			mouseSense.MouseMoved:Connect(function()
				icon.Label.Visible = true;
			end)
			mouseSense.MouseLeave:Connect(function()
				icon.Label.Visible = false;
			end)
			
			table.insert(Markers.List, {
				Id=id;
				Icon=icon; 
				Type=markType;
				Label=label;
				Target=target;
			});
		end
	else
		Markers.SetTarget(id, target, markType);
		Markers.SetLabel(id, label);
	end
end

function Markers.SetTarget(id, target, markType)
	if id == nil then return end;
	local markerTable = Markers.GetMarker(id);
	if markerTable then
		markerTable.Type = markType;
		markerTable.Target = target;
	end
end

function Markers.SetLabel(id, label)
	if id == nil then return end;
	local markerTable = Markers.GetMarker(id);
	if markerTable then
		markerTable.Label = label;
	end
end

function Markers.SetColor(id, color)
	if id == nil then return end;
	local markerTable = Markers.GetMarker(id);
	if markerTable then
		local markIcon = markerTable.Icon;
		if markIcon then
			markIcon.ImageColor3 = typeof(color) == "Color3" and color or typeof(color) == "string" and Markers.Colors[color] or Color3.fromRGB(255, 255, 255);
		end
	end
end

function Markers.GetIconInstance(id)
	if id == nil then return end;
	local markerTable = Markers.GetMarker(id);
	if markerTable then
		local markIcon = markerTable.Icon;
		return markIcon;
	end
end

function Markers.ClearMarker(id)
	if id == nil then return end;
	local markerTable, i = Markers.GetMarker(id);
	if markerTable then
		markerTable.Icon:Destroy();
		table.remove(Markers.List, i);
	end
end

function findClosestBorderPoint(x,y)
	local Screen = camera.ViewportSize;
    x = Screen.X - x
    y = Screen.Y - y
    local distanceToYBorder = math.min(y,Screen.Y-y)
    local distanceToXBorder = math.min(x,Screen.X-x)
    if distanceToYBorder < distanceToXBorder then
        if y < (Screen.Y - y) then
            return math.clamp(x,0,Screen.X),0
        else
            return math.clamp(x,0,Screen.X),Screen.Y
        end
    else
        if x < (Screen.X - x) then
            return 0,math.clamp(y,0,Screen.Y)
        else
            return Screen.X,math.clamp(y,0,Screen.Y)
        end
    end
end

if RunService:IsClient() then
	markersGui.Parent = localplayer.PlayerGui;
	RunService.RenderStepped:Connect(function()
		local vpHalfX, vpHalfY = camera.ViewportSize.X/2, camera.ViewportSize.Y/2;
		local viewportMinX = camera.ViewportSize.X*0.05;
		local viewportMaxX = camera.ViewportSize.X - viewportMinX;
		local viewportMinY = camera.ViewportSize.Y*0.125;
		local viewportMaxY = camera.ViewportSize.Y - viewportMinY;
		
		for a=1, #Markers.List do
			local markTable = Markers.List[a];
			local markType = markTable.Type;
			local markTarget = markTable.Target;
			local markIcon = markTable.Icon;
			local markLabel = markTable.Label;
			
			local pointPos;
			
			if markType == Markers.MarkerTypes.Waypoint and typeof(markTarget) == "Vector3" then
				pointPos = markTarget;
				
			elseif markType == Markers.MarkerTypes.Npc and typeof(markTarget) == "Instance" and markTarget:IsA("BasePart") then
				pointPos = markTarget.Position + Vector3.new(0, 5.2, 0);
				
			elseif markType == Markers.MarkerTypes.Object and typeof(markTarget) == "Instance" and markTarget:IsA("BasePart") then
				if markTarget:IsDescendantOf(workspace) then
					pointPos = markTarget.Position;
				end
				
			elseif markType == Markers.MarkerTypes.Player and game.Players:FindFirstChild(markTarget) then
				local player = game.Players[markTarget];
				if player and player.Character and player.Character.PrimaryPart then
					pointPos = player.Character.PrimaryPart.Position + Vector3.new(0, 5.2, 0);
				end
			elseif markType == Markers.MarkerTypes.Travel and typeof(markTarget) == "string" then
				local objs = interactables:GetChildren();
				local list = {};
				for a=1, #objs do
					if objs[a].Name == "Travel_"..markTarget then
						table.insert(list, objs[a]);
					end
				end
				local distance = math.huge;
				for a=1, #list do
					local dist = localplayer:DistanceFromCharacter(list[a].Position);
					if dist <= distance then
						distance = dist;
						pointPos = list[a].Position;
					end
				end
				if #list <= 0 then
					local linkedWorlds = modBranchConfigs.LinkedWorlds[markTarget];
					if linkedWorlds then
						markTarget = nil;
						for _, linked in pairs(linkedWorlds) do
							
							local list = {};
							for a=1, #objs do
								if objs[a].Name == "Travel_"..linked then
									table.insert(list, objs[a]);
								end
							end
							if #list > 0 then
								local distance = math.huge;
								for a=1, #list do
									local dist = localplayer:DistanceFromCharacter(list[a].Position);
									if dist <= distance then
										distance = dist;
										pointPos = list[a].Position;
									end
								end
								break;
							end
						end
					else
						pointPos = nil;
					end
				end
			end
			
			if pointPos then
				local screenPoint, onScreen = camera:WorldToViewportPoint(pointPos);
				
				markIcon.Label.Text = markLabel;
				
				if screenPoint.Z >= 0 then
					screenPoint = Vector2.new(
						screenPoint.X < 0 and 0 or screenPoint.X > camera.ViewportSize.X and camera.ViewportSize.X or screenPoint.X,
						screenPoint.Y < 0 and 0 or screenPoint.Y > camera.ViewportSize.Y and camera.ViewportSize.Y or screenPoint.Y
					);
				else
					screenPoint = Vector2.new(findClosestBorderPoint(screenPoint.X, screenPoint.Y));
				end
				
				local isVisible = true;
				if onScreen then
					local distance = localplayer:DistanceFromCharacter(pointPos);
					if distance < 6000 then
						markIcon.Distance.Text = math.ceil(distance).."u";
						markIcon.Distance.Visible = true;

						markIcon.Image = "rbxassetid://4336384617";
					else
						isVisible = false;
					end
				else
					markIcon.Distance.Visible = false;
					markIcon.Label.Visible = false;
					
					markIcon.Image = "rbxassetid://4339194475";
				end
				
				local newPosition = UDim2.new(0, math.clamp(screenPoint.X, viewportMinX, viewportMaxX),
					0, math.clamp(screenPoint.Y, viewportMinY, viewportMaxY));
				markIcon.Position = newPosition;
				
				markIcon.Visible = isVisible;
			else
				markIcon.Visible = false;
			end
		end
	end)
end

return Markers;