local UsableItems = {};
UsableItems.__index = UsableItems;
--== Script;
function UsableItems:Init(library)
	local function new(obj)
		if obj.ClassName ~= "ModuleScript" or obj.Name == "UsablePreset" then return end;
		local data = require(obj);
		data.Id = obj.Name;
		library:Add(data);
	end

	for _, obj in pairs(script:GetChildren()) do
		new(obj);
	end
	script.ChildAdded:Connect(function(obj)
		new(obj);
	end)
	
	local function add(data)
		local usableObj = require(script.Generics:FindFirstChild(data.Type));
		usableObj.__index = usableObj;
		
		local self = data;
		setmetatable(self, usableObj);
		
		library:Add(self);
	end
	
	
	--== Skin Permanent
	add{
		Id="arelshiftcrossantique";
		Type="SkinPerm";
	};
	
	add{
		Id="desolatorheavytoygun";
		Type="SkinPerm";
	};

	add{
		Id="czevo3asiimov";
		Type="SkinPerm";
	};

	add{
		Id="rusty48blaze";
		Type="SkinPerm";
	};
	
	-- sr308
	add{
		Id="sr308slaughterwoods";
		Type="SkinPerm";
	};
	add{
		Id="sr308horde";
		Type="SkinPerm";
	};


	add{
		Id="vectorxpossession";
		Type="SkinPerm";
	};
	
end

return UsableItems;