interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.invert = false
interface.level = "a2"
interface.cur_level = nil
interface.style = "normal"
interface.cur_style = nil
interface.opening = "standard"
interface.cur_opening = nil

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))
	send_input(":IN.1", 0x02, 0.5) -- Level
	sb_press_square(":board", 0.5, x, y)
	send_input(":IN.1", 0x02, 0.5) -- Level
end

function interface.setstyle()
	if (interface.cur_style == nil or interface.cur_style == interface.style) and
	   (interface.cur_opening == nil or interface.cur_opening == interface.opening) then
		return
	end
	interface.cur_style = interface.style
	interface.cur_opening = interface.opening
	send_input(":IN.1", 0x02, 0.5) -- Level
	local y = 1
	if interface.style == "aggressive" then y = 2
	elseif interface.style == "desperate" then y = 3
	elseif interface.style == "positional" then y = 4
	end
	if interface.opening == "rare" then y = y + 4
	end
	sb_press_square(":board", 0.5, 8, y)
	send_input(":IN.1", 0x02, 0.5) -- Level
end

function interface.setup_machine()
	sb_reset_board(":board")
	interface.invert = false
--	send_input(":IN.1", 0x80, 0.5) -- New Game
	emu.wait(2)

	interface.cur_level = "a2"
	interface.setlevel()
	emu.wait(0.5)
	interface.cur_style = "normal"
	interface.cur_opening = "standard"
	interface.setstyle()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x40, 0.5) -- Enter Position
		sb_clear_board(":board")
		emu.wait(10)
		return ("")
	else
		local piece=3
		local z
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.1", 0x20, 0.6) -- Sound/Color
					end
					emu.wait(0.5)
					if math.abs(p)~=math.abs(piece) then
						send_input(":IN.0", 0x80>>(math.abs(p)-1), 0.6)
					end
					if p>0 then
						z=6-p
					else
						z=12+p
					end
					send_input(":board:SPAWN", 0x01<<z, 0.09)
					sb_select_piece(":board", 1, x, 9-y, "put")
					piece=p
				end
			end
		end
		if mode*piece<0 then
			send_input(":IN.1", 0x20, 0.5) -- Sound/Color
		end
		send_input(":IN.1", 0x40, 0.5) -- Enter Position
	end
end

function interface.edit_game()
	send_input(":IN.1", 0x01, 0.5) -- Multi-Move
	emu.wait(0.5)
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":IN.0", 0x01, 0.5) -- Move
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	return output_value((y - 1) .. "." .. (x - 1)) ~= 0
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	if (event == "capture") then
		sb_press_square(":board", 0.5, x, y)
	end
	sb_select_piece(":board", 0.5, x, y, event)
	emu.wait(0.5)
end

function interface.get_options()
	return { { "string", "Level", "a2"}, { "combo", "Opening", "standard", "standard\trare"},
		 { "combo", "Style", "normal", "normal\taggressive\tdesperate\tpositional"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:match("^[a-e][1-8]$") or level:match("^f[1-4]$")) then
			interface.level = level
			interface.setlevel()
		end
	elseif (name == "style" and value ~= "") then
		interface.style = value
		interface.setstyle()
	elseif (name == "opening" and value ~= "") then
		interface.opening = value
		interface.setstyle()
	end
end

function interface.get_promotion(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local piece = 'q'
	if     (output_value("8.4") ~= 0) then piece = 'q'
	elseif (output_value("8.3") ~= 0) then piece = 'r'
	elseif (output_value("8.2") ~= 0) then piece = 'b'
	elseif (output_value("8.1") ~= 0) then piece = 'n'
	end
	return piece
end

function interface.promote_special(piece)
	if     (piece == "q") then send_input(":IN.0", 0x40, 0.5)
	elseif (piece == "r") then send_input(":IN.0", 0x20, 0.5)
	elseif (piece == "b") then send_input(":IN.0", 0x10, 0.5)
	elseif (piece == "n") then send_input(":IN.0", 0x08, 0.5)
	end
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board", x, y, piece)
end

return interface
