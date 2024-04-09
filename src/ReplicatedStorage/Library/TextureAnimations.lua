local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);

local library = modLibraryManager.new();
local TextureAnimations = {};
TextureAnimations.Library = library;

local lapse = 0;

library:Add{
	Id="SoftNoise";
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsU = texture.OffsetStudsU + delta;
		texture.OffsetStudsV = texture.OffsetStudsV + delta;
	end;
};

library:Add{
	Id="rbxassetid://4873625719";
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsU = texture.OffsetStudsU + delta;
		texture.OffsetStudsV = texture.OffsetStudsV + delta;
	end;
};

library:Add{
	Id="rbxassetid://7605228557";
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/5,1), 0.4, 1);
	end;
};

library:Add{
	Id="rbxassetid://7605250341";
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/5,1), 0.4, 1);
	end;
};

library:Add{
	Id="rbxassetid://8769490320";
	OnRenderStep=function(delta, texture)
		local parentPos = texture.Parent.Position;
		local parentOri = texture.Parent.Orientation;
		
		local ori = (parentOri.X + parentOri.Y + parentOri.Z)/360;
		texture.OffsetStudsU = (parentPos.X + parentPos.Z)/10 + ori
		texture.OffsetStudsV = (parentPos.Y)/10 + ori
	end;
};

library:Add{ --RGB snowsgiving
	Id="rbxassetid://11796312620"; --white background  --"rbxassetid://11787521160";
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/10,1), 0.5, 0.5);
	end;
};

library:Add{
	Id="rbxassetid://12960875825";
	OnRenderStep=function(delta, texture)
		local sineDelta = (math.sin(lapse/10)+1)/2;
		texture.StudsPerTileU =  0.5 + sineDelta;
		texture.StudsPerTileV = 0.5 + sineDelta;
		
		local colorA = texture:GetAttribute("ColorA") or Color3.fromRGB(74, 179, 86);
		local colorB = texture:GetAttribute("ColorB") or Color3.fromRGB(180, 169, 42);
		texture.Color3 = colorA:Lerp(colorB, (math.sin(lapse/10)+1)/2);
	end;
};

-- Cloud 
library:Add{
	Id="rbxassetid://14250875240";
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsU = texture.OffsetStudsU + delta*0.2;
	end;
};
library:Add{
	Id="rbxassetid://14250921231";
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsU = texture.OffsetStudsU - delta*0.2;
	end;
};
library:Add{
	Id="rbxassetid://14250924060";
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsV = texture.OffsetStudsV + delta*0.2;
	end;
};
library:Add{
	Id="rbxassetid://14250925805";
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsV = texture.OffsetStudsV - delta*0.2;
	end;
};

-- Halloween RGB
library:Add{
	Id="rbxassetid://15016521823";
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/5,1), 0.4, 1);
	end;
};
library:Add{
	Id="rbxassetid://15016528084";
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/5,1), 0.4, 1);
	end;
};


local active = false;
--== Script;

function TextureAnimations.Update()
	local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
	if modData.Settings.DisableTextureAnimation ~= true then
		if not active then
			active = true;
			RunService:BindToRenderStep("TextureAnimations", Enum.RenderPriority.Last.Value, function(delta)
				lapse = lapse + delta;
				
				local textures = CollectionService:GetTagged("AnimatedTextures");
				for a=1, #textures do
					local texture = textures[a];
					if texture:IsA("Texture") then
						local libId = texture:GetAttribute("TextureAnimationId");
						local lib = libId and library:Find(libId) or nil;
						
						if lib then
							lib.OnRenderStep(delta, texture);
						end
					end
				end
			end);
		end
	else
		if active then
			RunService:UnbindFromRenderStep("TextureAnimations");
			active = false;
		end
	end
end

return TextureAnimations;