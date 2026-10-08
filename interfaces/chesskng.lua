interface = {}

interface.turn = true
interface.invert = false
interface.last_get = nil
interface.level = 1
interface.cur_level = nil
local ram = emu.item(machine.devices[':maincpu'].items['0/:mainram'])
local adr = 0x3000
local cnt = 0

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local dl = interface.level - interface.cur_level
	interface.cur_level = interface.level
	send_input(":BUTTONS", 0x01, 0.25) -- SELECT
	send_input(":BUTTONS", 0x02, 0.25) -- START
	send_input(":BUTTONS", 0x04, 0.25) -- Confirm
	for i=1,math.abs(dl) do
		if dl>0 then
			send_input(":BUTTONS", 0x20, 0.25) -- right
		else
			send_input(":BUTTONS", 0x80, 0.25) -- left
		end
	end
	send_input(":BUTTONS", 0x04, 0.5) -- Confirm
	send_input(":BUTTONS", 0x08, 0.5) -- Return
end

function interface.setup_machine()
	interface.turn = true
	interface.invert = false
	interface.last_get = nil
	cnt = 0
	emu.wait(1.0)
	send_input(":BUTTONS", 0x04, 0.5) -- Confirm
	emu.wait(10)
	send_input(":BUTTONS", 0x02, 0.5) -- START

	interface.cur_level = 1
	interface.setlevel()
end

function interface.start_play(init)
	if init then
		interface.turn = false
		interface.invert = true
		cnt = 0
		send_input(":BUTTONS", 0x01, 0.25) -- SELECT
		send_input(":BUTTONS", 0x02, 0.25) -- START
		send_input(":BUTTONS", 0x40, 0.25) -- down
		send_input(":BUTTONS", 0x04, 0.25) -- Confirm
		send_input(":BUTTONS", 0x80, 0.25) -- left
		send_input(":BUTTONS", 0x04, 0.5) -- Confirm
		send_input(":BUTTONS", 0x08, 0.5) -- Return
	end
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	if ram:read(adr+0xc6)==cnt then
		return
	end
	local x1=ram:read(adr+0x0a)+1
	local y1=ram:read(adr+0x0c)+1
	local x2=ram:read(adr+0x18)+1
	local y2=ram:read(adr+0x1a)+1
	if (interface.invert) then
		x = 9 - x
		y = 9 - y
	end
	return (x==x1 and y==y1) or (x==x2 and y==y2)
end

function makemove(x, y)
	if (interface.invert) then
		x = 9 - x
		y = 9 - y
	end
	local x0=ram:read(adr+0x2e)+1
	local y0=ram:read(adr+0x30)+1
	while x~=x0 do
		if x<x0 then
			send_input(":BUTTONS", 0x80, 0.25) -- left
		else
			send_input(":BUTTONS", 0x20, 0.25) -- right
		end
		x0=ram:read(adr+0x2e)+1
	end
	while y~=y0 do
		if y<y0 then
			send_input(":BUTTONS", 0x40, 0.25) -- down
		else
			send_input(":BUTTONS", 0x10, 0.25) -- up
		end
		y0=ram:read(adr+0x30)+1
	end
	send_input(":BUTTONS", 0x04, 0.5) -- Confirm

end

function interface.select_piece(x, y, event)
	if (event == "get" and interface.turn) then
		interface.last_get = {x=x, y=y}
	elseif (event == "put" and interface.turn) then
		local move_type = get_move_type(interface.last_get.x, interface.last_get.y, x, y)
		if (move_type == "castling") then
			send_input(":BUTTONS", 0x01, 0.25) -- SELECT
			send_input(":BUTTONS", 0x02, 0.25) -- START
			send_input(":BUTTONS", 0x40, 0.25) -- down
			send_input(":BUTTONS", 0x40, 0.25) -- down
			send_input(":BUTTONS", 0x40, 0.25) -- down
			send_input(":BUTTONS", 0x04, 0.25) -- Confirm
			if x==3 then
				send_input(":BUTTONS", 0x40, 0.25) -- down
			end
			send_input(":BUTTONS", 0x04, 0.5) -- Confirm
			send_input(":BUTTONS", 0x08, 0.5) -- Return
		else
			makemove(interface.last_get.x, interface.last_get.y)
			makemove(x, y)
		end
		cnt = ram:read(adr+0xc6)
		interface.last_get = nil
	end
	if event=="put" then
		interface.turn = not interface.turn
	end
end

function interface.get_options()
	return { { "spin", "Level", "1", "1", "3"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 3) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	if ram:read(adr+0xc6)~=cnt then
		return
	end
	promotion_error(piece)
	emu.wait(1)
	send_input(":BUTTONS", 0x04, 0.5) -- Confirm
end

return interface
