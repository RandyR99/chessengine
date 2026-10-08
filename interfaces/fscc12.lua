interface = {}

interface.opt_clear_announcements = true
interface.level = 1
interface.cur_level = nil
interface.edit = false

function interface.get_module()
	if machine.system.name == "fscc12" then
		return "Fidelity Sensory 12"
	elseif machine.system.name == "fscc12a" then
		return "Fidelity Sensory 12 v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local led_code = { 1, 2, 4, 8, 16, 32, 64, 128, 192, 96, 48, 24 }
	local cur_leds = 0
	local cur_level = 0
	local dif_level
	send_input(":IN.0", 0x08, 0.5) -- LV
	for y = 0, 7 do
		local led_name = "1." .. tostring(7 - y)
		local led_state = machine.devices[":"]:output(led_name)
		if led_state and led_state:get() ~= 0 then
			cur_leds = cur_leds + (1 << y)
		end
	end
	repeat
		cur_level = cur_level + 1
	until cur_leds == led_code[cur_level]
	dif_level = interface.level - cur_level
	if (dif_level < 0) then
		dif_level = dif_level + 12
	end
	for y = 1, dif_level do
		send_input(":IN.0", 0x08, 0.7) -- LV
	end
	send_input(":IN.0", 0x40, 0.5) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	send_input(":IN.0", 0x80, 0.5) -- RE
	emu.wait(1)
	send_input(":IN.0", 0x40, 0.5) -- CL
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		if machine.system.name == "fscc12" then
			send_input(":IN.0", 0x20, 1) -- PB
		else
			send_input(":IN.0", 0x80, 1) -- RE
		end
		emu.wait(1)
		sb_press_square(":board", 1, 1, 7) -- Clear board
		emu.wait(1)
		send_input(":IN.0", 0x40, 1) -- CL
		emu.wait(1)
		send_input(":IN.0", 0x20, 1) -- PB
		if machine.system.name == "fscc12" then
			emu.wait(1)
			send_input(":IN.0", 0x10, 1) -- PV
		end
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x40 >> math.abs(p), 0.5)
					end
					sb_press_square(":board", 0.5, x, 9 - y)
					if p < 0 then
						sb_press_square(":board", 0.5, x, 9 - y)
					end
					piece = p
				end
			end
		end
		send_input(":IN.0", 0x40, 1) -- CL
		if mode == -1 then
			emu.wait(1)
			if machine.system.name == "fscc12" then
				send_input(":IN.0", 0x20, 1) -- PB
			else
				send_input(":IN.0", 0x80, 1) -- RE
			end
			emu.wait(1)
			sb_press_square(":board", 1, 1, 5) -- Change color
			emu.wait(1)
			send_input(":IN.0", 0x40, 1) -- CL
		end
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if machine.system.name == "fscc12" then
		send_input(":IN.0", 0x20, 1) -- PB
	else
		send_input(":IN.0", 0x80, 1) -- RE
	end
	sb_press_square(":board", 1, 6, 1)
	send_input(":IN.0", 0x40, 1) -- CL
	interface.edit = on
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.0", 0x01, 1) -- RV
end

function interface.is_led_on(tag, idx)
	for i = 1, 4 do
		local led_name = tag .. tostring(idx)
		local led_state = machine.devices[":"]:output(led_name)
		if not led_state or led_state:get() == 0 then
			return false
		end
		emu.wait(0.15)
	end
	return true
end

function interface.clear_announcements()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local lastval = {}
	for i = 1, 6 do
		local led_name = "0." .. tostring(i)
		local led_state = machine.devices[":"]:output(led_name)
		lastval[i] = (led_state and led_state:get() or 0)
	end
	emu.wait(0.25)
	for i = 1, 6 do
		local led_name = "0." .. tostring(i)
		local led_state = machine.devices[":"]:output(led_name)
		local current_val = (led_state and led_state:get() or 0)
		if (current_val ~= lastval[i]) then
			send_input(":IN.0", 0x40, 1)
		end
	end
	machine.video.throttled = throttled_state
end

function interface.is_selected(x, y)
	if (interface.edit == false and interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end
	local row_led_name = "1." .. tostring(8 - y)
	local row_led_state = machine.devices[":"]:output(row_led_name)
	local is_row_on = (row_led_state and row_led_state:get() ~= 0)
	
	return is_row_on and interface.is_led_on("0.", x - 1)
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "12" },
		{ "check", "Clear announcements", "1" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 12) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
	if (name == "clear announcements") then
		interface.opt_clear_announcements = tonumber(value) == 1
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- TODO
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x08, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x04, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x02, 1)
	end
end

return interface

