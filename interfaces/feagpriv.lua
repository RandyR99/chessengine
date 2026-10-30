interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board
interface.info_every = 1 -- show_info only reads the display

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.opt_clear_announcements = true
interface.level = "a1"
interface.cur_level = nil

-- Elite Private Line: the EAG 6081 program in an Elite A/S style case (A/S keys and LED matrix)

function interface.get_module()
	return "Fidelity Elite Private Line"
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
		send_input(":IN.0", 0x10 << n, 0.25)  -- ST / TB / LV
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
	send_input(":IN.0", 0x80, 0.5)  -- LV
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
	send_input(":IN.1", 0x02, 0.5) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(2)
	send_input(":IN.0", 0x01, 1) -- New Game
	emu.wait(2)
	machine.video.throttled = throttled_state
	interface.cur_level = "a1"
	interface.setlevel()
	-- Score / Depth ein
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x02, 1) -- option
	if output_value("4.15") == 0 then
		sb_press_square(":board", 1, 5, 1)  -- e1
		emu.wait(0.5)
	end
	send_input(":IN.1", 0x02, 1) -- clear
	machine.video.throttled = throttled_state
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x02, 0.5) -- OPTION
		sb_press_square(":board", 0.5, 4, 7) -- Clear board
		send_input(":IN.1", 0x02, 0.5) -- CL
		send_input(":IN.0", 0x04, 0.5) -- PB
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
						send_input(":IN.0", 0x01 << (math.abs(p) + 1), 0.5)
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
		send_input(":IN.1", 0x02, 0.5) -- CL
		if mode == -1 then
			send_input(":IN.0", 0x02, 0.5) -- OPTION
			sb_press_square(":board", 0.5, 4, 5) -- Change color
			send_input(":IN.1", 0x02, 0.5) -- CL
		end
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x02, 0.5) -- OPTION
	sb_press_square(":board", 1, 5, 6)
	send_input(":IN.1", 0x02, 0.5) -- CL
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.1", 0x04, 1) -- RV
end

function interface.clear_announcements()
	-- machine turns on all LEDs on the first line for mate/draw announcements
	if (output_value("0.15") ~= 0 and output_value("1.15") ~= 0 and output_value("2.15") ~= 0 and output_value("3.15") ~= 0 and output_value("4.15") ~= 0 and output_value("5.15") ~= 0 and output_value("6.15") ~= 0 and output_value("7.15") ~= 0) then
		send_input(":IN.1", 0x02, 1) -- CL
	end
end

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end
	return output_value((x - 1) .. "." .. (16 - y)) ~= 0
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
	if     (output_value("8.9")  ~= 0) then	return 'q'
	elseif (output_value("8.10") ~= 0) then	return 'r'
	elseif (output_value("8.11") ~= 0) then	return 'b'
	elseif (output_value("8.12") ~= 0) then	return 'n'
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
			if (output_value((x - 1) .. "." .. (16 - y)) ~= 0) then
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
	send_input(":IN.0", 0x08, 0.5) -- PV
	if     piece_led(0x08) then p = "Q"
	elseif piece_led(0x10) then p = "R"
	elseif piece_led(0x20) then p = "B"
	elseif piece_led(0x40) then p = "N"
	else p = "Q"
	end
	send_input(":IN.1", 0x02, 0.5) -- CL
	machine.video.throttled = throttled_state
	return p
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.0", 0x08, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x20, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x40, 1)
	end
end

-- option E1 (set in setup_machine) makes the player's display alternate every 5 s while the machine thinks
-- (manual 6.0 E1, pp. 26-27): the score in centipawns for the machine (a dot after the second digit = negative,
-- above 9990 = mate) and the search depth in hex next to the number of lines searched
local segment_hex = { [0x3f] = 0, [0x06] = 1, [0x5b] = 2, [0x4f] = 3, [0x66] = 4, [0x6d] = 5, [0x7d] = 6, [0x07] = 7,
	[0x7f] = 8, [0x67] = 9, [0x6f] = 9, [0x77] = 10, [0x7c] = 11, [0x39] = 12, [0x5e] = 13, [0x79] = 14, [0x71] = 15 }
local segment_dec = { [0x3f] = 0, [0x06] = 1, [0x5b] = 2, [0x4f] = 3, [0x66] = 4, [0x6d] = 5, [0x7d] = 6, [0x7c] = 6,
	[0x07] = 7, [0x7f] = 8, [0x67] = 9, [0x6f] = 9 }

function interface.show_info(on)
	if not on then
		interface.score = nil
		interface.depth = nil
		return nil
	end
	local d = {}
	local h = {}
	for i, name in ipairs({ "digit1", "digit0", "digit2", "digit3" }) do
		local v = output_value(name) & 0x7f
		d[i] = segment_dec[v]
		h[i] = segment_hex[v]
	end
	if d[1] and d[2] and d[3] and d[4] then
		local score = d[1] * 1000 + d[2] * 100 + d[3] * 10 + d[4]
		if output_value("1.7") ~= 0 then
			score = -score
		end
		interface.score = score
	elseif not h[3] and h[4] then
		interface.depth = h[4] -- depth 16 and up (two hex digits) would look like the clock, which starts right after the move
	end
	return { score = interface.score, depth = interface.depth }
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
