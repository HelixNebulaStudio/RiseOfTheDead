local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local modZSharpLexer = require(game.ReplicatedStorage.Library.ZSharp.ZSharpLexer);

local templateTextEditor = script:WaitForChild("TextEditor");

local TextEditor = {};
TextEditor.__index = TextEditor;
TextEditor.ClassName = "ZSCode";
--==

local color = Color3.fromRGB(128,128,128)

function TextEditor.new()
	local self = {
		VertDiv=0.8;
		HoriDiv=0.65;
		
		Windows = {
			Menu = false;
			Nav = false;
			Output = false;
		};
		
		ActiveDocument="script.zs";
	};
	self.Frame = templateTextEditor:Clone();

	local workFrame = self.Frame.WorkScrollFrame;
	local maxLines = 999;
	
	local function updateLineNumbers()
		local lineNumLabel = workFrame.TextBox.LineNumbers;
		local textboxHeight = workFrame.TextBox.AbsoluteSize.Y + 96;
		
		local linesCount = math.min(math.ceil(textboxHeight/16), maxLines);
		local lineNumStr = "";
		
		for a=1, linesCount do
			lineNumStr = lineNumStr..a.."\n";
		end
		
		lineNumLabel.Text = lineNumStr;
		if linesCount >= maxLines then
			lineNumStr = lineNumStr.."bruh";
		end
		
	end
		
	local function refreshVisualizedText()
		local source = workFrame.TextBox.Text;
		local strBuilder = "";
		for token, src in modZSharpLexer.scan(source) do
			strBuilder = strBuilder.. modZSharpLexer.highlightColors(token, src);
		end
		
		if #strBuilder < 16384 then
			workFrame.TextBox.VisualizedText.Text = strBuilder;
		else
			workFrame.TextBox.VisualizedText.Text = source;
		end
	end
		
	workFrame.TextBox:GetPropertyChangedSignal("Text"):Connect(refreshVisualizedText);
	refreshVisualizedText()
	
	workFrame.TextBox:GetPropertyChangedSignal("TextBounds"):Connect(function()
		workFrame.TextBox.Size = UDim2.new(1, 0, 0, math.min(workFrame.TextBox.TextBounds.Y+96, maxLines *16));
		updateLineNumbers();
	end)
	workFrame.TextButton.MouseButton1Click:Connect(function()
		workFrame.TextBox:CaptureFocus();
	end)
	
	setmetatable(self, TextEditor);
	return self;
end

function TextEditor:OnOpen(Interface)
	local terminalCache = Interface.TerminalCache;

	local cache = terminalCache.ZSCode or {};
	
	if cache.ActiveSource then
		self.Frame.WorkScrollFrame.TextBox.Text = cache.ActiveSource;
	end
end

function TextEditor:OnClose(Interface)
	local terminalCache = Interface.TerminalCache;
	
	local cache = terminalCache.ZSCode or {};
	if terminalCache.ZSCode == nil then
		terminalCache.ZSCode = cache;
	end
	
	cache.ActiveSource = self:GetSource();
	
end

function TextEditor:GetSource()
	return self.Frame.WorkScrollFrame.TextBox.Text;
end

function TextEditor:SetZIndex(v)
	self.Frame.ZIndex = v or 1;
	for _, obj in pairs(self.Frame:GetDescendants()) do
		if obj:IsA("GuiObject") then
			obj.ZIndex = v or 1;
		end
	end
end

function TextEditor:RefreshVisiblity()
	local menuFrame = self.Frame.MenuScrollFrame;
	if menuFrame.Visible ~= self.Windows.Menu then
		menuFrame.Visible = self.Windows.Menu;
	end
	menuFrame.Size = UDim2.new(1-self.VertDiv, 0, 1-self.HoriDiv, 0);

	local navFrame = self.Frame.NavScrollFrame;
	if navFrame.Visible ~= self.Windows.Nav then
		navFrame.Visible = self.Windows.Nav;
	end
	navFrame.Size = UDim2.new(1-self.VertDiv, 0, self.HoriDiv, 0);

	local outputFrame = self.Frame.OutputScrollFrame;
	if outputFrame.Visible ~= self.Windows.Output then
		outputFrame.Visible = self.Windows.Output;
	end
	outputFrame.Size = UDim2.new(self.VertDiv, 0, 1-self.HoriDiv, 0);
	
	local scaleX, scaleY = 1, 1;
	
	if self.Windows.Menu or self.Windows.Nav then
		scaleX = self.VertDiv;
	end
	
	if self.Windows.Output then
		scaleY = self.HoriDiv;
	end
	
	self.Frame.WorkScrollFrame.Size = UDim2.new(scaleX, 0, scaleY, 0);
end

function TextEditor:ToggleMenu()
	self.Windows.Menu = not self.Windows.Menu;
	self:RefreshVisiblity();
end

function TextEditor:ToggleNav()
	self.Windows.Nav = not self.Windows.Nav;
	self:RefreshVisiblity();
end

function TextEditor:ToggleOutput()
	self.Windows.Output = not self.Windows.Output;
	self:RefreshVisiblity();
end

function TextEditor:NewMenuButton()
	local new = script.MenuButton:Clone();

	local menuFrame = self.Frame.MenuScrollFrame;
	new.Parent = menuFrame;
	new.ZIndex = self.Frame.ZIndex;
	
	return new;
end

return TextEditor;