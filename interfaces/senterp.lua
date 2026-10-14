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
	if (interface.cur_style == nil or interface.cur_style == interface.style) then
		return
	end
	interface.cur_style = interface.style
	send_input(":IN.1", 0x02, 0.5) -- Level
	local y = 1
	if interface.style == "attacking" then y = 2
	elseif interface.style == "aggressive" then y = 3
	elseif interface.style == "positional" then y = 4
	end
	sb_press_square(":board", 0.5, 8, y)
	send_input(":IN.1", 0x02, 0.5) -- Level
end

function interface.setup_machine()
	sb_reset_board(":board")
	interface.invert = false
--	send_input(":IN.1", 0x80, 1)	-- New Game
	emu.wait(2)

	interface.cur_level = "a2"
	interface.setlevel()
	emu.wait(0.5)
	interface.cur_style = "normal"
	interface.setstyle()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x80, 0.5) -- K
	elseif (n == 2) then send_input(":IN.0", 0x40, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.0", 0x20, 0.5) -- R
	elseif (n == 4) then send_input(":IN.0", 0x10, 0.5) -- B
	elseif (n == 5) then send_input(":IN.0", 0x08, 0.5) -- N
	elseif (n == 6) then send_input(":IN.0", 0x04, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x40, 1)	-- Enter Position
		send_input(":IN.1", 0x10, 1)	-- Clear Board
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
		send_input(":IN.1", 0x40, 1)	-- Enter Position
	end
end

function interface.edit_game()
	send_input(":IN.1", 0x01, 1) -- Multi Move
	emu.wait(0.5)
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":IN.0", 0x01, 1)	-- Move
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local xval = output_value("2." .. tostring(x - 1)) ~= 0
	local yval = output_value("1." .. tostring(y - 1)) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return { { "string", "Level", "a2"}, { "combo", "Style", "normal", "normal\tattacking\taggressive\tpositional"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if (level:match("^[a-e][1-8]$") or level:match("^f[1-4]$")) then
			interface.level = level
			interface.setlevel()
		end
	elseif (name == "style" and value ~= "") then
		interface.style = value
		interface.setstyle()
	end
end

function interface.get_promotion(x, y)
	if     (output_value("0.4") ~= 0) then return 'q'
	elseif (output_value("0.3") ~= 0) then return 'r'
	elseif (output_value("0.2") ~= 0) then return 'b'
	elseif (output_value("0.1") ~= 0) then return 'n'
	end
	return nil
end

function interface.promote_special(piece)
	if interface.get_promotion(x, y) ~= nil then
		return
	end
	if     (piece=="q") then send_input(":IN.0", 0x40, 0.5)
	elseif (piece=="r") then send_input(":IN.0", 0x20, 0.5)
	elseif (piece=="b") then send_input(":IN.0", 0x10, 0.5)
	elseif (piece=="n") then send_input(":IN.0", 0x08, 0.5)
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
