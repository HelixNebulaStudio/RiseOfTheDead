local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--[[
	{Id="root"; Text="Root";};
	{Id="sys01"; PrevId="root"; Order=1; Text="Sys01";};
--]]
local RunService = game:GetService("RunService");

local templateLinkFrame = script:WaitForChild("linkFrame");
local NodeGridUI = {}
NodeGridUI.__index = NodeGridUI;

function NodeGridUI:NewNode(guiObject, nodeId, linkNode, order)
	for a=1, #self.Nodes do
		if self.Nodes[a].NodeId == nodeId then
			Debugger:Warn("NodeId (", nodeId,") already exist.");
			return;
		end
	end

	table.insert(self.Nodes, {NodeId=nodeId; LinkNode=linkNode; Order=order; GuiObject=guiObject;});
	return self.Nodes[#self.Nodes];
end

function NodeGridUI:Destroy(nodeId)
	for a=1, #self.Nodes do
		if self.Nodes[a].NodeId == nodeId then
			if self.Nodes[a].LinkFrame then
				game.Debris:AddItem(self.Nodes[a].LinkFrame, 0);
				self.Nodes[a].LinkFrame = nil;
			end
			table.remove(self.Nodes, a);
			return;
		end
	end
end

function NodeGridUI:GetNode(nodeId)
	for a=1, #self.Nodes do
		if self.Nodes[a].NodeId == nodeId then
			return self.Nodes[a];
		end
	end
end

function NodeGridUI:SetNodeLink(nodeId, linkNode)
	local node = self:GetNode(nodeId);
	node.LinkNode = linkNode;
end

local circlePi = math.pi*2;
function NodeGridUI:UpdateNodeTree()
	local nodeLayers = {Root={};};

	for a=1, #self.Nodes do
		if self.Nodes[a].LinkNode == nil then
			table.insert(nodeLayers.Root, self.Nodes[a]);
		else
			if nodeLayers[self.Nodes[a].LinkNode] == nil then
				nodeLayers[self.Nodes[a].LinkNode] = {};
			end

			table.insert(nodeLayers[self.Nodes[a].LinkNode], self.Nodes[a]);
		end
	end


	local startNodeGroup = nodeLayers[nodeLayers.Root[1].NodeId];
	local rootNodesAngle = circlePi / #startNodeGroup;

	local radialLayers = {};
	local function organizeNode(nodes, parentNode)
		table.sort(nodes, function(nodeA, nodeB) return (nodeA.Order or 0) < (nodeB.Order or 0) end);

		local rTotal = self.StartRadian;

		local noOfChildren = #nodes;
		for a=1, noOfChildren do -- list of child nodes;
			local node = nodes[a];
			node.Layer = parentNode == nil and 0 or (parentNode.Layer+1);
			node.Index = a;
			node.ParentNode = parentNode;

			if node.Layer == 1 then
				node.ParentRadian = rTotal;

			elseif node.Layer > 1 then
				node.ParentRadian = parentNode.ParentRadian;
				node.NeighbourCount = noOfChildren;

			end

			if radialLayers[node.Layer] == nil then
				radialLayers[node.Layer] = {};
			end
			table.insert(radialLayers[node.Layer], node);

			local nextNodeList = nodeLayers[node.NodeId];
			if nextNodeList then
				organizeNode(nextNodeList, node);
			end

			rTotal = rTotal + rootNodesAngle;
		end
	end


	local function renderRadial(layerIndex, layerTable)

		local noOfNodes = #layerTable;
		local angToAdd = rootNodesAngle;
		local rTotal = self.StartRadian;

		if layerIndex > (self.StartLayerIndex or 1) then
			angToAdd = (circlePi) / (layerIndex+16);

		end

		for a=1, noOfNodes do
			local node = layerTable[a];

			if layerIndex > (self.StartLayerIndex or 1) then
				if node.Index <= 1 then
					local addRadian = math.max(node.ParentNode.NodeRadian-rTotal, 0);
					
					if node.NeighbourCount and self.DisableRecenter ~= true then
						local subRadian = (node.NeighbourCount-1)*angToAdd/2;
						
						rTotal = rTotal - subRadian;
					end
					
					rTotal = rTotal + addRadian;
				end
			end

			local nodeGuiObj: ImageButton = node.GuiObject;
			if nodeGuiObj then
				if nodeGuiObj:IsA("ImageButton") then
					nodeGuiObj.MouseButton2Click:Connect(function()
						if not RunService:IsStudio() then return end;
						Debugger:Warn(nodeGuiObj.Name,
							"parent",node.ParentNode.GuiObject.Name,
							"Layer", node.Layer,
							"A",a,
							"Index",node.Index,
							"ParentRadian",node.ParentNode.NodeRadian);
					end)
				end

				if node.LinkNode then
					local additionalRadius = 0;

					local radius = layerIndex * (node.Radius or self.Radius) + additionalRadius;
					nodeGuiObj.Position = UDim2.new(
						0.5,
						math.sin(-rTotal)*(radius + additionalRadius),
						0.5,
						math.cos(rTotal)*(radius + additionalRadius)
					);
					node.NodeRadian = rTotal;

					local parentNode = node.ParentNode;
					if parentNode and node.LinkFrame and node.LinkFrame:FindFirstChild("linkButton") then -- Update link frame
						local linkFrame = node.LinkFrame;
						local linkButton = linkFrame.linkButton;

						local diff = (nodeGuiObj.AbsolutePosition + nodeGuiObj.AbsoluteSize * nodeGuiObj.AnchorPoint)
						- (parentNode.GuiObject.AbsolutePosition + parentNode.GuiObject.AbsoluteSize * parentNode.GuiObject.AnchorPoint);
						local length = diff.Magnitude;

						linkFrame.Name = node.NodeId;
						linkFrame.Parent = parentNode.GuiObject;
						linkFrame.Position = UDim2.new(0.5, diff.X/2, 0.5, diff.Y/2);

						linkButton.Size = UDim2.new(0, linkButton.Size.X.Offset, 0, length+14);
						
						linkButton.Rotation = math.deg(-math.atan2(diff.X, diff.Y));
					end

				end
			end

			rTotal = rTotal + angToAdd;
		end
	end

	local function linkNodes(nodes, parentNode)
		for a=1, #nodes do
			nodes[a].Parent = parentNode;
			if nodes[a].Parent and nodes[a].LinkFrame == nil then
				nodes[a].LinkFrame = templateLinkFrame:Clone();

				if self.OnNewLink then
					self.OnNewLink(nodes[a].LinkFrame);
				end
			end
			if nodeLayers[nodes[a].NodeId] then
				linkNodes(nodeLayers[nodes[a].NodeId], nodes[a]);
			end
		end
	end
	linkNodes(nodeLayers.Root);
	organizeNode(nodeLayers.Root);

	for layerIndex, layerTable in pairs(radialLayers) do
		renderRadial(layerIndex, layerTable)
	end
	
end

function NodeGridUI.new()
	local self = {
		Clockwise = true;
		UseNodePadding = false;
		Radius = 75;
		NodePadding = 60;
		StartRadian = math.pi;
		Nodes={};
	};

	setmetatable(self, NodeGridUI);
	return self;
end

return NodeGridUI;
