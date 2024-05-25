local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {
	CloseWindow=nil;
	modCharacter=nil;
	ToggleWindow=nil;
};
Interface.TerminalCache = {};

local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");

local localPlayer = game.Players.LocalPlayer;
local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modCommandHandler = require(game.ReplicatedStorage.Library:WaitForChild("CommandHandler"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modZSharpScript = require(game.ReplicatedStorage.Library.ZSharp.ZSharpScript);

local modTextEditor = require(game.ReplicatedStorage.Library.Terminal:WaitForChild("ZSCode"));
local modHackingMinigame = require(game.ReplicatedStorage.Library.Terminal:WaitForChild("LockHydra"));

local modZSharpLexer = require(game.ReplicatedStorage.Library.ZSharp.ZSharpLexer);
local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);

local terminalFrame = script.Parent.Parent:WaitForChild("Terminal");
local termFrame = terminalFrame:WaitForChild("Frame");
local inputBox: TextBox = termFrame:WaitForChild("TextInput");
local scrollFrame = termFrame:WaitForChild("ScrollingFrame");

local templateTerminalLabel = script:WaitForChild("terminalLabel");
local defaultFontSize = templateTerminalLabel.TextSize;

local hexPairList = {};
local hexConvert = {[10]="A"; [11]="B"; [12]="C"; [13]="D"; [14]="E"; [15]="F"};

local proccessingCmd = false;
local activeInteractData;

local cacheInputs = {};
local seekIndex = 0;
local activeInputCache = "";

local activeApp = nil;
local activeOutputFrame = scrollFrame;

local function fillspace(preText, fillSize)
	local n = fillSize-#preText;
	return string.rep(" ", n);
end

local function termWait(t)
	task.wait(t);
end

local function closeActiveApp(toggleClass)
	if activeApp == nil then return false; end;
	
	local className = activeApp.ClassName;
	
	if activeApp.OnClose then
		activeApp:OnClose(Interface);
	end
	
	if activeApp.Frame then
		game.Debris:AddItem(activeApp.Frame, 0);
	end
	activeOutputFrame = scrollFrame;
	activeApp = nil;
	Interface.Println("Closed ".. className);
	
	termWait(0.35);
	
	if className == toggleClass then
		return true;
	end

	return;
end

local isFullScreen = false;
local function toggleFullScreen(v)
	if v == nil then
		v = not isFullScreen;
	end
	
	isFullScreen = v;
	
	for _, obj in pairs(terminalFrame:GetDescendants()) do
		if obj:IsA("GuiObject") then
			obj.ZIndex = v==true and 5 or 1;
		end
	end
	
	if v == true then
		terminalFrame.Position = UDim2.new(0.5, 0, 0, 0);
		if terminalFrame:FindFirstChild("UISizeConstraint") then
			terminalFrame.UISizeConstraint.MaxSize = Vector2.new(9999, 9999);
		end

	else
		terminalFrame.Position = UDim2.new(0.5, 0, 0.1, 0);
		if terminalFrame:FindFirstChild("UISizeConstraint") then
			terminalFrame.UISizeConstraint.MaxSize = Vector2.new(800, 500);
		end
		
	end
end
termFrame.ChildAdded:Connect(function(obj)
	task.wait();
	for _, obj in pairs(obj:GetDescendants()) do
		if obj:IsA("GuiObject") then
			obj.ZIndex = isFullScreen==true and 5 or 1;
		end
	end
end)

Interface.TerminalCmds = {};
local cmdsList = {};
cmdsList = {
	{
		CmdId = "help";
		Desc = "List all available terminal commands.";
		Run=function(args)
			local cId = args[1];
			if cId then
				local cLib = Interface.TerminalCmds[cId];
				if cLib then
					Interface.Println("<b>Usage</b>:"..fillspace("Usage:", 16)..(cLib.Usage or cId));
					Interface.Println("<b>Description</b>:"..fillspace("Description:", 16)..(cLib.Desc or "No available description"));
					
				else
					Interface.Println("Unknown Command.");
				end
			else
				Interface.Println("List of terminal commands:\n")
				for index, info in pairs(Interface.TerminalCmds) do
					Interface.Println("    <b>"..info.CmdId.."</b>"..fillspace(info.CmdId, 16)..(info.Desc or "No available description"));
				end
			end
			Interface.Println("\n");
		end
	};
	{
		CmdId = "size";
		Usage = "size [size]";
		Desc = "Change font size between 16-24.";
		Run=function(args)
			local textSize = tonumber(args[1]) or 18;
			textSize = math.clamp(math.floor(textSize), 16, 24);
			
			templateTerminalLabel.TextSize = textSize;
			for _, obj in pairs(activeOutputFrame:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj.TextSize = textSize;
				end
			end
			
			Interface.Println("\n");
		end
	};
	{
		CmdId = "run";
		Desc = "Runs a script in z-sharp script";
		Run=function(args)
			for a=1, #args do
				args[a] = tostring(args[a]);
			end

			modZSharpScript.Run({
				Name="terminal.zs";
				Source=tostring(table.concat(args, " ") or "");
				Terminal=activeInteractData; 
			})
		end;
	};
	{
		CmdId = "code";
		Desc = "Open/Close ZS Code";
		Run=function()
			if closeActiveApp("ZSCode") then return end;

			local newTextEditor = modTextEditor.new();
			newTextEditor:OnOpen(Interface);
			newTextEditor:ToggleMenu(true)
			newTextEditor:ToggleNav(true);
			newTextEditor:ToggleOutput(true);

			local textEditorFrame = newTextEditor.Frame;
			textEditorFrame.Size = UDim2.new(1, 0, 1, -30);
			textEditorFrame.Parent = termFrame;

			templateTerminalLabel.TextSize = 12;
			activeOutputFrame = textEditorFrame:WaitForChild("OutputScrollFrame");
			
			local runButton: TextButton = newTextEditor:NewMenuButton();
			runButton.Text = "Run";
			
			runButton.MouseButton1Click:Connect(function()
				local s, e = pcall(function()
					modZSharpScript.Clean();
					modZSharpScript.Run({
						Name=newTextEditor.ActiveDocument or "unknown";
						Source=newTextEditor:GetSource();
						Terminal=activeInteractData;
					})
				end)
				if not s then
					Interface.Println(`Failed: <font color='rgb(143, 81, 81)'>{e}</font>`);
					Debugger:Warn(e);
				end
			end)
		
			Interface.Println("Opening ZSCode.");
			activeApp = newTextEditor;
			
			newTextEditor:RefreshVisiblity();
		end;
	};
	{
		CmdId = "lockhydra";
		Desc = "Open/Close Lock Hydra, a digital lock application.";
		Check=function()
			local equippedItem = Interface.modCharacter and Interface.modCharacter.EquippedItem;
			if equippedItem == nil or equippedItem.ItemId ~= "rcetablet" then
				return false;
			end
			return true;
		end;
		Run=function()
			if closeActiveApp("LockHydra") then return end;

			Interface.Println("Opening LockHydra.");
			for a=1, 3 do
				Interface.Println(".",a==3 and "Waiting for Lock Hydra Toolpad.." or "");
				termWait(0.1);
			end
			
			local connected = true;

			local equippedItem = Interface.modCharacter and Interface.modCharacter.EquippedItem;
			if equippedItem == nil or equippedItem.ItemId ~= "rcetablet" then
				Interface.Println("<b>Toolpad not connected! Please connect toolpad.</b>");
				return;
			end
			
			if connected == true then
				Interface.Println("<b>Toolpad connected! Initializiing...</b>");
				termWait(0.2);
			end
			
			if activeInteractData == nil or activeInteractData.LockHydra == nil then
				error("No lock detected for this terminal..", 0);
				return;
			end
			local lockHydraInfo = activeInteractData.LockHydra;
			
			for y=1, 4 do
				local prHexTxt = "";
				for x=1, 16 do
					prHexTxt = prHexTxt.." "..hexPairList[math.random(1, #hexPairList)];
				end
				Interface.Println(prHexTxt);
				wait();
			end
			Interface.Println("\nAlgorithm injected! Opening interface..");
			termWait(0.5);
			
			local newLockHydra = modHackingMinigame.new();
			
			newLockHydra:Load{
				Key=activeInteractData.LockHydraKey;
				Seed=activeInteractData.LockHydraSeed;
				TargetInteractData=activeInteractData;
				LockHydraInfo=lockHydraInfo;
			}
			
			local lockHydraFrame = newLockHydra.Frame;
			lockHydraFrame.Size = UDim2.new(1, 0, 1, -30);
			lockHydraFrame.Parent = termFrame;
			
			activeApp = newLockHydra;
		end;
	};
	{
		CmdId = "clear";
		Desc = "Clears the screen.";
		Run=function()
			Interface.Cls();
		end
	};
	{
		CmdId = "fullscreen";
		Desc = "Fullscreens the terminal.";
		Run = function()
			toggleFullScreen();
		end;
	};
	{
		CmdId = "exit";
		Desc = "Exits the terminal.";
		Run=function()
			inputBox:ReleaseFocus();
			Interface:ToggleWindow("TerminalWindow", false);
		end
	};
}



--== Script;
function Interface.PrintlnLexer(...)
	if terminalFrame.Visible == false then return end;
	
	local new = templateTerminalLabel:Clone();
	new.Text = modZSharpLexer.buildStr(Debugger:Stringify(...), true);
	new.ZIndex = activeOutputFrame.ZIndex;
	new.Parent = activeOutputFrame;
	
	activeOutputFrame.CanvasPosition = Vector2.new(0, 99999);
end

function Interface.Println(...)
	if terminalFrame.Visible == false then return end;
	
	local new = templateTerminalLabel:Clone();
	new.Text = Debugger:Stringify(...);
	new.ZIndex = activeOutputFrame.ZIndex;
	new.Parent = activeOutputFrame;
	
	activeOutputFrame.CanvasPosition = Vector2.new(0, 99999);
end

function Interface.ProcessCmd(inputText)
	if proccessingCmd then return end;

	local cmd, args = modCommandHandler.ProcessMessage("/"..inputText);
	if cmd == nil then return end;
	local cmdId = cmd:sub(2, #cmd):lower();
	
	spawn(function()
		proccessingCmd = true;
		Interface.Println(">"..inputText);
		
		local cmdLib = Interface.TerminalCmds[cmdId];
		if cmdLib and (cmdLib.Check == nil or cmdLib.Check()) then
			if cmdLib.Run then
				local s, e = pcall(function()
					cmdLib.Run(args);
				end)
				
				if not s then
					Interface.Println("Command execution failed: <font color='rgb(143, 81, 81)'>".. tostring(e) .."</font>");
					Debugger:Warn(e);
				end
			else
				Interface.Println("Command ".. cmdId .." is not executable.");
			end
		else
			Interface.Println("'"..cmdId.."' is not recognized as a command.");
		end
		
		proccessingCmd = false;
		activeOutputFrame.CanvasPosition = Vector2.new(0, 99999);
	end)
end

function Interface.Cls()
	for _, obj in pairs(activeOutputFrame:GetChildren()) do
		if obj:IsA("GuiObject") then
			obj:Destroy();
		end
	end
end

function Interface:AddCommand(cmdLib)
	Interface.TerminalCmds[cmdLib.CmdId] = cmdLib;
end

terminalFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
	Interface:CloseWindow("TerminalWindow");
end)
terminalFrame:WaitForChild("TitleFrame"):WaitForChild("touchSizeButton"):WaitForChild("button").MouseButton1Click:Connect(function()
	Interface.ProcessCmd("fullscreen");
end)

function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local window = Interface.NewWindow("TerminalWindow", terminalFrame);
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.5, 0, -1.5, 0));
	window.CompactFullscreen = true;
	
	if modConfigurations.CompactInterface then
		terminalFrame:WaitForChild("UISizeConstraint"):Destroy();
	end
	window:AddCloseButton(terminalFrame);
	
	window.OnWindowToggle:Connect(function(visible, runProgram)
		if visible then
			if #hexPairList <= 0 then
				for a=0, 15 do
					for b=0, 15 do
						local hex = (hexConvert[a] or a)..(hexConvert[b] or b);
						table.insert(hexPairList, hex);
					end
				end
			end
			
			Interface:HideAll{[window.Name]=true;};
			Interface:ToggleInteraction(false);

			activeInteractData = Interface.InteractData;
			if activeInteractData then
				activeInteractData.UserId = localPlayer.UserId;
			end
			
			Interface.TerminalCmds = {};
			for a=1, #cmdsList do
				if cmdsList[a].Check == nil or cmdsList[a].Check() then
					Interface.TerminalCmds[cmdsList[a].CmdId] = cmdsList[a];
				end
			end
			
			if activeInteractData and activeInteractData.OnTerminal then
				activeInteractData.OnTerminal(Interface);
				
			else
				
				
			end
			
			Interface.Cls();
			
			seekIndex = 0;
			activeInputCache = "";
			inputBox.Text = "";
			
			if runProgram == nil then
				inputBox:CaptureFocus();
			
				Interface.Println("Welcome to the Revive Executable Console (R.E.C.) terminal:\n\nCommands: Type 'help' into terminal for list of commands.\n");
				
				Interface.Update();
				
				spawn(function()
					repeat until not window.Visible 
						or Interface.Object == nil 
						or not Interface.Object:IsDescendantOf(workspace) 
						or Interface.modCharacter.Player:DistanceFromCharacter(Interface.Object.Position) >= 16 
						or not wait(0.5);
					window:Close();
				end)
					
			else
				if #runProgram <= 0 or runProgram == "none" then
					inputBox:CaptureFocus();
					Interface.Println("Welcome to the Revive Executable Console (R.E.C.) terminal:\n\nCommands: Type 'help' into terminal for list of commands.\n");
					Interface.Update();
					
				else
					Interface.ProcessCmd(runProgram);
				end
			end
			
		else
			activeInteractData = nil;
			toggleFullScreen(false);
			inputBox:ReleaseFocus();
			delay(0.3, function()
				inputBox:ReleaseFocus();
				Interface:ToggleInteraction(true);
			end)

			game.Debris:AddItem(terminalFrame.Frame:FindFirstChild("TextEditor"), 0);
			templateTerminalLabel.TextSize = defaultFontSize;
			activeOutputFrame = scrollFrame;
			
			if activeApp then
				closeActiveApp(activeApp.ClassName);
			end
		end
	end)
	
	inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		local inputText = inputBox.Text;
		if seekIndex == 0 then
			activeInputCache = inputText;
		end
		
	end)
	
	inputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			inputBox.TextEditable = false;
			local inputText = inputBox.Text;
			if #inputText > 0 then
				table.insert(cacheInputs, 1, inputText);
			end;
			
			if #cacheInputs >= 10 then
				table.remove(cacheInputs, 10);
			end
			
			seekIndex = 0;
			Interface.ProcessCmd(inputText);
			inputBox.Text = "";
			
			RunService.Heartbeat:Wait();
			inputBox:CaptureFocus();
			inputBox.TextEditable = true;
		end
	end)
	
	Interface.Garbage:Tag(UserInputService.InputBegan:Connect(function(inputObject)
		if not inputBox:IsFocused() then return end;
		
		local pass = false;
		if inputObject.KeyCode == Enum.KeyCode.Up then
			seekIndex = math.clamp(seekIndex +1, 0, 10);
			pass = true;
			
		elseif inputObject.KeyCode == Enum.KeyCode.Down then
			seekIndex = math.clamp(seekIndex -1, 0, 10);
			pass = true;
			
		end
		
		if pass then
			if seekIndex == 0 then
				inputBox.Text = activeInputCache;
				
			elseif cacheInputs[seekIndex] then
				inputBox.Text = cacheInputs[seekIndex];
				
			end
			inputBox.CursorPosition = #inputBox.Text+1;
		end
	end))
	
	Interface.Garbage:Tag(modZSharpScript.ConsoleOutput:Connect(function(str)
		Interface.Println(str);
	end))
	
	task.spawn(function()
		while Debugger.LogRemote == nil do task.wait(); end;
		Debugger.LogRemote.OnClientEvent:Connect(function(str)
			Interface.Println(modRichFormatter.Color(Color3.fromRGB(255, 142, 58):ToHex(), "Server>>  "), modZSharpLexer.buildStr(str, true));
		end)
	end)

	return Interface;
end;



function Interface.Update()
	
end

return Interface;