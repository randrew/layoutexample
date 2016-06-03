local Keyboard = stingray.Keyboard
local Quaternion = stingray.Quaternion
local Vector3 = stingray.Vector3

local Utils = {}

function Utils.keyboard_value(s)
	return Keyboard.button(Keyboard.button_id(s))
end
function Utils.is_key_down(s)
	return Utils.keyboard_value(s) ~= 0
end
function Utils.axis_keys(s1, s2)
	local ret = 0
	if Utils.is_key_down(s1) then ret = ret + 1 end
	if Utils.is_key_down(s2) then ret = ret - 1 end
	return ret
end
function Utils.was_key_pressed(s)
	return Keyboard.pressed(Keyboard.button_id(s))
end
function Utils.was_mouse_clicked(button)
	return stingray.Mouse.pressed(stingray.Mouse.button_id(button))
end

-- no idea the least inefficient way to handle passing the special math types in stingray

function Utils.spring_damper_vector3(current_val, current_vel, target_val, damping, strength, dt)
	local new_vel = current_vel + (target_val - current_val) * strength * dt
	new_vel = new_vel * math.pow(damping, dt)
	local new_val = current_val + new_vel * dt
	return new_val, new_vel
end

function Utils.lerp(a, b, alpha)
	return a + (b - a) * alpha
end

function Utils.clamp(x, min, max)
	return math.min(max, math.max(x, min))
end

-- obviously crap
function Utils.clamp_axis(angle)
	local wrapped = math.fmod(angle, 360.0)
	if wrapped < 0 then wrapped = wrapped + 360.0 end
	return wrapped
end

-- same as above
function Utils.normalize_axis(angle)
	local clamped = Utils.clamp_axis(angle)
	if clamped > 180.0 then clamped = clamped - 360.0 end
	return clamped
end

-- get the axis angles to -180..180 range
function Utils.normalized_rotator(rotator)
	return Vector3(Utils.normalize_axis(rotator.x), Utils.normalize_axis(rotator.y), Utils.normalize_axis(rotator.z))
end

function Utils.quat_to_rot(quat)
	local x, y, z = Quaternion.to_euler_angles_xyz(quat)
	return Vector3(Utils.normalize_axis(x), Utils.normalize_axis(y), Utils.normalize_axis(z))
end

function Utils.spring_damper_rotation(current_val, current_vel, target_val, damping, strength, dt)
	local current_val_rot = Utils.quat_to_rot(current_val)
	local difference = Utils.quat_to_rot(target_val) - current_val_rot
	difference = Utils.normalized_rotator(difference)
	local new_value, new_velocity
	-- no well-defined epsilon exists? oh well
	if Vector3.length(current_vel) < 0.00001 and Vector3.length(difference) < 0.00001 then
		new_velocity = Vector3.zero()
		new_value = target_val
	else
		new_velocity = (current_vel + difference * strength * dt) * math.pow(damping, dt)
		local new_rot_val = current_val_rot + new_velocity * dt
		new_value = Quaternion.from_euler_angles_xyz(new_rot_val.x, new_rot_val.y, new_rot_val.z)
	end
	return new_value, new_velocity
end

function Utils.lan_lobby_state_string(net_lobby)
	local state_str = "???"
	local state_int = stingray.LanLobby.state(net_lobby)
	if state_int == stingray.LanLobby.CREATING then
		state_str = "Creating"
	elseif state_int == stingray.LanLobby.FAILED then
		state_str = "Failed"
	elseif state_int == stingray.LanLobby.JOINED then
		state_str = "Joined"
	elseif state_int == stingray.LanLobby.JOINING then
		state_str = "Joining"
	end
	return state_str
end

function Utils.steam_server_state_string(steam_server)
	local state_int = stingray.SteamGameServer.state(steam_server)
	local state_str = "???"
	if state_int == stingray.SteamGameServer.CONNECTED then
		state_str = "Connected"
	elseif state_int == stingray.SteamGameServer.CONNECTING then
		state_str = "Connecting"
	elseif state_int == stingray.SteamGameServer.DISCONNECTED then
		state_str = "Disconnected"
	end
	return state_str
end

function Utils.weighted_average(current_value, target_value, fraction, dt)
	if math.abs(current_value - target_value) < 0.00000001 then return target_value end
	local weight = math.pow(fraction, dt)
	return weight * current_value + (1.0 - weight) * target_value
end

function Utils.weak_ref(x)
	local ref = {}
	ref.__mode = "v"
	ref.value = x
	return function() return ref.value end
end

function Utils.sign(x)
	if x < 0 then return -1
	elseif x > 0 then return 1
	else return 0
	end
end

return Utils