/* NULL//SHRINE dynamic pin forest — asymmetric topology, fields and mechanisms. */
const LAYOUT={width:420,height:640,ballR:8,pegR:4,gravity:1120,restitution:.76,wallBounce:.82,topBounce:.75,maxBalls:8,leftWall:18,rightWall:402,pocketTop:548,pocketH:56,pocketCount:7,launcherX:210,launcherY:614,launchPowerMax:1250};

const peg=(x,y,type="node",extra={})=>({x,y,baseX:x,baseY:y,r:type==="bumper"?10:type==="switch"?7:4,type,phase:Math.random()*6.28,lit:0,...extra});

function buildPegs(){
  const p=[];
  // Crown: sparse funnel that splits the opening decision three ways.
  [[210,82,"switch"],[154,110,"bumper"],[266,110,"bumper"],[112,145],[176,151],[244,151],[308,145]].forEach(v=>p.push(peg(...v)));
  // Left helix: curved acceleration lane.
  for(let i=0;i<9;i++){const a=-1.2+i*.34;p.push(peg(126+Math.cos(a)*69,255+Math.sin(a)*92,i%3===0?"bumper":"node",{zone:"helix"}))}
  // Right fracture: zig-zag deflection staircase, intentionally uneven.
  [[293,205],[340,231],[286,258],[350,290],[302,320],[360,352],[317,385]].forEach((v,i)=>p.push(peg(v[0],v[1],i===2||i===5?"switch":"node",{zone:"fracture"})));
  // Central moving lock and lower risk fork.
  p.push(peg(210,238,"gate",{axis:"x",amp:62,speed:1.25}));
  p.push(peg(210,334,"bumper",{zone:"core"}));
  p.push(peg(165,387,"gate",{axis:"y",amp:28,speed:1.7}));
  p.push(peg(255,405,"gate",{axis:"x",amp:34,speed:1.45}));
  [[70,400],[106,438],[145,468],[210,486],[276,468],[319,435],[356,400]].forEach((v,i)=>p.push(peg(v[0],v[1],i===3?"switch":"node",{zone:"basin"})));
  return p;
}

function buildPockets(){const total=LAYOUT.rightWall-LAYOUT.leftWall,w=total/LAYOUT.pocketCount,mid=3;return Array.from({length:7},(_,i)=>({x0:LAYOUT.leftWall+i*w,cx:LAYOUT.leftWall+(i+.5)*w,w,kind:i===mid?"jackpot":Math.abs(i-mid)===1?"red":"normal",reward:i===mid?14:Math.abs(i-mid)===1?6:2}));}

const WORLD={pegs:buildPegs(),pockets:buildPockets(),balls:[],particles:[],timeScale:1,time:0,fieldPulse:0,switches:0,comboFlash:0,
  fields:[
    {x:102,y:292,r:82,strength:540,type:"vortex",spin:1},
    {x:312,y:338,r:72,strength:620,type:"vortex",spin:-1},
    {x:210,y:438,r:62,strength:760,type:"magnet",active:false},
  ],
  portals:[{x:62,y:225,to:1,phase:0},{x:361,y:174,to:0,phase:Math.PI}],
  rails:[{x1:38,y1:342,x2:142,y2:508,side:1},{x1:382,y1:420,x2:286,y2:515,side:-1}]
};

function hitNode(ball,n){
  const dx=ball.x-n.x,dy=ball.y-n.y,d=Math.hypot(dx,dy),min=ball.r+n.r;if(!d||d>=min)return false;
  const nx=dx/d,ny=dy/d;ball.x=n.x+nx*min;ball.y=n.y+ny*min;const vn=ball.vx*nx+ball.vy*ny;
  if(vn<0){const boost=n.type==="bumper"?1.35:1;const j=-(1+LAYOUT.restitution)*vn*boost;ball.vx+=j*nx;ball.vy+=j*ny;const tangent=(n.type==="switch"?.16:.07)*(Math.random()-.5)*Math.hypot(ball.vx,ball.vy);ball.vx+=-ny*tangent;ball.vy+=nx*tangent;SFX.peg();}
  n.lit=1;
  if(n.type==="bumper"){burstParticles(n.x,n.y,8,"#80f0ff");ball.charge=Math.min(3,(ball.charge||0)+1);}
  if(n.type==="switch"&&!n.armed){n.armed=true;WORLD.switches++;WORLD.fieldPulse=1;WORLD.fields[2].active=WORLD.switches>=2;burstParticles(n.x,n.y,16,"#ff78bd");if(WORLD.switches>=3){WORLD.comboFlash=1;ball.vy-=280;}}
  return true;
}

function applyField(ball,f,dt){const dx=f.x-ball.x,dy=f.y-ball.y,d=Math.hypot(dx,dy);if(d>f.r||d<3||f.active===false)return;const q=(1-d/f.r)*f.strength;if(f.type==="magnet"){ball.vx+=dx/d*q*dt;ball.vy+=dy/d*q*dt}else{ball.vx+=(-dy/d)*q*f.spin*dt+dx/d*q*.18*dt;ball.vy+=(dx/d)*q*f.spin*dt+dy/d*q*.18*dt}ball.inField=f.type;}

function collideRail(ball,r){const vx=r.x2-r.x1,vy=r.y2-r.y1,l2=vx*vx+vy*vy,t=Math.max(0,Math.min(1,((ball.x-r.x1)*vx+(ball.y-r.y1)*vy)/l2)),px=r.x1+t*vx,py=r.y1+t*vy,dx=ball.x-px,dy=ball.y-py,d=Math.hypot(dx,dy);if(d>ball.r+3||!d)return;const nx=dx/d,ny=dy/d,vn=ball.vx*nx+ball.vy*ny;if(vn<0){ball.vx-=1.8*vn*nx;ball.vy-=1.8*vn*ny;ball.vx+=vx/Math.sqrt(l2)*95;ball.vy+=vy/Math.sqrt(l2)*95;SFX.peg();}}

function updatePhysics(dt){
  WORLD.time+=dt;WORLD.fieldPulse=Math.max(0,WORLD.fieldPulse-dt*1.8);WORLD.comboFlash=Math.max(0,WORLD.comboFlash-dt*1.4);
  WORLD.pegs.forEach(n=>{n.lit=Math.max(0,n.lit-dt*2.4);if(n.type==="gate"){const wave=Math.sin(WORLD.time*n.speed+n.phase)*n.amp;if(n.axis==="x")n.x=n.baseX+wave;else n.y=n.baseY+wave}});
  for(const b of WORLD.balls){if(b.state!=="flying")continue;b.inField="";b.portalLock=Math.max(0,(b.portalLock||0)-dt);b.vy+=LAYOUT.gravity*WORLD.timeScale*dt;WORLD.fields.forEach(f=>applyField(b,f,dt));b.x+=b.vx*dt*WORLD.timeScale;b.y+=b.vy*dt*WORLD.timeScale;
    if(b.x-b.r<LAYOUT.leftWall){b.x=LAYOUT.leftWall+b.r;b.vx=Math.abs(b.vx)*LAYOUT.wallBounce}if(b.x+b.r>LAYOUT.rightWall){b.x=LAYOUT.rightWall-b.r;b.vx=-Math.abs(b.vx)*LAYOUT.wallBounce}if(b.y-b.r<54){b.y=54+b.r;b.vy=Math.abs(b.vy)*LAYOUT.topBounce}
    WORLD.pegs.forEach(n=>hitNode(b,n));WORLD.rails.forEach(r=>collideRail(b,r));
    WORLD.portals.forEach((p,i)=>{if(b.portalLock>0)return;const d=Math.hypot(b.x-p.x,b.y-p.y);if(d<18){const q=WORLD.portals[p.to];b.x=q.x+(i===0?-24:24);b.y=q.y+14;b.vx*=-1;b.vy+=110;b.portalLock=.7;burstParticles(p.x,p.y,18,"#9a8cff");SFX.redZone();}});
    const speed=Math.hypot(b.vx,b.vy),max=1450;if(speed>max){b.vx*=max/speed;b.vy*=max/speed}if(b.y<LAYOUT.pocketTop)b.enteredField=true;if(b.vy>0&&b.y+b.r>LAYOUT.pocketTop)b.state="pocket";
  }
}

function settleBalls(onSettled){for(const b of WORLD.balls){if(b.state!=="pocket")continue;if(!b.enteredField){b.state="lost";onSettled(b,null);continue}const p=WORLD.pockets.find(p=>b.x>=p.x0&&b.x<p.x0+p.w);if(p){b.x=p.cx;b.y=LAYOUT.pocketTop+25;b.state="settled";onSettled(b,p)}else{b.state="lost";onSettled(b,null)}}WORLD.balls=WORLD.balls.filter(b=>b.state!=="settled"&&b.state!=="lost");if(!WORLD.balls.length){WORLD.switches=0;WORLD.fields[2].active=false;WORLD.pegs.forEach(n=>n.armed=false)}}
function addBall(vx,vy){if(WORLD.balls.length>=LAYOUT.maxBalls)WORLD.balls.shift();WORLD.balls.push({x:LAYOUT.launcherX,y:LAYOUT.launcherY,vx,vy,r:LAYOUT.ballR,state:"flying",enteredField:false,trail:[],charge:0,portalLock:0})}
function launch(power){const p=Math.min(Math.max(power,.08),1),speed=LAYOUT.launchPowerMax*(.58+p*.58),angle=-Math.PI/2+(Math.random()-.5)*.11;SFX.launch(p);addBall(Math.cos(angle)*speed,Math.sin(angle)*speed)}
function phaseNudge(direction){const b=WORLD.balls.find(b=>b.state==="flying");if(!b||b.nudged)return false;b.vx+=direction*260;b.vy-=80;b.nudged=true;burstParticles(b.x,b.y,14,"#ff78bd");SFX.redZone();return true}
function burstParticles(x,y,n,color){for(let i=0;i<n;i++){const a=Math.random()*Math.PI*2,sp=60+Math.random()*230;WORLD.particles.push({x,y,vx:Math.cos(a)*sp,vy:Math.sin(a)*sp-40,life:.55+Math.random()*.55,maxLife:1.1,color,size:1.5+Math.random()*3})}}
function updateParticles(dt){for(const p of WORLD.particles){p.life-=dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=420*dt}WORLD.particles=WORLD.particles.filter(p=>p.life>0)}
