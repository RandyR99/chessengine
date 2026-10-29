interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.opt_clear_announcements = true
interface.level = 1
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "feleg" then
		return "Fidelity Elegance"
	elseif machine.system.name == "felega" then
		return "Fidelity Elegance v2"
	elseif machine.system.name == "felega1" then
		return "Fidelity Elegance v3"
	elseif machine.system.name == "felega2" then
		return "Fidelity Elegance v4"
	elseif machine.system.name == "felega3" then
		return "Fidelity Elegance v5"
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
	local led_code = { 1, 2, 4, 8, 16, 32, 64, 128, 255, 63, 31, 15 }
	local cur_leds = 0
	local cur_level = 0
	local dif_level
	send_input(":IN.0", 0x08, 1) -- LV
	for y = 0, 7 do
		if output_value("7." .. y) ~= 0 then
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
		send_input(":IN.0", 0x08, 0.5) -- LV
	end
	send_input(":IN.0", 0x40, 1) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	send_input(":IN.0", 0x80, 0.3) -- RE
	if machine.system.name ~= "feleg" then
		sb_press_square(":board", 0.3, 4, 8)  -- D8
		send_input(":IN.0", 0x40, 0.3) -- CL
	end
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		if machine.system.name == "feleg" then
			send_input(":IN.0", 0x20, 0.5) -- PB
		else
			send_input(":IN.0", 0x80, 0.5) -- RE
		end
		sb_press_square(":board", 0.5, 4, 7) -- Clear board
		send_input(":IN.0", 0x40, 0.5) -- CL
		send_input(":IN.0", 0x20, 0.5) -- PB
		if machine.system.name == "feleg" then
			send_input(":IN.0", 0x10, 0.5) -- PV
		end
		sb_clear_board(":board")
		machine.video.throttled = throttled_state
		return ("")
	else
		local piece = 7
		local z
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x20 >> (math.abs(p) - 1), 0.5)
					end
					if p > 0 then
						z = 6 - p
					else
						z = 12 + p
					end
					send_input(":board:SPAWN", 0x01 << z, 0.09)
					sb_select_piece(":board", 1, x, 9 - y, "put")
					if p < 0 then
						sb_select_piece(":board", 1, x, 9 - y, "get")
						sb_select_piece(":board", 1, x, 9 - y, "put")
					end
					piece = p
				end
			end
		end
		send_input(":IN.0", 0x40, 0.5) -- CL
		if mode == -1 then
			if machine.system.name == "feleg" then
				send_input(":IN.0", 0x20, 0.5) -- PB
			else
				send_input(":IN.0", 0x80, 0.5) -- RE
			end
			sb_press_square(":board", 0.5, 4, 5) -- Change color
			send_input(":IN.0", 0x40, 0.5) -- CL
		end
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if machine.system.name == "feleg" then
		send_input(":IN.0", 0x20, 0.5) -- PB
	else
		send_input(":IN.0", 0x80, 0.5) -- RE
	end
	sb_press_square(":board", 1, 5, 6)
	send_input(":IN.0", 0x40, 0.5) -- CL
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.0", 0x01, 1) -- RV
end

function interface.clear_announcements()
	-- machine turns on all leds on the first line for mate/draw announcements
	local all_lit = true
	for i = 0, 7 do
		if output_value(i .. ".0") == 0 then
			all_lit = false
		end
	end
	if all_lit then
		send_input(":IN.0", 0x40, 1)
	end
end

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end

	return output_value((x - 1) .. "." .. (y - 1)) ~= 0
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

function interface.get_promotion_led()
	if     (output_value("8.6") ~= 0) then return 'q'
	elseif (output_value("8.5") ~= 0) then return 'r'
	elseif (output_value("8.4") ~= 0) then return 'b'
	elseif (output_value("8.3") ~= 0) then return 'n'
	end
	return nil
end

function interface.get_promotion(x, y)
	-- in a capture the piece leds show the captured piece: use test_promotion
	-- (the square is also occupied when this is called again after the move)
	if (get_piece_id(x, y) ~= 0) then
		return nil
	end
	if (interface.opt_clear_announcements) then
		interface.clear_announcements()
	end
	interface.select_piece(x, y, "")
	local new_type = nil
	for i = 1, 5 do
		emu.wait(0.25)
		new_type = interface.get_promotion_led()
		if (new_type ~= nil) then
			break
		end
	end
	interface.select_piece(x, y, "")
	return new_type
end

function interface.test_promotion(x, y)
	-- Position Verification: PV, then a piece key lights the squares with that piece
	local function piece_led(code)
		send_input(":IN.0", code, 0.5)
		for i = 1, 8 do
			if (output_value((x - 1) .. "." .. (y - 1)) ~= 0) then
				return true
			end
			emu.wait(0.15)
		end
		return false
	end

	local p
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(1)
	send_input(":IN.0", 0x10, 0.5) -- PV
	if     piece_led(0x10) then p = "Q"
	elseif piece_led(0x08) then p = "R"
	elseif piece_led(0x04) then p = "B"
	elseif piece_led(0x02) then p = "N"
	else p = "Q"
	end
	send_input(":IN.0", 0x40, 0.5) -- CL
	machine.video.throttled = throttled_state
	return p
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

