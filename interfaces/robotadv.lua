interface = {}

interface.turn = false
interface.level = 2
interface.cur_level = 2
interface.edit = false
local throttled = true

local ram = emu.item(machine.devices[':maincpu'].items['0/:nvram'])
local adr = 0x6e
local led = 2

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	ram:write(0xceb0,interface.level)
	ram:write(0xceb1,interface.level)
--	send_input(":IN.0", 0x40, 1) -- Level
--  send_input(":IN.0", 0x80, 1) -- GO
--	machine:popmessage("Level " .. tostring(interface.level))
end

function interface.setup_machine()
	interface.turn = false
	interface.edit = false
	emu.wait(1.0)
	send_input(":IN.2", 0x2, 2) -- New Game
    send_input(":IN.2", 0x40, 2) -- Emotions
	sb_reset_board(":board")
	emu.wait(1.0)
	adr = 0x6e
	led = 2

	interface.cur_level = ram:read(0xceb0)
	interface.setlevel()
end

function setpiece(n)
	if     n == 1 then send_input(":IN.1", 0x20, 1) -- K
	elseif n == 2 then send_input(":IN.1", 0x04, 1) -- Q
	elseif n == 3 then send_input(":IN.2", 0x20, 1) -- R
	elseif n == 4 then send_input(":IN.1", 0x02, 1) -- B
	elseif n == 5 then send_input(":IN.2", 0x40, 1) -- N
	elseif n == 6 then send_input(":IN.2", 0x04, 1) -- P
	end
end

function prompieces()
	local z = { 4,2,2,1,1,3,3}
	for y=1,7 do
		if output:get_value("piece_i" .. tostring(8-y)) == 0 then
			send_input(":board:SPAWN", 0x01<<z[y], 0.09)
			sb_move_piece(":board", 9, 8-y)
		end
		if output:get_value("piece_l" .. tostring(8-y)) == 0 then
			send_input(":board:SPAWN", 0x01<<(z[y]+6), 0.09)
			sb_move_piece(":board", 12, 8-y)
		end
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x40, 1) -- Set Up
		sb_clear_board(":board")
		prompieces()
		return ("")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.0", 0x04, 1) -- Change Color
					end
					if math.abs(p)~=math.abs(piece) then
						setpiece(math.abs(p))
					end
					if p>0 then
						z=6-p
					else
						z=12+p
					end
					send_input(":board:SPAWN", 0x01<<z, 0.09)
					sb_move_piece(":board", x, 9-y)
					emu.wait(0.5)
					piece=p
				end
			end
		end
		if mode*piece<0 then
			send_input(":IN.0", 0x04, 1) -- Change Color
		end
		send_input(":IN.1", 0x40, 1) -- Set Up
	end
end

function interface.edit_game(on)
	if on == true then
		send_input(":IN.0", 0x02, 1) -- Verify
		send_input(":IN.1", 0x40, 1) -- Setup
		interface.edit = true
		interface.turn = true
	else
		send_input(":IN.0", 0x02, 1) -- Verify
		send_input(":IN.1", 0x40, 1) -- Setup
		interface.edit = false
		interface.turn = false
	end
end

function interface.start_play(init)
	send_input(":IN.0", 0x80, 1) -- GO
	interface.turn = not interface.turn
	led = 5 - led
end

function interface.stop_play()
	send_input(":IN.0", 0x80, 1) -- GO
end

function get_piece_sb(x, y)
	local piece = output:get_value("piece_" .. ("abcdefgh"):sub(x,x) .. tostring(y))
	if piece < 7 then return 7 - piece
	elseif piece < 13 then return piece - 13
	else return 0
	end
end

function interface.is_selected(x, y)
--	if output:get_value("1." .. led) ~= 0 then -- slower but safer
	if get_piece_sb(x, y) ~= get_piece_id(x, y) then
		local z1 = (ram:read(adr))&0x77
		local z2 = (ram:read(adr+1))&0x77
		local x1 = 8-(z1>>4)
		local y1 = 8-(z1&0x07)
		local x2 = 8-(z2>>4)
		local y2 = 8-(z2&0x07)
		return (x == x1 and y == y1) or (x == x2 and y == y2)
	end
end

function interface.select_piece(x, y, event)
	if event == "get" then
		adr = adr + 2
		if interface.edit then
			led = 5 - led
		else
			interface.turn = not interface.turn
			if interface.turn then
				while output:get_value("1." .. led) == 0 do
					emu.wait(0.5)
				end
			end
		end
	end
	if interface.turn then
		if event == "en_passant" then
			sb_remove_piece(":board", x, y)
		else
			sb_select_piece(":board", 0.5, x, y, event)
			emu.wait(0.5)
		end
	end
end

function interface.get_options()
	return { { "spin", "Level", "2", "0", "9"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 0 or level > 9) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.test_promotion(x, y)
	local p
	throttled = machine:video().throttled
	machine:video().throttled = false
	emu.wait(15)
	prompieces()
	send_input(":IN.0", 0x02, 1) -- Verify
	sb_press_square(":board", 1, x, y)

	if     (output:get_value("2.5") ~= 0) then p = "Q"
	elseif (output:get_value("2.3") ~= 0) then p = "N"
	elseif (output:get_value("2.4") ~= 0) then p = "B"
	elseif (output:get_value("2.2") ~= 0) then p = "R"
	else p = "Q"
	end

	send_input(":IN.0", 0x02, 1) -- Verify
	machine:video().throttled = throttled
	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	if not interface.turn then
		sb_promote(":board", x, y, piece)
		return
	end
	send_input(":IN.1", 0x20, 1) -- Promote
	if     piece == "q" then send_input(":IN.1", 0x04, 1)
	elseif piece == "r" then send_input(":IN.2", 0x20, 1)
	elseif piece == "n" then send_input(":IN.2", 0x40, 1)
	elseif piece == "b" then send_input(":IN.1", 0x02, 1)
	end
	sb_promote(":board", x, y, piece)
end

return interface
