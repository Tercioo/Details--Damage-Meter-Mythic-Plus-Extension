
--mythic+ extension for Details! Damage Meter
local Details = Details
local detailsFramework = DetailsFramework
local _

---@type string, private
local tocFileName, private = ...

---@type detailsmythicplus
local addon = private.addon

--localization
local L = detailsFramework.Language.GetLanguageTable(tocFileName)
local Translit = LibStub("LibTranslit-1.0")

function addon.PreparePlayerName(name)
    name = detailsFramework:RemoveRealmName(name)
    return addon.profile.translit and Translit:Transliterate(name, "!") or name
end
