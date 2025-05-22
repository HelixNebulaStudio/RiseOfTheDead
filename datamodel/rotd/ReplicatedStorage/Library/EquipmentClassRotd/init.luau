local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local EquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local _Update = EquipmentClass.Update;
function EquipmentClass:Update(storageItem: StorageItem)
    _Update(self, storageItem);
end

function EquipmentClass.onRequire()
    local function loadModified(m: ModuleScript)
        if not m:IsA("ModuleScript") or m.Name == "Template" then return end;

        local baseEquipmentClassScript = EquipmentClass.Script:FindFirstChild(m.Name);
        if baseEquipmentClassScript then
            baseEquipmentClassScript:Destroy();
        end

        m.Parent = EquipmentClass.Script;
    end

	for _, m in pairs(script:GetChildren()) do
        loadModified(m);
	end
	script.ChildAdded:Connect(loadModified);
end

return EquipmentClass;