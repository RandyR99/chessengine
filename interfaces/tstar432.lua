interface = load_interface("sstar28k")

function interface.get_module()
	if machine.system.name == "tstar432" then
		return "SciSys Turbostar 432"
	elseif machine.system.name == "tstar432a" then
		return "SciSys Turbostar 432 v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Julio Kaplan"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x,y
	send_input(":IN.0", 0x08, 0.5)	-- LEVEL
	while (level ~= "") do
		x = cols_idx[level:sub(1, 1)]
		y = level:sub(2, 2)
		sb_press_square(":board", 1, x, y)
		level = level:sub(4)
	end
	send_input(":IN.0", 0x08, 0.5)	-- LEVEL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	interface.invert = false
	emu.wait(6)
	send_input(":IN.0", 0x20, 1)	-- NEW GAME
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "a1"
	interface.setlevel()
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		local tmp = level .. " "
		while (tmp ~= "") do
			if (tmp:sub(1,3):match("[a-ch][1-8]%s") == nil) then
				return
			else
				tmp = tmp:sub(4)
			end
		end
		interface.level = level
		interface.setlevel()
	end
end

return interface
