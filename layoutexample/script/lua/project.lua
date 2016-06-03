-- Because there does not seem to be any way to have a dir automatically added
-- to the Lua packages cpath, and there also does not seem to be a way to get
-- the current project directory, it must be specified here manually.
-- Otherwise, doing "require 'layout'" will fail, because the .dll will not be
-- in search path.
--
-- Edit the projectdir string to be the absolute path of this Stingray project
-- on disk.
local projectdir = 'C:\\Users\\myname\\Documents\\Stingray\\layoutexample\\'

Project = Project or {}

require 'script/lua/flow_callbacks'

local modulespath = projectdir .. 'layoutexample\\modules\\?.dll'
package.cpath = package.cpath .. ';' .. modulespath

Project.level_names = {
	empty = "content/levels/empty"
}

-- Can provide a config for the basic project, or it will use a default if not.
local SimpleProject = require 'core/appkit/lua/simple_project'
SimpleProject.config = {
	standalone_init_level_name = Project.level_names.empty,
	camera_unit = "core/appkit/units/camera/camera",
	camera_index = 1,
	shading_environment = nil, -- Will override levels that have env set in editor.
	create_free_cam_player = false, -- Project will provide its own player.
	exit_standalone_with_esc_key = true
}


-- Optional function by SimpleProject after level, world and player is loaded 
-- but before lua trigger level loaded node is activated.
function Project.on_level_load_pre_flow()
	if not Project.ui_started then

		if scaleform then
			scaleform.Stingray.load_project_and_scene("ui/layout_test.s2d/layout_test")
		end

		if GlobalUI then
			GlobalUI.start()
		end

		Project.ui_started = true
	end
end

-- Optional function by SimpleProject after loading of level, world and player and 
-- triggering of the level loaded flow node.
function Project.on_level_shutdown_post_flow()
end

-- Optional function called by SimpleProject after world update (we will probably want to split to pre/post appkit calls)
function Project.update(dt)
	-- I don't want to do this in update() every frame, but not sure where to
	-- put it to make it work correctly.
	if stingray.Window then
		stingray.Window.set_clip_cursor(false)
		stingray.Window.set_show_cursor(true)
	end

	if GlobalUI then
		GlobalUI.update(dt)
	end
end

-- Optional function called by SimpleProject *before* appkit/world render
function Project.render()
end

-- Optional function called by SimpleProject *before* appkit/level/player/world shutdown
function Project.shutdown()
	if Project.ui_started then
		if GlobalUI then
			GlobalUI.shutdown()
		end
		Project.ui_started = nil
	end
end

return Project
