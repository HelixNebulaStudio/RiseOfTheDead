local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);

local library = modLibraryManager.new();

library.TextureOffsetDir = {
	[Enum.NormalId.Left] = Vector2.new(-1, 1);
}

local lapse = 0;
--==

-- MARK: directional;
library:Add{
	Id="Right";
	OnRenderStep=function(delta, texture, dir)
		texture.OffsetStudsU = texture.OffsetStudsU + delta*0.2;
	end;
};
library:Add{
	Id="Left";
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsU = texture.OffsetStudsU - delta*0.2;
	end;
};
library:Add{
	Id="Up";
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsV = texture.OffsetStudsV + delta*0.2;
	end;
};
library:Add{
	Id="Down";
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsV = texture.OffsetStudsV - delta*0.2;
	end;
};

-- MARK: Special
library:Add{
	Id="SoftMotion";
	OnRenderStep=function(delta, texture, dir)
		texture.OffsetStudsU = texture.OffsetStudsU + (delta * dir.X)/10;
		texture.OffsetStudsV = texture.OffsetStudsV + (delta * dir.Y)/10;
	end;
};

library:Add{
	Id="Parallax";
	OnRenderStep=function(delta, texture, dir)
		local parentPos = texture.Parent.Position;
		local parentOri = texture.Parent.Orientation;
		
		local ori = (parentOri.X + parentOri.Y + parentOri.Z)/360;
		texture.OffsetStudsU = (parentPos.X + parentPos.Z)* dir.X/10 + ori
		texture.OffsetStudsV = (parentPos.Y)* dir.Y/10 + ori
	end;
};

library:Add{
	Id="FadeRGB";
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/5,1), 0.4, 1);
	end;
};

library:Add{
	Id="HueShiftHalfSat";
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/10,1), 0.5, 1);
	end;
};

library:Add{
	Id="HueShift";
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/10,1), 1, 1);
	end;
};




--== Outdated lib;
library:Add{
	Id="SoftNoise";
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsU = texture.OffsetStudsU + delta;
		texture.OffsetStudsV = texture.OffsetStudsV + delta;
	end;
};

library:Add{
	Id="rbxassetid://4873625719"; -- cotton fade
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsU = texture.OffsetStudsU + delta;
		texture.OffsetStudsV = texture.OffsetStudsV + delta;
	end;
};

library:Add{
	Id="rbxassetid://7605228557"; -- Spooky Skeletons RGB
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/5,1), 0.4, 1);
	end;
};

library:Add{
	Id="rbxassetid://7605250341"; -- Haunted Ghost RGB
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/5,1), 0.4, 1);
	end;
};

library:Add{
	Id="rbxassetid://8769490320"; -- Galaxy
	OnRenderStep=function(delta, texture)
		local parentPos = texture.Parent.Position;
		local parentOri = texture.Parent.Orientation;
		
		local ori = (parentOri.X + parentOri.Y + parentOri.Z)/360;
		texture.OffsetStudsU = (parentPos.X + parentPos.Z)/10 + ori
		texture.OffsetStudsV = (parentPos.Y)/10 + ori
	end;
};

library:Add{ --RGB Frostivus background
	Id="rbxassetid://11796312620"; --white background  --"rbxassetid://11787521160";
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/10,1), 0.5, 0.5);
	end;
};

library:Add{
	Id="rbxassetid://12960875825"; -- fallen leaves
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
	Id="rbxassetid://14250875240"; -- cloud right motion;
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsU = texture.OffsetStudsU + delta*0.2;
	end;
};
library:Add{
	Id="rbxassetid://14250921231"; -- cloud left motion;
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsU = texture.OffsetStudsU - delta*0.2;
	end;
};
library:Add{
	Id="rbxassetid://14250924060"; -- cloud up motion;
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsV = texture.OffsetStudsV + delta*0.2;
	end;
};
library:Add{
	Id="rbxassetid://14250925805"; -- cloud down motion;
	OnRenderStep=function(delta, texture)
		texture.OffsetStudsV = texture.OffsetStudsV - delta*0.2;
	end;
};

-- Halloween RGB
library:Add{
	Id="rbxassetid://15016521823"; -- Skulls RGB
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/5,1), 0.4, 1);
	end;
};
library:Add{
	Id="rbxassetid://15016528084"; -- Ghosts RGB
	OnRenderStep=function(delta, texture)
		texture.Color3 = Color3.fromHSV(math.fmod(lapse/5,1), 0.4, 1);
	end;
};



local active = false;
local checkSetting = tick();
--== Script;

function library.Update()
	local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	local textureStepBuffer = modData:GetSetting("TextureStepBuffer") or 2;

	if textureStepBuffer <= 7 then
		if not active then
			active = true;

			local stepBuffer = 0;
			RunService:BindToRenderStep("TextureAnimations", Enum.RenderPriority.Last.Value, function(delta)
				if stepBuffer >0 then 
					stepBuffer = math.max(stepBuffer-1, 0);
					return; 
				end;
				if tick()-checkSetting >= 1 then
					checkSetting = tick();
					textureStepBuffer = modData:GetSetting("TextureStepBuffer") or 2;
				end
				if textureStepBuffer >= 8 then
					return;

				elseif textureStepBuffer > 1 then
					stepBuffer = textureStepBuffer;
					delta = delta *textureStepBuffer;

				end

				lapse = lapse + delta;
				
				local textures = CollectionService:GetTagged("AnimatedTextures");
				for a=1, #textures do
					local texture: Texture = textures[a];
					if not texture:IsA("Texture") then continue end;

					local libId = texture:GetAttribute("TextureAnimationId");
					local lib = libId and library:Find(libId) or nil;
					
					if lib then
						local dir = library.TextureOffsetDir[texture.Face] or Vector2.one;
						lib.OnRenderStep(delta, texture, dir);
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

return library;