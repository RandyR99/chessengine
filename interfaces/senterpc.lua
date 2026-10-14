interface = load_interface("senterp")

interface.opening = "standard"
interface.cur_opening = nil

function interface.setstyle()
	if (interface.cur_style == nil or interface.cur_style == interface.style) and
	   (interface.cur_opening == nil or interface.cur_opening == interface.opening) then
		return
	end
	interface.cur_style = interface.style
	interface.cur_opening = interface.opening
	send_input(":IN.1", 0x02, 0.5) -- Level
	local y = 1
	if interface.style == "aggressive" then y = 2
	elseif interface.style == "desperate" then y = 3
	elseif interface.style == "positional" then y = 4
	end
	if interface.opening == "rare" then y = y + 4
	end
	sb_press_square(":board", 0.5, 8, y)
	send_input(":IN.1", 0x02, 0.5) -- Level
end

function interface.setup_machine()
	sb_reset_board(":board")
	interface.invert = false
--	send_input(":IN.1", 0x80, 1)	-- New Game
	emu.wait(2)

	interface.cur_level = "a2"
	interface.setlevel()
	emu.wait(0.5)
	interface.cur_style = "normal"
	interface.cur_opening = "standard"
	interface.setstyle()
end

function interface.get_options()
	return { { "string", "Level", "a2"}, { "combo", "Opening", "standard", "standard\trare"},
		 { "combo", "Style", "normal", "normal\taggressive\tdesperate\tpositional"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if (level:match("^[a-e][1-8]$") or level:match("^f[1-4]$")) then
			interface.level = level
			interface.setlevel()
		end
	elseif (name == "style" and value ~= "") then
		interface.style = value
		interface.setstyle()
	elseif (name == "opening" and value ~= "") then
		interface.opening = value
		interface.setstyle()
	end
end

return interface
