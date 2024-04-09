local ScreenRelativeTextSize = {};

local TextScales = {
	H1=0.04;
	H2=0.035;
	H3=0.03;
	P=0.025;
}

function ScreenRelativeTextSize.GetTextSize(tag)
	local vpSize = workspace.CurrentCamera.ViewportSize.Y;
	local textSize = 18;
	if TextScales[tag] then
		textSize = vpSize * TextScales[tag];
	else
		textSize = vpSize * TextScales.P;
	end
	
	return math.clamp(textSize, 12, 54);
end

return ScreenRelativeTextSize;
