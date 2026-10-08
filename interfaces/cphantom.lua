interface = {}

interface.level = "a1"
interface.cur_level = nil
interface.turn = true
interface.capt = 0
local ram = emu.item(machine.devices[':maincpu'].items['0/0-1fff'])
local f0 = "00"
local f1 = "--"
local f2 = "--"

function interface.get_module()
	return "Fidelity Chesster Phantom"
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))
	send_input(":IN.0", 0x004, 0.5) -- LEVEL
	sb_press_square(":board", 0.5, x, y)
	send_input(":IN.0", 0x080, 0.5) -- CLEAR
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	interface.turn = true
	interface.capt = 0
	f0 = "00"
	f1 = "--"
	f2 = "--"
	emu.wait(4)
    ram:write(0x087a, ram:read(0x087a) & 0xfd) -- Speech OFF
	for i = 1, 33 do
		emu.wait(1.1)
		machine:popmessage("Board-Test " .. tostring(33-i))
	end
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "a1"
	interface.setlevel()
end

function interface.start_play(init)
	interface.turn = false
	f0 = f1
    ram:write(0x087a, ram:read(0x087a) | 0x01) -- Ponder OFF
	send_input(":IN.0", 0x040, 1) -- MOVE
end

function interface.stop_play()
	send_input(":IN.0", 0x040, 1) -- MOVE
end

function getf(code)
	if (code == 0xff) then
		return "--"
	end
	local x = code % 16
	local y = (code - x) / 16
	return tostring(x+1) .. tostring(y+1):sub(1,1)
end

function interface.is_selected(x, y)
    if (ram:read(0x1000) == 0xff) then
		return
	elseif (f0 ~= "00" and getf(ram:read(0x1001)) == f0) then
        f1 = getf(ram:read(0x1000)) -- Source square
        f2 = getf(ram:read(0x00fb)) -- Destination square
		f0 = "00"
		ram:write(0x087a, ram:read(0x087a) & 0xfe) -- Ponder ON
	end
	if (f0 == "00") then
		local z = tostring(10 * x + y)
		return (z == f1 or z == f2)
	end
end

function removepiece(p)
	local z = 9
	if (p > 0) then
		send_input(":board:SPAWN", 0x01 << (6 - p), 1)
		z = 12
	elseif (p < 0) then
		send_input(":board:SPAWN", 0x01 << (12 + p), 1)
	end
	sb_move_piece(":board", z, 8)
	sb_press_square(":board", 1, z, 8)
end

function interface.select_piece(x, y, event)
	if (interface.turn and (event == "get_castling" or event == "put_castling" or event == "en_passant")) then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(1)
	if (output:get_value("digit2") == 0x40) then -- castling & enpassant
		sb_select_piece(":board", 1, x, y, event)
		if     (y == 4) then removepiece( 6)
		elseif (y == 5) then removepiece(-6)
		end
		machine.video.throttled = throttled_state
		return
	end
	if (interface.turn) then
		if (event == "get") then
			repeat
				emu.wait(0.5)
			until output:get_value("4.7") ~= 0x00
			f0 = tostring(x) .. tostring(y)
			ram:write(0x087a,ram:read(0x087a) | 0x01) -- Ponder OFF
		end
		sb_select_piece(":board", 1, x, y, event)
		if (interface.capt ~= 0) then -- capture
			removepiece(interface.capt)
			interface.capt = 0
		elseif (event == "capture") then
			interface.capt = get_piece_id(x, y)
		end
	end
	if (event == "put") then
		interface.turn = not interface.turn
	end
	machine.video.throttled = throttled_state
end

function interface.get_options()
	return {
		{ "string", "Level", "a1" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if (level:match("^[a-h][1-8]$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	return 'q' -- TODO
end

function interface.promote(x, y, piece)
	if (f0 == "00") then
		sb_promote(":board", x, y, piece)
		return
	end
	local z = 0
	local p = 8
	if     (piece == "n") then p = 5
	elseif (piece == "b") then p = 6
	elseif (piece == "r") then p = 7
	else z = 1
	end
	if (y == 1) then
		z = 9 + z
	else
		z = 12 - z
	end
	sb_press_square(":board", 1, x, y)
	sb_press_square(":board", 1, z, p)
	sb_press_square(":board", 1, x, y)
	sb_press_square(":board", 1, z, p)
	emu.wait(1)
	sb_promote(":board", x, y, piece)
end

return interface
