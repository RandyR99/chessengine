interface = {}

interface.invert = false
interface.level = "a4"
interface.cur_level = nil
local ram = machine.memory.shares[":maincpu:internal_ram"]

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "mm6" then
		return "Mephisto MM VI"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Frans Morsch"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = {a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8}
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))

	send_input(":IN.0", 0x04, 0.25) -- LEV
	ram:write_u16(0x3bc, 16*(x-1)+2*(y-1))
	send_input(":IN.1", 0x20, 0.25) -- ENT
	send_input(":IN.0", 0x04, 0.25) -- LEV
	emu.wait(1)
	send_input(":IN.1", 0x08, 0.25) -- CLR
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	interface.invert = false
--	send_input(":IN.0", 0x10, 0.5) -- NEW GAME
	emu.wait(4)
	-- an uninitialized EEPROM (no nvram file) shows 'Err: E' after power-on until a key is pressed,
	-- then the board LEDs sweep for about 4.5 s (a CLR after a normal boot does nothing)
	send_input(":IN.1", 0x08, 0.25) -- CLR
	emu.wait(5)

	interface.cur_level = "a4"
	interface.setlevel()
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board:board")
		interface.invert = true
	end
	send_input(":IN.1", 0x20, 0.5) -- ENT
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.1", 0x10, 0.5) -- K
	elseif (n == 2) then send_input(":IN.1", 0x40, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.1", 0x80, 0.5) -- R
	elseif (n == 4) then send_input(":IN.1", 0x04, 0.5) -- B
	elseif (n == 5) then send_input(":IN.1", 0x02, 0.5) -- N
	elseif (n == 6) then send_input(":IN.1", 0x01, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x40, 0.5) -- POS
		send_input(":IN.1", 0x20, 0.5) -- ENT
		send_input(":IN.1", 0x20, 0.5) -- ENT
		return (":board:board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					setpiece(math.abs(p))
					if p*piece<0 then
						if p<0 then
							send_input(":IN.0", 0x20, 0.5) -- Black
						else
							send_input(":IN.0", 0x08, 0.5) -- White
						end
					end
					sb_press_square(":board:board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		if mode<0 then
			send_input(":IN.0", 0x20, 0.5) -- Black
		else
			send_input(":IN.0", 0x08, 0.5) -- White
		end
		send_input(":IN.1", 0x08, 0.5) -- CLR
	end
end

function interface.edit_game()
	send_input(":IN.0", 0x02, 0.5) -- OPT
	send_input(":IN.1", 0x20, 0.5) -- ENT
	send_input(":IN.1", 0x08, 0.5) -- CLR
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local z = (x-1)+(y-1)*8
	return output_value("led" .. z) ~= 0
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_select_piece(":board:board", 0.5, x, y, event)
end

function interface.get_options()
	return {{"string", "Level", "a4"}}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if level:match("^[a-h][1-8]$") then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	if     output_value("s1.14") ~= 0 then return "q"
	elseif output_value("s1.16") ~= 0 then return "r"
	elseif output_value("s1.17") ~= 0 then return "b"
	elseif output_value("s1.19") ~= 0 then return "n"
	end
end

function interface.promote_special(piece)
	if     (piece == "q") then send_input(":IN.1", 0x40, 0.5)
	elseif (piece == "r") then send_input(":IN.1", 0x80, 0.5)
	elseif (piece == "b") then send_input(":IN.1", 0x04, 0.5)
	elseif (piece == "n") then send_input(":IN.1", 0x02, 0.5)
	end
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board:board", x, y, piece)
end

return interface
