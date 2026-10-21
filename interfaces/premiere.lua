interface = {}

if ioport.ports[":IN.3"]:read() & 0x01 ~= 0 then -- Program switch: 2265
	return load_interface("feagv4")
end

interface.opt_clear_announcements = true
interface.level = "a2"
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Fidelity Elite Premiere Vancouver"
end

function interface.get_author()
	return "Richard Lang"
end

function interface.setdigit(n,d,m)
	local lcd_num = { 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67 }
	local led = n
	if (led == 1) then
		led = 0
	end
	local cd = output_value("digit" .. led)
	while (cd == 0x00) do
		emu.wait(0.25)
		cd = output_value("digit" .. led)
	end
	
	n = 0
	while (cd ~= lcd_num[n + 1]) do
		n = n + 1
		if n > 10 then break end -- Infinite breakout guard
	end
	local k = d - n
	if (k > m / 2) then
		k = k - m
	elseif (k < -m / 2) then
		k = k + m
	end
	for i = 1, math.abs(k) do
		if (k > 0) then
			send_input(":IN.0", 0x10, 0.5) -- ST
		else
			send_input(":IN.0", 0x08, 0.5) -- TB
		end
	end
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
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = interface.level:sub(2, 2)
	send_input(":IN.0", 0x04, 0.5)  -- LV
	if (level:len() == 2) then
		sb_press_square(":board", 1, x, y)
	elseif (level:sub(1,2) == "f1" or level:sub(1,2) == "f2") then
		sb_press_square(":board", 1, x, y)
		level = level:sub(4)
		local d = 0
		d = level:sub(2,2)
		interface.setdigit(3,d,10)
		send_input(":IN.0", 0x04, 0.5)  -- LV
		d = level:sub(1,1)
		interface.setdigit(2,d,2)
	else
		level = level:sub(3)
		y = 1
		local d = 0
		while (level ~= "") do
			sb_press_square(":board", 1, x, y)
			d = level:sub(1,1)
			interface.setdigit(1,d,10)
			send_input(":IN.0", 0x04, 0.5)  -- LV
			d = level:sub(3,3)
			interface.setdigit(2,d,6)
			send_input(":IN.0", 0x04, 0.5)  -- LV
			d = level:sub(4,4)
			interface.setdigit(3,d,10)
			if level:sub(5,5) == "/" then
				sb_press_square(":board", 1, x, y + 1)
				d = level:sub(6,6)
				interface.setdigit(2,d,10)
				send_input(":IN.0", 0x04, 0.5)  -- LV
				d = level:sub(7,7)
				interface.setdigit(3,d,10)
				level = level:sub(9)
				y = y + 2
			else
				level = level:sub(6)
				y = y + 1
			end
		end
	end
	emu.wait(0.5)
	send_input(":IN.1", 0x01, 0.5) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(5)
	send_input(":IN.1", 0x04, 1) -- New Game
	emu.wait(3)
	
	-- Sound Off
	send_input(":IN.0", 0x02, 1) -- option
	emu.wait(0.2)
	if output_value("0.9") == 0 then
		sb_press_square(":board", 1, 2, 1)  -- b1
		emu.wait(0.5)
	end
	send_input(":IN.1", 0x01, 1) -- clear
	emu.wait(0.2)
	
	-- Ponder ON
	send_input(":IN.0", 0x02, 1) -- option
	emu.wait(0.2)
	if output_value("0.8") ~= 0 then
		sb_press_square(":board", 1, 1, 1)  -- a1
		emu.wait(0.5)
	end
	send_input(":IN.1", 0x01, 1) -- clear
	emu.wait(0.2)
	
	-- Book ON
	send_input(":IN.0", 0x02, 1) -- option
	emu.wait(0.2)
	if output_value("0.14") ~= 0 then
		sb_press_square(":board", 1, 7, 1)  -- g1
		emu.wait(0.5)
	end
	send_input(":IN.1", 0x01, 1) -- clear
	emu.wait(0.2)
	
	-- Monitor OFF
	send_input(":IN.0", 0x02, 1) -- option
	emu.wait(0.2)
	if output_value("0.10") ~= 0 then
		sb_press_square(":board", 1, 3, 1)  -- c1
		emu.wait(0.5)
	end
	send_input(":IN.1", 0x01, 1) -- clear
	
	machine.video.throttled = throttled_state
	interface.cur_level = "a2"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x80, 0.5) -- PB
		send_input(":IN.0", 0x02, 0.5) -- OPTION
		sb_clear_board(":board")
		emu.wait(1)
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
						send_input(":IN.0", 0x80 >> (math.abs(p) - 1), 0.5)
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
		if mode == -1 then
			send_input(":IN.0", 0x01, 0.5) -- RV
		end
		send_input(":IN.1", 0x01, 0.5) -- CL
		emu.wait(5) -- a move right after leaving Problem Mode is ignored
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x02, 0.5) -- OPTION
	sb_press_square(":board", 1, 3, 1) -- c1: Monitor Mode on/off
	send_input(":IN.1", 0x01, 0.5) -- CL
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.0", 0x01, 1) -- RV
end

function interface.clear_announcements()

	local d0 = output_value("digit0")
	local d1 = output_value("digit1")
	local d2 = output_value("digit2")
	local d3 = output_value("digit3")
	local d5 = output_value("digit5")
	local d6 = output_value("digit6")
	local d7 = output_value("digit7")
	local d8 = output_value("digit8")

	if ((d5 == 0x37 and d8 ~= 0x00) or (d0 == 0x37 and d3 ~= 0x00) or
	   (d6 == 0x5e and d5 == 0x50 and d8 == 0x4f) or (d1 == 0x5e and d0 == 0x50 and d3 == 0x4f) or
	   (d6 == 0x5e and d5 == 0x50 and d7 == 0x6d and d8 == 0x3f) or (d1 == 0x5e and d0 == 0x50 and d2 == 0x6d and d3 == 0x3f)) then
		send_input(":IN.1", 0x01, 1) -- CL
	end
end

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end
	return output_value((y - 1) .. "." .. (7 + x)) ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "a2" },
		{ "check", "Clear announcements", "1" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:match("^[a-e][1-8]$") or level:match("^f[3-8]$")
		or  level:match("^f1%s0[1-9]$") or level:match("^f1%s1[0-6]$")
		or  level:match("^f2%s0[0-9]$") or level:match("^f2%s[12][0-9]$")
		or  level:match("^[gh]%s%d:[0-5]%d/%d%d$")
		or  level:match("^[gh]%s%d:[0-5]%d/%d%d%s%d:[0-5]%d/%d%d$")
		or  level:match("^[gh]%s%d:[0-5]%d/%d%d%s%d:[0-5]%d/%d%d%s%d:[0-5]%d")) then
			interface.level = level
			interface.setlevel()
		end
	end
	if (name == "clear announcements") then
		interface.opt_clear_announcements = tonumber(value) == 1
	end
end

function interface.get_promotion_led()
	
	if     (output_value("8.12") ~= 0) then return 'q'
	elseif (output_value("8.11") ~= 0) then return 'r'
	elseif (output_value("8.10") ~= 0) then return 'b'
	elseif (output_value("8.9") ~= 0) then return 'n'
	end
	return nil
end

function interface.get_promotion(x, y)
	if (interface.opt_clear_announcements) then
		interface.clear_announcements()
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
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
	machine.video.throttled = throttled_state
	return new_type
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.0", 0x40, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x20, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x08, 1)
	end
end

return interface

