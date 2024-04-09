local JsonValidator = {};

local HttpService = game:GetService("HttpService");

function JsonValidator:Check(luaTable, layerPackage)
	if layerPackage == nil then
		layerPackage = {
			Log="Parsing error in root";
			Success=true;
			Layer=0;
		};
	end
	layerPackage.Layer = layerPackage.Layer +1;
	
	if layerPackage.Layer >= 5 then return layerPackage.Success, layerPackage.Log end;
	
	local testSuccess = pcall(function()
		HttpService:JSONEncode(luaTable);
	end)
	
	if not testSuccess then
		layerPackage.Success = false;
		layerPackage.Log = layerPackage.Log.."."..layerPackage.Key;
		
		for k, v in pairs(luaTable) do
			if typeof(v) == "table" then
				testSuccess = pcall(function()
					HttpService:JSONEncode(v);
				end)
				if not testSuccess then
					layerPackage.Key = k;
					JsonValidator:Check(v, layerPackage);
					break;
				end
			end
		end
	end
	return layerPackage.Success, layerPackage.Log;
end

return JsonValidator;