-- DOUBLEX HUB BedWars - Teste 02
-- Teste experimental de ativacao da ferramenta equipada.
-- Nao modifica dano, alcance do servidor ou remotes do jogo.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local player = Players.LocalPlayer
local old = player:WaitForChild('PlayerGui'):FindFirstChild('DOUBLEX_BW_TESTE02')
if old then old:Destroy() end
local gui = Instance.new('ScreenGui')
gui.Name = 'DOUBLEX_BW_TESTE02'
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui
local frame = Instance.new('Frame')
frame.Size = UDim2.fromOffset(290, 182)
frame.Position = UDim2.new(1,-306,0.52,-91)
frame.BackgroundColor3 = Color3.fromRGB(22,26,39)
frame.Parent = gui
Instance.new('UICorner',frame).CornerRadius = UDim.new(0,12)
local function label(text,y,height)
 local l=Instance.new('TextLabel')
 l.Size=UDim2.new(1,-20,0,height or 28)
 l.Position=UDim2.fromOffset(10,y)
 l.BackgroundTransparency=1
 l.TextColor3=Color3.new(1,1,1)
 l.TextScaled=true
 l.Font=Enum.Font.GothamBold
 l.Text=text
 l.Parent=frame
 return l
end
label('DOUBLEX | BedWars TESTE 02',8,26)
local status=label('Desativado',45,40)
local detail=label('Alcance: 15 studs',88,25)
local toggle=Instance.new('TextButton')
toggle.Size=UDim2.fromOffset(195,42)
toggle.Position=UDim2.fromOffset(10,130)
toggle.BackgroundColor3=Color3.fromRGB(35,145,96)
toggle.TextColor3=Color3.new(1,1,1)
toggle.Font=Enum.Font.GothamBold
toggle.TextScaled=true
toggle.Text='ATIVAR'
toggle.Parent=frame
Instance.new('UICorner',toggle).CornerRadius=UDim.new(0,9)
local close=Instance.new('TextButton')
close.Size=UDim2.fromOffset(65,42)
close.Position=UDim2.fromOffset(215,130)
close.BackgroundColor3=Color3.fromRGB(155,54,67)
close.TextColor3=Color3.new(1,1,1)
close.Text='X'
close.TextScaled=true
close.Parent=frame
Instance.new('UICorner',close).CornerRadius=UDim.new(0,9)
local enabled=false
local running=true
local radius=15
local lastAttack=0
local function getTarget()
 local char=player.Character
 local root=char and char:FindFirstChild('HumanoidRootPart')
 local humanoid=char and char:FindFirstChildOfClass('Humanoid')
 if not root or not humanoid or humanoid.Health<=0 then return nil,nil,'Aguardando personagem...' end
 local best,dist=nil,radius
 for _,other in ipairs(Players:GetPlayers()) do
  if other~=player and (not player.Team or not other.Team or other.Team~=player.Team) then
   local c=other.Character
   local r=c and c:FindFirstChild('HumanoidRootPart')
   local h=c and c:FindFirstChildOfClass('Humanoid')
   if r and h and h.Health>0 then
    local d=(r.Position-root.Position).Magnitude
    if d<=dist then best=other;dist=d end
   end
  end
 end
 return best,dist,nil
end
toggle.MouseButton1Click:Connect(function()
 enabled=not enabled
 toggle.Text=enabled and 'DESATIVAR' or 'ATIVAR'
 toggle.BackgroundColor3=enabled and Color3.fromRGB(160,95,38) or Color3.fromRGB(35,145,96)
end)
close.MouseButton1Click:Connect(function() running=false;enabled=false;gui:Destroy() end)
task.spawn(function()
 while running and gui.Parent do
  if enabled then
   local target,d,err=getTarget()
   if err then status.Text=err;detail.Text='Sem personagem ativo'
   elseif target then
    status.Text='Alvo: '..target.Name
    local char=player.Character
    local tool=char and char:FindFirstChildOfClass('Tool')
    detail.Text=string.format('Distancia: %.1f | Arma: %s',d,tool and tool.Name or 'nenhuma')
    if tool and os.clock()-lastAttack>=0.35 then
     lastAttack=os.clock()
     pcall(function() tool:Activate() end)
    end
   else status.Text='Nenhum inimigo no raio';detail.Text='Alcance: 15 studs' end
  else status.Text='Desativado';detail.Text='Alcance: 15 studs' end
  task.wait(0.15)
 end
end)
