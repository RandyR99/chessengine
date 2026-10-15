interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.invert = false
interface.level = "2"
interface.cur_level = nil

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local lev1 = string.find("12345678ABCDEFGH",interface.cur_level)
	local lev2 = string.find("12345678ABCDEFGH",interface.level)
	interface.cur_level = interface.level
	send_input(":IN.1", 0x20, 0.5) -- Sound
	send_input(":IN.1", 0x20, 0.5) -- Sound
	local n = (lev2 - lev1 + 16) % 16
	for i=0,n do
		send_input(":IN.1", 0x10, 0.5) -- Level
	end
end

function interface.setup_machine()
	sb_reset_board(":board")
	interface.invert = false
--	send_input(":IN.1", 0x80, 1)	-- New Game
	emu.wait(1)

	interface.cur_level = "2"
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x08, 0.5) -- K
	elseif (n == 2) then send_input(":IN.1", 0x08, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.0", 0x10, 0.5) -- R
	elseif (n == 4) then send_input(":IN.0", 0x20, 0.5) -- B
	elseif (n == 5) then send_input(":IN.0", 0x40, 0.5) -- N
	elseif (n == 6) then send_input(":IN.0", 0x80, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x04, 1)	-- Enter Pos
		send_input(":IN.1", 0x80, 1)	-- New Game
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.1", 0x20, 0.5) -- Color
					end
					if math.abs(p)~=math.abs(piece) then
						setpiece(math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		if mode*piece<0 then
			send_input(":IN.1", 0x20, 0.5) -- Color
		end
		send_input(":IN.0", 0x04, 1)	-- Enter Pos
	end
end

function interface.edit_game()
	send_input(":IN.1", 0x04, 1) -- Multi Move
	emu.wait(0.5)
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":IN.1", 0x02, 1)	-- Move
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local xval = output_value("6." .. tostring(8 - x)) ~= 0
	local yval = output_value("5." .. tostring(8 - y)) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	if (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 1, x, y, event)
	end
end

function interface.get_options()
	return { { "string", "Level", "2"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = string.upper(value:match("^%s*(.-)%s*$"):gsub("%s%s+"," ")) -- trim
		if level:match("^[1-8]$") or level:match("^[A-H]$") then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	if piece == piece:lower() then
		promotion_error(piece)
		sb_promote(":board", x, y, "q")	-- TODO
	else
		sb_promote(":board", x, y, piece)
 	end
end

return interface
