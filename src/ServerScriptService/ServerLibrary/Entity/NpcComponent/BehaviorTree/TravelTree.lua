local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);
local modBranchConfigs = Debugger:Require(game.ReplicatedStorage.Library.BranchConfigurations);

local worldNavLink = modBranchConfigs.NavLinks[modBranchConfigs.GetWorld()];

return function(self)
	local tree = modLogicTree.new{
	    Root={"And"; "Travel";};
	}
	
	-- self.CurrentNav
	-- self.TargetNav;
	local cache = {};
	
	tree:Hook("Travel", function()
		self.Prefab:SetAttribute("CurrentNav", self.CurrentNav);
		self.Prefab:SetAttribute("TargetNav", self.TargetNav);
		
		if self.TargetNav and self.CurrentNav ~= self.TargetNav then
			local route = {};
			
			local nextNav;
			local skipCTO = false;
			
			-- Target to outside;
			nextNav = self.TargetNav;
			for a=1, 10 do
				local navInfo = worldNavLink[nextNav];
				
				if navInfo then
					if navInfo.Parent == self.TargetNav then
						skipCTO = true;
						break;
					end
					
					if navInfo.Parent == self.CurrentNav then
						skipCTO = true;
						table.insert(route, nextNav);
						break;
					else
						table.insert(route, nextNav);
					end
					nextNav = navInfo.Parent or "Outside";
				else
					break;
				end
			end
			
			local enterIndex = #route;
			if not skipCTO then
				-- Current to outside;
				nextNav = self.CurrentNav;
				for a=1, 10 do
					local navInfo = worldNavLink[nextNav];
					
					if navInfo then
						if navInfo.Parent == self.TargetNav then
							break;
						else
							table.insert(route, enterIndex+1, nextNav);
						end
						nextNav = navInfo.Parent or "Outside";
					else
						break;
					end
					
					if navInfo == nil or navInfo.Parent == self.TargetNav then
						break;
					end
				end
			end
			
			local navId = route[#route];
			local nav = worldNavLink[navId];
			
			if navId == nil then
				self.CurrentNav = nextNav;
				
			else
				local isEnter = #route <= enterIndex;
				
				local doorName = isEnter and nav.Entrance or nav.Exit;
				local nextNav = isEnter and navId or nav.Parent;
				
				if doorName then
					local doorInstance = workspace.Interactables:FindFirstChild(doorName);
					local pathfind = doorInstance and doorInstance:FindFirstChild("PathFind");
					local destination = doorInstance and doorInstance.Position or self.RootPart.Position;
					
					if pathfind then
						destination = pathfind.WorldPosition;
					end
					
					self.Movement:Move(destination):OnComplete(function(arrived)
						if arrived then
							self.CurrentNav = nextNav;
							self.Actions:EnterDoor(doorInstance);
						end
					end)
					
				else
					self.CurrentNav = nextNav;
					
				end
			end
		else
			return modLogicTree.Status.Failure;
		end
		
		return modLogicTree.Status.Success;
	end)
	
	
	return tree;
end
