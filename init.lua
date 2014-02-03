local wibox      = require("wibox")
local beautiful  = require("beautiful")
local radical    = require("radical")
local awful      = require("awful")
local naughty    = require("naughty")
local cairo      = require("lgi").cairo
local color      = require("gears.color")
local pango      = require("lgi").Pango
local pangocairo = require("lgi").PangoCairo

local module = {}
module.items_limit = 10
module.items_max_characters = 80

module.items = {}
module.widget = nil
module.count = 0
module.padding = 3

-- Format notifications
local function update_notifications(data)
    local text,icon,time,count = data.text or "N/A", data.icon or beautiful.unknown, os.date("%H:%M:%S"), 1
    if data.title and data.title ~= "" then text = "<b>"..data.title.."</b> - "..text end
    local text = string.sub(text, 0, module.items_max_characters)
    for k,v in ipairs(module.items) do if text == v.text then count = v.count + 1 end end
    
    if data.preset and data.preset.bg then
        -- TODO: presets
    end
    
    if count == 1 then
        table.insert(module.items, {text=text,icon=icon,count=count,bg=bg,time=time})
        module.count = module.count + 1
    end
end

-- Reset notifications count/widget
function module.reset()
    module.items={}
    module.count = 0 -- Reset count
    module.widget:emit_signal("widget::updated") -- update widget
    if module.menu and module.menu.visible then
        module.menu.visible = false
    end
end

local function getX(i)
    local a = screen[1].geometry.height - beautiful.default_height or 16
    if i > module.items_limit then
        return a - (module.items_limit * beautiful.menu_height) - 40 -- 20 per scrollbar.
    else
        return a- i * beautiful.menu_height
    end
end
function module.main()
    if module.menu and module.menu.visible then module.menu.visible = false return end
    if module.items and #module.items > 0 then
        module.menu = radical.context({filer = false, enable_keyboard = false, direction = "bottom",
            style = radical.style.classic, item_style = radical.item_style.classic,
            max_items = module.items_limit, x = screen[1].geometry.width, y = getX(#module.items)
        })
        for k,v in ipairs(module.items) do
            module.menu:add_item({
                button1 = function()
                    table.remove(module.items, k)
                    module.count = module.count - 1
                    module.widget:emit_signal("widget::updated") -- Update widget
                    module.menu.visible = false
                    module.main() -- display the menu again
                end,
                text=v.text, icon=v.icon, underlay = v.count, tooltip = v.time
            })
        end
        module.menu.visible = true
    end
end

-- Callback used to modify notifications
naughty.config.notify_callback = function(data)
    module.widget:emit_signal("widget::updated")
    update_notifications(data)
    return data
end

local pl = nil
local function init_pl(height)
    if not pl and height > 0 then
        local pango_crx = pangocairo.font_map_get_default():create_context()
        pl = pango.Layout.new(pango_crx)
        local desc = pango.FontDescription()
        desc:set_family("Verdana")
        desc:set_weight(pango.Weight.ULTRABOLD)
        desc:set_size((height-2-module.padding*2) * pango.SCALE)
        pl:set_font_description(desc)
    end
end
local function fit(self,w,height)
    init_pl(height)
    if pl and module.count > 0 then
        pl.markup = "<b>"..module.count.."</b>"
        local text_ext = pl:get_pixel_extents()
        return 3*(height/4)+3*module.padding+(text_ext.width or 0),height
    end
    return 0,height
end
local function draw(self, w, cr, width, height)
    local tri_width = 3*(height/4)
    cr:set_source(color("#00000000"))
    cr:paint()
    cr:set_source(color(beautiful.widget.fg))
    cr:move_to(module.padding + tri_width/2,module.padding)
    cr:line_to(module.padding+tri_width,height-module.padding)
    cr:line_to(module.padding,height-module.padding)
    cr:line_to(module.padding + tri_width/2,module.padding)
    cr:close_path()
    cr:set_line_width(4)
    cr:set_line_join(1)
    cr:set_antialias(cairo.ANTIALIAS_SUBPIXEL)
    cr:stroke_preserve()
    cr:fill()
    cr:set_source(color("#000000"))
    pl.text = "!"
    local text_ext = pl:get_pixel_extents()
    cr:move_to(module.padding + tri_width/2-text_ext.width/2 - height/16,module.padding-text_ext.height/4+1)
    cr:show_layout(pl)

    pl:set_font_description(beautiful.get_font(font))
    pl.markup = "<b>"..module.count.."</b>"
    cr:move_to(tri_width+2*module.padding,module.padding-text_ext.height/4+1)--,-text_ext.height/2)
    cr:set_source(color(beautiful.widget.fg))
    cr:show_layout(pl)
end

-- Return widget
local function new()
    module.widget = wibox.widget.base.make_widget()
    module.widget.draw = draw
    module.widget.fit = fit
    module.widget:set_tooltip("Notifications")
    module.widget:buttons(awful.util.table.join(awful.button({ }, 1, module.main), awful.button({ }, 3, module.reset)))
    return module.widget
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })