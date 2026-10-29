interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.opt_clear_announcements = true
interface.level = "a1"
interface.cur_level = nil
interface.score = "0.00"
interface.depth = "0"

function interface.get_module()
	if machine.system.name == "feag" then
		return "Fidelity Elite Avant Garde"
	elseif machine.system.name == "feag2100" then
		return "Fidelity Elite Avant Garde 2100"
	elseif machine.system.name == "feag2100a" then
		return "Fidelity Elite Avant Garde 2100 v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setdigit(n,d)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local lcd_num = { 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67 }
	local led = n
	if (led == 1) then
		led = 0
	end
	while (output_value("digit" .. led) ~= lcd_num[d+1]) do
		send_input(":IN.0", 0x20 >> n, 0.25)  -- ST / TB / LV
	end
	machine.video.throttled = throttled_state
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
	sb_press_square(":board", 0.5, x, y)
	local num = level:sub(4)
	if (num ~= "" and num:len() <= 2) then
		if (num:len() == 1) then
			num = "0" .. num
		end
		for i = 1, 2 do
			interface.setdigit(i + 1, num:sub(i,i))
		end
	else
		local k = 1
		while (num ~= "") do
			local d = num:sub(1,1)
			if (d == " ") then
				sb_press_square(":board", 0.5, x, y)
				k = 1
			elseif (d == "/") then
				sb_press_square(":board", 0.5, x, y)
				k = 2
			elseif (d ~= ":") then
				interface.setdigit(k,d)
				k = k + 1
			end
			num = num:sub(2)
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
	emu.wait(2)
	send_input(":IN.1", 0x04, 1) -- New Game
	emu.wait(2)
	machine.video.throttled = throttled_state
	interface.cur_level = "a1"
	interface.setlevel()
	-- Score / Depth ein
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x02, 1) -- option
	if output_value(0 .. "." .. 12) == 0 then
		sb_press_square(":board", 1, 5, 1)  -- e1
		emu.wait(0.5)
	end
	send_input(":IN.1", 0x01, 1) -- clear
	machine.video.throttled = throttled_state
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x02, 0.5) -- OPTION
		sb_press_square(":board", 0.5, 4, 7) -- Clear board
		send_input(":IN.1", 0x01, 0.5) -- CL
		send_input(":IN.0", 0x80, 0.5) -- PB
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
		send_input(":IN.1", 0x01, 0.5) -- CL
		if mode == -1 then
			send_input(":IN.0", 0x02, 0.5) -- OPTION
			sb_press_square(":board", 0.5, 4, 5) -- Change color
			send_input(":IN.1", 0x01, 0.5) -- CL
		end
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x02, 0.5) -- OPTION
	sb_press_square(":board", 1, 5, 6)
	send_input(":IN.1", 0x01, 0.5) -- CL
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.0", 0x01, 1) -- RV
end

function interface.clear_announcements()
	-- machine turns on all LEDs on the first line for mate/draw announcements
	if (output_value("0.8") ~= 0 and output_value("0.9") ~= 0 and output_value("0.10") ~= 0 and output_value("0.11") ~= 0 and output_value("0.12") ~= 0 and output_value("0.13") ~= 0 and output_value("0.14") ~= 0 and output_value("0.15") ~= 0) then
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
		{ "string", "Level", "a1" },
		{ "check", "Clear announcements", "1" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:match("^a[1-8]$") or level:match("^b[1-7]$") or level:match("^b[4-6]%s%d%d?$") or level:match("^b[72]%s%d:%d%d$") or level:match("^b2%s%d:%d%d%s%d:%d%d$") or level:match("^b3%s%d:%d%d/%d%d$") or level:match("^b3%s%d:%d%d/%d%d%s%d:%d%d/%d%d$") or level:match("^b3%s%d:%d%d/%d%d%s%d:%d%d/%d%d%s%d:%d%d/%d%d$")) then
			interface.level = level
			interface.setlevel()
		end
	end
	if (name == "clear announcements") then
		interface.opt_clear_announcements = tonumber(value) == 1
	end
end

function interface.get_promotion_led()
	if     (output_value("8.12") ~= 0) then	return 'q'
	elseif (output_value("8.11") ~= 0) then	return 'r'
	elseif (output_value("8.10") ~= 0) then	return 'b'
	elseif (output_value("8.9")  ~= 0) then	return 'n'
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
			if (output_value((y - 1) .. "." .. (7 + x)) ~= 0) then
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
	send_input(":IN.0", 0x40, 0.5) -- PV
	if     piece_led(0x40) then p = "Q"
	elseif piece_led(0x20) then p = "R"
	elseif piece_led(0x10) then p = "B"
	elseif piece_led(0x08) then p = "N"
	else p = "Q"
	end
	send_input(":IN.1", 0x01, 0.5) -- CL
	machine.video.throttled = throttled_state
	return p
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.0", 0x40, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x20, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x08, 1)
	end
end

function interface.show_info(on)
	if on then
		local d1 = output_value("digit1")
		local d2 = output_value("digit0")
		local d3 = output_value("digit2")
		local d4 = output_value("digit3")
		if digit_ascii(d1) ~= " " and digit_ascii(d3) ~= " " then
			interface.score = digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4):gsub(" ","")
		else
			interface.depth = digit_ascii(d3) .. digit_ascii(d4):gsub(" ","")
		end
		return "info score cp " .. interface.score .. " depth " .. interface.depth
	end
end

function digit_ascii(digit)
	if     digit == nil then return " "
	elseif digit ==   0 then return " "
	elseif digit ==  63 then return "0"
	elseif digit ==   6 then return "1"
	elseif digit ==  91 then return "2"
	elseif digit ==  79 then return "3"
	elseif digit == 102 then return "4"
	elseif digit == 109 then return "5"
	elseif digit == 111 then return "5"
	elseif digit == 125 then return "6"
	elseif digit ==   7 then return "7"
	elseif digit == 127 then return "8"
	elseif digit == 103 then return "9"
	end
end

return interface
