interface = {}

interface.invert = false
interface.level = "a3"
interface.cur_level = nil

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	send_input(":IN.0", 0x20, 0.5) -- LEV
	sb_press_square(":board", 0.5, cols_idx[level:sub(1,1)], level:sub(2,2))
	send_input(":IN.0", 0x08, 0.5) -- ENT
end

function interface.setup_machine()
	sb_reset_board(":board")
	interface.invert = false
--	send_input(":IN.2", 0x01, 0.5) -- RES
	emu.wait(6.5)

	interface.cur_level = "a3"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x02, 0.9) -- POS
		send_input(":IN.0", 0x08, 0.9) -- ENT
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.0", 0x10, 0.9) -- White/Black
					end
					if math.abs(p)~=math.abs(piece) then
						send_input(":IN.1", 0x01<<(6-math.abs(p)), 0.9)
					end
					sb_press_square(":board", 0.9, x, 9-y)
					piece=p
				end
			end
		end
		if mode*piece<0 then
			send_input(":IN.0", 0x10, 0.9) -- White/Black
		end
		send_input(":IN.0", 0x01, 0.9) -- PLAY
	end
end

function interface.edit_game(on)
	if on then
		send_input(":IN.0", 0x04, 0.5) -- MEM
	else
		send_input(":IN.0", 0x01, 0.5) -- PLAY
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":IN.0", 0x08, 0.5) -- ENT
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	
	-- Modern output proxy lookups for row/column grid selection
	local x_led = machine.devices[":"]:output("2." .. tostring(x - 1))
	local y_led = machine.devices[":"]:output("0." .. tostring(y - 1))
	
	local xval = (x_led and x_led:get() or 0) ~= 0
	local yval = (y_led and y_led:get() or 0) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_select_piece(":board", 0.5, x, y, event)
end

function interface.get_options()
	return { { "string", "Level", "a3"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if (level:match("^[a-c][1-8]$") or level:match("^[de]1$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion_led()
	local q_led = machine.devices[":"]:output("1.6")
	local r_led = machine.devices[":"]:output("1.5")
	local b_led = machine.devices[":"]:output("1.4")
	local n_led = machine.devices[":"]:output("1.3")

	if     (q_led and q_led:get() ~= 0) then return 'q'
	elseif (r_led and r_led:get() ~= 0) then return 'r'
	elseif (b_led and b_led:get() ~= 0) then return 'b'
	elseif (n_led and n_led:get() ~= 0) then return 'n'
	end
	return nil
end

function interface.get_promotion(x, y)
	local previous_read = nil
	
	-- Loop to check the flashing LEDs over a window, requiring two identical consecutive reads
	for i = 1, 10 do
		local current_read = interface.get_promotion_led()
		
		if current_read ~= nil then
			if previous_read == current_read then
				return current_read -- Double-verified stable reading found!
			end
			previous_read = current_read
		end
		emu.wait(0.1) -- Micro-delay to blend out multiplexing gaps
	end

	return nil
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.1", 0x10, 1)
	elseif (piece == "r") then send_input(":IN.1", 0x08, 1)
	elseif (piece == "b") then send_input(":IN.1", 0x04, 1)
	elseif (piece == "n") then send_input(":IN.1", 0x02, 1)
	elseif (piece == "Q" or piece == "R" or piece == "B" or piece == "N") then
		sb_press_square(":board", 1, x, y)
	end
end

return interface
