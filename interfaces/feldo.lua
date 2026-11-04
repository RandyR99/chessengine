interface = {}
interface.setup_underpromotion = true -- the player's underpromotion goes in through the position setup
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.level = 1
interface.cur_level = nil
interface.edit = false
interface.stm = 1 -- side to move: 1 White, -1 Black

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Fidelity Eldorado"
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
	local level = interface.level
	repeat
		send_input(":IN.0", 0x08, 0.6) -- LEVEL
	until output_value("1." .. tostring(level - 1)) ~= 0
	send_input(":IN.0", 0x40, 0.6) -- CLEAR
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	interface.stm = 1
	interface.edit = false
	send_input(":IN.0", 0x80, 0.6) -- NEW GAME
	emu.wait(0.6)
	send_input(":IN.0", 0x40, 0.6) -- CLEAR
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
		local ram = machine.devices[":maincpu"].spaces["data"]
		send_input(":IN.0", 0x20, 0.6) -- PROBLEM
		for i=0,31 do
			ram:write_u8(0x0020+i,0x00)
		end
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if math.abs(p)~=math.abs(piece) then
						send_input(":IN.0", 0x40>>math.abs(p), 0.6)
					end
					sb_press_square(":board", 0.6, x, 9-y)
					if p<0 then
						sb_press_square(":board", 0.6, x, 9-y)
					end
					piece=p
				end
			end
		end
		if mode==-1 then
			ram:write_u8(0x0003,0xff)
		end
		send_input(":IN.0", 0x40, 0.6) -- CLEAR
		machine.video.throttled = throttled_state
		interface.stm = mode
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
	-- a forced reply comes at once: REVERSE would then swap the sides again
	local file, rank = false, false
	for i = 0, 7 do
		file = file or output_value("0." .. i) ~= 0
		rank = rank or output_value("1." .. i) ~= 0
	end
	if file and rank then
		return
	end
	send_input(":IN.0", 0x01, 0.6) -- REVERSE
end

function interface.stop_play()
	send_input(":IN.0", 0x02, 0.6) -- MOVE
end

function interface.is_selected(x, y)
	return output_value("0." .. tostring(x - 1)) ~= 0 and output_value("1." .. tostring(y - 1)) ~= 0
end

function interface.select_piece(x, y, event)
	if (event == "put") then
		interface.stm = -interface.stm
	end
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
		sb_select_piece(":board", 1, x, y, event)
	end
end

function interface.get_options()
	return { { "spin", "Level", "1", "1", "8"}, }
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
	local function piece_led(port, code, x, y)
		for n=1,8 do
			send_input(port, code, 0.5)
			for i=1,4 do
				if (output_value("0." .. tostring(x - 1)) ~= 0 and output_value("1." .. tostring(y - 1)) ~= 0) then
					return true
				end
				emu.wait(0.15)
			end
		end
		return false
	end

	local p
	local throttled_state = machine.video.throttled
	machine.video.throttled = false

	if     piece_led(":IN.0", 0x10, x, y) then p = "Q"
	elseif piece_led(":IN.0", 0x02, x, y) then p = "N"
	elseif piece_led(":IN.0", 0x04, x, y) then p = "B"
	elseif piece_led(":IN.0", 0x08, x, y) then p = "R"
	else p = "Q"
	end

	send_input(":IN.0", 0x40, 1) -- CLEAR
	machine.video.throttled = throttled_state
	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	if piece == piece:lower() then
		promotion_error(piece)
		sb_promote(":board", x, y, "q")	-- the machine only takes a queen
	else
		sb_promote(":board", x, y, piece)
	end
end

return interface
