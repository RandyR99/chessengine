local interface = {}

interface.level = "a1"
interface.cur_level = nil
interface.turn = true
interface.capt = 0
interface.edit = false
local getprom = false

-- MODERNIZED RAM OBJECT ACCESSOR:
-- Replaces the deprecated root emu.item string lookup with clean device spaces
local cpu = machine.devices[":maincpu"]
local ram = cpu and cpu.spaces["program"]

local f0 = "00"
local f1 = "--"
local f2 = "--"
local throttled = true

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))
	send_input(":IN.0", 0x04, 0.5) -- LEVEL
	sb_press_square(":board:board", 0.5, x, y)
	send_input(":IN.0", 0x80, 0.5) -- CLEAR
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	interface.turn = true
	interface.capt = 0
	interface.edit = false
	getprom = false
	f0 = "00"
	f1 = "--"
	f2 = "--"
	emu.wait(1)

	interface.cur_level = "a1"
	interface.setlevel()
end

function selectpiece(p,n)
	local q=math.abs(p)
	local x=11
	local y=8
	local z=1
	if p<0 then
		x=10
		z=-1
	end
	if q==1 then
		x=x+z
	elseif q==6 then
		if n<5 then
			y=n
		else
			x=x+z
			y=n-4
		end
	elseif q>2 then
		if n==2 then
			x=x+z
		end
		y=10-q
	end
	sb_select_piece(":board:board", 1, x, y, "get")
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x100, 1) -- SHIFT
		send_input(":IN.0", 0x001, 1) -- PROBLEM
		send_input(":IN.0", 0x020, 1) -- ALTERNATE
		for i=1,33 do
			emu.wait(2.6)
			machine:popmessage("board clear " .. tostring(33-i))
		end
		return ("")
	else
		local m = {0,0,0,0,0,0,0,0,0,0,0,0,0}
		local x0 = 0
		local y0 = 0
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					local n=m[p+7]+1
					m[p+7]=n
					selectpiece(p,n)
					sb_select_piece(":board:board", 1, x, 9-y, "put")
					if p==mode then
						x0=x
						y0=9-y
					end
				end
			end
		end
		sb_press_square(":board:board", 1, x0, y0)
		send_input(":IN.0", 0x080, 1) -- CLEAR
	end
end

function interface.edit_game(on)
	if not on then
		throttled = machine.video.throttled
		machine.video.throttled = false
		emu.wait(10)
	end
	send_input(":IN.0", 0x02, 0.5) -- OPTION
	sb_press_square(":board:board", 0.5, 3, 1)
	sb_press_square(":board:board", 0.5, 3, 1)
	send_input(":IN.0", 0x80, 0.5) -- CLEAR
	if not on then
		machine.video.throttled = throttled
	end
	interface.edit = on
	emu.wait(0.5)
	
	-- Refreshing ram variable handle safely before execution
	ram = machine.devices[":maincpu"].spaces["program"]
	if ram then
		f1 = getf(ram:read_u8(0x1000))
	end
end

function interface.start_play(init)
	interface.turn = false
	f0 = f1
	ram = machine.devices[":maincpu"].spaces["program"]
	if ram then
		ram:write_u8(0x000f, ram:read_u8(0x000f) | 0x01) -- Ponder OFF
	end
	send_input(":IN.0", 0x20, 1) -- MOVE
end

function interface.stop_play()
	send_input(":IN.0", 0x20, 1) -- MOVE
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
	local root = machine.devices[":"]
	if not root then return false end
	
	local d2_node = root:output("digit2")
	local d2_val = d2_node and d2_node:get() or 0
	if (d2_val == 0x54) then
		send_input(":IN.0", 0x80, 0.5) -- CLEAR
	end

	ram = machine.devices[":maincpu"].spaces["program"]
	if not ram then return false end
	
	if (ram:read_u8(0x1000) == 0xff) then
		return false
	elseif (f0 ~= "00" and getf(ram:read_u8(0x1001)) == f0) then
		f1 = getf(ram:read_u8(0x1000)) -- Source square
		f2 = getf(ram:read_u8(0x00fb)) -- Destination square
		f0 = "00"
		ram:write_u8(0x000f, ram:read_u8(0x000f) & 0xfe) -- Ponder ON
	end
	if (f0 == "00") then
		local z = tostring(10 * x + y)
		return (z == f1 or z == f2)
	end
	return false
end

function removepiece(p)
	local z = 9
	if (p > 0) then
		send_input(":board:SPAWN", 0x01<<(6-p), 1)
		z = 12
	elseif (p < 0) then
		send_input(":board:SPAWN", 0x01<<(12+p), 1)
	end
	sb_move_piece(":board:board", z, 8)
	sb_press_square(":board:board", 1, z, 8)
end

function interface.select_piece(x, y, event)
	if (interface.turn and not interface.edit and (event == "get_castling" or event == "put_castling" or event == "en_passant")) then
		return
	end
	emu.wait(1)
	
	local root = machine.devices[":"]
	if not root then return end
	
	local d2_node = root:output("digit2")
	local d2_val = d2_node and d2_node:get() or 0
	if (d2_val == 0x40) then -- castling & enpassant
		sb_select_piece(":board:board", 1, x, y, event)
		if     (y == 4) then removepiece(6)
		elseif (y == 5) then removepiece(-6)
		end
		return
	end
	if (interface.turn or interface.edit or event == "get_castling" or event == "put_castling" or event == "en_passant") then
		if (event == "get") then
			local dot_node = root:output("4.7")
			repeat
				emu.wait(0.5)
				local dot_val = dot_node and dot_node:get() or 0
			until dot_val ~= 0x00
			
			f0 = tostring(x) .. tostring(y)
			ram = machine.devices[":maincpu"].spaces["program"]
			if ram then
				ram:write_u8(0x000f, ram:read_u8(0x000f) | 0x01) -- Ponder OFF
			end
		end
		sb_select_piece(":board:board", 1, x, y, event)
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
end

function interface.get_options()
	return { { "string", "Level", "a1"}, }
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

function interface.test_promotion(x, y)
	getprom = true
	local p
	throttled = machine.video.throttled
	machine.video.throttled = false
	emu.wait(10)
	send_input(":IN.0", 0x001, 1) -- VERIFY
	sb_press_square(":board:board", 1, x, y)

	local root = machine.devices[":"]
	if root then
		local q_node = root:output("0.3")
		local n_node = root:output("0.6")
		local b_node = root:output("0.5")
		local r_node = root:output("0.4")

		if     (q_node and q_node:get() ~= 0) then p = "Q"
		elseif (n_node and n_node:get() ~= 0) then p = "N"
		elseif (b_node and b_node:get() ~= 0) then p = "B"
		elseif (r_node and r_node:get() ~= 0) then p = "R"
		else p = "Q"
		end
	else
		p = "Q"
	end

	send_input(":IN.0", 0x080, 1) -- CLEAR
	machine.video.throttled = throttled
	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	if getprom then
		sb_promote(":board:board", x, y, piece)
		getprom = false
		return
	end
	
	local root = machine.devices[":"]
	if not root then return end
	
	local z = 11
	local p = 8
	if     (piece == "n") then p = 5
	elseif (piece == "b") then p = 6
	elseif (piece == "r") then p = 7
	end
	if (y == 1) then
		z = 10
	end
	
	local q_node = root:output("0.3")
	repeat
		emu.wait(0.5)
		local q_val = q_node and q_node:get() or 0
	until q_val ~= 0
	
	sb_press_square(":board:board", 1, z, p)
	
	local check_node = root:output("piece_" .. ("ijkl"):sub(z-8,z-8) .. tostring(p))
	local check_val = check_node and check_node:get() or 0
	if check_val ~= 0 then
		sb_remove_piece(":board:board", z, p)
		sb_press_square(":board:board", 1, x, y)
		if (y == 1) then
			removepiece(-6)
		else
			removepiece(6)
		end
	elseif p ~= 8 then
		if (y == 1) then
			z = 9
		else
			z = 12
		end
		sb_remove_piece(":board:board", z, p)
	end
	sb_promote(":board:board", x, y, piece)
end

return interface

