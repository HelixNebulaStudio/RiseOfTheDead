local ChatInterface = {};

function ChatInterface.Initialize(chatFrame)
	if chatFrame:FindFirstChild("Initialized") then return end;
	local initializedTag = Instance.new("BoolValue", chatFrame); initializedTag.Name = "Initialized";
	local chatChannelParentFrame = chatFrame:WaitForChild("ChatChannelParentFrame");
	local chatBarParentFrame = chatFrame:WaitForChild("ChatBarParentFrame");
	local resizeButton = chatFrame:WaitForChild("ImageButton");
	local chatMessageLog = chatChannelParentFrame:WaitForChild("Frame_MessageLogDisplay"):WaitForChild("Scroller");
	local uiListLayout = Instance.new("UIListLayout"); uiListLayout.Parent = chatFrame;
	uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom;
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
	local function resizeChatFrame()
		resizeButton.Visible = false;
		local frames = chatMessageLog:GetChildren();
		local totalSize = 10;
		for a=1, #frames do
			if frames[a]:IsA("Frame") then
				totalSize = totalSize + frames[a].AbsoluteSize.Y;
			end
		end
		chatFrame.AnchorPoint = Vector2.new(0, 1);
		chatFrame.Position = UDim2.new(0, 5, 1, -5);
		chatMessageLog.Position = UDim2.new(0, 0, 0, 5);
		chatMessageLog.Size = UDim2.new(1, -4, 1, -10);
		chatMessageLog.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png";
		chatMessageLog.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png";
		chatChannelParentFrame.AnchorPoint = Vector2.new(0, 1);
		chatChannelParentFrame.Position = UDim2.new(0, 0, 1, -40);
		chatBarParentFrame.AnchorPoint = Vector2.new(0, 1);
		chatBarParentFrame.Position = UDim2.new(0, 0, 1, 0);
		chatBarParentFrame.LayoutOrder = 1;
		local chatBarBackgroundFrame = chatBarParentFrame:FindFirstChild("Frame");
		local inputBoxFrame = chatBarParentFrame:FindFirstChild("BoxFrame", true);
		local inputChatBar = chatBarParentFrame:FindFirstChild("ChatBar", true);
		local inputTextLabel = chatBarParentFrame:FindFirstChild("TextLabel", true);
		if chatBarBackgroundFrame then
			chatBarBackgroundFrame.AnchorPoint = Vector2.new(0, 1);
			chatBarBackgroundFrame.Position = UDim2.new(0, 0, 1, 0);
			chatBarParentFrame.Size = UDim2.new(1, 0, 0, math.clamp(chatBarBackgroundFrame.AbsoluteSize.Y, 40, 70));
		else
			chatBarParentFrame.Size = UDim2.new(1, 0, 0, 40);
		end
		if inputBoxFrame then
			inputBoxFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
			inputBoxFrame.Position = UDim2.new(0, 5, 0, 5);
			inputBoxFrame.Size = UDim2.new(1, -10, 1, -10);
		end
		if inputChatBar then
			inputChatBar.TextColor3 = Color3.fromRGB(255, 255, 255);
			inputChatBar.TextYAlignment = Enum.TextYAlignment.Center;
		end
		if inputTextLabel then
			inputTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
			inputTextLabel.TextYAlignment = Enum.TextYAlignment.Center;
		end
		pcall(function()
		chatChannelParentFrame:TweenSize(UDim2.new(1, 0, 0, math.clamp(totalSize, 15, 180)), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
		end)
	end
	
	chatMessageLog.ChildAdded:Connect(resizeChatFrame);
	chatMessageLog.ChildRemoved:Connect(resizeChatFrame);
	repeat resizeChatFrame(); until not chatMessageLog:IsDescendantOf(game.Players.LocalPlayer.PlayerGui) or not wait(1);
end

return ChatInterface;