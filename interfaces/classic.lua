local interface = {}
interface.setup_underpromotion = true -- the player's underpromotion goes in through the position setup
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.invert = false
interface.level = 1
interface.cur_level = nil
interface.edit = false
interface.stm = 1 -- side to move: 1 White, -1 Black

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

local function ram()
	return machine.devices[":maincpu"].spaces["data"]
end

-- Gambit Voice: no speech while the plugin presses keys and squares
local function voice(on)
	if machine.system.name == "gambitv" then
		local r = ram()
		if on then
			r:write_u8(0x0016, r:read_u8(0x0016) & 0xfb)
		else
			r:write_u8(0x0016, r:read_u8(0x0016) | 0x04)
		end
	end
end

-- The board is rotated when the computer plays White from the start
local function board_xy(x, y)
	if interface.invert then
		return 9 - x, 9 - y
	end
	return x, y
end

function interface.get_module()
	if machine.system.name == "gambitv" then
		return "Fidelity Gambit Voice"
	elseif machine.system.name == "classic" or machine.system.name == "classica" then
		return "Fidelity Classic"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	repeat
		send_input(":IN.0", 0x08, 0.6) -- LV/LEVEL
	until output_value("0." .. (interface.level - 1)) ~= 0
	send_input(":IN.0", 0x40, 0.6) -- CL/CLEAR
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	interface.invert = false
	interface.stm = 1
	interface.edit = false
	if machine.system.name == "gambitv" then
		-- Gambit Voice ignores the board until its power-on speech is over;
		-- let the 6 s greeting play at real speed (sound is muted while unthrottled)
		machine.video.throttled = true
		emu.wait(6.5)
		machine.video.throttled = false
	end
	emu.wait(1)
	send_input(":IN.0", 0x40, 0.6) -- CL/CLEAR
	emu.wait(0.6)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		return (":board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		voice(false)
		send_input(":IN.0", 0x20, 0.6) -- PB/PROBLEM
		-- empty the board (0x88, rows of 16 bytes): pressing a square only adds a piece,
		-- so pieces from the previous position would stay
		for y = 0, 7 do
			for x = 0, 7 do
				ram():write_u8(0x0088 + 16 * y + x, 0x00)
			end
		end
		send_input(":IN.0", 0x20, 0.6) -- PB/PROBLEM
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x40 >> math.abs(p), 0.6)
					end
					local bx, by = board_xy(x, 9 - y)
					sb_press_square(":board", 0.6, bx, by)
					if p < 0 then
						sb_press_square(":board", 0.6, bx, by)
					end
					piece = p
				end
			end
		end
		if mode == -1 then
			ram():write_u8(0x0003, 0x00)
		end
		interface.stm = mode
		voice(true)
		send_input(":IN.0", 0x40, 0.6) -- CL/CLEAR
		machine.video.throttled = throttled_state
	end
end

function interface.edit_game(on)
	-- move the history pieces silently, then set up the final position
	interface.edit = on
	if not on then
		interface.set_pos(0)
		interface.set_pos(interface.stm)
	end
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":IN.0", 0x01, 0.6) -- RV/MOVE
end

function interface.stop_play()
	send_input(":IN.0", 0x01, 0.6) -- RV/MOVE
end

function interface.is_selected(x, y)
	x, y = board_xy(x, y)
	return output_value("1." .. (x - 1)) ~= 0 and output_value("0." .. (y - 1)) ~= 0
end

function interface.select_piece(x, y, event)
	if (event == "put") then
		interface.stm = -interface.stm
	end
	x, y = board_xy(x, y)
	if interface.edit then
		if (event == "capture" or event == "en_passant") then
			sb_remove_piece(":board", x, y)
		else
			sb_move_piece(":board", x, y)
		end
	elseif (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		local function from_lit()
			return output_value("1." .. (x - 1)) ~= 0 and output_value("0." .. (y - 1)) ~= 0
		end
		if (event == "get" and not from_lit()) then
			-- The player's press is sometimes missed. The from square lights up once it is
			-- registered; if it does not, put the piece back silently and press again.
			-- (For the computer's own move the square is already lit.)
			emu.wait(1)
			for try = 1, 3 do
				sb_select_piece(":board", 1.2, x, y, event)
				for i = 1, 10 do
					if from_lit() then
						return
					end
					emu.wait(0.1)
				end
				sb_move_piece(":board", x, y)
				emu.wait(1)
			end
		else
			sb_select_piece(":board", 1.2, x, y, event)
		end
	end
end

function interface.get_options()
	return { { "spin", "Level", "1", "1", "8" }, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 8) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.test_promotion(x, y)
	x, y = board_xy(x, y)
	local function piece_led(port, code, x, y)
		for n = 1, 8 do
			send_input(port, code, 0.5)
			for i = 1, 4 do
				if (output_value("1." .. (x - 1)) ~= 0 and output_value("0." .. (y - 1)) ~= 0) then
					return true
				end
				emu.wait(0.15)
			end
		end
		return false
	end

	local p = "Q"
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	voice(false)
	send_input(":IN.0", 0x10, 1) -- PV/VERIFY

	if     piece_led(":IN.0", 0x10, x, y) then p = "Q"
	elseif piece_led(":IN.0", 0x02, x, y) then p = "N"
	elseif piece_led(":IN.0", 0x04, x, y) then p = "B"
	elseif piece_led(":IN.0", 0x08, x, y) then p = "R"
	end

	emu.wait(1)
	send_input(":IN.0", 0x40, 1) -- CL/CLEAR
	voice(true)
	machine.video.throttled = throttled_state
	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	x, y = board_xy(x, y)
	if piece == piece:lower() then
		emu.wait(1)
		promotion_error(piece)
		sb_promote(":board", x, y, "q")
	else
		sb_promote(":board", x, y, piece)
	end
end

return interface
