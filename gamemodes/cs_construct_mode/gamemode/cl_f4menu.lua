-- ============================================================
-- CS Construct — Меню настроек (F4)
-- Категории: ПРИЦЕЛ | ПЕРЧАТКИ
-- ============================================================

local F4Frame = nil

-- Цвета
local CS2_BG        = Color(14,  14,  18,  252)
local CS2_PANEL     = Color(22,  22,  28,  240)
local CS2_PANEL_LT  = Color(30,  30,  38,  235)
local CS2_BORDER    = Color(44,  44,  52,  255)
local CS2_TEXT      = Color(210, 210, 215, 255)
local CS2_MUTED     = Color(100, 100, 110, 255)
local CS2_ACCENT    = Color(87,  186, 255, 255)
local CS2_BTN       = Color(38,  38,  46,  255)
local CS2_BTN_HOV   = Color(52,  52,  62,  255)
local CS2_SEL       = Color(87,  186, 255, 30)
local CS2_SEL_BORD  = Color(87,  186, 255, 180)

surface.CreateFont("CS2_F4_Title",   { font = "Goodland SemiBold", size = 20, antialias = true })
surface.CreateFont("CS2_F4_Nav",     { font = "Goodland SemiBold", size = 13, antialias = true })
surface.CreateFont("CS2_F4_Section", { font = "Goodland SemiBold", size = 13, antialias = true })
surface.CreateFont("CS2_F4_Label",   { font = "Goodland SemiBold", size = 12, antialias = true })
surface.CreateFont("CS2_F4_Code",    { font = "Courier New",        size = 12, antialias = true })
surface.CreateFont("CS2_F4_Small",   { font = "Goodland SemiBold", size = 11, antialias = true })

-- ============================================================
-- Список перчаток (ключ = имя из player_manager.AddValidHands)
-- ============================================================
local GLOVES = {
    { name = "Без перчаток",  key = "",                                          skins = 0  },
    { name = "Голые руки",    key = "CSGO - Bare Hand",                          skins = 1  },
    { name = "Bloodhound",    key = "CSGO - Bloodhound Glove",                   skins = 4  },
    { name = "Hydra",         key = "CSGO - Bloodhound Glove - Hydra",           skins = 4  },
    { name = "Broken Fang",   key = "CSGO - Bloodhound Glove - Broken Fang",     skins = 4  },
    { name = "CT Default",    key = "CSGO - CT Default",                         skins = 1  },
    { name = "CT Black",      key = "CSGO - CT Default - Black",                 skins = 1  },
    { name = "CT Blue",       key = "CSGO - CT Default - Blue",                  skins = 1  },
    { name = "Specialist",    key = "CSGO - Specialist Gloves",                  skins = 11 },
    { name = "T Default",     key = "CSGO - T Default",                          skins = 1  },
    { name = "T Fullfinger",  key = "CSGO - T Fullfinger",                       skins = 1  },
    { name = "Handwrap",      key = "CSGO - Handwrap Gloves",                    skins = 12 },
    { name = "Moto",          key = "CSGO - Moto Gloves",                        skins = 13 },
    { name = "Slick",         key = "CSGO - Slick Gloves",                       skins = 13 },
    { name = "Sport",         key = "CSGO - Sport Gloves",                       skins = 13 },
    { name = "Legacy",        key = "CSGO - Legacy Gloves",                      skins = 1  },
}

-- ============================================================
-- Вспомогательная функция рисования прицела (из cl_tab.lua SWCS)
-- ============================================================
local function DrawCrosshairPreview(s, w, h)
    local cvDot      = GetConVar("swcs_crosshairdot")
    local cvStyle    = GetConVar("swcs_crosshairstyle")
    local cvColor    = GetConVar("swcs_crosshaircolor")
    local cvAlpha    = GetConVar("swcs_crosshairalpha")
    local cvR        = GetConVar("swcs_crosshaircolor_r")
    local cvG        = GetConVar("swcs_crosshaircolor_g")
    local cvB        = GetConVar("swcs_crosshaircolor_b")
    local cvSplitD   = GetConVar("swcs_crosshair_dynamic_splitdist")
    local cvGapWep   = GetConVar("swcs_crosshairgap_useweaponvalue")
    local cvGap      = GetConVar("swcs_crosshairgap")
    local cvFixGap   = GetConVar("swcs_crosshair_fixedgap")
    local cvSize     = GetConVar("swcs_crosshairsize")
    local cvThick    = GetConVar("swcs_crosshairthickness")
    local cvInA      = GetConVar("swcs_crosshair_dynamic_splitalpha_innermod")
    local cvOutA     = GetConVar("swcs_crosshair_dynamic_splitalpha_outermod")
    local cvRatio    = GetConVar("swcs_crosshair_dynamic_maxdist_splitratio")
    local cvOutline  = GetConVar("swcs_crosshair_drawoutline")
    local cvOutlineT = GetConVar("swcs_crosshair_outlinethickness")
    local cvUseAlpha = GetConVar("swcs_crosshairusealpha")
    local cvT        = GetConVar("swcs_crosshair_t")

    if not (cvDot and cvStyle and cvColor and cvSize) then return end

    draw.RoundedBox(4, 0, 0, w, h, CS2_PANEL)
    surface.SetDrawColor(CS2_BORDER)
    surface.DrawOutlinedRect(0, 0, w, h, 1)

    local COLORS = {
        [0] = Color(250, 50,  50),
        [1] = Color(50,  250, 50),
        [2] = Color(250, 250, 50),
        [3] = Color(50,  50,  250),
        [4] = Color(50,  250, 250),
        [5] = Color(cvR:GetInt(), cvG:GetInt(), cvB:GetInt()),
    }
    local col = COLORS[cvColor:GetInt()] or COLORS[1]
    local r, g, b = col.r, col.g, col.b
    local alpha = math.Clamp(cvAlpha:GetInt(), 0, 255)

    local bAdd = not cvUseAlpha:GetBool()
    if bAdd then
        if not s._texID then s._texID = surface.GetTextureID("vgui/white_additive") end
        surface.SetTexture(s._texID)
        alpha = 200
    end

    local function DrawXRect(dr, dg, db, da, x0, y0, x1, y1)
        local rw = math.max(x0, x1) - math.min(x0, x1)
        local rh = math.max(y0, y1) - math.min(y0, y1)
        if rw <= 0 or rh <= 0 then return end
        if cvOutline:GetBool() then
            local ft = cvOutlineT:GetFloat() * 2
            surface.SetDrawColor(0, 0, 0, da)
            surface.DrawRect(x0 - math.floor(ft / 2), y0 - math.floor(ft / 2), rw + ft, rh + ft)
        end
        surface.SetDrawColor(dr, dg, db, da)
        if bAdd then
            surface.DrawTexturedRect(x0, y0, rw, rh)
        else
            surface.DrawRect(x0, y0, rw, rh)
        end
    end

    local function YRES(y) return y * (h / 480) end

    local fHalfFov  = math.rad(90) * 0.5
    local flInac    = math.abs(math.sin(RealTime())) * 0.1
    local fSpreadD  = flInac * 320 / math.tan(fHalfFov)
    local flMaxD    = cvSplitD:GetFloat()
    local flCappedD = math.min(fSpreadD, flMaxD)

    local iSpreadD  = cvStyle:GetInt() < 4 and math.floor(YRES(fSpreadD))  or 2
    local iCappedD  = cvStyle:GetInt() < 4 and math.floor(YRES(flCappedD)) or 2

    local fGoal = cvGapWep:GetBool() and 0 or 4
    if not s._dist then s._dist = 0 end
    if s._dist > fGoal then
        if cvStyle:GetInt() == 5 then
            s._dist = s._dist - 42 * FrameTime()
        else
            s._dist = Lerp(FrameTime() / 0.025, fGoal, s._dist)
        end
    end
    s._dist = math.Clamp(s._dist, fGoal, 25.0)

    local iCrossDist, iBarSize, iBarThick, iCappedCross
    iCappedCross = 0
    iCrossDist   = math.floor((s._dist * h / 1200.0) + cvGap:GetFloat())
    iBarSize     = math.floor(YRES(cvSize:GetFloat()))
    iBarThick    = math.max(1, math.floor(YRES(cvThick:GetFloat())))

    local st = cvStyle:GetInt()
    if iSpreadD > 0 and (st == 2 or st == 3) then
        iCrossDist  = iSpreadD + cvGap:GetFloat()
        if st == 2 then iCappedCross = iCappedD + cvGap:GetFloat() end
    elseif st == 4 or (iSpreadD == 0 and (st == 2 or st == 3)) then
        iCrossDist  = fGoal + cvGap:GetFloat()
        iCappedCross = 4 + cvGap:GetFloat()
    elseif st == 1 then
        iCrossDist  = cvFixGap:GetFloat()
        iCappedCross = cvFixGap:GetFloat()
    end

    local cx = math.floor(w / 2)
    local cy = math.floor(h / 2)

    local flAIn, flAOut = alpha, alpha
    local iBarIn, iBarOut = iBarSize, iBarSize
    local iInnerDist = iCrossDist

    if st == 2 and fSpreadD > flMaxD then
        iInnerDist = iCappedCross
        flAIn   = alpha * cvInA:GetFloat()
        flAOut  = alpha * cvOutA:GetFloat()
        iBarIn  = math.ceil(iBarSize  * (1.0 - cvRatio:GetFloat()))
        iBarOut = math.floor(iBarSize *        cvRatio:GetFloat())
        local iIL = (cx - iCrossDist - iBarThick/2) - iBarIn
        local iIR = iIL + 2*(iCrossDist + iBarIn) + iBarThick
        local iOL = iIL - iBarOut;  local iOR = iIR + iBarOut
        local y0 = cy - iBarThick/2; local y1 = y0 + iBarThick
        DrawXRect(r, g, b, flAOut, iOL, y0, iIL, y1)
        DrawXRect(r, g, b, flAOut, iIR, y0, iOR, y1)
        local iIT = (cy - iCrossDist - iBarThick/2) - iBarIn
        local iIB = iIT + 2*(iCrossDist + iBarIn) + iBarThick
        local iOT = iIT - iBarOut;  local iOB = iIB + iBarOut
        local x0 = cx - iBarThick/2; local x1 = x0 + iBarThick
        if not cvT:GetBool() then DrawXRect(r, g, b, flAOut, x0, iOT, x1, iIT) end
        DrawXRect(r, g, b, flAOut, x0, iIB, x1, iOB)
    end

    local iIL = cx - iInnerDist - (iBarThick/2)
    local iIR = iIL + (2*iInnerDist) + iBarThick
    local iOL = iIL - iBarIn;  local iOR = iIR + iBarIn
    local y0 = cy - (iBarThick/2); local y1 = y0 + iBarThick
    DrawXRect(r, g, b, flAIn, iOL, y0, iIL, y1)
    DrawXRect(r, g, b, flAIn, iIR, y0, iOR, y1)

    local iIT = cy - iInnerDist - (iBarThick/2)
    local iIB = iIT + (2*iInnerDist) + iBarThick
    local iOT = iIT - iBarIn;  local iOB = iIB + iBarIn
    local x0 = cx - (iBarThick/2); local x1 = x0 + iBarThick
    if not cvT:GetBool() then DrawXRect(r, g, b, flAIn, x0, iOT, x1, iIT) end
    DrawXRect(r, g, b, flAIn, x0, iIB, x1, iOB)

    if cvDot:GetBool() then
        local dx0 = cx - iBarThick/2; local dx1 = dx0 + iBarThick
        local dy0 = cy - iBarThick/2; local dy1 = dy0 + iBarThick
        DrawXRect(r, g, b, alpha, dx0, dy0, dx1, dy1)
    end
end

-- ============================================================
-- Открытие меню
-- ============================================================
local function OpenF4Menu()
    if IsValid(F4Frame) then
        F4Frame:Remove()
        F4Frame = nil
        return
    end

    local W, H     = 800, 600
    local SIDEBAR  = 140   -- ширина левой навигации
    local HDR      = 50    -- высота заголовка
    local PAD      = 12

    local f = vgui.Create("DFrame")
    F4Frame = f
    f:SetSize(W, H)
    f:Center()
    f:SetTitle("")
    f:SetDraggable(true)
    f:ShowCloseButton(false)
    f:MakePopup()

    -- Фон
    f.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, CS2_BG)
        draw.RoundedBoxEx(6, 0, 0, SIDEBAR, h, CS2_PANEL, true, false, true, false)
        draw.RoundedBoxEx(6, 0, 0, w, HDR, CS2_PANEL, true, true, false, false)
        surface.SetDrawColor(CS2_BORDER)
        surface.DrawRect(0, HDR, w, 1)
        surface.DrawRect(SIDEBAR, HDR, 1, h - HDR)
        draw.SimpleText("НАСТРОЙКИ", "CS2_F4_Title", SIDEBAR + 16, HDR / 2, CS2_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("F4 — закрыть", "CS2_F4_Label", w - 16, HDR / 2, CS2_MUTED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    -- Кнопка закрыть
    local closeBtn = vgui.Create("DButton", f)
    closeBtn:SetPos(W - 40, 11)
    closeBtn:SetSize(28, 28)
    closeBtn:SetText("✕")
    closeBtn:SetFont("CS2_F4_Section")
    closeBtn.Paint = function(s, bw, bh)
        if s:IsHovered() then
            draw.RoundedBox(4, 0, 0, bw, bh, CS2_BTN_HOV)
            s:SetTextColor(CS2_TEXT)
        else
            s:SetTextColor(CS2_MUTED)
        end
    end
    closeBtn.DoClick = function() F4Frame:Remove() F4Frame = nil end

    -- ========================================================
    -- Панели контента
    -- ========================================================
    local contX = SIDEBAR + 1
    local contW = W - contX - PAD
    local contY = HDR + PAD
    local contH = H - contY - PAD

    local panels = {}
    local navBtns = {}
    local activeTab = nil

    local function SwitchTab(name)
        if activeTab == name then return end
        activeTab = name
        for k, p in pairs(panels) do
            p:SetVisible(k == name)
        end
        for k, b in pairs(navBtns) do
            b._active = (k == name)
        end
    end

    -- ========================================================
    -- Левый сайдбар: навигация
    -- ========================================================
    local navY = HDR + 20
    local function NavBtn(label, tabName)
        local btn = vgui.Create("DButton", f)
        btn:SetPos(0, navY)
        btn:SetSize(SIDEBAR, 36)
        btn:SetText("")
        btn._active = false
        btn.Paint = function(s, bw, bh)
            if s._active then
                draw.RoundedBox(0, 0, 0, bw, bh, CS2_SEL)
                surface.SetDrawColor(CS2_ACCENT)
                surface.DrawRect(bw - 2, 0, 2, bh)
                draw.SimpleText(label, "CS2_F4_Nav", bw / 2, bh / 2, CS2_ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            elseif s:IsHovered() then
                draw.RoundedBox(0, 0, 0, bw, bh, CS2_BTN_HOV)
                draw.SimpleText(label, "CS2_F4_Nav", bw / 2, bh / 2, CS2_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                draw.SimpleText(label, "CS2_F4_Nav", bw / 2, bh / 2, CS2_MUTED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
        btn.DoClick = function() SwitchTab(tabName) end
        navBtns[tabName] = btn
        navY = navY + 38
    end

    NavBtn("ПРИЦЕЛ",    "crosshair")
    NavBtn("ПЕРЧАТКИ",  "gloves")
    NavBtn("МОДЕЛЬ",    "playermodel")
    NavBtn("БИНДЫ",     "binds")

    -- ========================================================
    -- Вкладка ПРИЦЕЛ
    -- ========================================================
    local pCrosshair = vgui.Create("DPanel", f)
    pCrosshair:SetPos(contX, contY)
    pCrosshair:SetSize(contW, contH)
    pCrosshair:SetVisible(false)
    pCrosshair.Paint = function() end
    panels["crosshair"] = pCrosshair

    do
        local prevW = 230

        -- Превью прицела
        local prevBoard = vgui.Create("DPanel", pCrosshair)
        prevBoard:SetPos(0, 0)
        prevBoard:SetSize(prevW, prevW)
        prevBoard.Paint = DrawCrosshairPreview

        -- Код прицела
        local codeY = prevW + 12
        local lblCode = vgui.Create("DLabel", pCrosshair)
        lblCode:SetPos(0, codeY)
        lblCode:SetSize(prevW, 16)
        lblCode:SetText("КОД ПРИЦЕЛА")
        lblCode:SetFont("CS2_F4_Section")
        lblCode:SetTextColor(CS2_MUTED)

        local importE = vgui.Create("DTextEntry", pCrosshair)
        importE:SetPos(0, codeY + 20)
        importE:SetSize(prevW, 28)
        importE:SetPlaceholderText("Вставьте CSGO-XXXXX-...")
        importE:SetFont("CS2_F4_Code")
        importE.Paint = function(s, bw, bh)
            draw.RoundedBox(3, 0, 0, bw, bh, CS2_BTN)
            surface.SetDrawColor(CS2_BORDER)
            surface.DrawOutlinedRect(0, 0, bw, bh, 1)
            s:DrawTextEntryText(CS2_TEXT, CS2_ACCENT, CS2_MUTED)
        end
        importE.OnEnter = function(s)
            local code = s:GetValue()
            if swcs and swcs.ApplyCrosshairCode and swcs.ApplyCrosshairCode(code) then
                s:SetValue("")
                surface.PlaySound("UI/buttonclick.wav")
            end
        end

        local exportE = vgui.Create("DTextEntry", pCrosshair)
        exportE:SetPos(0, codeY + 52)
        exportE:SetSize(prevW, 28)
        exportE:SetEditable(false)
        exportE:SetFont("CS2_F4_Code")
        exportE.Think = function(s)
            local code = LocalPlayer().swcs_CrosshairCode
            if code and code ~= s:GetValue() then s:SetValue(code) end
        end
        exportE.OnGetFocus = function(s)
            hook.Run("OnTextEntryGetFocus", s)
            SetClipboardText(s:GetValue())
            surface.PlaySound("UI/buttonclick.wav")
        end
        exportE.Paint = function(s, bw, bh)
            draw.RoundedBox(3, 0, 0, bw, bh, Color(18, 18, 24))
            surface.SetDrawColor(CS2_BORDER)
            surface.DrawOutlinedRect(0, 0, bw, bh, 1)
            s:DrawTextEntryText(CS2_ACCENT, CS2_ACCENT, CS2_MUTED)
        end

        local hintLbl = vgui.Create("DLabel", pCrosshair)
        hintLbl:SetPos(0, codeY + 84)
        hintLbl:SetSize(prevW, 14)
        hintLbl:SetText("Нажмите на поле выше, чтобы скопировать")
        hintLbl:SetFont("CS2_F4_Label")
        hintLbl:SetTextColor(CS2_MUTED)

        -- Настройки (правая колонка)
        local rightX = prevW + 14
        local rightW = contW - rightX

        local scroll = vgui.Create("DScrollPanel", pCrosshair)
        scroll:SetPos(rightX, 0)
        scroll:SetSize(rightW, contH)

        local sbar = scroll:GetVBar()
        sbar:SetWide(4)
        sbar.Paint         = function(s, sw, sh) draw.RoundedBox(2, 0, 0, sw, sh, CS2_PANEL) end
        sbar.btnUp.Paint   = function() end
        sbar.btnDown.Paint = function() end
        sbar.btnGrip.Paint = function(s, sw, sh) draw.RoundedBox(2, 0, 0, sw, sh, CS2_BORDER) end

        local iW  = rightW - 8
        local curY = 0

        local function Section(text)
            local p = vgui.Create("DPanel", scroll)
            p:SetSize(iW, 24); p:SetPos(0, curY)
            p.Paint = function(s, pw, ph)
                surface.SetDrawColor(CS2_BORDER)
                surface.DrawRect(0, ph - 1, pw, 1)
                draw.SimpleText(text, "CS2_F4_Section", 0, ph / 2, CS2_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            curY = curY + 28
        end

        local function Check(text, cvar)
            local row = vgui.Create("DPanel", scroll)
            row:SetSize(iW, 24); row:SetPos(0, curY)
            row.Paint = function() end
            local ck = vgui.Create("DCheckBox", row)
            ck:SetPos(0, 3); ck:SetSize(18, 18); ck:SetConVar(cvar)
            local lbl = vgui.Create("DLabel", row)
            lbl:SetPos(24, 2); lbl:SetSize(iW - 24, 20)
            lbl:SetText(text); lbl:SetFont("CS2_F4_Label"); lbl:SetTextColor(CS2_TEXT)
            curY = curY + 26
        end

        local function Slider(text, cvar, mn, mx, dec)
            local sl = vgui.Create("DNumSlider", scroll)
            sl:SetPos(0, curY); sl:SetSize(iW, 26)
            sl:SetText(text); sl:SetConVar(cvar)
            sl:SetMin(mn); sl:SetMax(mx); sl:SetDecimals(dec or 0)
            if sl.Label and IsValid(sl.Label) then
                sl.Label:SetTextColor(CS2_TEXT)
                sl.Label:SetFont("CS2_F4_Label")
            end
            curY = curY + 28
        end

        local function Combo(text, cvar, choices)
            local row = vgui.Create("DPanel", scroll)
            row:SetSize(iW, 24); row:SetPos(0, curY)
            row.Paint = function() end
            local lbl = vgui.Create("DLabel", row)
            lbl:SetPos(0, 2); lbl:SetSize(100, 20)
            lbl:SetText(text); lbl:SetFont("CS2_F4_Label"); lbl:SetTextColor(CS2_TEXT)
            local cmb = vgui.Create("DComboBox", row)
            cmb:SetPos(104, 1); cmb:SetSize(iW - 106, 22)
            local cv = GetConVar(cvar)
            local curVal = cv and cv:GetInt() or 0
            for _, c in ipairs(choices) do
                cmb:AddChoice(c[1], c[2])
                if c[2] == curVal then cmb:SetValue(c[1]) end
            end
            cmb.OnSelect = function(_, _, _, data) RunConsoleCommand(cvar, tostring(data)) end
            local cbKey = "CS2_F4_Combo_" .. cvar
            cvars.AddChangeCallback(cvar, function(_, _, new)
                if not IsValid(cmb) then cvars.RemoveChangeCallback(cvar, cbKey) return end
                local val = tonumber(new)
                for _, c in ipairs(choices) do
                    if c[2] == val then cmb:SetValue(c[1]) return end
                end
            end, cbKey)
            curY = curY + 26
        end

        Section("ПРИЦЕЛ")
        Check("Кастомный прицел",   "swcs_crosshair")
        Check("Следовать отдаче",   "swcs_crosshair_recoil")
        Combo("Стиль", "swcs_crosshairstyle", {
            { "Default",          0 },
            { "Default Static",   1 },
            { "Accurate Split",   2 },
            { "Accurate Dynamic", 3 },
            { "Classic Static",   4 },
            { "Classic Dynamic",  5 },
        })
        Section("ЦВЕТ")
        Combo("Цвет", "swcs_crosshaircolor", {
            { "Красный",  0 },
            { "Зелёный",  1 },
            { "Жёлтый",   2 },
            { "Синий",    3 },
            { "Голубой",  4 },
            { "Свой",     5 },
        })
        Slider("Красный (R)",      "swcs_crosshaircolor_r",  0, 255, 0)
        Slider("Зелёный (G)",      "swcs_crosshaircolor_g",  0, 255, 0)
        Slider("Синий (B)",        "swcs_crosshaircolor_b",  0, 255, 0)
        Slider("Прозрачность (A)", "swcs_crosshairalpha",    0, 255, 0)
        Check("Использовать Alpha","swcs_crosshairusealpha")
        Section("ФОРМА")
        Check("T-образный (без верхней линии)", "swcs_crosshair_t")
        Check("Центральная точка",              "swcs_crosshairdot")
        Slider("Толщина",         "swcs_crosshairthickness", 0,   20,  1)
        Slider("Размер",          "swcs_crosshairsize",      0,   250, 0)
        Slider("Зазор",           "swcs_crosshairgap",      -10,  10,  0)
        Slider("Фикс. зазор",     "swcs_crosshair_fixedgap", 0,   20,  0)
        Check("Зазор по оружию",  "swcs_crosshairgap_useweaponvalue")
        Section("ОБВОДКА")
        Check("Обводка", "swcs_crosshair_drawoutline")
        Slider("Толщина обводки", "swcs_crosshair_outlinethickness", 0.1, 3, 1)
        Section("ДИНАМИКА (стили 2 / 3)")
        Slider("Макс. дистанция разделения", "swcs_crosshair_dynamic_splitdist",             1,   25,  0)
        Slider("Alpha внутренних линий",     "swcs_crosshair_dynamic_splitalpha_innermod",   0,   1,   2)
        Slider("Alpha внешних линий",        "swcs_crosshair_dynamic_splitalpha_outermod",   0.3, 1,   2)
        Slider("Соотношение длин",           "swcs_crosshair_dynamic_maxdist_splitratio",    0,   1,   2)

        scroll:GetCanvas():SetTall(curY + 10)
    end

    -- ========================================================
    -- Вкладка ПЕРЧАТКИ
    -- ========================================================
    local pGloves = vgui.Create("DPanel", f)
    pGloves:SetPos(contX, contY)
    pGloves:SetSize(contW, contH)
    pGloves:SetVisible(false)
    pGloves.Paint = function() end
    panels["gloves"] = pGloves

    do
        local LIST_W  = 200
        local SKIN_X  = LIST_W + 10
        local SKIN_W  = contW - SKIN_X
        local CARD_H  = 38
        local COLS    = 4
        local CELL    = math.floor((SKIN_W - 8) / COLS)
        local APPLY_H = 38   -- высота кнопки применить

        -- Текущий выбор
        local cvHands     = GetConVar("cl_playerhands")
        local cvHandsSkin = GetConVar("cl_playerhandsskin")
        local cvHandsBG   = GetConVar("cl_playerhandsbodygroups")
        local selKey  = cvHands    and cvHands:GetString() or ""
        local selSkin = cvHandsSkin and cvHandsSkin:GetInt() or 0
        local selBG   = cvHandsBG  and tonumber(cvHandsBG:GetString()) or 0

        -- ---- Левый список: типы перчаток ----
        local listScroll = vgui.Create("DScrollPanel", pGloves)
        listScroll:SetPos(0, 0)
        listScroll:SetSize(LIST_W, contH)

        local lsbar = listScroll:GetVBar()
        lsbar:SetWide(4)
        lsbar.Paint         = function(s, sw, sh) draw.RoundedBox(2, 0, 0, sw, sh, CS2_PANEL) end
        lsbar.btnUp.Paint   = function() end
        lsbar.btnDown.Paint = function() end
        lsbar.btnGrip.Paint = function(s, sw, sh) draw.RoundedBox(2, 0, 0, sw, sh, CS2_BORDER) end

        -- ---- Правая панель ----
        local skinPanel = vgui.Create("DPanel", pGloves)
        skinPanel:SetPos(SKIN_X, 0)
        skinPanel:SetSize(SKIN_W, contH)
        skinPanel.Paint = function() end

        -- Заголовок правой панели
        local skinTitle = vgui.Create("DLabel", skinPanel)
        skinTitle:SetPos(0, 0)
        skinTitle:SetSize(SKIN_W - APPLY_H - 8, 24)
        skinTitle:SetText("")
        skinTitle:SetFont("CS2_F4_Section")
        skinTitle:SetTextColor(CS2_MUTED)

        -- Скролл с содержимым (скины + bodygroups)
        local scrollH = contH - 28 - APPLY_H - 8
        local skinScroll = vgui.Create("DScrollPanel", skinPanel)
        skinScroll:SetPos(0, 28)
        skinScroll:SetSize(SKIN_W, scrollH)

        local ssbar = skinScroll:GetVBar()
        ssbar:SetWide(4)
        ssbar.Paint         = function(s, sw, sh) draw.RoundedBox(2, 0, 0, sw, sh, CS2_PANEL) end
        ssbar.btnUp.Paint   = function() end
        ssbar.btnDown.Paint = function() end
        ssbar.btnGrip.Paint = function(s, sw, sh) draw.RoundedBox(2, 0, 0, sw, sh, CS2_BORDER) end

        -- Кнопка ПРИМЕНИТЬ
        local applyBtn = vgui.Create("DButton", skinPanel)
        applyBtn:SetPos(0, contH - APPLY_H)
        applyBtn:SetSize(SKIN_W, APPLY_H - 2)
        applyBtn:SetText("")
        applyBtn.Paint = function(s, bw, bh)
            local bg = s:IsHovered() and Color(100, 200, 100, 60) or Color(70, 160, 70, 40)
            draw.RoundedBox(4, 0, 0, bw, bh, bg)
            surface.SetDrawColor(Color(80, 180, 80, 200))
            surface.DrawOutlinedRect(0, 0, bw, bh, 1)
            draw.SimpleText("ПРИМЕНИТЬ", "CS2_F4_Nav", bw / 2, bh / 2, Color(120, 220, 120, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        applyBtn.DoClick = function()
            RunConsoleCommand("cs_apply_hands")
            surface.PlaySound("UI/buttonclick.wav")
        end

        -- Кнопки перчаток и скинов
        local gloveCards = {}
        local dynBtns    = {}   -- скины + bodygroup кнопки (пересоздаются)

        local function SectionHeader(parent, y, text, w)
            local p = vgui.Create("DPanel", parent)
            p:SetPos(2, y)
            p:SetSize(w - 4, 24)
            p.Paint = function(s, pw, ph)
                surface.SetDrawColor(CS2_BORDER)
                surface.DrawRect(0, ph - 1, pw, 1)
                draw.SimpleText(text, "CS2_F4_Section", 0, ph / 2, CS2_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            table.insert(dynBtns, p)
            return p
        end

        local function GridBtn(parent, x, y, size, label, isSelFn, onClick)
            local btn = vgui.Create("DButton", parent)
            btn:SetPos(x, y)
            btn:SetSize(size - 4, size - 4)
            btn:SetText("")
            btn.Paint = function(s, bw, bh)
                local isSel = isSelFn()
                if isSel then
                    draw.RoundedBox(4, 0, 0, bw, bh, CS2_SEL)
                    surface.SetDrawColor(CS2_SEL_BORD)
                    surface.DrawOutlinedRect(0, 0, bw, bh, 1)
                elseif s:IsHovered() then
                    draw.RoundedBox(4, 0, 0, bw, bh, CS2_BTN_HOV)
                    surface.SetDrawColor(CS2_BORDER)
                    surface.DrawOutlinedRect(0, 0, bw, bh, 1)
                else
                    draw.RoundedBox(4, 0, 0, bw, bh, CS2_BTN)
                    surface.SetDrawColor(CS2_BORDER)
                    surface.DrawOutlinedRect(0, 0, bw, bh, 1)
                end
                draw.SimpleText(label, "CS2_F4_Nav", bw / 2, bh / 2, isSel and CS2_ACCENT or CS2_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            btn.DoClick = onClick
            table.insert(dynBtns, btn)
            return btn
        end

        local function RebuildRight(glove)
            for _, b in ipairs(dynBtns) do
                if IsValid(b) then b:Remove() end
            end
            dynBtns = {}

            local canvasY = 0
            local iW = SKIN_W - 8

            -- ---- СКИНЫ (skins) ----
            if glove and glove.skins > 1 then
                SectionHeader(skinScroll:GetCanvas(), canvasY, "СКИНЫ", iW)
                canvasY = canvasY + 28

                local row, col = 0, 0
                for i = 0, glove.skins - 1 do
                    local idx = i
                    GridBtn(
                        skinScroll:GetCanvas(),
                        col * CELL + 2, canvasY + row * CELL,
                        CELL,
                        tostring(idx + 1),
                        function() return selKey == glove.key and selSkin == idx end,
                        function()
                            selKey  = glove.key
                            selSkin = idx
                            RunConsoleCommand("cl_playerhands",     glove.key)
                            RunConsoleCommand("cl_playerhandsskin", tostring(idx))
                            surface.PlaySound("UI/buttonclick.wav")
                        end
                    )
                    col = col + 1
                    if col >= COLS then col = 0; row = row + 1 end
                end
                canvasY = canvasY + math.ceil(glove.skins / COLS) * CELL + 8
            end

            -- ---- СКИНЫ (bodygroups) ----
            SectionHeader(skinScroll:GetCanvas(), canvasY, "СКИНЫ (группа)", iW)
            canvasY = canvasY + 28

            local bgRow, bgCol = 0, 0
            for i = 0, 5 do
                local idx = i
                GridBtn(
                    skinScroll:GetCanvas(),
                    bgCol * CELL + 2, canvasY + bgRow * CELL,
                    CELL,
                    tostring(idx),
                    function() return selBG == idx end,
                    function()
                        selBG = idx
                        RunConsoleCommand("cl_playerhandsbodygroups", tostring(idx))
                        surface.PlaySound("UI/buttonclick.wav")
                    end
                )
                bgCol = bgCol + 1
                if bgCol >= COLS then bgCol = 0; bgRow = bgRow + 1 end
            end
            canvasY = canvasY + math.ceil(6 / COLS) * CELL + 4

            skinScroll:GetCanvas():SetTall(canvasY)
            skinTitle:SetText(glove and glove.name or "")
        end

        -- ---- Список типов перчаток ----
        local listY = 0
        for _, glove in ipairs(GLOVES) do
            local g = glove
            local btn = vgui.Create("DButton", listScroll:GetCanvas())
            btn:SetPos(0, listY)
            btn:SetSize(LIST_W - 8, CARD_H)
            btn:SetText("")
            btn.Paint = function(s, bw, bh)
                local isSel = (selKey == g.key)
                if isSel then
                    draw.RoundedBox(4, 0, 0, bw, bh, CS2_SEL)
                    surface.SetDrawColor(CS2_SEL_BORD)
                    surface.DrawOutlinedRect(0, 0, bw, bh, 1)
                    draw.SimpleText(g.name, "CS2_F4_Nav", 12, bh / 2, CS2_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                elseif s:IsHovered() then
                    draw.RoundedBox(4, 0, 0, bw, bh, CS2_BTN_HOV)
                    draw.SimpleText(g.name, "CS2_F4_Nav", 12, bh / 2, CS2_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                else
                    draw.RoundedBox(4, 0, 0, bw, bh, CS2_BTN)
                    draw.SimpleText(g.name, "CS2_F4_Nav", 12, bh / 2, CS2_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                if g.skins > 1 then
                    draw.SimpleText(g.skins .. " ск.", "CS2_F4_Small", bw - 8, bh / 2, isSel and CS2_ACCENT or CS2_MUTED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end
            btn.DoClick = function()
                selKey  = g.key
                selSkin = 0
                RunConsoleCommand("cl_playerhands",     g.key)
                RunConsoleCommand("cl_playerhandsskin", "0")
                surface.PlaySound("UI/buttonclick.wav")
                RebuildRight(g)
            end
            table.insert(gloveCards, btn)
            listY = listY + CARD_H + 2
        end
        listScroll:GetCanvas():SetTall(listY + 4)

        -- Инициализация правой панели
        local initGlove
        for _, g in ipairs(GLOVES) do
            if g.key == selKey then initGlove = g break end
        end
        RebuildRight(initGlove)
    end

    -- ========================================================
    -- Вкладка МОДЕЛЬ
    -- ========================================================
    local pPlayermodel = vgui.Create("DPanel", f)
    pPlayermodel:SetPos(contX, contY)
    pPlayermodel:SetSize(contW, contH)
    pPlayermodel:SetVisible(false)
    pPlayermodel.Paint = function() end
    panels["playermodel"] = pPlayermodel

    do
        local PM_LIST_W = 200
        local PM_CARD_H = 34
        local PM_APPLY_H = 38

        -- Collect ctm_* and tm_* models from player_manager
        local allModels = player_manager.AllValidModels()
        local ctModels  = {}
        local tModels   = {}

        local function PrettifyModel(key)
            local name = key:gsub("^ctm_", ""):gsub("^tm_", "")
            name = name:gsub("_", " ")
            name = name:gsub("(%a)([%w]*)", function(a, b) return a:upper() .. b end)
            return name
        end

        for key, mdl in SortedPairs(allModels) do
            if key:sub(1, 4) == "ctm_" then
                table.insert(ctModels, { key = key, mdl = mdl, name = PrettifyModel(key) })
            elseif key:sub(1, 3) == "tm_" then
                table.insert(tModels,  { key = key, mdl = mdl, name = PrettifyModel(key) })
            end
        end

        -- Left: scrollable list (above apply button)
        local listH = contH - PM_APPLY_H - 4
        local pmList = vgui.Create("DScrollPanel", pPlayermodel)
        pmList:SetPos(0, 0)
        pmList:SetSize(PM_LIST_W, listH)

        local pmVBar = pmList:GetVBar()
        pmVBar:SetWide(4)
        pmVBar.Paint         = function(s, sw, sh) draw.RoundedBox(2, 0, 0, sw, sh, CS2_PANEL) end
        pmVBar.btnUp.Paint   = function() end
        pmVBar.btnDown.Paint = function() end
        pmVBar.btnGrip.Paint = function(s, sw, sh) draw.RoundedBox(2, 0, 0, sw, sh, CS2_BORDER) end

        -- Apply button (bottom-left, like gloves)
        local applyPmBtn = vgui.Create("DButton", pPlayermodel)
        applyPmBtn:SetPos(0, contH - PM_APPLY_H)
        applyPmBtn:SetSize(PM_LIST_W, PM_APPLY_H - 2)
        applyPmBtn:SetText("")
        applyPmBtn.Paint = function(s, bw, bh)
            local bg = s:IsHovered() and Color(100, 200, 100, 60) or Color(70, 160, 70, 40)
            draw.RoundedBox(4, 0, 0, bw, bh, bg)
            surface.SetDrawColor(Color(80, 180, 80, 200))
            surface.DrawOutlinedRect(0, 0, bw, bh, 1)
            draw.SimpleText("ПРИМЕНИТЬ", "CS2_F4_Nav", bw / 2, bh / 2, Color(120, 220, 120, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Right: container panel for border styling
        local previewX = PM_LIST_W + 8
        local previewW = contW - PM_LIST_W - 8

        local previewWrap = vgui.Create("DPanel", pPlayermodel)
        previewWrap:SetPos(previewX, 0)
        previewWrap:SetSize(previewW, contH)
        previewWrap.Paint = function(s, pw, ph)
            draw.RoundedBox(4, 0, 0, pw, ph, CS2_PANEL)
            surface.SetDrawColor(CS2_BORDER)
            surface.DrawOutlinedRect(0, 0, pw, ph, 1)
        end

        -- DModelPanel inside wrapper — no Paint override so 3D renders correctly
        local mdlPanel = vgui.Create("DModelPanel", previewWrap)
        mdlPanel:SetPos(1, 1)
        mdlPanel:SetSize(previewW - 2, contH - 2)
        mdlPanel:SetModel("models/player/custom_player/donj/ctm_fbi.mdl")
        mdlPanel:SetCamPos(Vector(60, 0, 60))
        mdlPanel:SetLookAt(Vector(0, 0, 42))

        local pmAngle = 0
        mdlPanel.LayoutEntity = function(s, ent)
            pmAngle = pmAngle + FrameTime() * 25
            ent:SetAngles(Angle(0, pmAngle, 0))
        end

        local selPmKey = GetConVar("cl_playermodel") and GetConVar("cl_playermodel"):GetString() or ""

        local function SelectModel(key, mdl)
            selPmKey = key
            mdlPanel:SetModel(mdl)
            mdlPanel:SetCamPos(Vector(60, 0, 60))
            mdlPanel:SetLookAt(Vector(0, 0, 42))
            surface.PlaySound("UI/buttonclick.wav")
        end

        applyPmBtn.DoClick = function()
            if selPmKey ~= "" then
                RunConsoleCommand("cl_playermodel", selPmKey)
                surface.PlaySound("UI/buttonclick.wav")
            end
        end

        -- Section header helper
        local function AddSection(canvas, y, label)
            local hdr = vgui.Create("DPanel", canvas)
            hdr:SetPos(2, y)
            hdr:SetSize(PM_LIST_W - 10, 22)
            hdr.Paint = function(s, pw, ph)
                surface.SetDrawColor(CS2_BORDER)
                surface.DrawRect(0, ph - 1, pw, 1)
                draw.SimpleText(label, "CS2_F4_Section", 0, ph / 2, CS2_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            return y + 26
        end

        -- Card helper
        local function AddCard(canvas, y, entry)
            local btn = vgui.Create("DButton", canvas)
            btn:SetPos(0, y)
            btn:SetSize(PM_LIST_W - 8, PM_CARD_H)
            btn:SetText("")
            btn.Paint = function(s, bw, bh)
                local isSel = (selPmKey == entry.key)
                if isSel then
                    draw.RoundedBox(4, 0, 0, bw, bh, CS2_SEL)
                    surface.SetDrawColor(CS2_SEL_BORD)
                    surface.DrawOutlinedRect(0, 0, bw, bh, 1)
                    draw.SimpleText(entry.name, "CS2_F4_Small", 10, bh / 2, CS2_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                elseif s:IsHovered() then
                    draw.RoundedBox(4, 0, 0, bw, bh, CS2_BTN_HOV)
                    draw.SimpleText(entry.name, "CS2_F4_Small", 10, bh / 2, CS2_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                else
                    draw.RoundedBox(4, 0, 0, bw, bh, CS2_BTN)
                    draw.SimpleText(entry.name, "CS2_F4_Small", 10, bh / 2, CS2_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
            btn.DoClick = function() SelectModel(entry.key, entry.mdl) end
            return y + PM_CARD_H + 2
        end

        -- Populate list
        local canvas = pmList:GetCanvas()
        local curY = 4

        curY = AddSection(canvas, curY, "CT")
        for _, entry in ipairs(ctModels) do
            curY = AddCard(canvas, curY, entry)
        end
        curY = curY + 8

        curY = AddSection(canvas, curY, "T")
        for _, entry in ipairs(tModels) do
            curY = AddCard(canvas, curY, entry)
        end
        curY = curY + 4
        canvas:SetTall(curY)

        -- Init preview with current playermodel
        if selPmKey ~= "" and allModels[selPmKey] then
            mdlPanel:SetModel(allModels[selPmKey])
        end
    end

    -- ========================================================
    -- Вкладка БИНДЫ
    -- ========================================================
    local pBinds = vgui.Create("DPanel", f)
    pBinds:SetPos(contX, contY)
    pBinds:SetSize(contW, contH)
    pBinds:SetVisible(false)
    pBinds.Paint = function() end
    panels["binds"] = pBinds

    do
        -- Список биндов: { label, тип "custom"/"engine", cvarName/cmd, defaultKey }
        local SECTIONS = {
            {
                title = "ИГРОВЫЕ",
                rows = {
                    { label = "Меню закупки",   kind = "custom", cvar = "csm_key_buy",      default = KEY_B   },
                    { label = "Настройки (F4)", kind = "custom", cvar = "csm_key_settings",  default = KEY_F4  },
                },
            },
            {
                title = "ДВИЖЕНИЕ",
                rows = {
                    { label = "Прыжок",        kind = "engine", cmd = "+jump",         default = "SPACE" },
                    { label = "Присесть",      kind = "engine", cmd = "+duck",         default = "CTRL"  },
                    { label = "Тихий шаг",     kind = "engine", cmd = "+speed",        default = "SHIFT" },
                    { label = "Использовать",  kind = "engine", cmd = "+use",          default = "E"     },
                },
            },
            {
                title = "ПРОЧЕЕ",
                rows = {
                    { label = "Голосовой чат", kind = "engine", cmd = "+voicerecord",  default = "V"     },
                    { label = "Таблица счёта", kind = "engine", cmd = "+showscores",   default = "TAB"   },
                    { label = "Фонарик",       kind = "engine", cmd = "impulse 100",   default = "F"     },
                },
            },
        }

        -- Клавиши-модификаторы, которые пропускаем при назначении
        local SKIP_KEYS = {}
        for _, k in ipairs({ KEY_LSHIFT, KEY_RSHIFT, KEY_LCONTROL, KEY_RCONTROL,
                              KEY_LALT, KEY_RALT, KEY_LWIN, KEY_RWIN, KEY_NONE }) do
            SKIP_KEYS[k] = true
        end

        -- Получить текстовое название клавиши для отображения
        local function keyLabel(row)
            if row.kind == "custom" then
                local cv = GetConVar(row.cvar)
                if not cv then return "?" end
                local kn = input.GetKeyName(cv:GetInt())
                return kn and kn:upper() or "?"
            else
                local kn = input.LookupBinding(row.cmd, true)
                return kn and kn:upper() or "—"
            end
        end

        -- Назначить клавишу
        local function applyKey(row, keyIdx, keyName)
            if row.kind == "custom" then
                RunConsoleCommand(row.cvar, tostring(keyIdx))
            else
                game.ConsoleCommand('bind "' .. keyName:lower() .. '" "' .. row.cmd .. '"\n')
            end
        end

        -- Сбросить к дефолту
        local function resetKey(row)
            if row.kind == "custom" then
                RunConsoleCommand(row.cvar, tostring(row.default))
            else
                game.ConsoleCommand('bind "' .. row.default:lower() .. '" "' .. row.cmd .. '"\n')
            end
        end

        -- Состояние ожидания клавиши
        local listening = nil  -- { btn, row, prevText }

        -- Think — ловим нажатие при listening
        pBinds.Think = function(s)
            if not listening then return end
            for i = 1, 159 do
                if SKIP_KEYS[i] then continue end
                if input.IsKeyDown(i) then
                    if i == KEY_ESCAPE then
                        listening.btn:SetText(listening.prevText)
                        listening = nil
                    else
                        local kn = input.GetKeyName(i)
                        if kn then
                            applyKey(listening.row, i, kn)
                            listening.btn:SetText(kn:upper())
                            listening = nil
                        end
                    end
                    return
                end
            end
        end

        -- Scroll panel
        local scroll = vgui.Create("DScrollPanel", pBinds)
        scroll:SetPos(0, 0)
        scroll:SetSize(contW, contH)
        local sb = scroll:GetVBar()
        sb.Paint = function(s, w, h)
            draw.RoundedBox(2, 0, 0, w, h, CS2_BTN)
        end
        sb.btnUp.Paint   = function() end
        sb.btnDown.Paint = function() end
        sb.btnGrip.Paint = function(s, w, h)
            draw.RoundedBox(2, 1, 0, w - 2, h, CS2_ACCENT)
        end

        local canvas = scroll:GetCanvas()
        canvas.Paint = function() end

        local ROW_H    = 36
        local SEC_H    = 26
        local PAD_X    = 12
        local KEY_W    = 90
        local RST_W    = 60
        local curY     = 8

        local function AddSectionHdr(title)
            local lbl = vgui.Create("DLabel", canvas)
            lbl:SetPos(PAD_X, curY + SEC_H * 0.5 - 7)
            lbl:SetSize(contW - PAD_X * 2, 14)
            lbl:SetText(title)
            lbl:SetFont("CS2_F4_Section")
            lbl:SetTextColor(CS2_ACCENT)
            -- separator line
            lbl.Paint = function(s, w, h)
                draw.SimpleText(title, "CS2_F4_Section", 0, h / 2, CS2_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                surface.SetDrawColor(CS2_BORDER)
                local tw = select(1, surface.GetTextSize(title)) + 8
                surface.DrawRect(tw, h / 2, w - tw, 1)
            end
            lbl:SetText("")
            curY = curY + SEC_H + 2
        end

        local function AddRow(row)
            local rowPanel = vgui.Create("DPanel", canvas)
            rowPanel:SetPos(PAD_X, curY)
            rowPanel:SetSize(contW - PAD_X * 2, ROW_H)
            rowPanel.Paint = function(s, w, h)
                draw.RoundedBox(3, 0, 0, w, h, CS2_BTN)
            end

            -- Action label
            local lbl = vgui.Create("DLabel", rowPanel)
            lbl:SetPos(10, 0)
            lbl:SetSize(contW - PAD_X * 2 - KEY_W - RST_W - 30, ROW_H)
            lbl:SetText(row.label)
            lbl:SetFont("CS2_F4_Label")
            lbl:SetTextColor(CS2_TEXT)
            lbl:SetContentAlignment(4)

            -- Key button
            local keyBtn = vgui.Create("DButton", rowPanel)
            local kbX = contW - PAD_X * 2 - KEY_W - RST_W - 4
            keyBtn:SetPos(kbX, (ROW_H - 24) / 2)
            keyBtn:SetSize(KEY_W, 24)
            keyBtn:SetText(keyLabel(row))
            keyBtn:SetFont("CS2_F4_Code")
            keyBtn.Paint = function(s, w, h)
                local isListening = (listening and listening.btn == s)
                local bg = isListening and Color(87, 186, 255, 50) or (s:IsHovered() and CS2_BTN_HOV or CS2_PANEL_LT)
                draw.RoundedBox(3, 0, 0, w, h, bg)
                surface.SetDrawColor(isListening and CS2_ACCENT or CS2_BORDER)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                local col = isListening and CS2_ACCENT or CS2_TEXT
                draw.SimpleText(s:GetText(), "CS2_F4_Code", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            keyBtn.DoClick = function()
                if listening then
                    -- Отменяем предыдущий listening
                    listening.btn:SetText(listening.prevText)
                end
                listening = { btn = keyBtn, row = row, prevText = keyBtn:GetText() }
                keyBtn:SetText("...")
            end

            -- Reset button
            local rstBtn = vgui.Create("DButton", rowPanel)
            rstBtn:SetPos(kbX + KEY_W + 4, (ROW_H - 24) / 2)
            rstBtn:SetSize(RST_W, 24)
            rstBtn:SetText("СБРОС")
            rstBtn:SetFont("CS2_F4_Small")
            rstBtn.Paint = function(s, w, h)
                local bg = s:IsHovered() and CS2_BTN_HOV or CS2_BTN
                draw.RoundedBox(3, 0, 0, w, h, bg)
                draw.SimpleText("СБРОС", "CS2_F4_Small", w / 2, h / 2, CS2_MUTED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            rstBtn.DoClick = function()
                if listening and listening.btn == keyBtn then listening = nil end
                resetKey(row)
                if row.kind == "custom" then
                    keyBtn:SetText(input.GetKeyName(row.default):upper())
                else
                    keyBtn:SetText(row.default:upper())
                end
            end

            curY = curY + ROW_H + 3
        end

        -- Строим UI
        for _, section in ipairs(SECTIONS) do
            AddSectionHdr(section.title)
            for _, row in ipairs(section.rows) do
                AddRow(row)
            end
            curY = curY + 6
        end

        canvas:SetTall(curY + 8)

        -- Сбрасываем listening при закрытии меню
        pBinds.OnRemove = function()
            listening = nil
        end
    end

    -- Открываем первую вкладку
    SwitchTab("crosshair")
end

-- ============================================================
-- F4 — открыть/закрыть
-- ============================================================
local f4WasDown = false
hook.Add("Think", "CSConstruct_F4KeyToggle", function()
    local settKey = (GetConVar("csm_key_settings") and GetConVar("csm_key_settings"):GetInt()) or KEY_F4
    local down = input.IsKeyDown(settKey)
    if down and not f4WasDown then
        if not vgui.GetKeyboardFocus() then
            OpenF4Menu()
        end
    end
    f4WasDown = down
end)
