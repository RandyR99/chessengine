interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.turn = true
interface.invert = false
interface.color = "B"
interface.level = 4
interface.cur_level = nil

function interface.get_module()
	return "Chess Champion MK II"
end

function interface.get_author()
	return "Peter Jennings"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	--machine.video.throttled = false
	send_input(":IN.1", 0x10, 0.5) -- CLEAR
	emu.wait(0.5)
	send_input(":IN.0", 0x01, 0.5) -- LEVEL
	emu.wait(0.5)
	interface.send_pos2(interface.level)
	emu.wait(0.5)
	send_input(":IN.1", 0x08, 0.5) -- ENTER
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.invert = false
	interface.color = "B"
	send_input(":RESET", 0x01, 0.5) -- NEW GAME
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 4
	interface.setlevel()
end

function interface.set_pos(mode)
    if mode == 0 then
        return ("")
    else
        local ram = machine.devices[":maincpu"].spaces["program"]
        local num = {8,2,2,2,2,1,0,1,2,2,2,2,8}
        local adr = {17,9,7,5,3,1,0,18,20,22,24,26,34}
        local err = {"1 king", "2 queens", "2 rooks", "2 bishops", "2 knights", "8 pawns"}
        for i=0,33 do
            ram:write_u8(i,0xcc)
        end
        for x=1,8 do
            for y=1,8 do
                local p=get_piece_id(x,y)+7
                if p~=7 then
                    if num[p]==0 then
                        machine.video.throttled = true
                        emu.wait(1)
                        emu.print_error("ERROR: More than "..err[tonumber(math.abs(p-7))].." not supported by '"..machine.system.name.."'!")
                        return 0
                    end
                    num[p]=num[p]-1
                    adr[p]=adr[p]-1
                    ram:write_u8(adr[p],16*(8-y)+x-1)
                end
            end
        end
        ram:write_u8(0x74,0xf0)
        if mode == -1 then
            ram:write_u8(0x71,0x70)
            ram:write_u8(0x72,0x70)
            interface.set_color=-1
        end
    end
end

function invert_pos()
    interface.invert = true
    local ram = machine.devices[":maincpu"].spaces["program"]
    local b,w
    for i=0,16 do
        b=ram:read_u8(i)
        if b~=0xcc then
            b=(7-(b-b%16)/16)*16+b%16
        end
        w=ram:read_u8(i+17)
        if w~=0xcc then
            w=(7-(w-w%16)/16)*16+w%16
        end
        ram:write_u8(i,w)
        ram:write_u8(i+17,b)
    end
end

function interface.start_play(init)
	local throttled_state = machine.video.throttled
	--machine.video.throttled = false
    if interface.set_color==-1 then
        interface.set_color=0
        interface.color="W"
    end
    interface.turn = false
    send_input(":IN.1", 0x10, 1) -- CLEAR
    if (interface.color == "W") then
        interface.color = "B"
        send_input(":IN.0", 0x20, 1) -- A
    else
        interface.color = "W"
        send_input(":IN.1", 0x20, 1) -- H
    end
    send_input(":IN.1", 0x08, 1) -- ENTER
    send_input(":IN.1", 0x40, 1) -- G
    send_input(":IN.1", 0x08, 1) -- ENTER
	machine.video.throttled = throttled_state
end

function interface.is_selected(x, y)
	if (interface.invert) then
		y = 9 - y
	end
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit0")
	local d1 = output_value("digit1")
	local d2 = output_value("digit2")
	local d3 = output_value("digit3")
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos1(p)  -- "A" to "H" keys
	if	   (p == 1) then send_input(":IN.0", 0x20, 0.5)
	elseif (p == 2)	then send_input(":IN.0", 0x10, 0.5)
	elseif (p == 3)	then send_input(":IN.0", 0x08, 0.5)
	elseif (p == 4)	then send_input(":IN.0", 0x04, 0.5)
	elseif (p == 5)	then send_input(":IN.0", 0x02, 0.5)
	elseif (p == 6)	then send_input(":IN.0", 0x01, 0.5)
	elseif (p == 7)	then send_input(":IN.1", 0x40, 0.5)
	elseif (p == 8)	then send_input(":IN.1", 0x20, 0.5)
	end
end

function interface.send_pos2(p)  -- "1" to "8" keys
	if	   (p == 1) then send_input(":IN.0", 0x20, 0.5)
	elseif (p == 2)	then send_input(":IN.0", 0x10, 0.5)
	elseif (p == 3)	then send_input(":IN.0", 0x08, 0.5)
	elseif (p == 4)	then send_input(":IN.0", 0x04, 0.5)
	elseif (p == 5)	then send_input(":IN.0", 0x02, 0.5)
	elseif (p == 6)	then send_input(":IN.0", 0x01, 0.5)
	elseif (p == 7)	then send_input(":IN.1", 0x40, 0.5)
	elseif (p == 8)	then send_input(":IN.1", 0x20, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if interface.set_color == -1 then
		invert_pos()
		interface.set_color = 0
	end
	if (interface.invert) then
		y = 9 - y
	end
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (event == "get" and output_value("4.0") ~= 0) then
			send_input(":IN.1", 0x10, 0.5) -- CLEAR
		end
		if (interface.turn) then
			interface.send_pos1(x)
			interface.send_pos2(y)
		end
		if (event == "put") then
			if (interface.turn) then
				send_input(":IN.1", 0x08, 0.5)
			end
			interface.turn = not interface.turn
		end
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "4", "1", "8" },
	}
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

function interface.get_promotion(x, y)
	return 'q'	-- CC Mk 2 always promotes to Queen
end

function interface.promote(x, y, piece)
	-- automatic promotion to Queen, nothing to do/set
end

return interface
