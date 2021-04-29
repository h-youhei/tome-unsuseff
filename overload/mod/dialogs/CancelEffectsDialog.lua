require 'engine.class'
local Entity = require 'engine.Entity'
local Dialog = require 'engine.ui.Dialog'
local Button = require 'engine.ui.Button'
-- local TreeList = require 'engine.ui.TreeList'
local ListColumns = require 'engine.ui.ListColumns'
local Textzone = require 'engine.ui.Textzone'
local TextzoneList = require 'engine.ui.TextzoneList'
local Separator = require 'engine.ui.Separator'

module(..., package.seeall, class.inherit(Dialog))

function _M:init(actor)
	self.actor = actor
	actor.addon = actor.addon or {}
	actor.addon.uneffects = actor.addon.uneffects or { mark={}, confirm={} }
	self.uneffects = actor.addon.uneffects
	Dialog.init(self, _t'Disable Beneficial Effects', math.max(800, game.w * 0.8), math.max(600, game.h * 0.8))

	self.c_cancel = Button.new {
		text = _t'Cancel Effects',
		fct = function() self:cancelMarked() end
	}
	self.c_tut = Textzone.new {
		width = math.floor(self.iw/2) - 10,
		auto_height = true,
		no_color_bleed = true,
		text = _t[[#LIGHT_GREEN#Left-click#LAST# (or press <#LIGHT_GREEN#Enter#LAST#>) on a talent to add it to or remove it from the list of beneficial effects to cancel.]]
-- #LIGHT_GREEN#Right-click#LAST# (or press '#LIGHT_GREEN#~#LAST#') on a talent to toggle its confirmation status; if any marked effects are active when you click 'Cancel Effects', you will be prompted to confirm the cancel.]]
	}
	self.c_desc = TextzoneList.new {
		width = math.floor(self.iw/2) - 10,
		height = self.ih - self.c_tut.h - 50,
		scrollbar = true,
		no_color_bleed = true,
	}

	self.c_marked_title = Textzone.new {
		auto_width = true,
		auto_height = true,
		no_color_bleed = true,
		text = _t'#{bold}#Effects to cancel#{normal}#',
	}
	self.c_unmarked_title = Textzone.new {
		auto_width = true,
		auto_height = true,
		no_color_bleed = true,
		text = _t'#{bold}#Other Active Beneficial Effects#{normal}#',
	}

	self:generateLists()

	local lh_base = math.floor((self.ih - self.c_marked_title.h - self.c_unmarked_title.h -25)/3)
	local lw = math.floor(self.iw/2) - 10
	-- doesn't work
	-- local cols = {
	-- 	{ name=_t'Effect', width=80, display_prop='disp_name' },
	-- 	{ name=_t'Status', width=20, display_prop='status' }, }
	self.c_marked = ListColumns.new {
		width = lw,
		height = lh_base,
		scrollbar = true,
		all_clicks = true,
		-- columns = cols,
		columns = {
			{ name=_t'Effect', width=80, display_prop='disp_name' },
			-- { name=_t'Confirm', width=20, display_prop='confirm' },
			{ name=_t'Status', width=20, display_prop='status' }, },
		list = self.marked_list,
		fct = function(item, sel, button, event)
			self:use(item, sel, button, event, true)
		end,
		select = function(item, sel) self:select(item, true) end,
		-- no need without changing order
		-- on_drag = function(item, sel) self:onDrag(item, true) end,
		-- on_drag_end = function(item, sel) self:onDragEnd(true, item, sel) end,
	}
	self.c_marked.on_focus_change = function(zelf, v)
		-- Sneaky Hack(TM): If we just moused back into this list, forget our previous selection so that we will re-select our current selection to populate the shared description zone.
		if v then zelf.prev_sel = nil end
	end
	self.c_unmarked = ListColumns.new {
		width = lw,
		height = lh_base * 2,
		scrollbar = true,
		all_clicks = true,
		-- columns = cols,
		columns = {
			{ name=_t'Effect', width=100, display_prop='disp_name' }, },
		list = self.unmarked_list,
		fct = function(item, sel, button, event)
			self:use(item, sel, button, event, false)
		end,
		select = function(item, sel) self:select(item, false) end,
		-- no need without changing order
		-- on_drag = function(item, sel) self:onDrag(item, false) end,
		-- on_drag_end = function(item, sel) self:onDragEnd(false, item, sel) end,
	}
	self.c_unmarked.on_focus_change = function(zelf, v)
		-- Sneaky Hack(TM), redux
		if v then zelf.prev_sel = nil end
	end

	local hs = Separator.new { dir = 'horizontal', size = self.ih - 15 }
	local vs = Separator.new { dir = 'vertical', size = self.c_tut.w }
	local h1 = self.c_marked_title.h
	local h2 = h1 + self.c_marked.h
	local h3 = h2 + self.c_unmarked_title.h
	local rh1 = 40
	local rh2 = rh1 + self.c_tut.h
	local rh3 = rh2 + 20
	self:loadUI {
		{ left=0, top=0, ui=self.c_marked_title },
		{ left=0, top=h1, ui=self.c_marked },
		{ left=0, top=h2, ui=self.c_unmarked_title },
		{ left=0, top=h3, ui=self.c_unmarked },
		{ right=0, top=0, ui=self.c_cancel },
		{ right=0, top=40, ui=self.c_tut },
		{ right=0, top=40+self.c_tut.h, ui=vs },
		{ right=0, top=60+self.c_tut.h, ui=self.c_desc },
		{ hcenter=0, top=5, ui=hs},
	}
	self:setFocus(self.c_unmarked)
	self:setupUI()

	self.key:addBinds {
		EXIT = function() game:unregisterDialog(self) end,
	}
	self.c_marked.key:addCommands {
		__TEXTINPUT = function(c)
			if c == '-' then self:use(self.cur_item, self.c_marked.sel, 'right', nil, true) end
		end,
	}
end

local function prepend(ts, pfx)
	if type(ts) == 'string' then
		ts = ts:toTString()
	end
	pfx:merge(ts)
	return pfx
end

function _M:select(item, in_marked)
	if item and item.desc then
		local desc = item.desc
		-- need string to construct tstring{}
		local name = item.effect and item.effect.desc
		if name then
			desc = prepend(desc, tstring{{'font', 'bold'}, {'color','GOLD'}, name, {'color','LAST'}, {'font', 'normal'}, true, true})
		end
		self.c_desc:switchItem(item, desc, true)
	end
	self.cur_item = item
end

function _M:use(item, sel, button, event, in_marked)
	if not item then return end
	if not item.effect then return end

	-- if button == 'right' then
	-- 	if self.uneffects.confirm[item.id] then
	-- 		self.uneffects.confirm[item.id] = nil
	-- 	else
	-- 		self.uneffects.confirm[item.id] = true
	-- 	end
	-- 	if in_marked then
	-- 		self.c_marked:generateRow(item, true)
	-- 	end
	-- 	self:select(item, in_marked)
	if button == 'left' then
		-- Left click on an unmarked talent to mark it.
		if not in_marked then
			self.uneffects.mark[item.id] = true
		else
			self.uneffects.mark[item.id] = nil
		end
		self:markEffects(self.actor, item.id)
		self:generateLists()
	end
end

function _M:cancelMarked()
	local marks = self.actor.addon and self.actor.addon.uneffects and self.actor.addon.uneffects.mark or {}
	game:unregisterDialog(self)
	for id, _ in pairs(marks) do
		local e = self.actor.tempeffect_def[id]
		game.logPlayer(self.actor, '%s is canceled.', self:getDisplayName(e):toTString())
		self.actor:removeEffect(id)
	end
end

function _M:generateLists()
	local marked, unmarked = {}, {}

	for id in pairs(self.uneffects.mark) do
		local e = self.actor.tempeffect_def[id]
		if e.status == 'beneficial' then
			-- how to get p(power, chance, turn, etc) for not activated effects
			local desc = self:getDescription(e, self.actor.tmp[id])
			marked[#marked+1] = {
				effect = e,
				id = id,
				disp_name = self:getDisplayName(e):toTString(),
				-- confirm = self:getDisplayConfirm(self.uneffects.confirm[id]),
				status = self.actor.tmp[id] and "active" or "inactive",
				desc = desc,
			}
		end
	end
	for id, p in pairs(self.actor.tmp) do
		local e = self.actor.tempeffect_def[id]
		if e.status == 'beneficial' and not self.uneffects.mark[id] then
			unmarked[#unmarked+1] = {
				effect = e,
				id = id,
				disp_name = self:getDisplayName(e):toTString(),
				desc = self:getDescription(e, p),
			}
		end
	end

	self.marked_list = marked
	self.unmarked_list = unmarked
	if self.c_unmarked then
		self.c_unmarked:setList(self.unmarked_list)
	end
	if self.c_marked then
		self.c_marked:setList(self.marked_list)
	end
end

function _M:getDisplayName(e)
	local name = e.desc
	if e.display_entity then
		name = e.display_entity:getDisplayString() .. name
	end
	return name
end

-- function _M:getDisplayConfirm(c)
-- 	if c  then
-- 		return "Yes"
-- 	else
-- 		return "No"
-- 	end
-- end

function _M:getDescription(e, p)
	if p then
		return e.long_desc(game.player, p)
	else
		return "This effect isn't activated now."
	end
end

-- Adds special markers
function _M:markEffects(actor, id)
	local marks = actor.addon and actor.addon.uneffects and actor.addon.uneffects.mark or {}
	local e = actor.tempeffect_def[id]
	if e and e.status == 'beneficial' and e.display_entity then
		-- Find the current mark if any.
		local idx = -1
		for i, ov in ipairs(e.display_entity.add_displays or {}) do
			if ov.is_uneffect_mark then
				idx = i
				break
			end
		end
		if marks[id] and idx < 0 then
			-- Not marked and it should be.
			e.display_entity:removeAllMOs()
			e.display_entity.add_displays = e.display_entity.add_displays or {}
			local ov = Entity.new { image='mark-cancel-entity.png', is_uneffect_mark=true }
			table.insert(e.display_entity.add_displays, ov)
		elseif not marks[id] and idx > 0 then
			-- Marked and it shouldn't be.
			e.display_entity:removeAllMOs()
			table.remove(e.display_entity.add_displays, idx)
			if #e.display_entity.add_displays == 0 then
				e.display_entity.add_displays = nil
			end
		end
	end
end

function _M:markEffectsAll(actor)
	local marks = actor.addon and actor.addon.uneffects and actor.addon.uneffects.mark or {}
	for id, _ in pairs(marks) do
		self:markEffects(actor, id)
	end
end
