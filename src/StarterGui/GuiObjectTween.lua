local Module = {};
local TweenService = game:GetService("TweenService");
Module.FadeDirection = {In=0; Out=1;};

local Transparencies = {};
local FadeOuts = {
	Frame={
		BackgroundTransparency = 1;
	};
	TextButton={
		BackgroundTransparency = 1;
		TextTransparency = 1;
		TextStrokeTransparency = 1;
	};
	TextBox={
		BackgroundTransparency = 1;
		TextTransparency = 1;
		TextStrokeTransparency = 1;
	};
	TextLabel={
		BackgroundTransparency = 1;
		TextTransparency = 1;
		TextStrokeTransparency = 1;
	};
	ImageButton={
		BackgroundTransparency = 1;
		ImageTransparency = 1;
	};
	ImageLabel={
		BackgroundTransparency = 1;
		ImageTransparency = 1;
	};
	ScrollingFrame={
		BackgroundTransparency = 1;
	};
};

function Module.FadeTween(element, direction, tweenInfo, tweenPropertiesOverride)
	local list = element:GetDescendants();
	table.insert(list, element);
	
	local customFade;
	if direction > 0 and direction < 1 then
		customFade = {
			Frame={
				BackgroundTransparency = direction;
			};
			TextButton={
				BackgroundTransparency = direction;
				TextTransparency = direction;
				TextStrokeTransparency = direction;
			};
			TextBox={
				BackgroundTransparency = direction;
				TextTransparency = direction;
				TextStrokeTransparency = direction;
			};
			TextLabel={
				BackgroundTransparency = direction;
				TextTransparency = direction;
				TextStrokeTransparency = direction;
			};
			ImageButton={
				BackgroundTransparency = direction;
				ImageTransparency = direction;
			};
			ImageLabel={
				BackgroundTransparency = direction;
				ImageTransparency = direction;
			};
			ScrollingFrame={
				BackgroundTransparency = direction;
			};
		};
	end
	
	for a=1, #list do
		if list[a]:IsA("GuiObject") then
			local fullName = list[a]:GetFullName();
			local tweenProperties = Transparencies[fullName];
			
			if direction == Module.FadeDirection.Out then
				if tweenProperties == nil then
					Transparencies[fullName] = list[a]:IsA("Frame") and {
						BackgroundTransparency = list[a].BackgroundTransparency;
					}
					or list[a]:IsA("TextButton") and {
						BackgroundTransparency = list[a].BackgroundTransparency;
						TextTransparency = list[a].TextTransparency;
						TextStrokeTransparency = list[a].TextStrokeTransparency;
					}
					or list[a]:IsA("TextBox") and {
						BackgroundTransparency = list[a].BackgroundTransparency;
						TextTransparency = list[a].TextTransparency;
						TextStrokeTransparency = list[a].TextStrokeTransparency;
					}
					or list[a]:IsA("TextLabel") and {
						BackgroundTransparency = list[a].BackgroundTransparency;
						TextTransparency = list[a].TextTransparency;
						TextStrokeTransparency = list[a].TextStrokeTransparency;
					}
					or list[a]:IsA("ImageButton") and {
						BackgroundTransparency = list[a].BackgroundTransparency;
						ImageTransparency = list[a].ImageTransparency;
					}
					or list[a]:IsA("ImageLabel") and {
						BackgroundTransparency = list[a].BackgroundTransparency;
						ImageTransparency = list[a].ImageTransparency;
					}
					or list[a]:IsA("ScrollingFrame") and {
						BackgroundTransparency = list[a].BackgroundTransparency;
					}
				end
				
				tweenProperties = FadeOuts[list[a].ClassName];
			elseif direction > 0 then
				tweenProperties = customFade[list[a].ClassName];
			end
			
			if tweenPropertiesOverride then
				Transparencies[fullName] = tweenPropertiesOverride;
			end
			
			if tweenProperties then
				TweenService:Create(list[a], tweenInfo, tweenPropertiesOverride or tweenProperties):Play();
			end
		end
	end
end

return Module;
