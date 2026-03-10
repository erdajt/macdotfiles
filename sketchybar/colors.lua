-- Read active theme from aerospace state file
local theme_name = "tokyo-night"
local state_file = os.getenv("HOME") .. "/.config/aerospace/.theme-state"
local f = io.open(state_file, "r")
if f then
	theme_name = f:read("*l") or "tokyo-night"
	f:close()
end

-- Map theme names that share colors
local theme_map = {
	["tokyo-dracula"] = "tokyo-night",
}
theme_name = theme_map[theme_name] or theme_name

-- Load theme colors
local ok, theme = pcall(require, "themes." .. theme_name)
if not ok then
	theme = require("themes.tokyo-night")
end

-- Add with_alpha helper
theme.with_alpha = function(color, alpha)
	if alpha > 1.0 or alpha < 0.0 then
		return color
	end
	return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end

return theme
