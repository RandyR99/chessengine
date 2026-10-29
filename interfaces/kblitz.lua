interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

-- Based on the MessNew (CB-Emu) kblitzx interface. In MAME 0.289 the cursor keys
-- became two dials. They can only be turned from Lua in MAME 0.290 or later (0.289's
-- analog_field::read ignored mask/shift/remap for set_value overrides);
-- kblitz.lua.0289 is the reduced interface for MAME 0.289.

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = "a3"
interface.cur_level = nil
local ram = machine.memory.shares[":maincpu:internal_ram"]

local port = machine.ioport.ports[":IN.0"]
local mode_dial = port.fields["Mode Dial"]
local shuttle_dial = port.fields["Shuttle Dial"]
-- Mode Dial stops (position index): 0 Ready, 1 Options, 2 Info, 3 Game, 4 Set up, 5 Level
local mode_pos = 0
local shuttle_pos = 0

local function set_mode_pos(pos)
	mode_pos = pos % 6
	mode_dial:set_value(mode_pos)
	emu.wait(0.5)
end

-- one stop down / up on the Mode Dial; turning it enters the shown option
local function mode_down() set_mode_pos(mode_pos + 1) end
local function mode_up() set_mode_pos(mode_pos - 1) end

-- turn the Mode Dial down to a stop (as the real dial does, through the stops between)
local function setmode(pos)
	while mode_pos ~= pos do
		mode_down()
	end
end

-- turn the Shuttle Dial n detents right (n > 0) or left (n < 0); a detent is two
-- quadrature steps
local function shuttle(n)
	local dir = n > 0 and 1 or -1
	for i = 1, math.abs(n) * 2 do
		shuttle_pos = (shuttle_pos + dir) % 4
		shuttle_dial:set_value(shuttle_pos)
		emu.wait(0.2)
	end
	emu.wait(0.3)
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = {a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8}
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))
	ram:write_u16(0x394, 16*(x-1)+y-1)
	ram:write_u16(0x398, 16*(x-1)+y-1)
end

function interface.setup_machine()
	emu.wait(1)
	mode_pos = 0
	shuttle_pos = 0
	mode_dial:set_value(mode_pos)
	shuttle_dial:set_value(shuttle_pos)
	sb_reset_board(":board")
	emu.wait(6)

	interface.cur_level = "a3"
	interface.setlevel()
end

-- piece type shown in Set up mode
local function getpiece()
	local p = 0x00
	for i=0,3 do
		if output_value("s"..tostring(i)..".10") ~= 0 then
			p = p | (1 << i)
		end
	end
	if     p == 0x0d then p = 1
	elseif p == 0x0f then p = 2
	elseif p == 0x0c then p = 3
	elseif p == 0x01 then p = 4
	elseif p == 0x08 then p = 5
	elseif p == 0x00 and output_value("s3.9") ~= 0 then p = 6
	else p = 0
	end
	if output_value("s3.11") ~= 0 then
		p = -p
	end
	return p
end

-- put all pieces of type p on the board, returns the king square (10*x+y)
local function setpiece(p)
	local k=0
	local z
	if p>0 then
		z=6-p
	else
		z=12+p
	end
	for x=1,8 do
		for y=1,8 do
			if get_piece_id(x,y) == p then
				send_input(":board:SPAWN", 0x01<<z, 0.09)
				sb_select_piece(":board", 0.5, x, y, "put")
				emu.wait(0.25)
				if math.abs(p) == 1 then
					k = 10*x+y
				end
			end
		end
	end
	return k
end

function interface.set_pos(mode)
	if mode == 0 then
		return ("")
	end
	local p,k,x,y,z
	setmode(4) -- Set up
	emu.wait(0.5)
	sb_clear_board(":board")
	for i=1,12 do
		emu.wait(0.5)
		p = getpiece()
		if p ~= 0 then
			k = setpiece(p)
			if p == mode then
				z = k
			end
		end
		if i < 12 then
			shuttle(-1) -- next piece type
		end
	end
	emu.wait(1)
	-- touching the king of the side to move twice selects that side to move
	y = z % 10
	x = (z - y) / 10
	sb_press_square(":board", 0.5, x, y)
	sb_press_square(":board", 0.5, x, y)
	setmode(0) -- Ready (through Level)
end

function interface.edit_game(on)
	setmode(1) -- Options
	if on then
		shuttle(3) -- End Search
	else
		shuttle(2)
	end
	mode_up() -- enter
end

function interface.start_play()
	setmode(1) -- Options
	shuttle(1) -- Beg Search
	mode_up() -- enter
end

function interface.is_selected(x, y)
	return output_value(tostring(y-1).."."..tostring(x-1)) ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 0.5, x, y, event)
end

function interface.get_options()
	return {{"string", "Level", "a3"}}
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
	if     output_value("s1.10") ~= 0 then return "q"
	elseif output_value("s2.10") ~= 0 then return "r"
	elseif output_value("s0.10") ~= 0 then return "b"
	elseif output_value("s3.10") ~= 0 then return "n"
	end
end

-- the promotion piece is chosen with the Shuttle Dial before the pawn is put down
function interface.promote_special(piece)
	if     piece == "r" then shuttle(1)
	elseif piece == "b" then shuttle(2)
	elseif piece == "n" then shuttle(-1)
	end
	emu.wait(0.5)
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
end

return interface
