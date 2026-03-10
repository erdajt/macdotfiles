return {
	black = 0xff1a1b26, -- Darker background like TokyoNight
	white = 0xffc0caf5, -- Soft white-blueish tone
	red = 0xfff7768e, -- TokyoNight red
	green = 0xff9ece6a, -- TokyoNight green
	blue = 0xff7aa2f7, -- TokyoNight blue
	yellow = 0xffe0af68, -- TokyoNight yellow
	orange = 0xffff9e64, -- TokyoNight orange
	magenta = 0xffbb9af7, -- TokyoNight magenta
	grey = 0xff565f89, -- TokyoNight grey
	transparent = 0x00000000,

	bar = {
		bg = 0xff1a1b26, -- Darker TokyoNight background for the bar
		border = 0xff3b4261, -- Darker border matching TokyoNight theme
	},
	popup = {
		bg = 0xff1a1b26, -- Popup background
		border = 0xff565f89, -- Popup border matching the TokyoNight grey
	},
	bg1 = 0xff24283b, -- Slightly lighter background (TokyoNight's main background)
	bg2 = 0xff1a1b26, -- Darker background shade for contrast

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
