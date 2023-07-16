-- ex: extend_section_bg[100] = 0
--     extend_section_bg[200] = 0
-- the video background associated with section 0 will continue playing into 100 and 200 without restarting.
-- will also cause any existing level 100, 200 backgrounds specified to NOT render.

-- please also note that you cannot currently extend any "named" backgrounds, such as "title" and "options-input"

extend_section_bg = {}

-- extend_section_bg[100] = 0
-- extend_section_bg[200] = 0
-- remove the dashes 

return extend_section_bg