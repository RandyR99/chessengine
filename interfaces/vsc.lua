interface = {}

interface.level = "1"
interface.cur_level = nil
interface.edit = false
interface.stm = 1 -- side to move: 1 White, -1 Black

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Fidelity Voice Sensory Chess Challenger"
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local lcd_lev = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67, 0x76 }
	local level = interface.level
	local lev = "123456789H"
	lev = lev:find(level:sub(1,1))
	local presses = 0
	repeat
		send_input(":IN.1", 0x08, 0.6) -- LV
		presses = presses + 1
	until output_value("digit0") == lcd_lev[lev] or presses > 25
	send_input(":IN.1", 0x01, 0.6) -- TM
end

function interface.setup_machine()
	sb_reset_board(":board")
--	send_input(":IN.0", 0x80, 1) -- RE
	emu.wait(6.0) -- spoken introduction at power-on: keys are lost until it ends
	send_input(":IN.0", 0x40, 1) -- CL
	emu.wait(1.0)

	interface.cur_level = "1"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x04, 0.6) -- Voice off
		send_input(":IN.1", 0x01, 0.6) -- TM
		return (":board")
	else
		if mode==-1 then
			send_input(":IN.0", 0x40, 0.6) -- CL
			send_input(":IN.1", 0x02, 0.6) -- RV
			emu.wait(1)
			for y=1,8 do
				for x=1,8 do
					if interface.is_selected(x, y) then
						sb_press_square(":board", 0.6, x, y)
					end
				end
			end
		end
		-- the machine sometimes ignores a key press: verify the set-up and repeat it if needed
		for try=1,3 do
			if try > 1 then
				interface.clear_illegal()
				send_input(":IN.0", 0x40, 0.6) -- CL: drop a square press taken as a move
			end
			interface.enter_pos()
			if interface.verify_pos() then
				break
			end
		end
		send_input(":IN.1", 0x04, 0.6) -- SPK
		send_input(":IN.1", 0x04, 0.6) -- Voice on
		send_input(":IN.1", 0x01, 0.6) -- TM
		interface.stm = mode
	end
end

local piece_keys = { 0x20, 0x10, 0x02, 0x08, 0x04, 0x01 } -- K Q R B N P

local function piece_key(key)
	-- a key pressed too soon after the previous one is sometimes ignored
	send_input(":IN.0", key, 0.6)
	emu.wait(0.4)
end

function interface.clear_illegal()
	-- "----": a square press was taken as an illegal move; put the piece back as the manual says
	for i=1,4 do
		if not (output_value("digit0") == 0x40 and output_value("digit1") == 0x40 and output_value("digit2") == 0x40 and output_value("digit3") == 0x40) then
			return
		end
		local pressed = false
		for y=1,8 do
			for x=1,8 do
				if not pressed and interface.is_selected(x, y) then
					sb_press_square(":board", 0.6, x, y)
					pressed = true
				end
			end
		end
		emu.wait(0.5)
	end
end

function interface.enter_pos()
	local key=0x00
	for n=1,6 do
		key = piece_keys[n]
		piece_key(key)
		piece_key(key)
		piece_key(0x40) -- CL
		for y=1,8 do
			for x=1,8 do
				if get_piece_id(x,y)==n then
					sb_press_square(":board", 0.6, x, y)
				end
			end
		end
		piece_key(key)
		piece_key(0x40) -- CL
		for y=1,8 do
			for x=1,8 do
				if get_piece_id(x,y)==-n then
					sb_press_square(":board", 0.6, x, y)
				end
			end
		end
		piece_key(key)
	end
end

function interface.verify_pos()
	-- Position Verification per piece type: white pieces steady, dark pieces flashing
	for n=1,6 do
		send_input(":IN.0", piece_keys[n], 0.6)
		local on = {}
		for i=1,15 do
			for y=1,8 do
				for x=1,8 do
					if interface.is_selected(x, y) then
						on[y*8+x] = (on[y*8+x] or 0) + 1
					end
				end
			end
			emu.wait(0.1)
		end
		send_input(":IN.0", 0x40, 0.6) -- CL
		for y=1,8 do
			for x=1,8 do
				local p = get_piece_id(x, y)
				local c = on[y*8+x] or 0
				if (p == n and c ~= 15) or (p == -n and (c == 0 or c == 15)) or (math.abs(p) ~= n and c ~= 0) then
					return false
				end
			end
		end
	end
	return true
end

function interface.edit_game(on)
	-- move the history pieces silently, then set up the final position after RE
	interface.edit = on
	if not on then
		local stm = interface.stm
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":IN.0", 0x80, 1) -- RE
		emu.wait(6.0) -- spoken introduction
		interface.cur_level = "1"
		interface.setlevel()
		interface.set_pos(0)
		interface.set_pos(stm)
		machine.video.throttled = throttled_state
	end
end

function interface.start_play(init)
	if (init) then
		sb_press_square(":board", 1, 5, 8) -- e8 (black king)
	else
		send_input(":IN.0", 0x40, 1) -- CL
		send_input(":IN.1", 0x02, 1) -- RV
	end
end

function interface.stop_play()
	send_input(":IN.1", 0x20, 1) -- ST
end

function interface.is_selected(x, y)
	return output_value(tostring(x - 1) .. "." .. tostring(y - 1 + 8)) ~= 0
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
	elseif (event ~= "capture") then
		sb_select_piece(":board", 1, x, y, event)
	end
end

function interface.get_options()
	return { { "string", "Level", "1"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:upper():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if level == "10" then
			level = "H"
		end
		if (level:match("^[1-9H]$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	sb_promote(":board", x, y, "q")	-- TODO
end

return interface
