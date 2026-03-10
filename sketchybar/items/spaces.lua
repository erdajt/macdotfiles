local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local spaces = {}
local space_brackets = {}
local space_paddings = {}

-- Add aerospace workspace change event
sbar.add("event", "aerospace_workspace_change")

local function update_spaces(focused_workspace)
	-- Get occupied workspaces
	sbar.exec("aerospace list-workspaces --monitor all --empty no", function(result)
		local occupied = {}
		if result then
			for line in result:gmatch("[^\r\n]+") do
				occupied[line] = true
			end
		end

		for i = 1, 10 do
			local ws = tostring(i)
			local is_focused = focused_workspace == ws
			local is_occupied = occupied[ws] or false
			local is_visible = is_focused or is_occupied

			spaces[i]:set({
				drawing = is_visible,
				icon = { highlight = is_focused },
				label = { highlight = is_focused },
				background = { border_color = is_focused and colors.black or colors.bg2 },
			})
			space_brackets[i]:set({
				drawing = is_visible,
				background = { border_color = is_focused and colors.grey or colors.bg2 },
			})
			space_paddings[i]:set({ drawing = is_visible })
		end
	end)
end

for i = 1, 10, 1 do
	local space = sbar.add("item", "space." .. i, {
		drawing = false,
		icon = {
			font = { family = settings.font.numbers },
			string = i,
			padding_left = 20,
			padding_right = 0,
			color = colors.white,
			highlight_color = colors.red,
		},
		label = {
			padding_right = 20,
			color = colors.grey,
			highlight_color = colors.white,
			font = "sketchybar-app-font:Regular:16.0",
			y_offset = -1,
		},
		padding_right = 1,
		padding_left = 1,
		background = {
			color = colors.bg1,
			border_width = 1,
			height = 26,
			border_color = colors.black,
		},
	})

	spaces[i] = space

	local space_bracket = sbar.add("bracket", { space.name }, {
		drawing = false,
		background = {
			color = colors.transparent,
			border_color = colors.bg2,
			height = 28,
			border_width = 2,
		},
	})
	space_brackets[i] = space_bracket

	local space_padding = sbar.add("item", "space.padding." .. i, {
		drawing = false,
		script = "",
		width = settings.group_paddings,
	})
	space_paddings[i] = space_padding

	space:subscribe("mouse.clicked", function(env)
		sbar.exec("aerospace workspace " .. i)
	end)
end

-- Single observer for workspace changes
local space_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})

space_observer:subscribe("aerospace_workspace_change", function(env)
	update_spaces(env.FOCUSED_WORKSPACE)
end)

-- Initial update - get current focused workspace
sbar.exec("aerospace list-workspaces --focused", function(focused)
	if focused then
		focused = focused:gsub("%s+", "")
		update_spaces(focused)
	end
end)

local spaces_indicator = sbar.add("item", {
	padding_left = -3,
	padding_right = 0,
	icon = {
		padding_left = 8,
		padding_right = 9,
		color = colors.grey,
		string = icons.switch.on,
	},
	label = {
		width = 0,
		padding_left = 0,
		padding_right = 8,
		string = "Spaces",
		color = colors.bg1,
	},
	background = {
		color = colors.with_alpha(colors.grey, 0.0),
		border_color = colors.with_alpha(colors.bg1, 0.0),
	},
})

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
	local currently_on = spaces_indicator:query().icon.value == icons.switch.on
	spaces_indicator:set({
		icon = currently_on and icons.switch.off or icons.switch.on,
	})
end)

spaces_indicator:subscribe("mouse.entered", function(env)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = { alpha = 1.0 },
				border_color = { alpha = 1.0 },
			},
			icon = { color = colors.bg1 },
			label = { width = "dynamic" },
		})
	end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = { alpha = 0.0 },
				border_color = { alpha = 0.0 },
			},
			icon = { color = colors.grey },
			label = { width = 0 },
		})
	end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
	sbar.trigger("swap_menus_and_spaces")
end)
