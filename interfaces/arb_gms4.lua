interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function led_on(name)
	local led = machine.devices[":"]:output(name)
	return led ~= nil and led:get() ~= 0
end

interface.opt_clear_announcements = true
interface.level = 0
interface.cur_level = nil

function interface.get_module()
	return "Grand Master Series 4"
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
	local led_code = {1, 2, 4, 8, 16, 32, 64, 128, 129}
	local cur_leds = 0
	local cur_level = 0
	local dif_level
	send_input(":IN.0", 0x40, 0.5) -- Change Level
	for y = 0, 7 do
		if led_on("8." .. (7 - y)) then
			cur_leds = cur_leds + (1 << y)
		end
	end
	while cur_leds ~= led_code[cur_level + 1] do
		cur_level = cur_level + 1
	end
	dif_level = interface.level - cur_level
	if (dif_level < 0) then
		dif_level = dif_level + 9
	end
	for y = 1, dif_level do
		send_input(":IN.0", 0x40, 0.5) -- Change Level
	end
	emu.wait(0.5)
	send_input(":IN.0", 0x02, 0.5) -- Clear
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(1)
	send_input(":IN.0", 0x80, 0.5) -- New Game
	sb_press_square(":board", 1, 4, 8) -- d8
	send_input(":IN.0", 0x02, 0.5) -- Clear
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 0
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x80, 0.5) -- OPTIONS / New Game
		sb_press_square(":board", 1, 4, 7) -- d7
		send_input(":IN.0", 0x02, 0.5) -- Clear
		sb_clear_board(":board")
		send_input(":IN.0", 0x10, 0.5) -- Change Board
		machine.video.throttled = throttled_state
		return ("")
	else
		local piece = 7
		local z
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x ,9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x01 << (math.abs(p) + 1), 0.5)
					end
					if p > 0 then
						z = 6 - p
					else
						z = 12 + p
					end
					send_input(":board:SPAWN", 0x01 << z, 0.09)
					sb_select_piece(":board", 0.5, x, 9-y, "put")
					if p<0 then
						sb_select_piece(":board", 0.5, x, 9-y, "get")
						sb_select_piece(":board", 0.5, x, 9-y, "put")
					end
					piece = p
				end
			end
		end
		send_input(":IN.0", 0x02, 0.5) -- Clear
		if mode==-1 then
			send_input(":IN.0", 0x80, 0.5) -- Options
			sb_press_square(":board", 1, 4, 5) -- d5
		end
		send_input(":IN.0", 0x02, 0.5) -- Clear
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	send_input(":IN.0", 0x80, 0.5) -- OPTIONS / New Game
	sb_press_square(":board", 1, 5, 6) -- e6
	send_input(":IN.0", 0x02, 0.5) -- Clear
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":IN.0", 0x20, 0.5) -- Change Color
	emu.wait(0.5)
end

function interface.stop_play()
	send_input(":IN.1", 0x02, 0.5) -- HALT
end

function interface.clear_announcements()
	if (led_on("0.0") and led_on("1.1") and
		led_on("2.2") and led_on("3.3") and
		led_on("4.4") and led_on("5.5") and
		led_on("6.6") and led_on("7.7") and
		led_on("0.7") and led_on("1.6") and
		led_on("2.5") and led_on("3.4") and
		led_on("4.3") and led_on("5.2") and
		led_on("6.1") and led_on("7.0")) then
		send_input(":IN.0", 0x02, 0.5) -- Clear
	end
end

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
		emu.wait(0.5)
	end
	return led_on((x - 1) .. "." .. (y - 1))
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "0", "0", "8" },
		{ "check", "Clear announcements", "1" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		value = value:gsub("_", " ")
		local level = tonumber(value)
		if (level < 0 or level > 8) then
			return
		end
		interface.level = level
		interface.setlevel()
	elseif (name == "clear announcements") then
		interface.opt_clear_announcements = tonumber(value) == 1
	end
end

function interface.test_promotion(x, y)
	local function board_led(x, y)
		for i = 1, 5 do
			if (led_on((x - 1) .. "." .. (y - 1))) then
				send_input(":IN.0", 0x02, 0.5) -- Clear
				return true
			end
			emu.wait(0.1)
		end
		return false
	end
	send_input(":IN.0", 0x08, 0.5) -- Verify
	send_input(":IN.0", 0x08, 0.5)
	if board_led(x, y) then
		return "Q"
	end
	send_input(":IN.0", 0x40, 0.5)
	if board_led(x, y) then
		return "N"
	end
	send_input(":IN.0", 0x20, 0.5)
	if board_led(x, y) then
		return "B"
	end
	send_input(":IN.0", 0x10, 0.5)
	if board_led(x, y) then
		return "R"
	end
	send_input(":IN.0", 0x02, 0.5) -- Clear
	return "Q"
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.0", 0x08, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x20, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x40, 1)
	end
end

return interface
