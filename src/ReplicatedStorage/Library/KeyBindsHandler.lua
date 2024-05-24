local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local UserInputService = game:GetService("UserInputService");

local KeyBindsHandler = {};
KeyBindsHandler.__index = KeyBindsHandler;

KeyBindsHandler.DefaultKeybind = { --KeyBindsHandler.KeyBinds
	["KeySprint"]={Key=Enum.KeyCode.LeftShift;}; -- Enum.KeyCode.ButtonL3
	["KeyCrouch"]={Key=Enum.KeyCode.LeftControl;}; -- Enum.KeyCode.ButtonR3
	["KeyWalk"]={Key=Enum.KeyCode.LeftAlt;};
	["KeyJump"]={Key=Enum.KeyCode.Space;};
	
	["KeyFire"]={Key=Enum.UserInputType.MouseButton1}; -- Enum.KeyCode.ButtonR2
	["KeyFocus"]={Key=Enum.UserInputType.MouseButton2}; -- Enum.KeyCode.ButtonL2
	
	["KeyReload"]={Key=Enum.KeyCode.R}; -- Enum.KeyCode.ButtonB
	["KeyInspect"]={Key=Enum.KeyCode.F};
	["KeyToggleSpecial"]={Key=Enum.KeyCode.Q};
	["KeyTogglePat"]={Key=nil;};
	
	["KeyInteract"]={Key=Enum.KeyCode.E}; -- Enum.KeyCode.ButtonX
	
	["KeyHideHud"]={Key=nil;};
	["KeyCamSide"]={Key=nil;};
};

KeyBindsHandler.BindCache = {};


--== Script;
function KeyBindsHandler:GetKey(keyId)
	return self.KeyBinds[keyId] or KeyBindsHandler.DefaultKeybind[keyId];
end

function KeyBindsHandler:UpdateBindCache()
	local binds = {};
	
	for k, _ in pairs(KeyBindsHandler.DefaultKeybind) do
		local v = self.KeyBinds[k] or KeyBindsHandler.DefaultKeybind[k];
		
		if v.Key == nil then continue end;
		if binds[v.Key] == nil then
			binds[v.Key] = {};
		end
		
		binds[v.Key][k] = true;
	end
	
	self.BindCache = binds;
end

function KeyBindsHandler:GetKeyIds(inputObject)
	if inputObject == nil then return; end;
	
	local isKeyboard = inputObject.KeyCode ~= Enum.KeyCode.Unknown;
	local inputKey = isKeyboard and inputObject.KeyCode or inputObject.UserInputType;
	local keyIds = self.BindCache[inputKey];
	
	if keyIds == nil then
		self:UpdateBindCache();
		keyIds = self.BindCache[inputKey];
	end
	
	return keyIds;
end

function KeyBindsHandler:ToString(keyId, useDefault)
	local keyInfo = self:GetKey(keyId);
	
	if useDefault then
		keyInfo = KeyBindsHandler.DefaultKeybind[keyId];
	end
	
	if keyInfo == nil or keyInfo.Key == nil then return "None"; end
	local list = tostring(keyInfo.Key):split(".");
	if #list > 0 then return list[#list]; end
	return "None";
end

function KeyBindsHandler:Match(inputObject, keyId)
	if inputObject == nil then return false; end;
	local keyInfo = self:GetKey(keyId);
	if keyInfo == nil then return false; end;
	
	if inputObject.KeyCode == keyInfo.Key then
		return true;
	elseif inputObject.UserInputType == keyInfo.Key then
		return true;
	end
	return false;
end

function KeyBindsHandler:SetKey(keyId, key)
	if KeyBindsHandler.DefaultKeybind[keyId] == nil then return end;
	
	if key == nil then
		self.KeyBinds[keyId] = nil;
		
	else
		key = self:KeyCheck(key);
		if self.KeyBinds[keyId] == nil then self.KeyBinds[keyId] = {}; end;
		
		if key == "MouseButton1" or key == "MouseButton2" or key == "MouseButton3" then
			if keyId:sub(1, 9) ~= "KeyWindow" then
				self.KeyBinds[keyId].Key = Enum.UserInputType[key];
			end
		else
			self.KeyBinds[keyId].Key = Enum.KeyCode[key];
			
		end
	end
	
	self:UpdateBindCache();
end


function KeyBindsHandler:KeyCheck(key)
	local r = key;
	if key == "Escape" or key == "Backspace" or key == "Unknown" then return nil end;
	
	if key == "MouseButton1" or key == "MouseButton2" or key == "MouseButton3" then
		return r;
	end
	
	local s, e = pcall(function()
		local test = Enum.KeyCode[key];
	end)
	if not s then r = nil; end;
	return r;
end

function KeyBindsHandler:IsKeyDown(keyId)
	local keyInfo = self:GetKey(keyId);
	local key = self:ToString(keyId);
	
	if key == "MouseButton1" or key == "MouseButton2" or key == "MouseButton3" then
		local buttons = UserInputService:GetMouseButtonsPressed();
		for _, button in pairs(buttons) do
			if button.UserInputType.Name == key then
				return true;
			end
		end
	else
		return UserInputService:IsKeyDown(keyInfo.Key);
	end
	return false;
end

function KeyBindsHandler.new()
	local self = {
		KeyBinds = {};
	};
	
	setmetatable(self, KeyBindsHandler);
	return self;
end

function KeyBindsHandler:SetDefaultKey(windowName, keyCode)
	KeyBindsHandler.DefaultKeybind[windowName]={Key=keyCode};
end

local debounce = {};
function KeyBindsHandler:Debounce(keyId)
	if debounce[keyId] == nil or tick()-debounce[keyId] >= 0.1 then
		debounce[keyId] = tick();
		return false;
	end
	
	return true;
end

return KeyBindsHandler.new();