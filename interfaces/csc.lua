interface = {}

interface.level = "1"
interface.cur_level = nil
local turn  = 0
local check = 3
interface.fen = false    -- the game began with a set_pos
interface.silent = false -- history replay after a set_pos: pieces are only moved on the sensorboard
interface.stm = 1

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Fidelity Champion Sensory Chess Challenger"
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local lcd_lev = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x79, 0x71, 0x3d, 0x76 }
	local lcd_num = { 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67 }
	local level = interface.level
	local lev = "12345678EFGH"
	lev = lev:find(level:sub(1,1))
	if (lev < 9 or lev > 10) then
		for i = 1, 30 do
			send_input(":IN.3", 0x100, 0.6) -- LV
			if (output_value("digit0") == lcd_lev[lev]) then
				break
			end
		end
	else
		for i = 1, 30 do
			send_input(":IN.3", 0x100, 0.6) -- LV
			if (output_value("digit0") == lcd_lev[lev-1]) then
				break
			end
		end
		send_input(":IN.3", 0x100, 0.6) -- LV
		level = level:sub(3)
		local d1,d2,d3
		for i=1,2 do
			if (lev == 9) then
				send_input(":IN.4", 0x100, 0.6) -- DM
				if (level:sub(1,2) ~= "00") then
					d1=lcd_num[tonumber(level:sub(1,1))+1]
					d2=lcd_num[tonumber(level:sub(2,2))+1]
					machine.ioport.ports[":IN.5"]:field(0x100):set_value(1) -- ST
					for n = 1, 1200 do -- ST held: the digits count up
						emu.wait(0.05)
						if (output_value("digit1") == d1 and output_value("digit0") == d2) then
							break
						end
					end
				end
				machine.ioport.ports[":IN.5"]:field(0x100):set_value(0) -- ST
				emu.wait(0.5)
				level = level:sub(4)
			end
			send_input(":IN.2", 0x100, 0.6) -- TM
			if (level:sub(1,4) ~= "0:00") then
				d1=lcd_num[tonumber(level:sub(1,1))+1]
				d2=lcd_num[tonumber(level:sub(3,3))+1]
				d3=lcd_num[tonumber(level:sub(4,4))+1]
				machine.ioport.ports[":IN.5"]:field(0x100):set_value(1) -- ST
				for n = 1, 1200 do -- ST held: the digits count up
					emu.wait(0.05)
					if (output_value("digit2") == d1 and output_value("digit1") == d2 and output_value("digit0") == d3) then
						break
					end
				end
			end
			machine.ioport.ports[":IN.5"]:field(0x100):set_value(0) -- ST
			emu.wait(0.5)
			level = level:sub(6)
		end
		send_input(":IN.2", 0x100, 0.6) -- TM
	end
	send_input(":IN.2", 0x100, 0.6) -- TM
end

function interface.setup_machine()
	interface.fen = false
	interface.silent = false
	interface.stm = 1
	sb_reset_board(":board")
	emu.wait(5)
	send_input(":IN.8", 0x40, 1) -- CL
	emu.wait(1.0)

	interface.cur_level = "1"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x100, 0.6) -- SPK
		send_input(":IN.0", 0x100, 0.6) -- SPK
		send_input(":IN.1", 0x100, 0.6) -- RV	-- Voice off
		send_input(":IN.2", 0x100, 0.6) -- TM
		return (":board")
	else
		interface.fen = true
		interface.stm = mode
		local key=0x00
		for n=1,6 do
			if     n==1 then key=0x20 -- K
			elseif n==2 then key=0x10 -- Q
			elseif n==3 then key=0x02 -- R
			elseif n==4 then key=0x08 -- B
			elseif n==5 then key=0x04 -- N
			elseif n==6 then key=0x01 -- P
			end
			send_input(":IN.8", key, 0.6)
			send_input(":IN.8", key, 0.6)
			for y=1,8 do
				for x=1,8 do
					if get_piece_id(x,y)==n then
						sb_press_square(":board", 0.6, x, y)
					end
				end
			end
			send_input(":IN.8", key, 0.6)
			for y=1,8 do
				for x=1,8 do
					if get_piece_id(x,y)==-n then
						sb_press_square(":board", 0.6, x, y)
					end
				end
			end
			send_input(":IN.8", key, 0.6)
		end
		if mode==-1 then
			send_input(":IN.8", 0x40, 0.6)  -- CL
			send_input(":IN.1", 0x100, 0.6) -- RV
		end
		send_input(":IN.0", 0x100, 0.6) -- SPK
		send_input(":IN.0", 0x100, 0.6) -- SPK
		send_input(":IN.1", 0x100, 0.6) -- RV	-- Voice on
		send_input(":IN.2", 0x100, 0.6) -- TM
	end
end

function interface.edit_game(on)
    local throttled_state = machine.video.throttled
    if (interface.fen) then
        -- Player Mode is only allowed before the first move: after a set_pos the history is
        -- replayed on the sensorboard alone, then RE and the final position is set up again
        interface.silent = on
        if (not on) then
            machine.video.throttled = false
            send_input(":IN.8", 0x80, 1) -- RE
            emu.wait(2)
            interface.cur_level = "1"
            interface.setlevel()
            interface.set_pos(0)
            interface.set_pos(interface.stm)
            machine.video.throttled = throttled_state
        end
    elseif on then
        send_input(":IN.0", 0x100, 0.6) -- SPK
        send_input(":IN.0", 0x100, 0.6) -- SPK
        send_input(":IN.1", 0x100, 0.6) -- RV    -- Voice off
        local lv = 3 -- LV three times: Player Mode (the Elite needs one press)
        if (machine.system.name == "csce" or machine.system.name == "cscet") then
            lv = 1
        end
        for i = 1, lv do
            send_input(":IN.3", 0x100, 0.6) -- LV
            emu.wait(0.5)
        end
        send_input(":IN.2", 0x100, 0.6) -- TM
    else
        machine.video.throttled = false
        send_input(":IN.8", 0x01, 0.6)  -- P
        send_input(":IN.8", 0x01, 0.6)  -- P
        send_input(":IN.8", 0x01, 0.6)  -- P
        send_input(":IN.8", 0x01, 0.6)  -- P
        send_input(":IN.0", 0x100, 0.6) -- SPK
        send_input(":IN.0", 0x100, 0.6) -- SPK
        send_input(":IN.1", 0x100, 0.6) -- RV    -- Voice on
        send_input(":IN.2", 0x100, 0.6) -- TM
        machine.video.throttled = throttled_state
    end
    emu.wait(0.5)
end

function interface.start_play(init)
    if (check==1) then
        check=3
    else
        check=1
    end
	send_input(":IN.4", 0x100, 1) -- DM
	send_input(":IN.1", 0x100, 1) -- RV
end

function interface.stop_play()
	send_input(":IN.5", 0x100, 1) -- ST
end

function interface.is_selected(x, y)
	return output_value(tostring(x - 1) .. "." .. tostring(y - 1 + 8)) ~= 0
end

function interface.select_piece(x, y, event)
    if (event == "put") then
        interface.stm = -interface.stm
    end
    if (interface.silent) then
        if (event == "capture" or event == "en_passant") then
            sb_remove_piece(":board", x, y)
        else
            sb_move_piece(":board", x, y)
        end
        return
    end
    if (event ~= "capture") then
        if (event ~= "en_passant" and event ~= "get_castling" and event ~= "put_castling") then
            turn = turn + 1
             if turn > 3 then
                turn = 0
             end
             if turn == check then
                emu.wait(4)
             end
        end
    end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return { { "string", "Level", "1"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:upper():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:match("^[1-8GH]$")
		or  level:match("^E%s%d%d/%d:[0-5]%d%s%d%d/%d:[0-5]%d$")
		or  level:match("^F%s%d:[0-5]%d%s%d:[0-5]%d$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.test_promotion(x, y)
	local function piece_led(port, code, x, y)
		send_input(port, code, 0.6)
		for i=1,5 do
			if (output_value(tostring(x - 1) .. "." .. tostring(y - 1 + 8)) ~= 0) then
				return true
			end
			emu.wait(0.1)
		end
		return false
	end

	local p
	send_input(":IN.0", 0x100, 0.6) -- SPK
	send_input(":IN.0", 0x100, 0.6) -- SPK
	send_input(":IN.1", 0x100, 0.6) -- RV (Voice off)
	send_input(":IN.2", 0x100, 0.6) -- TM

	if     piece_led(":IN.8", 0x10, x, y) then p = "Q"
	elseif piece_led(":IN.8", 0x04, x, y) then p = "N"
	elseif piece_led(":IN.8", 0x08, x, y) then p = "B"
	elseif piece_led(":IN.8", 0x02, x, y) then p = "R"
	else p = "Q"
	end

	send_input(":IN.8", 0x40,  0.6) -- CL
	send_input(":IN.0", 0x100, 0.6) -- SPK
	send_input(":IN.0", 0x100, 0.6) -- SPK
	send_input(":IN.1", 0x100, 0.6) -- RV (Voice on)
	send_input(":IN.2", 0x100, 0.6) -- TM
	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if (interface.silent) then
		return
	end
	emu.wait(1.0)
	local key = { q = 0x10, r = 0x02, b = 0x08, n = 0x04 }
	if (key[piece] == nil) then
		return
	end
	-- the promotion square flashes until the piece is taken; the first press can be
	-- announced only ("promote to a bishop, promote pawn"), so press again while it flashes
	for n = 1, 3 do
		send_input(":IN.8", key[piece], 1)
		local flashing = false
		for i = 1, 20 do
			emu.wait(0.1)
			if (interface.is_selected(x, y)) then
				flashing = true
				break
			end
		end
		if (not flashing) then
			break
		end
	end
end

return interface
