do
    local addonId = ...
    local languageTable = DetailsFramework.Language.RegisterLanguage(addonId, "ruRU")
    local L = languageTable

    L["ADDON_MENU_ADDONS_TITLE"] = "Фрейм М+"
    L["ADDON_MENU_ADDONS_TOOLTIP"] = "Открыть окно М+ Details!"

    L["COMMAND_OPEN_OPTIONS"] = "Открыть параметры"
    L["COMMAND_OPEN_OPTIONS_PRINT"] = "Открытие параметров M+ Details!, для получения дополнительной информации используйте %s"
    L["COMMAND_HELP"] = "Отображает этот список команд"
    L["COMMAND_HELP_PRINT"] = "доступные команды"
    L["COMMAND_SHOW_VERSION"] = "Показать версию во всплывающем окне"
    L["COMMAND_OPEN_SCOREBOARD"] = "Открыть окно М+ Details!"
    L["COMMAND_OPEN_LOGS"] = "Показать последние журналы"
    L["COMMAND_LIST_RUN_HISTORY"] = "Список последних забегов"
    L["COMMAND_LIST_RUN_HISTORY_NO_RUNS"] = "В настоящее время нет сохраненных забегов"
    L["COMMAND_CLEAR_RUN_HISTORY"] = "Очистить историю последних забегов"
    L["COMMAND_CLEAR_RUN_HISTORY_DONE"] = "Очищена история %s забегов"

    L["OPTIONS_WINDOW_TITLE"] = "Параметры M+ Details!"
    L["OPTIONS_GENERAL_OPTIONS"] = "Общие параметры"
    L["OPTIONS_AUTO_OPEN_LABEL"] = "Автоматически открывать окно М+ Details!"
    L["OPTIONS_AUTO_OPEN_DESC"] = "Хотите ли вы, чтобы окно М+ Details! автоматически открывалось после обыска сундука или после завершения забега?"
    L["OPTIONS_AUTO_OPEN_CHOICE_LOOT_CLOSED"] = "При получении добычи"
    L["OPTIONS_AUTO_OPEN_CHOICE_OVERALL_READY"] = "При завершении прохождения ключа М+"

    L["OPTIONS_OPEN_DELAY_LABEL"] = "Задержка открытия окна М+ Details!"
    L["OPTIONS_OPEN_DELAY_DESC"] = "Количество секунд, по истечении которых появится окно М+ Details! в соответствии с настройкой выше"
    L["OPTIONS_SCOREBOARD_SCALE_LABEL"] = "Масштаб окна М+ Details!"
    L["OPTIONS_SCOREBOARD_SCALE_DESC"] = "Увеличить или уменьшить масштаб окна М+ Details!"
    L["OPTIONS_SHOW_TOOLTIP_SUMMARY_LABEL"] = "Сводка во всплывающей подсказке"
    L["OPTIONS_SHOW_TOOLTIP_SUMMARY_DESC"] = "При наведении курсора на столбец в таблице результатов отобразится сводка по данным"
    L["OPTIONS_SECTION_TIMELINE"] = "Хронология"
    L["OPTIONS_TRANSLIT_LABEL"] = "Перевод символов"
    L["OPTIONS_SAVING"] = "Сохранение"
    L["OPTIONS_HISTORY_RUNS_TO_KEEP_LABEL"] = "Сохранённые забеги"
    L["OPTIONS_HISTORY_RUNS_TO_KEEP_DESC"] = "Количество забегов, которые необходимо сохранить. Существующая история, превышающая это значение, будет удалена при следующей перезагрузке или входе в систему. Большие объемы могут немного увеличить время загрузки."
    L["OPTIONS_TRANSLIT_DESC"] = "Перевести кириллические символы в латинский алфавит"
    L["OPTIONS_SHOW_TIME_SECTIONS_LABEL"] = "Показывать временные метки для разделов"
    L["OPTIONS_SHOW_TIME_SECTIONS_DESC"] = "Показывает временные метки для разделов на временной шкале в качестве ориентира"
    L["OPTIONS_SHOW_REMAINING_TIME_LABEL"] = "Показывать оставшееся время"
    L["OPTIONS_SHOW_REMAINING_TIME_DESC"] = "Когда ключ пройден вовремя, будет добавлен дополнительный раздел, показывающий оставшееся время"
    L["OPTIONS_DEBUG"] = "Отладка"
    L["OPTIONS_DEBUG_STORE_DEBUG_INFO_LABEL"] = "Сохранить отладочную информацию"
    L["OPTIONS_DEBUG_STORE_DEBUG_INFO_DESC"] = "Включение этой опции позволит сохранить больше информации при перезагрузке в целях отладки. Рекомендуется не включать этот параметр, если Вы не занимаетесь отладкой."

    L["SCOREBOARD_NO_SCORE_AVAILABLE"] = "В настоящее время на табло нет очков"
    L["SCOREBOARD_TITLE_PLAYER_NAME"] = "Имя игрока"
    L["SCOREBOARD_TITLE_SCORE"] = "Результат М+"
    L["SCOREBOARD_TITLE_LOOT"] = "Добыча"
    L["SCOREBOARD_TITLE_DEATHS"] = "Смерти"
    L["SCOREBOARD_TITLE_DAMAGE_TAKEN"] = "Полученный урон"
    L["SCOREBOARD_TITLE_DPS"] = "DPS"
    L["SCOREBOARD_TITLE_HPS"] = "HPS"
    L["SCOREBOARD_TITLE_INTERRUPTS"] = "Прерывания"
    L["SCOREBOARD_TITLE_DISPELS"] = "Рассеивания"
    L["SCOREBOARD_TITLE_CC_CASTS"] = "Контроли заклинаний"
    L["SCOREBOARD_NOT_IN_COMBAT_LABEL"] = "Не в бою"
    L["SCOREBOARD_UNKNOWN_DUNGEON_LABEL"] = "Неизвестное подземелье"
    L["SCOREBOARD_TOOLTIP_OPEN_BREAKDOWN"] = "Нажмите, чтобы открыть таблицу с данными"
    L["SCOREBOARD_TOOLTIP_INTERRUPT_SUCCESS_LABEL"] = "Успех"
    L["SCOREBOARD_TOOLTIP_INTERRUPT_OVERLAP_LABEL"] = "Перекрытие"
    L["SCOREBOARD_TOOLTIP_INTERRUPT_MISSED_LABEL"] = "Пропущено"
    L["ADDON_STARTUP_REMOVED_CORRUPT_HISTORY"] = "Удалено %d поврежденных забегов из истории."
    L["ADDON_STARTUP_REMOVED_TOO_MANY_HISTORY"] = "Удалено %d забегов из истории после обнаружения слишком большого количества сохраненных забегов."

    ------------------------------------------------------------
    --@localization(locale="ruRU", format="lua_additive_table")@
end
