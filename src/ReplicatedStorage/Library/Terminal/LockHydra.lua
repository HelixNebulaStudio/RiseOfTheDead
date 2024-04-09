local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local greekDictionary = {
	Alpha={Value="α"; Index=1;};
	Beta={Value="β"; Index=2;};
	Gamma={Value="Γ"; Index=3;};
	Delta={Value="Δ"; Index=4;};
	Epsilon={Value="ε"; Index=5;};
	Zeta={Value="ζ"; Index=6;};
	Eta={Value="η"; Index=7;};
	Theta={Value="Θ"; Index=8;};
	Iota={Value="Ι"; Index=9;};
	Kappa={Value="Κ"; Index=10;};
	Lambda={Value="λ"; Index=11;};
	Mu={Value="μ"; Index=12;};
	Nu={Value="Ν"; Index=13;};
	Xi={Value="Ξ"; Index=14;};
	Omicron={Value="Ο"; Index=15;};
	Pi={Value="π"; Index=16;};
	Rho={Value="Ρ"; Index=17;};
	Sigma={Value="Σ"; Index=18;};
	Tau={Value="Τ"; Index=19;};
	Upsilon={Value="Υ"; Index=20;};
	Phi={Value="Φ"; Index=21;};
	Chi={Value="Χ"; Index=22;};
	Psi={Value="Ψ"; Index=23;};
	Omega={Value="Ω"; Index=24;};
};
greekIndexList = {};
for k, v in pairs(greekDictionary) do
	v.Name = k;
	table.insert(greekIndexList, v);
end
table.sort(greekIndexList, function(a, b) return a.Index < b.Index; end);

local russianDictionary = {
	A={Value="А"; Index=1;};
	B={Value="Б"; Index=2;};
	V={Value="В"; Index=3;};
	G={Value="Г"; Index=4;};
	D={Value="Д"; Index=5;};
	Ye={Value="Е"; Index=6;};
	Yo={Value="Ё"; Index=7;};
	Zh={Value="Ж"; Index=8;};
	Z={Value="З"; Index=9;};
	Ee={Value="И"; Index=10;};
	I={Value="Й"; Index=11;};
	K={Value="К"; Index=12;};
	L={Value="Л"; Index=13;};
	M={Value="М"; Index=14;};
	N={Value="Н"; Index=15;};
	O={Value="О"; Index=16;};
	P={Value="П"; Index=17;};
	R={Value="Р"; Index=18;};
	S={Value="С"; Index=19;};
	T={Value="Т"; Index=20;};
	U={Value="У"; Index=21;};
	F={Value="Ф"; Index=22;};
	H={Value="Х"; Index=23;};
	Ts={Value="Ц"; Index=24;};
	Ch={Value="Ч"; Index=25;};
	Shu={Value="Ш"; Index=26;};
	She={Value="Щ"; Index=27;};
	Hs={Value="Ъ"; Index=28;};
	Il={Value="Ы"; Index=29;};
	Ss={Value="Ь"; Index=30;};
	E={Value="Э"; Index=31;};
	Yu={Value="Ю"; Index=32;};
	Ya={Value="Я"; Index=33;};
}; 
russianIndexList = {};
for k, v in pairs(russianDictionary) do
	v.Name = k;
	table.insert(russianIndexList, v);
end
table.sort(russianIndexList, function(a, b) return a.Index < b.Index; end);


--
local TweenService = game:GetService("TweenService");
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local remoteLockHydra = modRemotesManager:Get("LockHydra");


local templateHackingFrame = script:WaitForChild("HackingFrame");
local templateButton = script:WaitForChild("TemplateButton");

local HackingPanel = {};
HackingPanel.__index = HackingPanel;
HackingPanel.ClassName = "LockHydra";

HackingPanel.GreekDictionary = greekDictionary;
HackingPanel.RussianDictionary = russianDictionary;
HackingPanel.GreekIndexList = greekIndexList;
HackingPanel.RussianIndexList = russianIndexList;
--==
function HackingPanel:PlayClick()
	modAudio.Play("Collectible", self.Frame.Parent).PlaybackSpeed = math.random(95,105)/10;
end

local Ranks = {
	Easy = {Columns=3; Rows=3;};
	Normal = {Columns=6; Rows=4;};
	Hard = {Columns=9; Rows=5;};
}

-- easy: 3, 3;
-- normal: 6, 4;
-- hard: 9, 5;
function HackingPanel.new()
	local self = {
		Seed = nil;
		Key = nil;
		
		Columns = 6;
		Rows = 4;
		
		LastClickColumn = nil;
		Active = nil;
		Table = {};
		
		Complete = false;
		History = {};
	};
	self.Frame = templateHackingFrame:Clone();

	setmetatable(self, HackingPanel);
	
	self.Frame:WaitForChild("Reset").MouseButton1Click:Connect(function()
		self:PlayClick();
		self.LastClickColumn = nil;
		self.Active = nil;
		self:Reset();
		self:Render();
	end)
	
	self.Frame:WaitForChild("SelectedButton").MouseButton1Click:Connect(function()
		self:PlayClick();
		if self.Active and self.LastClickColumn then
			table.insert(self.LastClickColumn.List, self.Active);
			self.Active = nil;
		end
		self:Render();
	end)
	
	self.Frame:WaitForChild("Undo").MouseButton1Click:Connect(function()
		self:PlayClick();
		
		if #self.History > 0 then
			local undoObj = table.remove(self.History, #self.History);
			
			local active = table.remove(undoObj.NewColumn.List, #undoObj.NewColumn.List);
			table.insert(undoObj.OldColumn.List, active);
			
		else
			self.Frame.Undo.BackgroundColor3 = Color3.fromRGB(100, 60, 60);
			TweenService:Create(self.Frame.Undo, TweenInfo.new(1), {
				BackgroundColor3 = Color3.fromRGB(100, 100, 100);
			}):Play();
			
		end
		
		self:Render();
	end)
	
	return self;
end

function HackingPanel:IsColumnComplete(columnObj)
	if #columnObj.List <= 0 then return true end;
	
	local allMatch = true;
	if #columnObj.List >= self.Rows then
		local matchIndex = nil;
		for a=1, #columnObj.List do
			if matchIndex == nil then
				matchIndex = columnObj.List[a].Index;
			end
			if matchIndex ~= columnObj.List[a].Index then
				allMatch = false;
				break;
			end
		end
	else
		allMatch = false;
	end
	return allMatch;
end

function HackingPanel:Render(gameStateUpdate)
	local scrollFrame = self.Frame.ScrollingFrame;
	
	scrollFrame.UIListLayout.Padding = UDim.new(0, self.Columns > 6 and 20 or 60);
	
	if self.Active then
		self.Frame.SelectedButton.Text = self.Active.Value;
		self.Frame.SelectedButton.Visible = true;
	else
		self.Frame.SelectedButton.Visible = false;
	end
	
	for a=1, #self.Table do
		local columnObj = self.Table[a];
		
		local isComplete = self:IsColumnComplete(columnObj);
		if columnObj.Locked == true and not isComplete then
			columnObj.Locked = false;
		end
		
		local button: TextButton = scrollFrame:FindFirstChild(a);
		if button == nil then
			button = templateButton:Clone();
			button.Name = a;
			
			button.TextSize = self.Rows > 4 and 45 or 52
			
			button.MouseButton1Click:Connect(function()
				columnObj = self.Table[a];
				if columnObj.Locked then return end;
				self:PlayClick();
				
				local refreshGameState = false;
				
				if self.Active == nil then
					if #columnObj.List > 0 then
						self.Active = table.remove(columnObj.List, #columnObj.List);
						self.LastClickColumn = columnObj;
						
						if self.TimeLapseTimer == nil then
							self.TimeLapseTimer = tick();
						end
					end
					
				else
					local canPut = false;
					
					if #columnObj.List <= 0 then
						canPut = true;
						
					elseif #columnObj.List < self.Rows+1 then
						local lastValue = columnObj.List[#columnObj.List];
						
						if lastValue.Index == self.Active.Index then
							canPut = true;
						end
					end
					if columnObj == self.LastClickColumn then
						canPut = true;
					end
					
					
					if canPut then
						table.insert(self.History, {
							OldColumn = self.LastClickColumn;
							NewColumn = columnObj;
						});
						
						self.LastClickColumn = nil;
						table.insert(columnObj.List, self.Active);
						self.Active = nil;

						local allMatch = self:IsColumnComplete(columnObj);
						
						if allMatch then
							button.BackgroundColor3 = Color3.fromRGB(60, 100, 60);
							TweenService:Create(button, TweenInfo.new(0.5), {
								BackgroundColor3 = Color3.fromRGB(100, 100, 100);
							}):Play();
							columnObj.Locked = true;
							refreshGameState = true;
							modAudio.Play("Collectible", self.Frame.Parent);
							
						else
							button.BackgroundColor3 = Color3.fromRGB(60, 60, 100);
							TweenService:Create(button, TweenInfo.new(0.5), {
								BackgroundColor3 = Color3.fromRGB(100, 100, 100);
							}):Play();
							columnObj.Locked = false;
							
						end
						
					else
						button.BackgroundColor3 = Color3.fromRGB(100, 60, 60);
						TweenService:Create(button, TweenInfo.new(0.5), {
							BackgroundColor3 = Color3.fromRGB(100, 100, 100);
						}):Play();
						modAudio.Play("Electrocute", self.Frame.Parent).PlaybackSpeed = 2;
						
					end
				end

				self:Render(refreshGameState);
			end)
		end
		button.Parent = scrollFrame;
		
		local btStr = "";
		
		if columnObj.Locked == true or #columnObj.List <= 0 then
			btStr = btStr.."⚫\n\n";
		else
			btStr = btStr.."⚪\n\n";
		end
		
		for b=1, #columnObj.List do
			local alphabetObj = columnObj.List[b];
			btStr = btStr..alphabetObj.Value.. (b ~= #columnObj and "\n" or "");
		end
		button.Text = btStr;
		
	end
	for _, obj in pairs(scrollFrame:GetChildren()) do
		if obj:IsA("TextButton") and tonumber(obj.Name) and self.Table[tonumber(obj.Name)] == nil then
			obj:Destroy();
		end
	end
	
	if gameStateUpdate then
		local tableComplete = true;

		for _, tableObj in pairs(self.Table) do
			local columnMatch = self:IsColumnComplete(tableObj);
			if columnMatch == false then
				tableComplete = false;
				break;
			end
		end

		if self.Complete ~= tableComplete then
			self.Complete = tableComplete;
			
			local timeLapsed = math.round( (tick()-(self.TimeLapseTimer or 0)) *100 )/100;
			
			task.spawn(function()
				self.Frame.StateLabel.Text = "Injecting payload...";
				remoteLockHydra:InvokeServer("submit", self.TargetInteractData, timeLapsed);
				self.Frame.StateLabel.Text = "Lock Destroyed in ".. timeLapsed .."s!";
			end)
		end
	end
		
	self.Frame.StateLabel.Visible = self.Complete == true;
end

function HackingPanel:Reset()
	table.clear(self.Table);
	table.clear(self.History);
	self.Complete = false;
	self.TimeLapseTimer = nil;
	
	self.Random = self.Seed and Random.new(self.Seed) or Random.new();

	if self.IndexList == nil then
		local list = {greekIndexList; russianIndexList};
		self.IndexList = list[self.Random:Clone():NextInteger(1, #list)];
	end
	
	local spaceColumns = 1;
	if self.Columns > 6 then
		spaceColumns = 2;
	end
	
	local alphabets = {};
	repeat
		local chosen = self.IndexList[self.Random:NextInteger(1, #self.IndexList)];
		if table.find(alphabets, chosen) == nil then
			table.insert(alphabets, chosen);
		end
	until #alphabets >= self.Columns-spaceColumns;
	
	local pool = {};
	for a=1, #alphabets do
		for b=1, self.Rows do
			table.insert(pool, table.clone(alphabets[a]));
		end
	end
	
	local emptyColumns = {};
	for a=1, self.Columns do
		if self.Table[a] == nil then
			self.Table[a] = {List={}; Locked=false;};
		end
		local columnObj = self.Table[a];

		if a <= self.Columns-spaceColumns then
			for b=1, self.Rows do
				if #pool <= 0 then break; end;
			
				table.insert(columnObj.List, table.remove(pool, self.Random:NextInteger(1, #pool)));
			end
		else
			table.insert(emptyColumns, columnObj);
		end
	end

	for _, tableObj in pairs(self.Table) do
		if #tableObj.List <= 0 then continue end;
		
		local columnMatch = self:IsColumnComplete(tableObj);
		if columnMatch == true then
			local active = table.remove(tableObj.List, #tableObj.List);
			table.insert(emptyColumns[self.Random:Clone():NextInteger(1, #emptyColumns)].List, active);
		end
	end
end

function HackingPanel:Load(packet)
	self.Key = packet.Key;
	self.Seed = packet.Seed;
	self.TargetInteractData = packet.TargetInteractData;
	self.LockHydraInfo = packet.LockHydraInfo;
	
	if self.LockHydraInfo and self.LockHydraInfo.Rank and Ranks[self.LockHydraInfo.Rank] then
		local rankSettings = Ranks[self.LockHydraInfo.Rank];
		for k, v in pairs(rankSettings) do
			self[k] = v;
		end
	end
	
	self:Reset();
	self:Render();
end

return HackingPanel;
