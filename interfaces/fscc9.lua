interface = {}

interface.opt_clear_announcements = true
interface.level = 1
interface.cur_level = nil
interface.black_setup = false -- set up with Black to move, machine not started yet

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "fscc9" then
		return "Fidelity Sensory 9"
	elseif machine.system.name == "fscc9b" then
		return "Fidelity Sensory 9 v2"
	elseif machine.system.name == "fscc9c" then
		return "Fidelity Sensory 9 v3"
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
	local led_code = { 1, 2, 4, 8, 16, 32, 64, 128, 255 }
	local cur_leds = 0
	local cur_level = 0
	local dif_level
	send_input(":IN.0", 0x08, 0.5) -- LV
	for y = 0, 7 do
		if output_value("7." .. 7-y) ~= 0 then
			cur_leds = cur_leds + (1 << y)
		end
	end
	repeat
		cur_level = cur_level + 1
	until cur_leds == led_code[cur_level]
	dif_level = interface.level - cur_level
	if (dif_level < 0) then
		dif_level = dif_level + 9
	end
	for y = 1, dif_level do
		send_input(":IN.0", 0x08, 0.6) -- LV
	end
	send_input(":IN.0", 0x40, 0.5) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	send_input(":IN.0", 0x40, 0.5) -- CL
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x80, 0.5) -- RE
		return (":board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local ram = machine.devices[':maincpu'].spaces['program']
		sb_press_square(":board", 0.5, 3, 5) -- Clear board
		send_input(":IN.0", 0x20, 0.5) -- PB
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x20 >> (math.abs(p) - 1), 0.5)
					end
					sb_press_square(":board", 1, x, 9 - y)
					if p < 0 then
						sb_press_square(":board", 1, x, 9 - y)
					end
					piece = p
				end
			end
		end
		if mode == -1 then
			ram:write_u8(0x008b, 0x10)
		end
		interface.black_setup = (mode == -1)
		send_input(":IN.0", 0x40, 0.5) -- CL
		machine.video.throttled = throttled_state
	end
end

function interface.edit_game(on)
	interface.black_setup = false
	if on then
		local ram = machine.devices[':maincpu'].spaces['program']
		ram:write_u8(0x00cd, ram:read_u8(0x00cd) | 0x08)
	end
end

function interface.start_play(init)
	interface.black_setup = false
	send_input(":IN.0", 0x01, 1) -- RV
end

function interface.clear_announcements()
	-- machine turns on all LEDs on the first line for mate/draw announcements
	if (output_value("0.7") ~= 0 and output_value("1.7") ~= 0 and output_value("2.7") ~= 0 and output_value("3.7") ~= 0 and
	    output_value("4.7") ~= 0 and output_value("5.7") ~= 0 and output_value("6.7") ~= 0 and output_value("7.7") ~= 0) then
		send_input(":IN.0", 0x40, 1)
	end
end

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end
	return output_value(tostring(x - 1) .. "." .. tostring(8 - y)) ~= 0
end

function interface.select_piece(x, y, event)
	if (event == "get") then
		interface.pawn_lifted = math.abs(get_piece_id(x, y)) == 6
	end
	sb_select_piece(":board", 1, x, y, event)
	-- after a Black-to-move setup the machine waits for RV after the player's move
	-- (a promotion presses it in promote, after the piece key)
	if (event == "put" and interface.black_setup and not (interface.pawn_lifted and (y == 1 or y == 8))) then
		interface.black_setup = false
		send_input(":IN.0", 0x01, 1) -- RV
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "9" },
		{ "check", "Clear announcements", "1" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 9) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
	if (name == "clear announcements") then
		interface.opt_clear_announcements = tonumber(value) == 1
	end
end

function interface.test_promotion(x, y)
	local function board_led(x, y)
		for i = 1, 5 do
			if output_value(tostring(x - 1) .. "." .. tostring(8 - y)) ~= 0 then
				send_input(":IN.0", 0x40, 0.5) -- CL
				return true
			end
			emu.wait(0.1)
		end
		return false
	end
	if (interface.opt_clear_announcements) then
		interface.clear_announcements()
	end
	send_input(":IN.0", 0x10, 0.5) -- PV
	send_input(":IN.0", 0x10, 0.5)
	if board_led(x, y) then
		return "Q"
	end
	send_input(":IN.0", 0x02, 0.5)
	if board_led(x, y) then
		return "N"
	end
	send_input(":IN.0", 0x04, 0.5)
	if board_led(x, y) then
		return "B"
	end
	send_input(":IN.0", 0x08, 0.5)
	if board_led(x, y) then
		return "R"
	end
	send_input(":IN.0", 0x40, 0.5) -- CL
	return "Q"
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x08, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x04, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x02, 1)
	end
	if interface.black_setup then
		interface.black_setup = false
		send_input(":IN.0", 0x01, 1) -- RV
	end
end

return interface
