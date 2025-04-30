local addonName, private = ...

---@type detailsmythicplus
local addon = private.addon
local ScoreboardColumn = {}
addon.ScoreboardColumn = ScoreboardColumn

---@class scoreboard_column
---@field GetId fun(self: scoreboard_column) : string
---@field GetHeaderText fun(self: scoreboard_column) : string
---@field GetWidth fun(self: scoreboard_column) : number
---@field SetOnRender fun(self: scoreboard_column, callback: fun(frame: frame, playerData: scoreboard_playerdata, isBest: boolean))
---@field CalculateBestPlayerData fun(self: scoreboard_column, allPlayerData: scoreboard_playerdata[]) : scoreboard_playerdata[]
---@field SetCalculateBestLine fun(self: scoreboard_column, callback: fun(allPlayerData: scoreboard_playerdata[]))
---@field Render fun(self: scoreboard_column, playerData: scoreboard_playerdata)
---@field BindToLine fun(self: scoreboard_column, line: scoreboard_line) : frame

local ScoreboardColumnMixin = {
    ColumnId = nil,
    HeaderText = nil,
    Width = nil,
    Constructor = nil,
    OnRender = function () end,
    OnHide = function () end,
    OnCalculateBestLine = function () end,
}

---@return scoreboard_column
function ScoreboardColumn:Create(id, headerText, width, constructor)
    local column = CreateFromMixins(ScoreboardColumnMixin)
    column.ColumnId = id
    column.Width = width
    column.Constructor = constructor
    column.HeaderText = headerText

    return column
end

function ScoreboardColumnMixin:GetId()
    return self.ColumnId
end

function ScoreboardColumnMixin:GetHeaderText()
    return self.HeaderText
end

function ScoreboardColumnMixin:GetWidth()
    return self.Width
end

function ScoreboardColumnMixin:SetOnRender(callback)
    self.OnRender = callback
end

function ScoreboardColumnMixin:SetOnHide(callback)
    self.OnHide = callback
end

function ScoreboardColumnMixin:CalculateBestPlayerData(allPlayerData)
    return self.OnCalculateBestLine(allPlayerData)
end

function ScoreboardColumnMixin:SetCalculateBestLine(callback)
    self.OnCalculateBestLine = callback
end

function ScoreboardColumnMixin:Render(frame, playerData, isBest)
    self.OnRender(frame, playerData, isBest)
end

function ScoreboardColumnMixin:Hide(frame)
    self.OnHide(frame)
end

function ScoreboardColumnMixin:BindToLine(line)
    local frame = self.Constructor(line)
    frame.ColumnDefinition = self
    return frame
end
