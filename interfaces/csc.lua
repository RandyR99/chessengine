interface = {}

interface.level = "1"
interface.cur_level = nil
local turn  = 0
local check = 3

function interface.get_module()
	return "Fidelity Champion Sensory Chess Challenger"
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local lcd_lev = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x79, 0x71, 0x3d, 0x76 }
	local lcd_num = { 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67 }
	local level = interface.level
	local lev = "12345678EFGH"
	lev = lev:find(level:sub(1,1))
	
	local root = machine.devices[":"]
	local safety_counter = 0
	
	if (lev < 9 or lev > 10) then
		repeat
			send_input(":IN.3", 0x100, 0.6) -- LV
			emu.wait(0.1)
			
			-- MODERNIZED: Fetches outputs safely using proxy container variables
			local p0 = root:output("digit0")
			local d0_val = p0 and p0:get() or 0
			
			if d0_val == lcd_lev[lev] then
				break
			end
			
			safety_counter = safety_counter + 1
			if safety_counter > 30 then break end
		until false
	else
		repeat
			send_input(":IN.3", 0x100, 0.6) -- LV
			emu.wait(0.1)
			
			local p0 = root:output("digit0")
			local d0_val = p0 and p0:get() or 0
			
			if d0_val == lcd_lev[lev-1] then
				break
			end
			
			safety_counter = safety_counter + 1
			if safety_counter > 30 then break end
		until false
		
		send_input(":IN.3", 0x100, 0.6) -- LV
		level = level:sub(3)
		local d1,d2,d3
		for i=1,2 do
			if (lev == 9) then
				send_input(":IN.4", 0x100, 0.6) -- DM
				if (level:sub(1,2) ~= "00") then
					d1=lcd_num[tonumber(level:sub(1,1))+1]
					d2=lcd_num[tonumber(level:sub(2,2))+1]
					
					-- MODERNIZED: Updated un-sandboxed ioport setters to container fields
					machine.ioports[":IN.5"]:fields()["ST"]:set_value(1)
					
					local sub_safety = 0
					repeat
						emu.wait(0.05)
						local p1_node = root:output("digit1")
						local p0_node = root:output("digit0")
						local v1 = p1_node and p1_node:get() or 0
						local v0 = p0_node and p0_node:get() or 0
						
						if (v1 == d1 and v0 == d2) then break end
						sub_safety = sub_safety + 1
						if sub_safety > 50 then break end
					until false
				end
				machine.ioports[":IN.5"]:fields()["ST"]:set_value(0)
				emu.wait(0.5)
				level = level:sub(4)
			end
			send_input(":IN.2", 0x100, 0.6) -- TM
			if (level:sub(1,4) ~= "0:00") then
				d1=lcd_num[tonumber(level:sub(1,1))+1]
				d2=lcd_num[tonumber(level:sub(3,3))+1]
				d3=lcd_num[tonumber(level:sub(4,4))+1]
				
				machine.ioports[":IN.5"]:fields()["ST"]:set_value(1)
				local tm_safety = 0
				repeat
					emu.wait(0.05)
					local p2_node = root:output("digit2")
					local p1_node = root:output("digit1")
					local p0_node = root:output("digit0")
					local v2 = p2_node and p2_node:get() or 0
					local v1 = p1_node and p1_node:get() or 0
					local v0 = p0_node and p0_node:get() or 0
					
					if (v2 == d1 and v1 == d2 and v0 == d3) then break end
					tm_safety = tm_safety + 1
					if tm_safety > 50 then break end
				until false
			end
			machine.ioports[":IN.5"]:fields()["ST"]:set_value(0)
			emu.wait(0.5)
			level = level:sub(6)
		end
		send_input(":IN.2", 0x100, 0.6) -- TM
	end
	send_input(":IN.2", 0x100, 0.6) -- TM
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(5)
	send_input(":IN.8", 0x40, 1) -- CL
	emu.wait(1.0)

	interface.cur_level = "1"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x100, 0.6) -- SPK
		send_input(":IN.0", 0x100, 0.6) -- SPK
		send_input(":IN.1", 0x100, 0.6) -- RV	-- Voice off
		send_input(":IN.2", 0x100, 0.6) -- TM
		return (":board")
	else
		local key=0x00
		for n=1,6 do
			if     n==1 then key=0x20 -- K
			elseif n==2 then key=0x10 -- Q
			elseif n==3 then key=0x02 -- R
			elseif n==4 then key=0x08 -- B
			elseif n==5 then key=0x04 -- N
			elseif n==6 then key=0x01 -- P
			end
			send_input(":IN.8", key, 0.6)
			send_input(":IN.8", key, 0.6)
			for y=1,8 do
				for x=1,8 do
					if get_piece_id(x,y)==n then
						sb_press_square(":board", 0.6, x, y)
					end
				end
			end
			send_input(":IN.8", key, 0.6)
			for y=1,8 do
				for x=1,8 do
					if get_piece_id(x,y)==-n then
						sb_press_square(":board", 0.6, x, y)
					end
				end
			end
			send_input(":IN.8", key, 0.6)
		end
		if mode==-1 then
			send_input(":IN.8", 0x40, 0.6)  -- CL
			send_input(":IN.1", 0x100, 0.6) -- RV
		end
		send_input(":IN.0", 0x100, 0.6) -- SPK
		send_input(":IN.0", 0x100, 0.6) -- SPK
		send_input(":IN.1", 0x100, 0.6) -- RV	-- Voice on
		send_input(":IN.2", 0x100, 0.6) -- TM
	end
end

function interface.edit_game(on)
    local throttled_state = machine.video.throttled
    if on then
        send_input(":IN.0", 0x100, 0.6) -- SPK
        send_input(":IN.0", 0x100, 0.6) -- SPK
        send_input(":IN.1", 0x100, 0.6) -- RV    -- Voice off
        send_input(":IN.3", 0x100, 0.6) -- LV
        send_input(":IN.3", 0x100, 0.6) -- LV
        send_input(":IN.3", 0x100, 0.6) -- LV
        send_input(":IN.2", 0x100, 0.6) -- TM
    else
        machine.video.throttled = false
        send_input(":IN.8", 0x01, 0.6)  -- P
        send_input(":IN.8", 0x01, 0.6)  -- P
        send_input(":IN.8", 0x01, 0.6)  -- P
        send_input(":IN.8", 0x01, 0.6)  -- P
        send_input(":IN.0", 0x100, 0.6) -- SPK
        send_input(":IN.0", 0x100, 0.6) -- SPK
        send_input(":IN.1", 0x100, 0.6) -- RV    -- Voice on
        send_input(":IN.2", 0x100, 0.6) -- TM
        machine.video.throttled = throttled_state
    end
    emu.wait(0.5)
end

function interface.start_play(init)
    if (check==1) then
        check=3
    else
        check=1
    end
	send_input(":IN.4", 0x100, 1) -- DM
	send_input(":IN.1", 0x100, 1) -- RV
end

function interface.stop_play()
	send_input(":IN.5", 0x100, 1) -- ST
end

function interface.is_selected(x, y)
	local root = machine.devices[":"]
	local led_node = root:output(tostring(x - 1) .. "." .. tostring(y - 1 + 8))
	local led_val = led_node and led_node:get() or 0
	return led_val ~= 0
end

function interface.select_piece(x, y, event)
    if (event ~= "capture") then
        if (event ~= "en_passant" and event ~= "get_castling" and event ~= "put_castling") then
            turn = turn + 1
             if turn > 3 then
                turn = 0
             end
             if turn == check then
                emu.wait(4)
             end
        end
    end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return { { "string", "Level", "1"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:upper():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:match("^[1-8GH]$")
		or  level:match("^E%s%d%d/%d:[0-5]%d%s%d%d/%d:[0-5]%d$")
		or  level:match("^F%s%d:[0-5]%d%s%d:[0-5]%d$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.test_promotion(x, y)
	local function piece_led(port, code, x, y)
		send_input(port, code, 0.6)
		local root_dev = machine.devices[":"]
		for i=1,5 do
			local check_node = root_dev:output(tostring(x - 1) .. "." .. tostring(y - 1 + 8))
			local check_val = check_node and check_node:get() or 0
			if (check_val ~= 0) then
				return true
			end
			emu.wait(0.1)
		end
		return false
	end

	local p
	send_input(":IN.0", 0x100, 0.6) -- SPK
	send_input(":IN.0", 0x100, 0.6) -- SPK
	send_input(":IN.1", 0x100, 0.6) -- RV (Voice off)
	send_input(":IN.2", 0x100, 0.6) -- TM

	if     piece_led(":IN.8", 0x10, x, y) then p = "Q"
	elseif piece_led(":IN.8", 0x04, x, y) then p = "N"
	elseif piece_led(":IN.8", 0x08, x, y) then p = "B"
	elseif piece_led(":IN.8", 0x02, x, y) then p = "R"
	else p = "Q"
	end

	send_input(":IN.8", 0x40,  0.6) -- CL
	send_input(":IN.0", 0x100, 0.6) -- SPK
	send_input(":IN.0", 0x100, 0.6) -- SPK
	send_input(":IN.1", 0x100, 0.6) -- RV (Voice on)
	send_input(":IN.2", 0x100, 0.6) -- TM
	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	emu.wait(1.0)
	if     (piece == "q") then	send_input(":IN.8", 0x10, 1)
	elseif (piece == "r") then	send_input(":IN.8", 0x02, 1)
	elseif (piece == "b") then	send_input(":IN.8", 0x08, 1)
	elseif (piece == "n") then	send_input(":IN.8", 0x04, 1)
	end
end

return interface

