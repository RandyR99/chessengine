interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.level = "a3"
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = {a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8}
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))

	send_input(":IN.2", 0x01, 0.5) -- Level
	local clevx = 0
	local clevy = 0
	for cx=1,8 do
		for cy=1,8 do
			if (interface.is_selected(cx, cy)) then
				clevx = cx
				clevy = cy
				cx = 8
				cy = 8
			end
		end
	end
	if (clevx > 0 and clevy > 0) and (clevx ~= x or clevy ~= y) then
		local dlev = (x * 8 + y) - (clevx * 8 + clevy)
		local dx = (x - clevx + 8) % 8
		local dy = y - clevy
		if (dlev >= -7 and dlev <= 4) then
			dx = 0
			dy = dlev
		end
		for i=1,dx do
			send_input(":IN.1", 0x02, 0.5) -- Tab
		end
		for i=1,math.abs(dy) do
			if (dy > 0) then
				send_input(":IN.2", 0x80, 0.5) -- +
			else
				send_input(":IN.0", 0x02, 0.5) -- -
			end
		end
	end
	send_input(":IN.1", 0x01, 0.5) -- Normal
end

function interface.setup_machine()
	sb_reset_board(":board")
--	send_input(":IN.0", 0x20, 0.5) -- New Game
	emu.wait(6)

	interface.cur_level = "a3"
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x04, 0.5) -- K
	elseif (n == 2) then send_input(":IN.2", 0x04, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.2", 0x08, 0.5) -- R
	elseif (n == 4) then send_input(":IN.0", 0x08, 0.5) -- B
	elseif (n == 5) then send_input(":IN.1", 0x04, 0.5) -- N
	elseif (n == 6) then send_input(":IN.1", 0x08, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.2", 0x40, 0.5) -- Set Up
		emu.wait(0.5)
		send_input(":IN.2", 0x10, 0.5) -- Sound
		emu.wait(0.5)
		send_input(":IN.1", 0x80, 0.5) -- Function
		send_input(":IN.0", 0x20, 0.5) -- New Game
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.1", 0x02, 0.5) -- Tab/Color
					end
					setpiece(math.abs(p))
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		if mode*piece<0 then
			send_input(":IN.1", 0x02, 0.5) -- Tab/Color
		end
		emu.wait(0.5)
		send_input(":IN.2", 0x10, 0.5) -- Sound
		emu.wait(0.5)
		send_input(":IN.1", 0x01, 0.5) -- Normal
	end
end

function interface.edit_game(on)
	if on then
		send_input(":IN.1", 0x20, 0.5) -- Analysis
	else
		send_input(":IN.1", 0x01, 0.5) -- Normal
	end
	emu.wait(0.5)
end

function interface.start_play()
	send_input(":IN.2", 0x02, 0.5) -- Play
end

-- game end (mate, stalemate, threefold, 50 moves, insufficient material): the info line shows move number,
-- symbol and move instead of the clocks, so the LCD stops changing; while it thinks its clock runs
local lcd_last, lcd_since
function interface.game_over()
	for i = 0, 7 do
		if output_value("1." .. i) ~= 0 or output_value("0." .. i) ~= 0 then
			lcd_last = nil
			return false
		end
	end
	local lcd = "" -- (no 'table' library in the interface environment)
	for r = 0, 15 do
		for c = 9, 28 do
			lcd = lcd .. output_value("s" .. r .. "." .. c)
		end
	end
	local t = machine.time:as_double()
	if lcd ~= lcd_last then
		lcd_last, lcd_since = lcd, t
		return false
	end
	return t - lcd_since >= 3
end

function interface.is_selected(x, y)
	local xval = output_value("1." .. (x - 1)) ~= 0
	local yval = output_value("0." .. (y - 1)) ~= 0
	return xval and yval
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

function getpiece()
	local piece = 0x00
	for i=1,7 do
		if (output_value("s" .. (i+8) .. ".12") ~= 0) then
			piece = piece | (1 << (i-1))
		end
	end
	return piece
end

function interface.get_promotion(x, y)
	local piece = getpiece()
	if     (piece == 0x3e) then return "q"
	elseif (piece == 0x3f) then return "r"
	elseif (piece == 0x36) then return "b"
	elseif (piece == 0x7c) then return "n"
	end
	return nil
end

function interface.promote_special(piece)
	if interface.get_promotion(x, y) ~= nil then
		return
	end
	if     (piece == "q") then send_input(":IN.2", 0x04, 0.5)
	elseif (piece == "r") then send_input(":IN.2", 0x08, 0.5)
	elseif (piece == "b") then send_input(":IN.0", 0x08, 0.5)
	elseif (piece == "n") then send_input(":IN.1", 0x04, 0.5)
	end
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
end

return interface
