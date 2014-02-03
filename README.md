### Dependencies

* Awesome v3.5.2 (works with latest git version) - http://awesome.naquadah.org
* Radical menu system - https://github.com/Elv13/radical

### Installation

```bash
git clone https://github.com/mindeunix/notifications.git ~/.config/awesome/notifications
```
Now require it at the top of your rc.lua:
```lua
notifications = require("notifications")
```

And finally add the widget to wibox. For instance, if you want it to the right of the screen add it here : 
```lua
-- Widgets that are aligned to the right
local right_layout = wibox.layout.fixed.horizontal()
right_layout:add(notifications()) -- ADD THIS LINE HERE
if s == 1 then right_layout:add(wibox.widget.systray()) end
right_layout:add(mytextclock)
right_layout:add(mylayoutbox[s])
```

### Usage

[![Awesome WM - Notifications history widget](http://img.youtube.com/vi/OgRFhSH9apA/0.jpg)](http://www.youtube.com/watch?v=OgRFhSH9apA)
