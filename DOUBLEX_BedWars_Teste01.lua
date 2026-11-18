-- DOUBLEX HUB BedWars - Teste 01 (Delta Mobile)
-- Diagnostico local de alvos. Nao realiza ataques.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local CoreGui = game:GetService('CoreGui')
local player = Players.LocalPlayer
local old = CoreGui:FindFirstChild('DOUBLEX_BEDWARS_TEST01')
if old then old:Destroy() end
local gui = Instance.new('ScreenGui')
gui.Name = 'DOUBLEX_BEDWARS_TEST01'
gui.ResetOnSpawn = false
gui.Parent = CoreGui
local frame = Instance.new('Frame')
frame.Size = UDim2.fromOffset(260, 164)
frame.Position = UDim2.new(0.5, -130, 0.28, 0)
frame.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new('UICorner', frame).CornerRadius = UDim.new(0, 12)
local function label(text, y, height)
 local x = Instance.new('TextLabel')
 x.BackgroundTransparency = 1
 x.Size = UDim2.new(1, -20, 0, height)
 x.Position = UDim2.fromOffset(10, y)
 x.Text = text
 x.TextColor3 = Color3.new(1,1,1)
 x.TextSize = 14
 x.Font = Enum.Font.GothamBold
 x.TextWrapped = true
 x.Parent = frame
 return x
end
label('DOUBLEX | BedWars TESTE 01', 8, 24)
local status = label('Deteccao desligada', 39, 55)
local toggle = Instance.new('TextButton')
toggle.Size = UDim2.fromOffset(165, 36)
toggle.Position = UDim2.fromOffset(12, 112)
toggle.BackgroundColor3 = Color3.fromRGB(35, 140, 90)
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.Text = 'ATIVAR TESTE'
toggle.Parent = frame
Instance.new('UICorner', toggle).CornerRadius = UDim.new(0, 8)
local close = Instance.new('TextButton')
close.Size = UDim2.fromOffset(55, 36)
close.Position = UDim2.fromOffset(190, 112)
close.BackgroundColor3 = Color3.fromRGB(140, 45, 55)
close.TextColor3 = Color3.new(1,1,1)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Text = 'X'
close.Parent = frame
Instance.new('UICorner', close).CornerRadius = UDim.new(0, 8)
local enabled = false
local connection
local function stop()
 enabled = false
 toggle.Text = 'ATIVAR TESTE'
 status.Text = 'Deteccao desligada'
 if connection then connection:Disconnect() connection = nil end
end
local function update()
 local character = player.Character
 local root = character and character:FindFirstChild('HumanoidRootPart')
 if not root then status.Text = 'Aguardando personagem...' return end
 local nearest, distance
 local total = 0
 for _, other in ipairs(Players:GetPlayers()) do
  if other ~= player then
   local c = other.Character
   local r = c and c:FindFirstChild('HumanoidRootPart')
   local h = c and c:FindFirstChildOfClass('Humanoid')
   local allied = player.Team ~= nil and other.Team ~= nil and player.Team == other.Team
   if r and h and h.Health > 0 and not allied then
    local d = (r.Position - root.Position).Magnitude
    if d <= 15 then
     total = total + 1
     if not distance or d < distance then nearest, distance = other, d end
    end
   end
  end
 end
 if nearest then
  status.Text = string.format('Alvos no raio: %d\nMais proximo: %s (%.1f studs)', total, nearest.DisplayName, distance)
 else
  status.Text = 'Nenhum alvo a ate 15 studs\n(Aliados ignorados quando Team existe)'
 end
end
toggle.MouseButton1Click:Connect(function()
 if enabled then stop() return end
 enabled = true
 toggle.Text = 'DESATIVAR'
 update()
 local elapsed = 0
 connection = RunService.Heartbeat:Connect(function(dt)
  elapsed = elapsed + dt
  if elapsed >= 0.25 then elapsed = 0 update() end
 end)
end)
close.MouseButton1Click:Connect(function() stop() gui:Destroy() end)
