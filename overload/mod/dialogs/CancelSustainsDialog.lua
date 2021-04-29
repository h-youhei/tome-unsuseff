require 'engine.class'
local Entity = require 'engine.Entity'
local Dialog = require 'engine.ui.Dialog'
-- local Button = require 'engine.ui.Button'
-- local TreeList = require 'engine.ui.TreeList'
-- local ListColumns = require 'engine.ui.ListColumns'
-- local Textzone = require 'engine.ui.Textzone'
-- local TextzoneList = require 'engine.ui.TextzoneList'
-- local Separator = require 'engine.ui.Separator'

module(..., package.seeall, class.inherit(Dialog))

function _M:init(actor)
	self.actor = actor
	actor.addon = actor.addon or {}
	actor.addon.unsustain = actor.addon.unsustain or { mark={} }
	self.unsustain = actor.addon.unsustain
end

-- Adds special markers
function _M:markSustains(actor, id)
	local marks = actor.addon and actor.addon.unsustain and actor.addon.unsustain.mark or {}
	local t = actor.talents_def[id]
	if t.mode == 'sustained' and t.display_entity then
		-- Find the current mark if any.
		local idx = -1
		for i, ov in ipairs(t.display_entity.add_displays or {}) do
			if ov.is_unsustain_mark then
				idx = i
				break
			end
		end
		if marks[id] and idx < 0 then
			-- Not marked and it should be.
			t.display_entity:removeAllMOs()
			t.display_entity.add_displays = t.display_entity.add_displays or {}
			local ov = Entity.new { image='mark-cancel-entity.png', is_unsustain_mark=true }
			table.insert(t.display_entity.add_displays, ov)
		elseif not marks[id] and idx > 0 then
			-- Marked and it shouldn't be.
			t.display_entity:removeAllMOs()
			table.remove(t.display_entity.add_displays, idx)
			if #t.display_entity.add_displays == 0 then
				t.display_entity.add_displays = nil
			end
		end
	end
end

function _M:markSustainsAll(actor)
	local marks = actor and actor.addon and actor.addon.unsustain and actor.addon.unsustain.mark or {}
	for id, _ in pairs(marks) do
		self:markSustains(actor, id)
	end
end
