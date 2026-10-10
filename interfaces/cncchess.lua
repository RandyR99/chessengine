interface = {}

local function digit(n)
	local d = machine.devices[":"]:output("digit" .. n)
	return d and d:get() or 0
end

interface.turn = true
interface.invert = false
interface.last_get = nil
interface.level = 1
interface.cur_level = nil
interface.set_color = 0

function interface.get_module()
	return "Conic Master"
end

function interface.get_author()
	return "David B. Goodrich"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":RESET", 0x01, 1) 		-- Reset
	emu.wait(0.5)
	if (interface.level > 4) then
		send_input(":IN.1", 0x08 >> (interface.level-5), 1)
	else
		send_input(":IN.0", 0x08 >> (interface.level-1), 1)
	end
	send_input(":IN.3", 0x04, 1) 		-- F
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.invert = false
	interface.last_get = nil
	interface.set_color = 0
	send_input(":RESET", 0x01, 1)		-- Reset
	send_input(":IN.0", 0x08, 0.5)		-- 1
	send_input(":IN.3", 0x04, 0.5)		-- F
	emu.wait(0.5)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
    if mode == 0 then
        return ("")
    else
        local ram = machine.devices[":maincpu"].spaces["program"]
        local fig = {0xfe,0xfb,0xfa,0xf5,0xec,0xf8,0x00,0x08,0x14,0x0b,0x06,0x05,0x02}
        local adr = 0x1815
        for x=1,8 do
            for y=1,8 do
                local p=get_piece_id(x,y)
                local z=fig[p+7]
                ram:write_u8(adr+10*(y-1)+x-1,z)
            end
        end
        interface.set_color = mode
    end
end

function invert_pos()
    interface.invert = true
    local ram = machine.devices[":maincpu"].spaces["program"]
    local adr = 0x1815
    for x=1,8 do
        for y=1,4 do
            local z=ram:read_u8(adr+10*(y-1)+x-1)
            ram:write_u8(adr+10*(y-1)+x-1,256-ram:read_u8(adr+10*(9-y-1)+x-1))
            ram:write_u8(adr+10*(9-y-1)+x-1,256-z)
        end
    end
end

function interface.start_play(init)
	if (init) then
		interface.invert = true
		interface.turn = false
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":IN.1", 0x02, 1) -- SP
		send_input(":IN.3", 0x01, 1) -- GO
		emu.wait(0.5)
		machine.video.throttled = throttled_state
	elseif interface.set_color ~= 0 then
		interface.turn = false
		if interface.set_color == 1 then
			invert_pos()
		end
		interface.set_color = 0
		send_input(":IN.1", 0x02, 1) -- SP
		send_input(":IN.3", 0x01, 1) -- GO
		emu.wait(0.5)
	end
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	if (interface.invert) then
		y = 9 - y
	end
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = digit(0)
	local d1 = digit(1)
	local d2 = digit(2)
	local d3 = digit(3)
	if (d0 == 0x39 and d1 == 0x40 and d2 == 0x40 and d3 == 0x77) then -- "C--A", computer castles queenside
		if ((x == 5 or x == 3) and (y == 8)) then
			return true
		else
			return false
		end
	end
	if (d0 == 0x39 and d1 == 0x40 and d2 == 0x40 and d3 == 0x76) then -- "C--H", computer castles kingside
		if ((x == 5 or x == 7) and (y == 8)) then
			return true
		else
			return false
		end
	end
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos1(p)  	-- "A" to "H" keys
	if	   (p == 1) then send_input(":IN.2", 0x08, 0.5)
	elseif (p == 2)	then send_input(":IN.2", 0x04, 0.5)
	elseif (p == 3)	then send_input(":IN.2", 0x02, 0.5)
	elseif (p == 4)	then send_input(":IN.2", 0x01, 0.5)
	elseif (p == 5)	then send_input(":IN.3", 0x08, 0.5)
	elseif (p == 6)	then send_input(":IN.3", 0x04, 0.5)
	elseif (p == 7)	then send_input(":IN.3", 0x02, 0.5)
	elseif (p == 8)	then send_input(":IN.3", 0x01, 0.5)
	end
end

function interface.send_pos2(p)  	-- "1" to "8" keys
	if (interface.invert) then
		p = 9 - p
	end
	if	   (p == 1) then send_input(":IN.0", 0x08, 0.5)
	elseif (p == 2)	then send_input(":IN.0", 0x04, 0.5)
	elseif (p == 3)	then send_input(":IN.0", 0x02, 0.5)
	elseif (p == 4)	then send_input(":IN.0", 0x01, 0.5)
	elseif (p == 5)	then send_input(":IN.1", 0x08, 0.5)
	elseif (p == 6)	then send_input(":IN.1", 0x04, 0.5)
	elseif (p == 7)	then send_input(":IN.1", 0x02, 0.5)
	elseif (p == 8)	then send_input(":IN.1", 0x01, 0.5)
	end
end

function interface.send_pos(x, y)
	interface.send_pos1(x)
	interface.send_pos2(y)
end

function interface.select_piece(x, y, event)
	if interface.set_color == -1 then
		invert_pos()
		interface.set_color = 0
	end
	if (event == "get" and interface.turn) then
		interface.last_get = {x=x, y=y}
	elseif (event == "put" and interface.turn) then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local move_type = get_move_type(interface.last_get.x, interface.last_get.y, x, y)
		if (move_type == "castling") then
			local pos
			if (x == 7) then
				pos = { pstart = 8, pend = 6, pking = 8 }
			elseif (x == 3) then
				pos = { pstart = 1, pend = 4, pking = 2 }
			end
			interface.send_pos(pos.pstart, y)
			interface.send_pos(pos.pend, y)
			send_input(":IN.3", 0x02, 0.5)
			interface.send_pos(5, y)
			interface.send_pos(pos.pking, y)
			send_input(":IN.3", 0x02, 0.5)
			interface.send_pos(pos.pking, y)
			interface.send_pos(x, y)
			send_input(":IN.3", 0x01, 0.5) -- GO
		elseif (move_type == "en_passant") then
			interface.send_pos(interface.last_get.x, interface.last_get.y)
			interface.send_pos(x, interface.last_get.y)
			send_input(":IN.3", 0x02, 0.5) -- MD
			interface.send_pos(x, interface.last_get.y)
			interface.send_pos(x, y)
			send_input(":IN.3", 0x01, 0.5) -- GO
		elseif (move_type == "promotion" or move_type == "capture_promotion") then
			interface.send_pos(interface.last_get.x, interface.last_get.y)
			interface.send_pos(x, y)
			send_input(":IN.3", 0x02, 0.5) -- MD
		else
			interface.send_pos(interface.last_get.x, interface.last_get.y)
			interface.send_pos(x, y)
			send_input(":IN.3", 0x01, 0.5) -- GO
		end
		interface.last_get = nil
		machine.video.throttled = throttled_state
	end
	if (event == "put") then
		interface.turn = not interface.turn
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "6" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 6) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":IN.1", 0x01, 0.5) -- IP
		local p = get_piece_id(x,y)
		if (interface.invert) then
			p = -p
		end
		if p > 0 then
			if	   (piece == "q") then send_input(":IN.3", 0x08, 0.5)
			elseif (piece == "r") then send_input(":IN.2", 0x04, 0.5)
			elseif (piece == "b") then send_input(":IN.2", 0x01, 0.5)
			elseif (piece == "n") then send_input(":IN.2", 0x02, 0.5)
			end
		else
			if     (piece == "q") then send_input(":IN.1", 0x08, 0.5)
			elseif (piece == "r") then send_input(":IN.0", 0x04, 0.5)
			elseif (piece == "b") then send_input(":IN.0", 0x01, 0.5)
			elseif (piece == "n") then send_input(":IN.0", 0x02, 0.5)
			end
		end
		interface.send_pos(x, y)
		send_input(":IN.3", 0x01, 0.5) -- GO
		machine.video.throttled = throttled_state
	end
end

return interface
