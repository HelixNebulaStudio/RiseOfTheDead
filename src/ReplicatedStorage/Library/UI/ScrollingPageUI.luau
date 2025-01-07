local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);

local templateScrollingPage = script:WaitForChild("ScrollingPage");
local templateBorder = script:WaitForChild("PageBorders");

--==
local ScrollingPageUI = {};
ScrollingPageUI.__index = ScrollingPageUI;

function ScrollingPageUI.new(pageFrame: Frame)
    local self = {
        ScrollFrame = templateScrollingPage:Clone() :: ScrollingFrame;
        PageFrame = pageFrame;
        ScrollDirection = "Y";

        Page = 0;
        MaxPage = 1;
        _lastMaxPages = 0;

        ScrollerFrame = nil;
        ScrollerButton = nil;

        Garbage = modGarbageHandler.new();
    };

    local uiListLayout = pageFrame:WaitForChild("UIListLayout");
    self.UIListLayout = uiListLayout;

    setmetatable(self, ScrollingPageUI);

    pageFrame.Parent = self.ScrollFrame;

    local pageHandler = require(pageFrame:WaitForChild("ScrollingPageHandler"));
    task.spawn(pageHandler.init, self);
	
	self.ScrollFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function() self:Refresh(); end);
	pageFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:Refresh(); end);
	self:Refresh();
	

    local lastChange = tick();
    self.ScrollFrame.InputChanged:Connect(function(input: InputObject)
        local absWinSize = self.ScrollFrame.AbsoluteWindowSize;
        if absWinSize[self.ScrollDirection] <= 0 then return end;
        
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            lastChange = tick();
        elseif input.UserInputType == Enum.UserInputType.Touch then
            lastChange = tick();
        else
            return;
        end

        local canPosA = self.ScrollFrame.CanvasPosition[self.ScrollDirection];
        task.wait();
        local canPosB = self.ScrollFrame.CanvasPosition[self.ScrollDirection];
        self.Page = self:GetPageIndex(canPosB-canPosA);
    end)

    self.Garbage:Tag(RunService.RenderStepped:Connect(function()
        local absWinSize = self.ScrollFrame.AbsoluteWindowSize;
        local absCanvasPosition = self.ScrollFrame.CanvasPosition;
        
        if tick()-lastChange <= 0.4 then return end;

        local absWinAxisSize = absWinSize[self.ScrollDirection];
        local newAxisPos = (absWinAxisSize*self.Page);
        local newPos = self.ScrollDirection == "Y" and Vector2.new(0, newAxisPos) or Vector2.new(newAxisPos, 0);

        local diff = math.abs(newAxisPos-absCanvasPosition[self.ScrollDirection]);
        if diff <= 1 then
            self.ScrollFrame.CanvasPosition = newPos;
        else
            self.ScrollFrame.CanvasPosition = self.ScrollFrame.CanvasPosition:Lerp(newPos, 0.1);
        end
    end))

	self.ScrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if self.ScrollerFrame == nil then return end;
        self:RefreshScroller();
    end);

    self.ScrollFrame.Destroying:Connect(function()
        self:Destroy();
    end)

    return self;
end

function ScrollingPageUI:RefreshScroller()
    if self.ScrollerFrame == nil then return end;
    if self.ScrollerButton == nil then return end;

    if self._lastMaxPages ~= self.MaxPage then
        self._lastMaxPages = self.MaxPage;

        for _, obj in pairs(self.ScrollerFrame:GetChildren()) do
            if not obj:IsA("GuiObject") then continue end;
            obj:Destroy();
        end

        self.ScrollerFrame.Visible = false;
        
        for a=1, self.MaxPage do
            local new = self.ScrollerButton:Clone();
            new.Parent = self.ScrollerFrame;
            
            local page = a-1;
            new.Name = page;
            new.LayoutOrder = page;
            new.MouseButton1Click:Connect(function()
                self:SetPage(page);
            end);
        end
        if self.MaxPage > 0 then
            self.ScrollerFrame.Visible = true;
        end
    end

    if self.ScrollerFrame.Visible == false then return end;

    for _, obj in pairs(self.ScrollerFrame:GetChildren()) do
        if not obj:IsA("GuiObject") then continue end;
        if self.ScrollerParams and self.ScrollerParams.RefreshScrollButtonsFunc then
            self.ScrollerParams.RefreshScrollButtonsFunc(obj);
        end
    end
end

function ScrollingPageUI:Refresh()
    local scrollFrame: ScrollingFrame = self.ScrollFrame;
    local uiListLayout: UIListLayout = self.UIListLayout;
	local pageFrame = self.PageFrame;

	local absSize = pageFrame.AbsoluteSize;
	scrollFrame.CanvasSize = UDim2.new(0, absSize.X, 0, absSize.Y);
    scrollFrame.ScrollingDirection = self.ScrollDirection == "Y" and Enum.ScrollingDirection.Y or Enum.ScrollingDirection.X;

    uiListLayout.FillDirection = self.ScrollDirection == "Y" and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal;

	local absWinSize = scrollFrame.AbsoluteWindowSize;

    local pageCount = 0;
	for _, obj in pairs(pageFrame:GetChildren()) do
		if not obj:IsA("GuiObject") then continue end;
		obj.Size = UDim2.new(0, absWinSize.X, 0, absWinSize.Y);
        pageCount = pageCount +1;
	end
    self.MaxPage = pageCount;

    local absConSize = uiListLayout.AbsoluteContentSize;
    pageFrame.Size = UDim2.new(0, absConSize.X, 0, absConSize.Y);

	if self.Border then
		local uiStroke = self.Border.UIStroke;
		local thickness = uiStroke.Thickness;
		
		self.Border.Position = UDim2.new(0, thickness, 0, thickness);
		self.Border.Size = UDim2.new(1, -thickness*2, 1, -thickness*2);
	end
	
	self:SetPage(self.Page, true);
    
    self:RefreshScroller();
end

function ScrollingPageUI:SetPage(index, snap)
    self.Page = index;
end

function ScrollingPageUI:GetPageIndex(bias)
    local scrollFrame = self.ScrollFrame;
    local dir = math.sign(bias);

	local absWinAxisSize = scrollFrame.AbsoluteWindowSize[self.ScrollDirection];
	local currAxisPos = scrollFrame.CanvasPosition[self.ScrollDirection] + dir*math.ceil(absWinAxisSize*0.333);

    local pageIndex = math.floor((currAxisPos/absWinAxisSize)+0.5);
	return pageIndex;
end

function ScrollingPageUI:SetBorder(thickness)
    if thickness > 0 then
        if self.Border == nil then
            self.Border = templateBorder:Clone();
            self.Border.Parent = self.ScrollFrame;
        end

        local uiStroke: UIStroke = self.Border:WaitForChild("UIStroke");
        uiStroke.Thickness = thickness;

    else
        if self.Border then
            self.Border:Destroy();
            self.Border = nil;
        end

    end
end

function ScrollingPageUI:SetScroller(frame: Frame, params)
    local uiListLayout = frame:WaitForChild("UIListLayout");
    local templateButton = uiListLayout:WaitForChild("TextButton");

    self.ScrollerFrame = frame;
    self.ScrollerButton = templateButton;
    self.ScrollerParams = params or {};

    frame.Parent = self.ScrollFrame.Parent;

    self:Refresh();
end

function ScrollingPageUI:Destroy()
    Debugger:Warn("Destroy ScrollingPageUI");
    self.Garbage:Destruct();
    if self.ScrollerFrame then
        self.ScrollerFrame:Destroy();
    end
end

return ScrollingPageUI;