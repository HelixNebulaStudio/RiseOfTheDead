local GraphRenderer = {};
GraphRenderer.__index = GraphRenderer;


--==

function GraphRenderer.new(frame)
	local self = {
		Frame = frame;
		Resolution = 75;
		ToolTipEnabled = true;
		BaselineZero = false;
		
		Range = {Min=-1; Max=1};
	}

	local BaseZIndex = self.Frame.ZIndex;
	
	
	self.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local Size = self.Frame.AbsoluteSize
		wait(0.04)
		if Size == self.Frame.AbsoluteSize then
			self.Render()
		end
	end)
	
	local GraphingFrame = Instance.new("Frame");
	GraphingFrame.Name = "GraphingFrame";
	GraphingFrame.Size = UDim2.new(1,0,1,0);
	GraphingFrame.Position = UDim2.new(0,0,0,0);
	GraphingFrame.BackgroundTransparency = 1;
	GraphingFrame.ZIndex = BaseZIndex+2;
	GraphingFrame.Parent = self.Frame;

	local Busy = false;
	function GraphRenderer.Render()
		if self.Data == nil then return end;
		while Busy do wait(0.1) end
		Busy = true
		
		GraphingFrame:ClearAllChildren()
		GraphingFrame.ZIndex = BaseZIndex+2
		
		local Range = self.Range.Max - self.Range.Min;

		-- Calculate our range of values

		for Key, Set in pairs(self.Data) do
			local SetAmount = #Set
			if SetAmount <= 0 then continue end;

			for i=1,SetAmount, math.ceil(SetAmount/self.Resolution) do
				local SortedChunk = {}
				for x=i,i+math.ceil(SetAmount/self.Resolution) do
					SortedChunk[#SortedChunk+1] = Set[x]
				end
				table.sort(SortedChunk, function(a, b)
					return a.Value < b.Value;
				end)

				local Value = SortedChunk[math.round(#SortedChunk*0.55)]
				if not Value then continue end
			end
		end
		
		-- Draw the graph at this range
		local KeyColors = {}
		for Key, Set in pairs(self.Data) do
			-- Designate a color for this dataset
			KeyColors[Key] = Color3.fromRGB(255,255,255); --getKeyColor(Key)

			-- Graph the set

			local SetAmount = #Set
			if SetAmount <= 0 then continue end;
			
			local LastPoint;

			--print("  "..Key, Set)

			for i=1, SetAmount, math.ceil(SetAmount/self.Resolution) do

				local SortedChunk = {}
				for x=i, i+math.ceil(SetAmount/self.Resolution) do
					SortedChunk[#SortedChunk+1] = Set[x]
				end
				--table.sort(SortedChunk, function(a, b) dunno what this is for..
				--	return a.Value > b.Value;
				--end)

				local DataPoint = SortedChunk[math.round(#SortedChunk*0.55)]
				if not DataPoint then continue end
				
				local Value = -DataPoint.Value;
				
				-- Create the point
				local Point = Instance.new("Frame")
				Point.Name = Key..i
				Point.Position = UDim2.new( (i/SetAmount), 0, ((Value-self.Range.Min)/Range), 0)
				Point.AnchorPoint = Vector2.new(0.5,0.5)
				Point.Size = UDim2.new(0, 3, 0, 3);

				Point.BorderSizePixel = 0
				Point.BackgroundTransparency = 0
				Point.BackgroundColor3 = Color3.fromRGB(255,255,255);
				Point.Rotation = 45;
				Point.ZIndex = BaseZIndex+2

				local Label = Instance.new("TextLabel")
				Label.Visible = false
				Label.AutomaticSize = Enum.AutomaticSize.XY;
				Label.Text = i .." ".. string.format("%.2f",Value)
				Label.BackgroundColor3 = Color3.fromRGB(45,45,50);
				Label.TextColor3 = Color3.fromRGB(220,220,230);
				Label.Position = UDim2.new(0,0,0,-10)
				Label.AnchorPoint = Vector2.new(0, 1);
				Label.Font = Enum.Font.Code
				Label.TextSize = 12;
				Label.Parent = Point
				Label.ZIndex = BaseZIndex+3

				Point.MouseEnter:Connect(function()
					if self.ToolTipEnabled == false then return end;
					Label.Visible = true
				end)
				Point.MouseLeave:Connect(function()
					Label.Visible = false
				end)

				-- Create the line
				local Connector;
				if LastPoint then
					Connector = Instance.new("Frame")
					Connector.Name = "Link"..Key..i.."-"..i-1
					Connector.BackgroundColor3 = KeyColors[Key]
					Connector.BorderSizePixel = 0
					Connector.AnchorPoint = Vector2.new(0.5, 0.5)
					Connector.ZIndex = BaseZIndex

					local Size = GraphingFrame.AbsoluteSize
					local startX, startY = Point.Position.X.Scale*Size.X, Point.Position.Y.Scale*Size.Y
					local endX, endY = LastPoint.Position.X.Scale*Size.X, LastPoint.Position.Y.Scale*Size.Y

					local Distance = (Vector2.new(startX, startY) - Vector2.new(endX, endY)).Magnitude +2

					Connector.Size = UDim2.new(0, Distance, 0, 2)
					Connector.Position = UDim2.new(0, (startX + endX) / 2, 0, (startY + endY) / 2)
					Connector.Rotation = math.atan2(endY - startY, endX - startX) * (180 / math.pi)

					Connector.Parent = GraphingFrame
				end
				
				if self.OnDataRender then
					self:OnDataRender(Set[i], Point, Connector);
				end
				
				LastPoint = Point
				Point.Parent = GraphingFrame

			end

		end

		Busy = false
	end
	
	setmetatable(self, GraphRenderer);
	return self;
end

return GraphRenderer;