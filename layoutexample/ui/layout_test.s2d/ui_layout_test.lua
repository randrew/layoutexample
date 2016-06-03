require 'layout'

local Actor = scaleform.Actor
local Component = scaleform.Component
local ContainerComponent = scaleform.ContainerComponent

local VisBox = {}

function VisBox.create()
    local act = Actor.load("borderbox.s2dactor")
    local image_actor = Actor.actor_by_name_path(act, "bg")
    return {
        actor=act,
        image_actor = image_actor,
        container = Actor.container(image_actor),
        children = {}
    }
end
function VisBox.set_size(vb, w, h)
    local size = scaleform.Size()
    size.width = w
    size.height = h
    Actor.set_dimensions(vb.image_actor, size)
end
function VisBox.set_local_position(vb, x, y)
    local p = scaleform.Point()
    p.x = x
    p.y = y
    Actor.set_local_position(vb.actor, p)
end
function VisBox.insert(parent, child)
	ContainerComponent.add_actor(parent.container, child.actor)
    parent.children[child] = true
end
function VisBox.set_world_rect(vb, x, y, w, h)
    local p = scaleform.Point()
    p.x = x
    p.y = y
    Actor.set_local_position(vb.actor, p)
    local size = scaleform.Size()
    size.width = w
    size.height = h
    Actor.set_dimensions(vb.image_actor, size)
end
function VisBox.set_rect_by_item(vb, ctx, item_id)
    local p = scaleform.Point()
    local size = scaleform.Size()
    p.x, p.y, size.width, size.height = Layout.rect(ctx, item_id)
    Actor.set_local_position(vb.actor, p)
    Actor.set_dimensions(vb.image_actor, size)
end
function VisBox.destroy(vb)
    local parent = Actor.parent(vb.actor)
    if parent then
        local container = Actor.container(parent)
        if container then
            ContainerComponent.remove_actor(container, vb.actor)
        end
    end
end

-- Layout context
local ctx = nil
-- Root layout item ID
local root_id = -1
-- 'Master list view' item ID. We need to store this across frames in order to
-- animate its size.
local masterbox_id = -1
-- Animated item inside the master list view box.
local resizable_master_item = -1
-- This table will store a mapping from Layout ID to 'VisBox' item (which
-- contains a Scaleform actor).
local id_to_visbox = {}
-- Accumulated total time the UI has been running. Used for animation
-- calculations.
local total_time = 0.0

GlobalUI = GlobalUI or {}

function GlobalUI.start()
	local this_actor = scaleform.Stage.actor_by_name_path("LayoutScene")
    local child_container = Actor.container(this_actor)

    -- Create a new Layout context.
    ctx = Layout.new()
    -- And create the root item of the item tree.
    root_id = Layout.item(ctx)

    -- Helper function to create a new Scaleform actor and Layout item, and
    -- associate them together.
    function make_box()
        local vb = VisBox.create()
        local id = Layout.item(ctx)
        id_to_visbox[id] = vb
        ContainerComponent.add_actor(child_container, vb.actor)
        return id
    end

    -- Layout items that are used for positioning/sizing but aren't visible as
    -- an actual Scaleform actor can be created directly with Layout.item().
    --
    -- This 'maincolumn' item will contain the fake master-detail view at the
    -- top, and some kind of fake timeline bar thing at the bottom.
    local maincolumn = Layout.item(ctx)
    -- Margins create extra space around an item.
    Layout.set_margins(ctx, maincolumn, 4, 4, 4, 4)
    -- Set how an item acts as a container. Layout.COLUMN means the item will
    -- arrange its children vertically as a list.
    Layout.set_contain(ctx, maincolumn, Layout.COLUMN)
    -- Set how an item behaves inside of its parent. Layout.FILL means it wants
    -- to take up any free space that exists within the parent.
    Layout.set_behave(ctx, maincolumn, Layout.FILL)
    -- Insert maincolumn into root_id. An item can't be inserted more than
    -- once, and it can't be removed from its parent. If you need to remove an
    -- item from its existing parent and put it into a different item, just
    -- rebuild the entire layout. (Don't worry, it's fast).
    Layout.insert(ctx, root_id, maincolumn)

    -- The lrsplit item will act as a row which contains the 'master list' on
    -- the left, a splitter handle, and then the 'content view' on the right.
    local lrsplit = Layout.item(ctx)
    Layout.set_behave(ctx, lrsplit, Layout.FILL)
    Layout.set_contain(ctx, lrsplit, Layout.ROW)
    Layout.insert(ctx, maincolumn, lrsplit)

    -- We can also use the colon calling syntax, if we want. I'll freely mix
    -- using either, to show that it works.
    --
    -- It doesn't matter which you use, though if you want to save a bit of
    -- time spent on name lookup, you can create local bindings of the Layout
    -- functions. I'm not going to do that here, but you can see examples of
    -- doing that in Stingray library and example code.
    local leftarea = ctx:item()
    ctx:set_contain(leftarea, Layout.COLUMN, Layout.START)
    ctx:set_behave(leftarea, Layout.VFILL)
    ctx:insert(lrsplit, leftarea)

    masterbox_id = make_box()
    Layout.insert(ctx, leftarea, masterbox_id)
    Layout.set_contain(ctx, masterbox_id, Layout.COLUMN)
    Layout.set_behave(ctx, masterbox_id, Layout.LEFT)

    local belowmasterlist = make_box()
    ctx:insert(leftarea, belowmasterlist)
    ctx:set_behave(belowmasterlist, Layout.RIGHT)
    ctx:set_margins(belowmasterlist, 0, 4, 0, 0)
    ctx:set_size(belowmasterlist, 80, 40)

    local splitbar = make_box()
    ctx:set_size(splitbar, 3, 10)
    ctx:set_margins(splitbar, 2, 0, 2, 0)
    ctx:insert(lrsplit, splitbar)

    local rightcolumn = ctx:item()
    ctx:set_contain(rightcolumn, Layout.COLUMN)
    ctx:set_behave(rightcolumn, Layout.FILL)
    ctx:insert(lrsplit, rightcolumn)

    local righttitle = make_box()
    ctx:set_contain(righttitle, Layout.ROW)
    ctx:set_behave(righttitle, Layout.HFILL)
    ctx:set_size(righttitle, 0, 50)
    ctx:set_margins(righttitle, 0, 0, 0, 4)
    ctx:insert(rightcolumn, righttitle)

    local righttitle_content = make_box()
    ctx:set_size(righttitle_content, 120, 36)
    ctx:set_margins(righttitle_content, 0, 0, 20, 0)
    ctx:insert(righttitle, righttitle_content)

    local rightarea = make_box()
    ctx:set_contain(rightarea, Layout.ROW, Layout.WRAP, Layout.START)
    ctx:set_behave(rightarea, Layout.FILL)
    ctx:insert(rightcolumn, rightarea)

    local botbar = make_box()
    ctx:set_contain(botbar, Layout.ROW, Layout.MIDDLE)
    ctx:set_margins(botbar, 0, 4, 0, 0)
    ctx:set_behave(botbar, Layout.HFILL)
    ctx:set_size(botbar, 0, 40)
    ctx:insert(maincolumn, botbar)

    for i=0,9 do
        local id = make_box()
        Layout.set_behave(ctx, id, Layout.HFILL)
        Layout.set_size(ctx, id, 0, 30 + math.floor((i % 3) / 2) * 20)
        Layout.set_margins(ctx, id, 5, 5, 5, 5)
        Layout.insert(ctx, masterbox_id, id)
        -- The fourth item in the list is the one we will animate
        if i == 3 then
            resizable_master_item = id
        end
    end

    for i=1,10 do
        local id = make_box()
        ctx:set_margins(id, 4, 4, 0, 4)
        ctx:insert(botbar, id)
        ctx:set_behave(id, Layout.VFILL)
        ctx:set_size(id, 18 + (i % 3) * 12, 0)
    end

    for i=1,100 do
        local id = make_box()
        ctx:set_margins(id, 4, 4, 4, 4)
        local x = 20 + math.floor((i % 10) * 10)
        ctx:set_size(id, x, 60)
        ctx:insert(rightarea, id)
    end

    -- Now that we've created all of our items, we need to run the layout and
    -- set the rectangles on the Scaleform actors. We're doing an animated
    -- interface, and we will need to do this each frame. Therefore, we've
    -- split that stuff out into a separate procedure. We'll go ahead and call
    -- it now, so that we have valid positioning for the first frame that our
    -- UI is shown, and then we'll continue to call it once per frame after
    -- that.
    update_ui()
end

function update_ui()
    -- If we wanted to support changing the point size of the canvas/layout, we
    -- could set it here. We have set our Scaleform stage to always be 1280x720
    -- points, though, so we'll just set it to that.
    Layout.set_size(ctx, root_id, 1280, 720)
    -- The 'master view' list on the left has an animated width
    Layout.set_size(ctx, masterbox_id, 200 + 100 * math.sin(total_time), 0)
    -- One of the items in the 'mast view' on the left has an animated height.
    Layout.set_size(ctx, resizable_master_item, 0, 60 + math.sin(total_time * 1.3) * 50)
    -- Run the layout, which recalculates the rectangles of all of the items
    -- based on the inputs we have given it.
    Layout.run(ctx)
    -- Now that the rectangles in the layout context are valid, we iterate
    -- through our items and set the Scaleform actor positions and sizes.
    for id,vb in pairs(id_to_visbox) do
        VisBox.set_rect_by_item(vb, ctx, id)
    end
end

function GlobalUI.update(dt)
    -- Update the accmulated time
    total_time = total_time + dt
    -- Recalculate rectangles and set Scaleform actor positions/sizes.
	update_ui()
end

function GlobalUI.shutdown()
    for id,vb in pairs(id_to_visbox) do
        VisBox.destroy(vb)
    end

    id_to_visbox = {}
    rood_id = nil
    masterbox_id = -1
    resizable_master_item = -1
    ctx = nil
    total_time = 0.0
end
