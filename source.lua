-- title:  Bug Knight
-- author: Istvan and Szabi
-- desc:   platformer
-- script: lua
-- date:   2021-11-15
-- twitter:@pisti72
-- jam: https://itch.io/jam/game-off-2021

--DEBUG=true
DEBUG=false



ALPHA=0
SKIN=0
LIGHTBROWN=1
BROWN=2
DARKBROWN=3
DARKRED=4
RED=5
ORANGE=6
YELLOW=7
LIGHTGREEN=8
GREEN=9
DARKGREEN=10
GREY=11
LIGHTGREY=12
WHITE=13
CYAN=14
BLUE=15

UP   =0
DOWN =1
RIGHT=2
LEFT =3
BTN_A=4
BTN_B=5
BTN_X=6
BTN_Y=7

BTN_A_GFX=170

GRAVITY=.1
GRAVITY_MAX=2

BOTTOM=120

MAP_WIDTH=50
MAP_HEIGHT=50

MAX_LIVES=5

PLATFORM_SPEED=.5
PLATFORM_Y=5
CANNON_RELOAD=100

TILE=16
HALFTILE=TILE/2

DIALOGS={
	{"HELLO KNIGHT",
	 "HELLO SIGN"},
		
	{"HI!\nI AM AGAIN"},
	
	{"THIS MY THIRD",
	 "Tell me! What you want?",
		"Just take care",
		"Ok.Bye!"},
	{"Hello,\nI am 1","HI! I am the Great Knight!"},
	{"Hello,\nI am 2","HI! I am the Great Knight!"},
	{"Hello,\nI am 3","HI! I am the Great Knight!"},
	{"Hello,\nI am 4","HI! I am the Great Knight!"},
	{"Hello,\nI am 5","HI! I am the Great Knight!"},
	{"Hello,\nI am 6","HI! I am the Great Knight!"},
	{"Hello,\nI am 7","HI! I am the Great Knight!"},
}

flr=math.floor
abs=math.abs

cam={
 x=0,
 y=0,
 xd=0,
 yd=0,
 speed=.01
}

IDLE=0
RUNNING=1
ONLADDER=2
ONPLATFORM=3



p1={
 x=1,
 y=1,
 xd=0,
 yd=0,
 mode=IDLE,
 jump_force=2.5,
 points={
  {x=4,y=15,ground=true},
  {x=11,y=15,ground=true},
  {x=7,y=7,ground=false}
 },
 alpha=0,
 live=true,
 lives=MAX_LIVES,
 on_ground=false,
 idle={288,290,292,290},
 run={256,258,260,262,264},
 small=5,
 flip=0,
 lastpos={},
 platform={
 	on=false
 }
}

NONE=0
SIGN=1
SPIKE=2
PLATFORM=3
LADDER=4
CHECKPOINT=5
BALE=6
VAMPIRETON=7
BALLJR=8
CANNON=9
CANNONBALL=10
EVILBUG1=11
EVILBUG2=12
BIRD=13
STONE=14
MUSHROOM=15
BUSH=16
BIGBUG=17

actors_db={
 {
  name=SPIKE,
  small=7,
  idle={294,326},
 },
 {
  name=PLATFORM,
  small=9,
  idle={328},
 },
 {
  name=LADDER,--TBD
  small=1007,
  idle={1000},
 },
 {
  name=SIGN,
  small=6,
  idle={388},
  id=999
 },
 {
  name=CHECKPOINT,
  small=10,
  idle={330},
  id=999
 },
 {
  name=BALE,
  small=11,
  idle={356}
 },
 {
  name=VAMPIRETON,
  small=1000,
  idle={1000}
 },
 {
  name=BALLJR,
  small=12,
  idle={352}
 },
 {
  name=CANNON,
  small=8,
  idle={358}
 },
 {
  name=CANNONBALL,
  small=1000,
  idle={1000}
 },
 {
  name=EVILBUG1,
  small=1000,
  idle={1000}
 },
 {
  name=EVILBUG2,
  small=1000,
  idle={1000}
 },
 {
  name=BIRD,
  small=1000,
  idle={1000}
 },
 {
  name=STONE,
  small=1000,
  idle={1000}
 },
 {
  name=MUSHROOM,
  small=1000,
  idle={1000}
 },
 {
  name=BUSH,
  small=1000,
  idle={1000}
 },
 {
  name=BIGBUG,
  small=1000,
  idle={1000}
 }
}

talking={
	counter=0
}

TITLE=0
INGAME=1
TALKING=2
FAILED=3
READING=4
READING_END=5
GAMEOVER=6

state=TITLE
--state=FAILED
--state=GAMEOVER

actors={}

t=0

function init_actors()
 local id=0
 for y=0,MAP_HEIGHT do
  for x=0,MAP_WIDTH do
   if mget(x,y)==p1.small then
    p1.x=TILE*x
    p1.y=TILE*y
    p1.lastpos.x=p1.x
    p1.lastpos.y=p1.y
    mset(x,y,0)
   end
   
   for i,v in ipairs(actors_db) do
    if mget(x,y)==v.small then
     if v.name==SIGN or v.name==BALE or v.name==BALLJR then
      id=id+1
      v.id=id
     elseif v.name==PLATFORM then
      v.xd=PLATFORM_SPEED
     elseif v.name==CANNON then
      v.reload=0
     end
     add_actor(v,x,y)
     mset(x,y,0)
    end
   end
  end
 end
end

function add_actor(e,x,y)
 actor={
  name=e.name,
  idle=e.idle,
  reload=e.reload,
  id=e.id,
  xd=e.xd,
  x=x*TILE,
  y=y*TILE
 }
 table.insert(actors,actor)
end

function border(c)
 poke(0x03FF8, c)
end

border(3)
init_actors()

function update_actors()
 p1.nearby=NONE
 p1.platform.on=false
 for i,v in ipairs(actors) do
  if abs(v.x-p1.x)<HALFTILE and 
   abs(v.y-p1.y)<HALFTILE and 
   p1.live and 
   state==INGAME then	 
   if v.name==SIGN or v.name==BALE or v.name==BALLJR then
    talking.n=1
    talking.to=v.name
    talking.texts=DIALOGS[v.id] 
    p1.nearby=v.name
   elseif v.name==SPIKE or v.name==CANNONBALL then
    kill_knight()
   elseif v.name==PLATFORM then
    p1.yd=0
    p1.mode=ONPLATFORM
    p1.y=v.y-PLATFORM_Y
    p1.platform={
     on=true,
     xd=v.xd
    }
   elseif v.name==CHECKPOINT then
    p1.lastpos.x=v.x
    p1.lastpos.y=v.y
    p1.nearby=v.name
   end
  end
  
  --TODO only if they are close
  if v.name==PLATFORM then
   if mget(flr((v.x+v.xd)/TILE),flr(v.y/TILE))~=0 or
      mget(flr((v.x+v.xd+TILE-1)/TILE),flr(v.y/TILE))~=0 then
    v.xd=-v.xd
   end
   v.x=v.x+v.xd
  elseif v.name==CANNON then
   if v.reload>0 then
    v.reload=v.reload-1
   else
    v.reload=CANNON_RELOAD
    local e={}
    e.name=CANNONBALL
    e.idle={360,362,364}
    x=(v.x-HALFTILE)/TILE
    y=v.y/TILE
    e.xd=-1
    if state==INGAME then
    	sfx(4)
    end
    add_actor(e,x,y)
   end
  elseif v.name==CANNONBALL then
   v.x=v.x+v.xd
   if mget(flr((v.x+v.xd)/TILE),flr(v.y/TILE))~=0 then
    table.remove(actors,i)
   end
  end
  spr16(v.idle[flr(t/8)%(#v.idle)+1],
   v.x-flr(cam.x),
   v.y-flr(cam.y),
   p1.alpha)
 end
end

function kill_knight()
 p1.live=false
 p1.yd=-p1.jump_force
 sfx(1)
end

function update_talking()
 local y=96
 
 if state==READING or state==READING_END then
		map(90,51,30,6,0,88,0)
		local gfx=448
		if talking.to==BALE then
		 gfx=452
		elseif talking.to==BALLJR then
		 gfx=456
		end
		if talking.n%2==0 then gfx=460 end
		spr(gfx,8,y,-1,1,0,0,4,4)
		local txt=talking.texts[talking.n]
		print(string.sub(txt,1,talking.counter),60+1,y+1,DARKBROWN)
		print(string.sub(txt,1,talking.counter),60,y,WHITE)
		if state==READING_END then
		 local i=0
			if t%40>30 then i=1 end 
			spr16(BTN_A_GFX,220,114+i)
		end
		
		if t%5==0 then
		 if talking.counter<string.len(txt) then
		 	talking.counter=talking.counter+1
				if string.sub(txt,talking.counter,talking.counter)~=" " then
				 if talking.n%2==0 then
					 sfx(5)
					else
					 sfx(3)
					end
				end
			else
					state=READING_END
			end 
		end
	end
end

function TIC()
	cls(14)
	
	update_actors()
	update_ground()
	update_player()
	update_camera()
	update_talking()
	update_states()
	update_debug()
	
	t=t+1
end

function update_states()
	--scan keypresses
	if btnp(BTN_A) or btnp(BTN_B) then
		if state==TITLE then
			state=INGAME
			sfx(2)
		elseif state==INGAME then
			if p1.nearby==SIGN or p1.nearby==BALE or p1.nearby==BALLJR then
				talking.counter=0
				state=READING
			end
		elseif state==READING_END then
		 if talking.n<#talking.texts then
				 talking.n=talking.n+1
					talking.counter=0
					state=READING
			else
				state=INGAME
			end
		elseif state==FAILED then
		 p1.x=p1.lastpos.x
			p1.y=p1.lastpos.y
			p1.live=true
			state=INGAME
			sfx(2)
		elseif state==GAMEOVER then
		 state=TITLE
			p1.x=p1.lastpos.x
			p1.y=p1.lastpos.y
			p1.lives=MAX_LIVES
			sfx(2)
	 end
	end
	
	--draw texts
	
	if state==TITLE then
	 draw_title()
	 press_fire("START")
	elseif state==INGAME then
	 draw_lives()
		if p1.nearby==SIGN then
		 press_fire("READ")
		elseif p1.nearby==BALE or  p1.nearby==BALLJR then
		 press_fire("TALK TO")
		elseif p1.nearby==CHECKPOINT then
		 print_middle("Checkpoint",BOTTOM)
		end
	elseif state==FAILED then
	 draw_lives()
	 print_middle("KNIGHT FAILED!",60)
		press_fire("RETRY")
	elseif state==GAMEOVER then
	 print_middle("GAME OVER",60)
		press_fire("TITLE SCREEN")
	end
end

function draw_lives()
	for i=1,p1.lives do
		spr16(172,i*16-16,0)
	end
end

function update_debug()
 if DEBUG and t%20>5 then
		print("Debug:"..state,0,0,13)
		--print("In development",0,0,13)
	end
end

function update_camera()
 if p1.live then
	 cam.xd=(flr(p1.x)-120-cam.x)*cam.speed
	 cam.yd=(flr(p1.y)-65-cam.y)*cam.speed
	 cam.x=cam.x+cam.xd
	 cam.y=cam.y+cam.yd
	 if cam.x<0 then cam.x=0 end
 end
end

function update_ground()
 for y=0,MAP_HEIGHT do
  for x=0,MAP_WIDTH do
   local small=mget(x,y)
   spr16(small*2+128,
    x*TILE-flr(cam.x),
    y*TILE-flr(cam.y))
  end
 end
end

function update_player()
 p1.xd=0
 p1.mode=IDLE
 if p1.live and state==INGAME then
  if btn(UP) or btn(BTN_A) or btn(BTN_B) then 
   if p1.on_ground or p1.platform.on then
    p1.yd=-p1.jump_force
    p1.mode=MOVE
    sfx(0)
   end
  end
  --if btn(DOWN) then p1.yd=1 end
  if btn(RIGHT) then 
   p1.xd=-1
   p1.flip=1 
   p1.mode=MOVE
  end
  if btn(LEFT) then 
   p1.xd=1
   p1.flip=0
   p1.mode=MOVE
  end
  if p1.platform.on then
   p1.xd=p1.xd+p1.platform.xd
  end
 end
 
 if not p1.platform.on then
 	p1.yd=p1.yd+GRAVITY
 end
 if p1.yd>GRAVITY_MAX then 
  p1.yd=GRAVITY_MAX
 end
 
 if p1.live then	
  local empty=true
  for i,v in ipairs(p1.points) do
   if mget(flr((p1.x+p1.xd+v.x)/TILE),flr((p1.y+v.y)/TILE))~=0 then
    empty=false
   end 
  end
  
  if empty then
   p1.x=p1.x+p1.xd
  end
	 
		empty=true
		p1.on_ground=false
	 for i,v in ipairs(p1.points) do
   if mget(flr((p1.x+v.x)/TILE),flr((p1.y+p1.yd+v.y)/TILE))~=0 then
    empty=false
    if v.ground then
     p1.on_ground=true
    end
   end 
  end
		
		if empty then
	  p1.y=p1.y+p1.yd
	 else
	 	p1.yd=0
	 end
	else
	 p1.x=p1.x+p1.xd
		p1.y=p1.y+p1.yd
		if p1.y-cam.y>150 and state==INGAME then
		 if p1.lives>0 then
			 p1.lives=p1.lives-1
				state=FAILED
			else
			 state=GAMEOVER
			end
		end
	end
 
 if p1.mode==IDLE then
  spr(p1.idle[flr(t/16)%3+1],
   p1.x-flr(cam.x),
   p1.y-flr(cam.y),
   p1.alpha,1,p1.flip,0,2,2)
 else
  spr(p1.run[flr(t/4)%4+1],
   p1.x-flr(cam.x),
   p1.y-flr(cam.y),
   p1.alpha,1,p1.flip,0,2,2)
 end
end

function draw_title()
 local x=1
 local y=0
 local txt="BUG"
 print(txt,50+x,20+y,
  GREY,false,5)
 print(txt,50,20,
  RED,false,5)
 txt="Knight"
 print(txt,120-53+x,40+y,
  GREY,false,4)
 print(txt,120-53,40,
  ORANGE,false,4)
 txt="Developed by Istvan and Szabi"
 print(txt,120-53+x,66+y,
  GREY,false,1,true)
 print(txt,120-53,66,
  WHITE,false,1,true)
  txt="for the Game Off 2021 jam"
 print(txt,120-45+x,76+y,
  GREY,false,1,true)
 print(txt,120-45,76,
  WHITE,false,1,true)
 --print(width,0,0)
end

function press_fire(txt)
 local y=BOTTOM
 width=print_middle("PRESS    TO "..txt,y)
 i=0
 if t%40>30 then i=1 end
 spr16(BTN_A_GFX,120-flr(width/2)+30,y+i-7)
end

function print_middle(txt,y)
 width=print(txt,0,-20)
 print(txt,120-flr(width/2)+1,y,GREY)
 print(txt,120-flr(width/2),y,WHITE)
 return width
end

function spr16(gfx,x,y)
 spr(gfx,x,y,ALPHA,1,0,0,2,2)
end

