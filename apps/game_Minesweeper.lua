local component = require("component")
local gpu = component.gpu
local event = require("event")
local term = require("term")
local unicode = require("unicode")
local computer = require("computer")

local BOMB_COUNT= 5 -- 6 мин = 40% на победу, 5 мин 47% на победу
local BET = 3
local player = ""

fieldtypes = {
  ["clear"] = 0x98df94,
  ["close"] = 0xd0d0d0,
  ["bomb"] = 0xff0000, 
  ["closebomb"] = 0xff0000,
}
gpu.setResolution(78,39)
gpu.setBackground(0xe0e0e0)
term.clear()
gpu.setBackground(0xffffff)
gpu.fill(3,2,74,37," ")
gpu.setForeground(0x00a000)
gpu.set(4,29,"Правила игры и награды:")
gpu.setForeground(0x000000)
gpu.set(4,30,"Начинайте игру и ищите поля без мин. Если 3 раза")
gpu.set(4,31,"подряд не наткнулись на поле с миной, то вы" )
gpu.set(4,32,"победили. Всего в игре 24 поля, из которых 5 ")
gpu.set(4,33,"заминированы. Игра стоит ".. BET .." дюр, а победа прино-")
gpu.set(4,34,"сит ".. (BET*2) .." дюр.")
gpu.set(4,37,"Разработчик: krovyaka, Валюта: Durex77, Идея: GG")
gpu.setBackground(0xe0e0e0)
gpu.fill(1,27,76,1," ")
gpu.fill(54,27,2,12," ")
gpu.setBackground(0x90ef7e)
gpu.fill(58,29,17,9," ")

Animations = {
  ["load"] = function()
    for i = 1,24 do
      drawField(i,"clear")
      os.sleep()
      drawField(i,"close")
    end
  end,
  
  ["reveal"] = function()
    for i = 0,3 do
      for j = 1,6 do
        drawField(j+i*6,"clear")
      end
      os.sleep(0.1)
      for j = 1,6 do
        if(Fields[j+i*6]=="closebomb") then
          drawField(j+i*6,"bomb")
        else
          drawField(j+i*6,"close")
        end
      end
    end
    os.sleep(1)
    for i = 0,3 do
      for j = 1,6 do
        drawField(j+i*6,"clear")
      end
      os.sleep(0.1)
      for j = 1,6 do
        drawField(j+i*6,"close")
      end
    end
  end,
  ["error"] = function()
    for i = 1, 2 do
      gpu.setBackground(0xff0000)
      gpu.fill(58,29,17,9," ")
      os.sleep(0.1)
      gpu.setBackground(0x90ef7e)
      gpu.fill(58,29,17,9," ")
      os.sleep(0.1)
    end
    gpu.set(61,33,"Начать игру")    
  end  
}

Fields = {}
function generateFields() 
  Fields = {}
  for i = 1, 24 do Fields[i] = "close" end
  local i = 0
  while i < BOMB_COUNT
 do
    local rand = math.random(1,24)
    if(Fields[rand] ~= "closebomb") then
      Fields[rand] = "closebomb"
      i = i + 1
    end    
  end
end

function getBombPos(x) return 5+((x-1)%6)*12, 3+math.floor((x-1)/6)*6 end
function getBombId(left,top)
  if(((left-3)%12) == 0) or (((left-4)%12) == 0) or (((top-2)%6)==0) then return 0 end
  return (math.floor((top-3)/6)*6) + math.floor((left+7)/12)
end

local symb = string.rep(unicode.char(0xE0BF),2)
function drawField(x,ftype)
  gpu.setBackground(fieldtypes[ftype])
  posx,posy = getBombPos(x)
  gpu.fill(posx,posy,10,5," ")  
  if(ftype == "bomb") then
    gpu.set(posx,posy+0,symb .. "      " .. symb)
    gpu.set(posx,posy+1,"  \\    /  ")
    gpu.set(posx,posy+2,"    " .. symb .. "    ")
    gpu.set(posx,posy+3,"  /    \\  ")
    gpu.set(posx,posy+4,symb .. "      " .. symb)
  end
end

Animations.load()
Animations.error()
local attempts,ending = 0,0
while true do
  local _,_,left,top,_,p = event.pull("touch")
  if(left >= 58) and (left <= 75) and (top >= 29) and (top <= 38) then 
    if(Connector:pay(p,BET)) then
      player = p
      generateFields()
      gpu.setBackground(0xffa500)
      gpu.fill(58,29,17,9," ")
      gpu.set(61,32,"Идёт игра у")
      gpu.set(66-math.floor(string.len(player)/2),33,player)
      local balance = Connector:get(player) .. " $"
      gpu.set(66-math.floor(string.len(balance)/2),34,balance)
      attempts,ending = 3,os.time()+2160
      while attempts>0 do
        local _,_,left2,top2,_,p = event.pull(3,"touch")
        if(p==player) and (left2~=nil) then
          local id = getBombId(left2,top2)
          if(id>0) then
            if(Fields[id] == "close") then drawField(id,"clear") Fields[id]="clear" attempts = attempts - 1
            end
            if(Fields[id] == "closebomb") then drawField(id,"bomb") attempts = -1
            end
          end
        end
        if(os.time() > ending) then attempts = -1 end
      end
      if(attempts == 0) then Connector:give(player,BET*2) end
      os.sleep(0.7)
      Animations.reveal()
      gpu.setBackground(0x90ef7e)
      gpu.fill(58,29,17,9," ")
      gpu.set(58,33,"   Начать игру   ")
    else
      Animations.error()
    end
  end
end