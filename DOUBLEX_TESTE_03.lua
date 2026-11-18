-- DOUBLEX HUB | TESTE 03 | Delta Android
-- Diagnostico local: arma, jogador proximo e alteracoes de vida.
-- Nao executa ataques automaticos.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("DOUBLEX_TESTE_03")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "DOUBLEX_TESTE_03"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = pg

local function rounded(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
end

local bubble = Instance.new("TextButton")
bubble.Name = "Abrir"
bubble.Size = UDim2.fromOffset(48, 48)
bubble.Position = UDim2.new(0, 12, 0.4, 0)
bubble.BackgroundColor3 = Color3.fromRGB(26, 33, 50)
bubble.TextColor3 = Color3.new(1,1,1)
bubble.Text = "DX"
bubble.TextSize = 17
bubble.Font = Enum.Font.GothamBold
bubble.Parent = gui
rounded(bubble, 24)

local panel = Instance.new("Frame")
panel.Name = "Painel"
panel.Size = UDim2.fromOffset(230, 174)
panel.Position = UDim2.new(0, 65, 0.35, 0)
panel.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
panel.Visible = false
panel.Parent = gui
rounded(panel, 12)

local header = Instance.new("TextButton")
header.Size = UDim2.new(1, -64, 0, 34)
header.Position = UDim2.fromOffset(8, 3)
header.BackgroundTransparency = 1
header.Text = "DOUBLEX | TESTE 03"
header.TextColor3 = Color3.new(1,1,1)
header.Font = Enum.Font.GothamBold
header.TextSize = 12
header.Parent = panel

local function btn(text, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(26, 26)
    b.Position = UDim2.new(1, x, 0, 6)
    b.BackgroundColor3 = Color3.fromRGB(48, 54, 72)
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 15
    b.Parent = panel
    rounded(b, 7)
    return b
end
local minimize = btn("−", -60)
local close = btn("×", -30)

local info = Instance.new("TextLabel")
info.Position = UDim2.fromOffset(12, 40)
info.Size = UDim2.new(1, -24, 1, -50)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(225, 234, 250)
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Font = Enum.Font.Code
info.TextSize = 12
info.TextWrapped = true
info.Text = "Aguardando personagem..."
info.Parent = panel

local alive = true
bubble.MouseButton1Click:Connect(function() panel.Visible = not panel.Visible end)
minimize.MouseButton1Click:Connect(function() panel.Visible = false end)
close.MouseButton1Click:Connect(function() alive = false gui:Destroy() end)

local function draggable(handle, target)
    local dragging, startPos, startInput
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = target.Position
            startInput = input.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not dragging or not startInput then return end
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d = input.Position - startInput
        target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end)
end
draggable(bubble, bubble)
draggable(header, panel)

local lastHealth = {}
local lastChange = "Nenhuma alteracao observada"
local elapsed = 0
local conn
conn = RunService.Heartbeat:Connect(function(dt)
    if not alive or not gui.Parent then if conn then conn:Disconnect() end return end
    elapsed = elapsed + dt
    if elapsed < 0.3 then return end
    elapsed = 0
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local tool = char and char:FindFirstChildOfClass("Tool")
    local backpack = player:FindFirstChildOfClass("Backpack")
    local backpackCount = 0
    if backpack then
        for _, obj in ipairs(backpack:GetChildren()) do
            if obj:IsA("Tool") then backpackCount = backpackCount + 1 end
        end
    end
    local closest, dist
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local oc = other.Character
            local hrp = oc and oc:FindFirstChild("HumanoidRootPart")
            local hum = oc and oc:FindFirstChildOfClass("Humanoid")
            if root and hrp and hum and hum.Health > 0 then
                local d = (root.Position - hrp.Position).Magnitude
                if not dist or d < dist then closest, dist = other, d end
                local previous = lastHealth[other.UserId]
                if previous and math.abs(previous - hum.Health) > 0.01 then
                    lastChange = other.DisplayName .. ": " .. math.floor(previous) .. " -> " .. math.floor(hum.Health)
                end
                lastHealth[other.UserId] = hum.Health
            end
        end
    end
    local toolName = tool and tool.Name or "Nenhuma Tool equipada"
    local targetName = closest and closest.DisplayName or "Nenhum"
    local distance = dist and string.format("%.1f studs", dist) or "--"
    info.Text = "Arma: " .. toolName .. "\n" ..
        "Tools mochila: " .. backpackCount .. "\n" ..
        "Proximo: " .. targetName .. "\n" ..
        "Distancia: " .. distance .. "\n" ..
        "Vida observada:\n" .. lastChange .. "\n\n" ..
        "Ataque automatico: DESLIGADO"
end)
