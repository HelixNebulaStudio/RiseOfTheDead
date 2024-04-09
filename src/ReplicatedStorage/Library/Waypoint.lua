local PathfindingService = game:GetService("PathfindingService");
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local Waypoint = {};
local waypointPrefab = script:WaitForChild("WaypointPrefab");

local waypointsFolder = Instance.new("Folder");
waypointsFolder.Name = "Waypoints";
waypointsFolder.Parent = workspace.CurrentCamera;

local waypointInstances = {};
--== Script;

function Waypoint.NewWaypoint(startObject, endObject, completeFunc, onDistanceChanged)
	local path = PathfindingService:CreatePath({AgentRadius=2; AgentHeight=3;});
	local destroy = false; local completed = false;
	spawn(function()
		local prevStartPosition = Vector3.new();
		local prevEndPosition = Vector3.new();
		while not destroy and startObject and startObject:IsDescendantOf(workspace) and endObject:IsDescendantOf(workspace) do
			if waypointsFolder.Parent ~= workspace.CurrentCamera then
				waypointsFolder.Parent = workspace.CurrentCamera;
			end
			
			if not modConfigurations.DisableWaypointers then
				local startPosition = startObject.CFrame.p;
				local endPosition = endObject.CFrame.p;
				local startDistance = (prevStartPosition-startPosition);
				local startPositionChanged = (math.abs(startDistance.X)^2+math.abs(startDistance.Y)^2+math.abs(startDistance.Z)^2) > 16;
				local endDistance = (prevEndPosition-endPosition);
				local endPositionChanged = (math.abs(endDistance.X)^2+math.abs(endDistance.Y)^2+math.abs(endDistance.Z)^2) > 16;
				if startPositionChanged or endPositionChanged then
					prevStartPosition = startPosition;
					prevEndPosition = endPosition;
					path:ComputeAsync(startPosition, endPosition);
					for a=1, #waypointInstances do
						if waypointInstances[a] then waypointInstances[a]:Destroy(); end;
					end
					waypointInstances = {};
					if path.Status == Enum.PathStatus.Success then
						local waypoints = path:GetWaypoints();
						for a=1, #waypoints do
							if a ~= 1 and a ~= #waypoints then
								local new = waypointPrefab:Clone();
								new.Parent = waypointsFolder;
								new.CFrame = CFrame.new(waypoints[a].Position-Vector3.new(0, 0.5, 0), waypoints[a+1].Position-Vector3.new(0, 0.5, 0));
								table.insert(waypointInstances, new);
							end
						end
					end
				end
				
				if onDistanceChanged then
					local distanceFromEnd = (startPosition-endPosition)
					onDistanceChanged(distanceFromEnd.Magnitude);
				end
			else
				waypointsFolder:ClearAllChildren();
				waypointInstances = {};
			end
			wait(0.2);
		end
		waypointsFolder:ClearAllChildren();
		waypointInstances = {};
		if completeFunc then
			completeFunc(completed);
		end
	end);
	
	local methods = {};
	function methods.Cancel()
		destroy = true;
	end
	
	modConfigurations.OnChanged("DisableWaypointers", function(oldValue, value)
		if value then
			waypointsFolder:ClearAllChildren();
			waypointInstances = {};
		end
	end)
	return methods;
end

return Waypoint;