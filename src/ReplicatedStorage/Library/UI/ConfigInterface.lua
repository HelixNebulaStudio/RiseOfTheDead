local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);

--==
local ConfigInterface = {}
ConfigInterface.__index = ConfigInterface;

function ConfigInterface.new()
	local self = {
		IndexCount = 0;
		Elements = {};
		
		Templates = script:WaitForChild("Templates");
		Frame = nil;
		
		Garbage = modGarbageHandler.new();
	};
	
	setmetatable(self, ConfigInterface);
	return self;
end

function ConfigInterface:SetTemplates(folder)
	self.Templates = folder;
end

function ConfigInterface:ClearAll()
	for a=1, #self.Elements do
		Debugger.Expire(self.Elements[a].Instance, 0);
		self.Elements[a].Instance = nil;
	end
end

function ConfigInterface:Add(parentName, templateName, paramPacket)
	paramPacket = paramPacket or {};
	self.IndexCount = paramPacket.Index or self.IndexCount +1;
	
	local newElement = {
		Id = paramPacket.Id or templateName..self.IndexCount;
		Index=self.IndexCount;
		
		ParentName=parentName;
		TemplateName=templateName;
		
		ClickOnRender=paramPacket.ClickOnRender;
		ButtonLink=paramPacket.ButtonLink;
		
		Properties={};
		
		Tags = {};
		
		Config = paramPacket.Config or {};
	};
	
	if paramPacket.Id then
		table.insert(newElement.Tags, paramPacket.Id);
	end
	if paramPacket.Text then
		table.insert(newElement.Tags, paramPacket.Text);
	end
	if paramPacket.Tags then
		for a=1, #paramPacket.Tags do
			table.insert(newElement.Tags, paramPacket.Tags[a]);
		end
	end
	
	local templateInstance = self.Templates[templateName];
	for k, v in pairs(paramPacket) do
		if typeof(v) ~= "table" then continue end;
		local isPropertyTable = string.match(k, "Properties") ~= nil;
		
		if isPropertyTable then
			local key = "";
			if k ~= "Properties" then
				key = string.gsub(k, "Properties", "");
			end
			
			local properties = v;
			newElement.Properties[key] = properties;
		end
	end
	
	table.insert(self.Elements, newElement);
end

function ConfigInterface:SetMenu(frame)
	self.Frame = frame;
end

function ConfigInterface:Render(mainInterface)
	local objCache = {};
	local clickOnRender = {};
	
	for a=1, #self.Elements do
		local elementInfo = self.Elements[a];
		
		local newTemplate = elementInfo.Instance;
		if newTemplate == nil then
			newTemplate = self.Templates[elementInfo.TemplateName]:Clone();
			newTemplate.Name = elementInfo.Id;
			
			newTemplate.Destroying:Connect(function()
				elementInfo.Instance = nil;
			end)
			
			if elementInfo.ButtonLink then
				elementInfo.OnClick = function()
					local pageObj = objCache[elementInfo.ButtonLink];
					
					for _, obj in pairs(pageObj.Parent:GetChildren()) do
						if obj:IsA("GuiObject") then
							obj.Visible = false;
						end
					end
					pageObj.Visible = true;
				end
				
				newTemplate.MouseButton1Click:Connect(elementInfo.OnClick);
				
				if elementInfo.ClickOnRender then
					table.insert(clickOnRender, elementInfo.OnClick);
				end
			end
			
			elementInfo.Instance = newTemplate;
		end
		objCache[elementInfo.Id] = newTemplate;
		
		for insName, properties in pairs(elementInfo.Properties) do
			local inst = newTemplate;
			local hierachyList = insName ~= "" and string.split(insName, ".") or {};
			
			local s, e = pcall(function()
				for a=1, #hierachyList do
					inst = inst:WaitForChild(hierachyList[a]);
				end
				
				for k, v in pairs(properties) do
					inst[k] = v;
				end
			end) if not s then Debugger:Warn(e, insName, properties) end;
		end
		
		local parentInstance = objCache[elementInfo.ParentName] or self.Frame[elementInfo.ParentName];
		newTemplate.Parent = parentInstance;
	end
	
	for a=1, #clickOnRender do
		clickOnRender[a]();
	end
end

function ConfigInterface:Destroy()
	self.Garbage:Destruct();
end

return ConfigInterface;
