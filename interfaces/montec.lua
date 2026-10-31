interface = {}

interface.invert = false
interface.level = "c2"
interface.cur_level = nil
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end


function interface.get_module()
	if machine.system.name == "montec" then
		return "Mephisto Monte Carlo"
	elseif machine.system.name == "monteca" then
		return "Mephisto Monte Carlo v2"
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
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1,1)]
	if (x > 5) then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local y = interface.level:sub(2,2)
	send_input(":KEY.0", 0x20, 1) -- LEV
	emu.wait(0.5)
	sb_press_square(":board:board", 1, x, y)
	emu.wait(0.5)
	send_input(":KEY.0", 0x40, 1) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board:board")
	interface.invert = false
	emu.wait(2)
	machine.video.throttled = throttled_state
	interface.cur_level = "c2"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		sb_clear_board(":board:board")
		emu.wait(8)
		send_input(":KEY.0", 0x02, 0.5) -- POS
		send_input(":KEY.0", 0x40, 0.5) -- ENT
		send_input(":KEY.0", 0x40, 0.5) -- ENT
		machine.video.throttled = throttled_state
		return ("")
	else
		local piece = 7
		local z
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						if p < 0 then
							send_input(":KEY.1", 0x40, 0.5) -- Black
						else
							send_input(":KEY.1", 0x80, 0.5) -- White
						end
					end
					if math.abs(p) ~= math.abs(piece) then
						send_input(":KEY.1", 0x01 << (6 - math.abs(p)), 0.5)
					end
					if p > 0 then
						z = 6 - p
					else
						z = 12 + p
					end
					send_input(":board:board:SPAWN", 0x01 << z, 0.09)
					sb_move_piece(":board:board", x, 9 - y)
					emu.wait(0.5)
					piece = p
				end
			end
		end
		if mode == 1 then
			send_input(":KEY.1", 0x80, 0.5) -- White
		else
			send_input(":KEY.1", 0x40, 0.5) -- Black
		end
		send_input(":KEY.0", 0x10, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY.0", 0x04, 0.5) -- MEM
	else
		send_input(":KEY.0", 0x10, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board:board")
		interface.invert = true
	end
	send_input(":KEY.0", 0x40, 0.5) -- ENT
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local d1_val = output_value("digit1")
	local d5_val = output_value("digit5")
	
	if (d1_val & 0x80 ~= 0 and d5_val & 0x80 ~= 0) then
		return false
	end
	
	return output_value("led" .. ((y - 1) * 8 + (x - 1))) ~= 0
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_select_piece(":board:board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "c2" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		interface.level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local d0 = output_value("digit0") & 0x7f
	local d1 = output_value("digit1") & 0x7f
	local d4 = output_value("digit4") & 0x7f
	local d5 = output_value("digit5") & 0x7f
	
	local d3 = nil
	if (d0 == 0x73 and d1 == 0x50) then	-- upper display shows 'Pr'
		d3 = output_value("digit3") & 0x7f
	end
	if (d4 == 0x73 and d5 == 0x50) then	-- lower display shows 'Pr'
		d3 = output_value("digit7") & 0x7f
	end
	
	if     (d3 == 0x5e) then return "q"
	elseif (d3 == 0x31) then return "r"
	elseif (d3 == 0x38) then return "b"
	elseif (d3 == 0x6d) then return "n"
	end
	return nil
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board:board", x, y, piece)
	if     (piece == "q") then send_input(":KEY.1", 0x10, 1)
	elseif (piece == "r") then send_input(":KEY.1", 0x08, 1)
	elseif (piece == "b") then send_input(":KEY.1", 0x04, 1)
	elseif (piece == "n") then send_input(":KEY.1", 0x02, 1)
	end
end

-- show_info reads the search result from RAM, without key presses (an INFO press could land just as the move appears
-- and hide it). Found in the code of the INFO pages: the search stores its result block (0xbe29 in the montec ROM)
-- with the main line as from-squares at base and to-squares at base + 6 (up to 6 moves, 0 ends it; 10x12 board,
-- a1 = 21), the depth at base + 0x2a (the INFO page shows it + 1) and the evaluation for the machine as a 16-bit value
-- at base + 0x30/0x31 (0x8000 = 0.00, high byte pawns, low byte 1/256 pawn). The Super Mondial program (smondial.lua
-- borrows this reader) keeps the same block 0x14 bytes higher.
local info_ram = { montec = 0x06c8, monteca = 0x06c8, smondial = 0x06dc, smondialab = 0x06dc, smondialb = 0x06dc }
local base = info_ram[machine.system.name]
local stale = nil
local first = true

function interface.show_info(on)
	local sp = machine.devices[":maincpu"].spaces["program"]
	local raw = ""
	for a = base, base + 0x0b do
		raw = raw .. string.char(sp:read_u8(a))
	end
	for _, a in ipairs({ base + 0x2a, base + 0x30, base + 0x31 }) do
		raw = raw .. string.char(sp:read_u8(a))
	end
	if not on or first then
		first = false -- battery RAM still holds the last search before this session's first player turn
		stale = raw
		return nil
	end
	if raw == stale then
		return nil -- nothing from this search yet
	end
	stale = nil
	local info = {}
	local function square(v)
		local file, rank = (v - 21) % 10, (v - 21) // 10
		if v >= 21 and v <= 98 and file <= 7 then
			return string.char(0x61 + file) .. (rank + 1)
		end
	end
	local pv = {}
	for k = 1, 6 do
		local from, to = square(raw:byte(k)), square(raw:byte(k + 6))
		if not from or not to or from == to then
			break
		end
		pv[#pv + 1] = from .. to
	end
	if #pv > 0 then
		info.pv = pv
	end
	local depth, lo, hi = raw:byte(13, 15)
	info.depth = depth + 1
	info.score = ((hi << 8 | lo) - 0x8000) * 100 // 256
	return info
end

if base == nil then
	interface.show_info = nil -- result block not checked for this program
end
interface.info_every = 1 -- show_info only reads RAM

return interface

