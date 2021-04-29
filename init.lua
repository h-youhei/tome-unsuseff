-- tome-target-myself/init.lua
-- For ToME version 1.7.2

long_name = "Cancel Sustain/Effect on Rest"
short_name = "unsuseff" -- Determines the name of your addon's file.
for_module = "tome"
version = {1,7,2}
addon_version = {0,0,1}
weight = 100 -- The lower this value, the sooner your addon will load compared to other addons.
author = {'hukumitu.youhei@gmail.com'}
homepage = 'https://hkmtyh.com'
description = [[You can cancel Sustains and Beneficial effects on Rest.

Sustains can be marked to be canceled by right-click talent icons on the talent bar.

Beneficial effects can be marked to be canceled in dialog. (default: Ctrl+Alt+E).

This addon driven by canceling it many times;
- resource-consuming sustains like Never Stop Running
- rest-preventing beneficial effects like Spatial Tether

Github: https://github.com/h-youhei/tome-unsuseff

Weight: 100

SuperLoad:
- mod/class/Player.lua:getTarget()

Special Thanks:
Restart Sustains]] -- the [[ ]] things are like quote marks that can span multiple lines
tags = {'sustain', 'effect', 'cancel'} -- tags MUST immediately follow description

overload = true
superload = true
data = true
hooks = true
