interface = {}

interface.level = 1
interface.cur_level = nil
-- MCU RAM (HMCS40 data space): board at 16*(x-1)+y-1, level at 0x18
local ram = machine.devices[":maincpu"].spaces["data"]

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	ram:write_u8(0x18, interface.level - 1)
	machine:popmessage("Level " .. tostring(interface.level))
end

function interface.setup_machine()
	sb_reset_board(":board0")
	emu.wait(8) -- the power-on LED sweep takes ~6 s on the Electronic Trio; keys are ignored until it ends

	interface.cur_level = 1
	interface.setlevel()
end

function interface.start_play()
	send_input(":IN.0", 0x04, 1) -- Play
end

-- set_pos is switched off: writing the board RAM is not enough. The MCU also keeps the king
-- squares, castling rights and move history elsewhere in RAM (two alternating blocks, one per
-- side to move), and follows its opening book by move history. A position with the kings off
-- their home squares hangs it. Games and takebacks still work through edit_game (Multi-Move).
if false then
function interface.set_pos(mode)
	if mode == 0 then
		return (":board0")
	else
		-- leave the opening book: new game, then non-book moves (a2a3, plus h7h6 if white is
		-- to move) in Multi-Move mode. New Game on the Electronic Trio also steps
		-- Chess -> Checkers -> Tic-Tac-Toe, so repeat until the chess start position is in RAM.
		for i = 1, 3 do
			send_input(":IN.0", 0x01, 1) -- New Game
			emu.wait(1)
			if ram:read_u8(0x00) == 0x04 and ram:read_u8(0x07) == 0x0c then
				break
			end
		end
		send_input(":IN.0", 0x10, 1) -- Multi Move
		sb_press_square(":board0", 1, 1, 2) -- a2
		sb_press_square(":board0", 1, 1, 3) -- a3
		if mode == 1 then
			sb_press_square(":board0", 1, 8, 7) -- h7
			sb_press_square(":board0", 1, 8, 6) -- h6
		end
		send_input(":IN.0", 0x10, 1) -- Multi Move
		local fig = {0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x00, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01}
		for x = 1, 8 do
			for y = 1, 8 do
				ram:write_u8(16 * (x - 1) + y - 1, fig[get_piece_id(x, y) + 7])
			end
		end
	end
end
end

function interface.edit_game()
	send_input(":IN.0", 0x10, 1) -- Multi Move
end

function interface.is_selected(x, y)
	local xval = output_value("0." .. tostring(8 - x)) ~= 0
	local yval = output_value("0." .. tostring(y + 7)) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if (event == "en_passant") then
		sb_remove_piece(":board0", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board0", x, y)
	else
		sb_select_piece(":board0", 0.5, x, y, event)
	end
end

function interface.get_options()
	return { { "spin", "Level", "1", "1", "8"}, }
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

function interface.test_promotion(x, y)
	emu.wait(0.5)
	local p=ram:read_u8(16 * (x - 1) + y - 1) & 0x07
	if     p == 0x05 then return "Q"
	elseif p == 0x04 then return "R"
	elseif p == 0x03 then return "B"
	elseif p == 0x02 then return "N"
	else return "Q"
	end
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	if piece == piece:lower() then
		emu.wait(1.5)
		promotion_error(piece)
		sb_promote(":board0", x, y, "q")
	else
		sb_promote(":board0", x, y, piece)
 	end
end

return interface
