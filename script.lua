-- TPS Street Soccer | Delta Executor
local _G0 = game:GetService("Players")
local _G1 = game:GetService("RunService")
local _G2 = game:GetService("UserInputService")
local _G3 = game:GetService("TweenService")
local _G4 = game:GetService("Lighting")
local _G5 = game:GetService("StarterGui")

local LP = _G0.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- Bypass: firetouchinterest dolaylı referans
local _fti = pcall(function() return firetouchinterest end) and firetouchinterest or nil
local function _touch(a, b)
    if not _fti then return end
    pcall(_fti, a, b, 0)
    task.wait(0.01 + math.random() * 0.005)
    pcall(_fti, a, b, 1)
end

-- Bypass: rastgele GUI adı (her execute'da farklı)
math.randomseed(tick())
local _gname = "UI_" .. tostring(math.random(10000, 99999))

-- Karakter
local Char, HRP, Hum
local function RefChar()
    Char = LP.Character
    if not Char then return end
    HRP = Char:FindFirstChild("HumanoidRootPart")
    Hum = Char:FindFirstChildOfClass("Humanoid")
end
RefChar()
LP.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    Char = c
    HRP  = c:WaitForChild("HumanoidRootPart")
    Hum  = c:WaitForChild("Humanoid")
    _lastLeg = 0 _lastMoss = 0 _lastR15 = 0
end)

-- Ayarlar
local S = {
    LegOn=false,  LX=5, LY=5, LZ=5,
    MossOn=false, MX=5, MY=5, MZ=5,
    R15On=false,  RX=5, RY=5, RZ=5,
    React="",
    FPS=false, Bright=false, Fog=false, IJ=false,
}

-- Top bul
local function GetBall()
    local sys = workspace:FindFirstChild("TPSSystem")
    if sys then
        local t = sys:FindFirstChild("TPS")
        if t then return t end
    end
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n=="tps" or n:find("ball") or n:find("soccer") then return v end
        end
    end
end

-- Preferred foot
local function GetLeg(char, hum)
    if not char or not hum then return end
    local lit  = _G4:FindFirstChild(LP.Name)
    local pref = lit and lit:FindFirstChild("PreferredFoot")
    local R    = pref and (pref.Value == 1)
    if hum.RigType == Enum.HumanoidRigType.R6 then
        return R and char:FindFirstChild("Right Leg") or char:FindFirstChild("Left Leg")
    else
        return R and char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("LeftLowerLeg")
    end
end

-- Cooldown: topun hızına göre + küçük jitter (bypass)
local function KickCD(ball)
    local ok, spd = pcall(function() return ball.AssemblyLinearVelocity.Magnitude end)
    if not ok then spd = 0 end
    local base = spd < 6 and 0.035 or (spd > 16 and 0.07 or 0.05)
    return base + math.random() * 0.012
end

_lastLeg = 0 _lastMoss = 0 _lastR15 = 0

_G1.RenderStepped:Connect(function()
    if not Char or not HRP or not Hum then return end
    local ball = GetBall() if not ball then return end
    local now  = tick()

    if S.LegOn then
        local d = (HRP.Position - ball.Position).Magnitude
        local r = 2 + S.LX * 0.8 + S.LZ * 0.5
        if d <= r and (now - _lastLeg) >= KickCD(ball) then
            local leg = GetLeg(Char, Hum)
            if leg then _touch(leg, ball) end
            _lastLeg = now
        end
    end

    if S.MossOn then
        local head = Char:FindFirstChild("Head")
        if head then
            local d = (head.Position - ball.Position).Magnitude
            local r = 2 + S.MX * 0.8 + S.MZ * 0.5
            if d <= r and (now - _lastMoss) >= KickCD(ball) then
                _touch(head, ball)
                _lastMoss = now
            end
        end
    end

    if S.R15On then
        local d = (HRP.Position - ball.Position).Magnitude
        local r = 2 + S.RX * 0.8 + S.RZ * 0.5
        if d <= r and (now - _lastR15) >= KickCD(ball) then
            local leg = GetLeg(Char, Hum)
            if leg then _touch(leg, ball) end
            _lastR15 = now
        end
    end
end)

-- React: firetouchinterest bazlı (referans script gibi)
-- Her react kendi menzil yaricapina sahip, top o mesafeye gelince otomatik kick tetikler
local RD = {
    Atzzy   = {range=2.0},
    Jinx    = {range=1.8},
    Azrael  = {range=2.5},
    Tunaz   = {range=3.0},
    Wayz    = {range=1.5},
    ["4v0"] = {range=2.2},
    Yagix   = {range=2.8},
    Daeky   = {range=1.6},
    Vincent = {range=3.2},
    Kitty   = {range=2.4},
}
local _rLast = 0
_G1.RenderStepped:Connect(function()
    if S.React == "" or not Char or not HRP or not Hum then return end
    local def = RD[S.React] if not def then return end
    local ball = GetBall() if not ball then return end
    local now  = tick()
    local dist = (HRP.Position - ball.Position).Magnitude
    if dist <= def.range and (now - _rLast) >= KickCD(ball) then
        local leg = GetLeg(Char, Hum)
        if leg then _touch(leg, ball) end
        _rLast = now
    end
end)

-- Infinite jump
local _ijC
local function ApplyIJ(v)
    if _ijC then _ijC:Disconnect() end
    if v then _ijC = _G2.JumpRequest:Connect(function()
        if Hum then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end) end
end

-- ═══════════════════════════════════════════════
--                  G U I
-- ═══════════════════════════════════════════════

-- Eski varsa temizle
for _,g in pairs(PG:GetChildren()) do
    if g:IsA("ScreenGui") and g.Name:sub(1,3)=="UI_" then g:Destroy() end
end

local SG = Instance.new("ScreenGui")
SG.Name = _gname
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.Parent = PG

-- Renkler (screenshot'a göre)
local BG   = Color3.fromRGB(20,20,20)
local SBC  = Color3.fromRGB(14,14,14)
local CONT = Color3.fromRGB(26,26,26)
local ACC  = Color3.fromRGB(90,150,255)
local TXT  = Color3.fromRGB(230,230,230)
local DIM  = Color3.fromRGB(120,120,120)
local TON  = Color3.fromRGB(60,195,90)
local TOFF = Color3.fromRGB(50,50,50)
local WH   = Color3.fromRGB(255,255,255)
local BOX  = Color3.fromRGB(35,35,35)
local SLB  = Color3.fromRGB(45,45,45)
local RED  = Color3.fromRGB(200,50,50)
local DISC = Color3.fromRGB(88,101,242)
local YTBC = Color3.fromRGB(220,40,40)

local function MkF(p,a)
    local f=Instance.new("Frame") f.BorderSizePixel=0
    for k,v in pairs(a or {}) do pcall(function()f[k]=v end) end
    f.Parent=p return f
end
local function MkL(p,a)
    local l=Instance.new("TextLabel") l.BorderSizePixel=0 l.BackgroundTransparency=1
    for k,v in pairs(a or {}) do pcall(function()l[k]=v end) end
    l.Parent=p return l
end
local function MkB(p,a)
    local b=Instance.new("TextButton") b.BorderSizePixel=0
    for k,v in pairs(a or {}) do pcall(function()b[k]=v end) end
    b.Parent=p return b
end
local function Rnd(o,r) local u=Instance.new("UICorner") u.CornerRadius=UDim.new(0,r) u.Parent=o end
local function Tw(o,pr,t) _G3:Create(o,TweenInfo.new(t or 0.15,Enum.EasingStyle.Quad),pr):Play() end

-- ── Ana Pencere ───────────────────────────────
local Win = MkF(SG, {
    Size     = UDim2.new(0, 500, 0, 310),
    Position = UDim2.new(0.5, -250, 0.5, -155),
    BackgroundColor3 = BG,
    Active   = true,
})
Rnd(Win, 10)

-- ── Title Bar ────────────────────────────────
local TitleBar = MkF(Win, {
    Size             = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = SBC,
})
Rnd(TitleBar, 10)
MkF(TitleBar, {
    Size             = UDim2.new(1, 0, 0, 12),
    Position         = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = SBC,
})

local TitleLbl = MkL(TitleBar, {
    Text      = "RAYY MENU - Home",
    Size      = UDim2.new(1, -70, 1, 0),
    Position  = UDim2.new(0, 35, 0, 0),
    TextColor3 = TXT,
    Font      = Enum.Font.GothamBold,
    TextSize  = 14,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex    = 2,
})

-- Kapat
local CB = MkB(TitleBar, {
    Size             = UDim2.new(0, 26, 0, 26),
    Position         = UDim2.new(1, -32, 0.5, -13),
    BackgroundColor3 = RED,
    Text             = "✕",
    TextColor3       = WH,
    Font             = Enum.Font.GothamBold,
    TextSize         = 12,
    ZIndex           = 3,
})
Rnd(CB, 6)
local shown = true
CB.MouseButton1Click:Connect(function()
    shown = not shown Win.Visible = shown
end)

-- Sürükle (title bar)
do
    local drag, ds, sp = false
    TitleBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true ds=i.Position sp=Win.Position
        end
    end)
    _G2.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds Win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    _G2.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

-- ── Sidebar ───────────────────────────────────
local SBar = MkF(Win, {
    Size             = UDim2.new(0, 110, 1, -36),
    Position         = UDim2.new(0, 0, 0, 36),
    BackgroundColor3 = SBC,
})
-- Ayraç çizgisi
MkF(SBar, {Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,0,0,0),BackgroundColor3=Color3.fromRGB(40,40,40)})

-- ── İçerik ────────────────────────────────────
local CPan = MkF(Win, {
    Size             = UDim2.new(1, -110, 1, -36),
    Position         = UDim2.new(0, 110, 0, 36),
    BackgroundColor3 = CONT,
})
local Scr = Instance.new("ScrollingFrame")
Scr.Size                = UDim2.new(1,0,1,0)
Scr.BackgroundTransparency = 1
Scr.BorderSizePixel     = 0
Scr.ScrollBarThickness  = 3
Scr.ScrollBarImageColor3 = ACC
Scr.CanvasSize          = UDim2.new(0,0,0,1600)
Scr.ScrollingDirection  = Enum.ScrollingDirection.Y
Scr.Parent              = CPan
local Con = MkF(Scr, {Size=UDim2.new(1,-6,0,1600),BackgroundTransparency=1})

-- Y pozisyon
local cY = 14
local function NY(h, g) local y=cY cY=cY+h+(g or 8) return y end

-- Bileşenler
local function MkSec(txt)
    local y = NY(22, 6)
    local f = MkF(Con, {Size=UDim2.new(1,-24,0,22),Position=UDim2.new(0,12,0,y),BackgroundTransparency=1})
    MkL(f, {Text=txt:upper(),Size=UDim2.new(1,0,1,0),TextColor3=ACC,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left})
    MkF(f, {Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=ACC,BackgroundTransparency=0.6})
end

local function MkTog(txt, init, cb)
    local y = NY(42, 6)
    local bx = MkF(Con, {Size=UDim2.new(1,-24,0,42),Position=UDim2.new(0,12,0,y),BackgroundColor3=BOX})
    Rnd(bx, 10)
    -- Sol accent şeridi
    MkF(bx, {Size=UDim2.new(0,3,0.5,0),Position=UDim2.new(0,0,0.25,0),BackgroundColor3=ACC,BackgroundTransparency=0.3})
    MkL(bx, {Text=txt,Size=UDim2.new(1,-64,1,0),Position=UDim2.new(0,14,0,0),TextColor3=TXT,Font=Enum.Font.GothamSemibold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left})
    local TW,TH = 46,26
    local trk = MkF(bx, {Size=UDim2.new(0,TW,0,TH),Position=UDim2.new(1,-(TW+10),0.5,-TH/2),BackgroundColor3=init and TON or TOFF})
    Rnd(trk, 13)
    local KS = 20
    local knob = MkF(trk, {Size=UDim2.new(0,KS,0,KS),Position=init and UDim2.new(0,TW-KS-3,0.5,-KS/2) or UDim2.new(0,3,0.5,-KS/2),BackgroundColor3=WH})
    Rnd(knob, 10)
    local st = init
    MkB(bx, {Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""}).MouseButton1Click:Connect(function()
        st = not st
        Tw(trk,  {BackgroundColor3=st and TON or TOFF})
        Tw(knob, {Position=st and UDim2.new(0,TW-KS-3,0.5,-KS/2) or UDim2.new(0,3,0.5,-KS/2)})
        cb(st)
    end)
end

local function MkSld(txt, mn, mx, ini, cb)
    local y = NY(64, 6)
    local bx = MkF(Con, {Size=UDim2.new(1,-24,0,64),Position=UDim2.new(0,12,0,y),BackgroundColor3=BOX})
    Rnd(bx, 10)
    MkF(bx, {Size=UDim2.new(0,3,0.5,0),Position=UDim2.new(0,0,0.25,0),BackgroundColor3=ACC,BackgroundTransparency=0.3})
    MkL(bx, {Text=txt,Size=UDim2.new(0.65,0,0,22),Position=UDim2.new(0,14,0,9),TextColor3=TXT,Font=Enum.Font.GothamSemibold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left})
    local vl = MkL(bx, {Text=tostring(ini),Size=UDim2.new(0.3,-4,0,22),Position=UDim2.new(0.7,0,0,9),TextColor3=ACC,Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Right})
    local sbg = MkF(bx, {Size=UDim2.new(1,-28,0,6),Position=UDim2.new(0,14,0,44),BackgroundColor3=SLB})
    Rnd(sbg, 3)
    local p0 = (ini-mn)/(mx-mn)
    local fill = MkF(sbg, {Size=UDim2.new(p0,0,1,0),BackgroundColor3=ACC}) Rnd(fill,3)
    local kn   = MkF(sbg, {Size=UDim2.new(0,16,0,16),Position=UDim2.new(p0,-8,0.5,-8),BackgroundColor3=WH}) Rnd(kn,8)
    local drag = false
    local function upd(x)
        local p = math.clamp((x-sbg.AbsolutePosition.X)/sbg.AbsoluteSize.X,0,1)
        local v = math.floor(mn+(mx-mn)*p+0.5)
        fill.Size=UDim2.new(p,0,1,0) kn.Position=UDim2.new(p,-8,0.5,-8) vl.Text=tostring(v) cb(v)
    end
    sbg.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true upd(i.Position.X) end
    end)
    _G2.InputChanged:Connect(function(i)
        if drag and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end
    end)
    _G2.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

-- ── Tab Sistemi ───────────────────────────────
local Tabs   = {}
local CurTab = nil
local sbY    = 6

local function RegTab(name, bld)
    local btn = MkB(SBar, {
        Size             = UDim2.new(1, 0, 0, 34),
        Position         = UDim2.new(0, 0, 0, sbY),
        BackgroundColor3 = SBC,
        Text             = name,
        TextColor3       = DIM,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
    })
    sbY = sbY + 35
    Tabs[name] = {btn=btn, bld=bld}

    btn.MouseButton1Click:Connect(function()
        if CurTab == name then return end
        if CurTab and Tabs[CurTab] then
            Tw(Tabs[CurTab].btn, {BackgroundColor3=SBC, TextColor3=DIM})
        end
        CurTab = name
        TitleLbl.Text = "RAYY MENU - " .. name
        Tw(btn, {BackgroundColor3=Color3.fromRGB(30,30,30), TextColor3=TXT})
        for _,ch in pairs(Con:GetChildren()) do
            if not ch:IsA("UIPadding") then ch:Destroy() end
        end
        cY = 12
        Scr.CanvasPosition = Vector2.new(0,0)
        bld()
    end)
    btn.MouseEnter:Connect(function() if CurTab~=name then Tw(btn,{BackgroundColor3=Color3.fromRGB(22,22,22)}) end end)
    btn.MouseLeave:Connect(function() if CurTab~=name then Tw(btn,{BackgroundColor3=SBC}) end end)
end

-- ═══ TAB İÇERİKLERİ ════════════════════════════

-- HOME
local function BldHome()
    -- Avatar dairesi (ortalanmış)
    local ay = NY(80, 6)
    local av = Instance.new("ImageLabel")
    av.Size             = UDim2.new(0,72,0,72)
    av.Position         = UDim2.new(0.5,-36,0,ay)
    av.BackgroundColor3 = Color3.fromRGB(80,80,80)
    av.BorderSizePixel  = 0
    av.Image            = "rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=150&h=150"
    av.Parent           = Con
    Rnd(av, 36)

    -- Owner etiketi
    local oy = NY(22, 8)
    MkL(Con, {
        Text      = "Owner: Rayy",
        Size      = UDim2.new(1,-20,0,22),
        Position  = UDim2.new(0,10,0,oy),
        TextColor3 = TXT,
        Font      = Enum.Font.GothamBold,
        TextSize  = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    -- Sosyal butonlar (ekran görüntüsüne göre: D / Y prefix)
    local socs = {
        {"D", "Discord Server",  DISC},
        {"Y", "Youtube Channel", YTBC},
    }
    for _, s in ipairs(socs) do
        local sy = NY(46, 6)
        local bx = MkB(Con, {
            Size             = UDim2.new(1,-20,0,46),
            Position         = UDim2.new(0,10,0,sy),
            BackgroundColor3 = BOX,
            Text             = "",
        })
        Rnd(bx, 8)
        -- Sol harf kutusu
        local lbox = MkF(bx, {
            Size             = UDim2.new(0,46,1,0),
            BackgroundColor3 = Color3.fromRGB(28,28,28),
        })
        Rnd(lbox, 8)
        MkF(lbox, {Size=UDim2.new(0,6,1,0),Position=UDim2.new(1,-6,0,0),BackgroundColor3=Color3.fromRGB(28,28,28)})
        MkL(lbox, {
            Text      = s[1],
            Size      = UDim2.new(1,0,1,0),
            TextColor3 = s[3],
            Font      = Enum.Font.GothamBold,
            TextSize  = 18,
            TextXAlignment = Enum.TextXAlignment.Center,
        })
        -- Sağ metin
        MkL(bx, {
            Text      = s[2],
            Size      = UDim2.new(1,-60,1,0),
            Position  = UDim2.new(0,54,0,0),
            TextColor3 = TXT,
            Font      = Enum.Font.GothamSemibold,
            TextSize  = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        bx.MouseEnter:Connect(function() Tw(bx,{BackgroundColor3=Color3.fromRGB(42,42,42)}) end)
        bx.MouseLeave:Connect(function() Tw(bx,{BackgroundColor3=BOX}) end)
    end
end

-- LEG REACH
local function BldLeg()
    MkSec("Leg Reach")
    MkTog("Leg Reach Aktif", S.LegOn, function(v) S.LegOn=v _lastLeg=0 end)
    MkSec("Menzil (1-10)")
    MkSld("X - Yatay",  1,10,S.LX, function(v) S.LX=v end)
    MkSld("Y - Dikey",  1,10,S.LY, function(v) S.LY=v end)
    MkSld("Z - Derinlik",1,10,S.LZ,function(v) S.LZ=v end)
end

-- MOSS REACH
local function BldMoss()
    MkSec("Moss Reach - Kafa")
    MkTog("Moss Reach Aktif", S.MossOn, function(v) S.MossOn=v _lastMoss=0 end)
    MkSec("Menzil (1-10)")
    MkSld("X - Yatay",  1,10,S.MX, function(v) S.MX=v end)
    MkSld("Y - Dikey",  1,10,S.MY, function(v) S.MY=v end)
    MkSld("Z - Derinlik",1,10,S.MZ,function(v) S.MZ=v end)
end

-- PLAYERS REACT
local function BldReact()
    MkSec("Top Vurus Reactlari")
    -- Aktif react bilgisi (range açıklaması)
    local infoY = NY(20, 4)
    MkL(Con, {Text="Sec: top yaklasinca otomatik kick tetikler",
        Size=UDim2.new(1,-20,0,20),Position=UDim2.new(0,10,0,infoY),
        TextColor3=DIM,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left})

    local rlist = {"Atzzy","Jinx","Azrael","Tunaz","Wayz","4v0","Yagix","Daeky","Vincent","Kitty"}
    local TW, TH, KS = 44, 24, 18
    local tRefs = {}

    for _, rn in ipairs(rlist) do
        local isOn = (S.React == rn)   -- tab yeniden acilsa bile state korunur
        local ry = NY(36, 5)
        local bx = MkF(Con, {Size=UDim2.new(1,-20,0,36),Position=UDim2.new(0,10,0,ry),
            BackgroundColor3= isOn and Color3.fromRGB(28,36,28) or BOX})
        Rnd(bx, 8)
        -- Range etiketi (kücük, sağda)
        local rangeTxt = tostring(RD[rn] and RD[rn].range or "?").." st"
        MkL(bx, {Text=rn,Size=UDim2.new(1,-90,1,0),Position=UDim2.new(0,12,0,0),
            TextColor3=TXT,Font=Enum.Font.GothamSemibold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left})
        MkL(bx, {Text=rangeTxt,Size=UDim2.new(0,38,1,0),Position=UDim2.new(1,-(TW+8+42),0,0),
            TextColor3=DIM,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right})
        local trk = MkF(bx, {Size=UDim2.new(0,TW,0,TH),Position=UDim2.new(1,-(TW+8),0.5,-TH/2),
            BackgroundColor3= isOn and TON or TOFF})
        Rnd(trk, 12)
        local knob = MkF(trk, {Size=UDim2.new(0,KS,0,KS),
            Position= isOn and UDim2.new(0,TW-KS-3,0.5,-KS/2) or UDim2.new(0,3,0.5,-KS/2),
            BackgroundColor3=WH})
        Rnd(knob, 9)
        tRefs[rn] = {trk=trk, knob=knob, bx=bx}

        MkB(bx, {Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""}).MouseButton1Click:Connect(function()
            local was = (S.React == rn)
            -- hepsini kapat
            S.React = ""
            for _, ref in pairs(tRefs) do
                Tw(ref.trk,  {BackgroundColor3=TOFF})
                Tw(ref.knob, {Position=UDim2.new(0,3,0.5,-KS/2)})
                Tw(ref.bx,   {BackgroundColor3=BOX})
            end
       
