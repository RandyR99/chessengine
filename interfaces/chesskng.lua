interface = {}

interface.turn = true
interface.invert = false
interface.last_get = nil
interface.level = 1
interface.cur_level = nil
local mem = machine.devices[':maincpu'].spaces['program']
local ram = { read = function(self, a) return mem:read_u8(a) end }
local adr = 0x3000
local cnt = 0

-- RAM: 0x15 = screen state (8 language, 6 game menu, 9 busy, 0 waiting for a key),
-- 0x45 = 0/1 while the board is idle (cursor blink), 2 while a menu is open,
-- 0x1b0 = menu cursor
local function wait_ram(a, test, timeout)
	local t = 0
	while not test(ram:read(a)) and t < timeout do
		emu.wait(0.1)
		t = t + 0.1
	end
	return test(ram:read(a))
end

local function board_idle(v)
	return v <= 1
end

local function menu_cursor(item)
	for i=1,10 do
		if ram:read(0x1b0) == item then
			break
		elseif ram:read(0x1b0) < item then
			send_input(":BUTTONS", 0x40, 0.25) -- down
		else
			send_input(":BUTTONS", 0x10, 0.25) -- up
		end
		emu.wait(0.25)
	end
end

-- open the in-game menu and choose an item: 0 Play Level, 1 Play Order, 2 Restart Game, 3 Castling, 4 Play Hint
local function open_menu(item)
	wait_ram(0x45, board_idle, 10)
	for i=1,5 do
		send_input(":BUTTONS", 0x01, 0.25) -- SELECT
		if wait_ram(0x45, function(v) return v == 2 end, 1) then
			break
		end
	end
	menu_cursor(item)
	send_input(":BUTTONS", 0x04, 0.25) -- Confirm (a longer press also closes the dialog)
	emu.wait(0.5)
end

-- set the value of the open dialog (0x1b0) with right/left, then close the menu
local function dialog_value(value)
	for i=1,10 do
		if ram:read(0x1b0) == value then
			break
		elseif ram:read(0x1b0) < value then
			send_input(":BUTTONS", 0x20, 0.25) -- right
		else
			send_input(":BUTTONS", 0x80, 0.25) -- left
		end
		emu.wait(0.25)
	end
	send_input(":BUTTONS", 0x04, 0.25) -- Confirm
	emu.wait(0.5)
	send_input(":BUTTONS", 0x08, 0.25) -- Return
	wait_ram(0x45, board_idle, 5)
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	open_menu(0) -- Play Level
	dialog_value(interface.level)
end

function interface.setup_machine()
	interface.turn = true
	interface.invert = false
	interface.last_get = nil
	cnt = 0
	emu.wait(1.0)
	-- language screen (shown when no NVRAM is saved), retry until the game menu shows
	for i=1,10 do
		if ram:read(0x15) ~= 8 then
			break
		end
		send_input(":BUTTONS", 0x04, 0.25) -- Confirm English
		emu.wait(0.5)
	end
	wait_ram(0x15, function(v) return v == 6 end, 5)
	menu_cursor(1) -- Chess
	send_input(":BUTTONS", 0x04, 0.25) -- Confirm
	emu.wait(1)
	wait_ram(0x15, function(v) return v == 0 end, 15) -- intro ends on PUSH START
	-- START is ignored until PUSH START has been shown for a while
	for i=1,20 do
		send_input(":BUTTONS", 0x02, 0.5) -- START
		if wait_ram(0x45, board_idle, 1) then
			break
		end
	end

	interface.cur_level = 1
	interface.setlevel()
end

function interface.start_play(init)
	if init then
		interface.turn = false
		interface.invert = true
		cnt = 0
		open_menu(1) -- Play Order
		dialog_value(0) -- Last
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
			open_menu(3) -- Castling
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
