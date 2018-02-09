
local function round(x, bias_up)
	if bias_up then
		return math.floor(x + 0.5)
	else
		return math.ceil(x - 0.5)
	end
end

local function sign(x)
	if x > 0 then
		return 1
	elseif x < 0 then
		return -1
	else
		return 0
	end
end

local function progressor_negative(x)
	return round(x, false) - 0.5
end

local function progressor_positive(x)
	return round(x, true) + 0.5
end

local function progressor(x)
	if x > 0 then
		return progressor_positive
	else
		return progressor_negative
	end
end

local function lowest(x, y, z)
	if x < y then
		if x < z then
			return 1
		else
			return 3
		end
	elseif y < z then
		return 2
	else
		return 3
	end
end

-- Makes an iterator that returns t and node position
function arcana.line_iterator(origin, direction, distance)
	local dir = vector.normalize(direction)
	
	local t_per_x = 1 / dir.x
	local t_per_y = 1 / dir.y
	local t_per_z = 1 / dir.z

	local t_per_x_step = math.abs(t_per_x)
	local t_per_y_step = math.abs(t_per_y)
	local t_per_z_step = math.abs(t_per_z)

	local x_step = sign(dir.x)
	local y_step = sign(dir.y)
	local z_step = sign(dir.z)

	
	local x_prog = progressor(dir.x)
	local y_prog = progressor(dir.y)
	local z_prog = progressor(dir.z)

	local t_to_next_x = t_per_x * (x_prog(origin.x) - origin.x)
	local t_to_next_y = t_per_y * (y_prog(origin.y) - origin.y)
	local t_to_next_z = t_per_z * (z_prog(origin.z) - origin.z)

	assert(t_to_next_x >= 0)
	assert(t_to_next_y >= 0)
	assert(t_to_next_z >= 0)

	local x = round(origin.x)
	local y = round(origin.y)
	local z = round(origin.z)
	local t = 0

	local first = true

	return function()
		if first then
			first = false
			return t, { x = x, y = y, z = z }
		end
		
		local l = lowest(t_to_next_x, t_to_next_y, t_to_next_z)
		if l == 1 then
			local dt = t_to_next_x
			
			t = t + dt
			x = x + x_step

			t_to_next_x = t_per_x_step
			t_to_next_y = t_to_next_y - dt
			t_to_next_z = t_to_next_z - dt
		elseif l == 2 then
			local dt = t_to_next_y
			
			t = t + dt
			y = y + y_step

			t_to_next_x = t_to_next_x - dt
			t_to_next_y = t_per_y_step
			t_to_next_z = t_to_next_z - dt
		else
			local dt = t_to_next_z
			
			t = t + dt
			z = z + z_step

			t_to_next_x = t_to_next_x - dt
			t_to_next_y = t_to_next_y - dt
			t_to_next_z = t_per_z_step
		end

		if (t > distance) then
			return nil
		else
			return t, { x = x, y = y, z = z }
		end
	end
end
