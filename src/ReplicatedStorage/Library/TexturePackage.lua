local TexturePackage = {};
TexturePackage.ClassName = "TexturePackage";
TexturePackage.__index = TexturePackage;

--function Texture:__index(key)
--	if key == "Image" then
--		local texturePacket = self.IdList[1];
		
--		if typeof(texturePacket) == "string" then
--			return texturePacket;
			
--		elseif typeof(texturePacket) == "table" then
--			return texturePacket.Id;
			
--		end
		
--		return "rbxasset://textures/ui/GuiImagePlaceholder.png"; --self.IdList[1];
--	end
--	return rawget(self, key);
--end

--function Texture:GetRotate(index)
--	assert(index, "GetRotate index can not be nil.");
--	return self.IdList[index];
--end

--function Texture:GetTextures()
--	return self.IdList;
--end

function TexturePackage:GetTexture()
	return #self.Pack > 0 and self.Pack[1].Id or "rbxasset://textures/ui/GuiImagePlaceholder.png";
end

function TexturePackage.new(id, textureIds)
	local self = {
		Id=id;
		Pack = {};
		UVPack = {};
	};
	
	
	if typeof(textureIds) == "string" then
		table.insert(self.Pack, {Id=textureIds;});
		
	elseif typeof(textureIds) == "table" then
		if #textureIds == 1 and typeof(textureIds[1]) == "string" then
			table.insert(self.Pack, {Id=textureIds[1];});
			
		else
			for a=1, #textureIds do
				table.insert(self.Pack, textureIds[a]);
			end
			for k, v in pairs(textureIds) do
				self.UVPack[k] = v;
			end
			
		end
	end
	
	setmetatable(self, TexturePackage);
	return self;
end

return TexturePackage;
