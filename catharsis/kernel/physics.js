/* NULL//SHRINE dynamic pin forest — asymmetric topology, fields and mechanisms. */
const LAYOUT={width:420,height:640,ballR:8,pegR:4,gravity:1120,restitution:.76,wallBounce:.82,topBounce:.75,maxBalls:8,leftWall:18,rightWall:402,pocketTop:548,pocketH:56,pocketCount:7,launcherX:210,launcherY:614,launchPowerMax:1250};

const peg=(x,y,type="node",extra={})=>({x,y,baseX:x,baseY:y,r:type==="bumper"?10:type==="switch"?7:4,type,phase:Math.random()*6.28,lit:0,...extra});

function buildPegs(){
  const p=[];
  // Crown: open vertical corridor so a dead-center launch is not auto-bounced.
  // Side bumpers and switches still force an early left/right commitment.
  [[154,96,"switch"],[266,96,"switch"],[112,145,"bumper"],[308,145,"bumper"],[176,151],[244,151]].forEach(v=>p.push(peg(...v)));
  // Left helix: curved acceleration lane.
  for(let i=0;i<9;i++){const a=-1.2+i*.34;p.push(peg(126+Math.cos(a)*69,255+Math.sin(a)*92,i%3===0?"bumper":"node",{zone:"helix"}))}
  // Right fracture: zig-zag deflection staircase, intentionally uneven.
  [[293,205],[340,231],[286,258],[350,290],[302,320],[360,352],[317,385]].forEach((v,i)=>p.push(peg(v[0],v[1],i===2||i===5?"switch":"node",{zone:"fracture"})));
  // Off-center moving locks — never park a red post on the launcher axis.
  p.push(peg(188,238,"gate",{axis:"x",amp:54,speed:1.25}));
  p.push(peg(248,348,"bumper",{zone:"core"}));
  p.push(peg(152,392,"gate",{axis:"y",amp:28,speed:1.7}));
  p.push(peg(268,410,"gate",{axis:"x",amp:34,speed:1.45}));
  // Basin: leave the mid trough open so lazy drops die in the drain.
  // Side posts create the only clean channels into the wall jackpots.
  [[64,408,"switch"],[108,442],[148,474],[272,474],[318,442],[360,408,"switch"]].forEach(v=>p.push(peg(...v,{zone:"basin"})));
  return p;
}

// Arcade trough: gravity's home is the drain (center). Jackpots hug the walls —
// you steer there with flippers / launch angle, you don't fall into them for free.
function buildPockets(){
  const total=LAYOUT.rightWall-LAYOUT.leftWall;
  const kinds=["jackpot","red","normal","normal","normal","red","jackpot"];
  const rewards=[16,7,2,1,2,7,16];
  const widths=[.11,.14,.15,.20,.15,.14,.11];
  let x=LAYOUT.leftWall;
  return kinds.map((kind,i)=>{
    const w=total*widths[i];
    const pocket={x0:x,cx:x+w*.5,w,kind,reward:rewards[i]};
    x+=w;
    return pocket;
  });
}

const WORLD={pegs:buildPegs(),pockets:buildPockets(),balls:[],particles:[],timeScale:1,time:0,fieldPulse:0,switches:0,comboFlash:0,
  fields:[
    {x:102,y:292,r:82,strength:540,type:"vortex",spin:1},
    {x:312,y:338,r:72,strength:620,type:"vortex",spin:-1},
    // Armed shrine well: repels out of the drain toward the wall jackpots.
    {x:210,y:500,r:78,strength:820,type:"repulsor",active:false},
  ],
  portals:[{x:62,y:225,to:1,phase:0},{x:361,y:174,to:0,phase:Math.PI}],
  rails:[{x1:38,y1:342,x2:128,y2:492,side:1},{x1:382,y1:420,x2:292,y2:492,side:-1}],
  flippers:[
    {side:"left",pivotX:46,pivotY:498,length:112,radius:12,rest:.34,active:-.62,angle:.34,omega:0,pressed:false,pulse:0},
    {side:"right",pivotX:374,pivotY:498,length:112,radius:12,rest:Math.PI-.34,active:Math.PI+.62,angle:Math.PI-.34,omega:0,pressed:false,pulse:0}
  ],
  flipperPulse:0
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

function applyField(ball,f,dt){const dx=f.x-ball.x,dy=f.y-ball.y,d=Math.hypot(dx,dy);if(d>f.r||d<3||f.active===false)return;const q=(1-d/f.r)*f.strength;if(f.type==="magnet"){ball.vx+=dx/d*q*dt;ball.vy+=dy/d*q*dt}else if(f.type==="repulsor"){ball.vx-=dx/d*q*dt;ball.vy-=dy/d*q*.35*dt;const outward=ball.x<f.x?-1:1;ball.vx+=outward*q*.22*dt}else{ball.vx+=(-dy/d)*q*f.spin*dt+dx/d*q*.18*dt;ball.vy+=(dx/d)*q*f.spin*dt+dy/d*q*.18*dt}ball.inField=f.type;}

function collideRail(ball,r){const vx=r.x2-r.x1,vy=r.y2-r.y1,l2=vx*vx+vy*vy,t=Math.max(0,Math.min(1,((ball.x-r.x1)*vx+(ball.y-r.y1)*vy)/l2)),px=r.x1+t*vx,py=r.y1+t*vy,dx=ball.x-px,dy=ball.y-py,d=Math.hypot(dx,dy);if(d>ball.r+3||!d)return;const nx=dx/d,ny=dy/d,vn=ball.vx*nx+ball.vy*ny;if(vn<0){ball.vx-=1.8*vn*nx;ball.vy-=1.8*vn*ny;ball.vx+=vx/Math.sqrt(l2)*95;ball.vy+=vy/Math.sqrt(l2)*95;SFX.peg();}}

function setFlipper(side,pressed){const f=WORLD.flippers.find(x=>x.side===side);if(f)f.pressed=pressed}
function updateFlippers(dt){
  WORLD.flipperPulse=Math.max(0,WORLD.flipperPulse-dt*4);
  for(const f of WORLD.flippers){
    const target=f.pressed?f.active:f.rest,diff=target-f.angle;
    // Snap faster on press so the bat actually meets the ball mid-swing.
    const gain=f.pressed?58:28;
    f.omega=diff*Math.min(62,gain+Math.abs(diff)*42);
    f.angle+=f.omega*dt;
    // Clamp to the swing arc so tunneling/overshoot cannot skip the hit window.
    if(f.side==="left"){
      f.angle=Math.max(f.active,Math.min(f.rest,f.angle));
    }else{
      f.angle=Math.min(f.active,Math.max(f.rest,f.angle));
    }
    f.pulse=Math.max(0,f.pulse-dt*5);
  }
}
function flipperNear(ball,f){
  const dx=ball.x-f.pivotX,dy=ball.y-f.pivotY;
  const reach=f.length+f.radius+ball.r+18;
  return dx*dx+dy*dy<=reach*reach;
}
function collideFlipper(ball,f){
  const ex=f.pivotX+Math.cos(f.angle)*f.length,ey=f.pivotY+Math.sin(f.angle)*f.length;
  const sx=ex-f.pivotX,sy=ey-f.pivotY,l2=sx*sx+sy*sy;
  const t=Math.max(0,Math.min(1,((ball.x-f.pivotX)*sx+(ball.y-f.pivotY)*sy)/l2));
  const px=f.pivotX+t*sx,py=f.pivotY+t*sy,dx=ball.x-px,dy=ball.y-py;
  const d=Math.hypot(dx,dy),min=ball.r+f.radius;if(!d||d>=min)return false;
  // Prefer the playfield-facing normal (upward) so the bat is a solid shelf, not a ghost edge.
  let nx=-Math.sin(f.angle),ny=Math.cos(f.angle);
  if(ny>0){nx=-nx;ny=-ny;}
  if(dx*nx+dy*ny<0){nx=-nx;ny=-ny;}
  ball.x=px+nx*min;ball.y=py+ny*min;
  const rx=px-f.pivotX,ry=py-f.pivotY;
  const surfaceX=-f.omega*ry,surfaceY=f.omega*rx;
  const rel=(ball.vx-surfaceX)*nx+(ball.vy-surfaceY)*ny;
  if(rel<0){
    if(!f.pressed){
      // Resting bat is solid rubber: bounce gently, do not ghost through.
      ball.vx-=(1.55*rel)*nx;
      ball.vy-=(1.55*rel)*ny;
      ball.vx*=0.92;ball.vy*=0.88;
      return true;
    }
    const impulse=-(2.35*rel);
    ball.vx+=impulse*nx+surfaceX*.42;
    ball.vy+=impulse*ny+surfaceY*.55-(1180+Math.min(420,Math.abs(f.omega)*10));
    const max=1650,speed=Math.hypot(ball.vx,ball.vy);if(speed>max){ball.vx*=max/speed;ball.vy*=max/speed}
    ball.flipperHits=(ball.flipperHits||0)+1;f.pulse=1;WORLD.flipperPulse=1;
    burstParticles(px,py,12,f.side==="left"?"#3dfff3":"#ff2d6a");
    if(SFX.flipperHit)SFX.flipperHit();else SFX.peg();
  }
  return true;
}
function resolveFlippers(ball){
  let hit=false;
  for(const f of WORLD.flippers){
    if(!flipperNear(ball,f))continue;
    if(collideFlipper(ball,f))hit=true;
  }
  return hit;
}

function updatePhysics(dt){
  WORLD.time+=dt;WORLD.fieldPulse=Math.max(0,WORLD.fieldPulse-dt*1.8);WORLD.comboFlash=Math.max(0,WORLD.comboFlash-dt*1.4);updateFlippers(dt);
  WORLD.pegs.forEach(n=>{n.lit=Math.max(0,n.lit-dt*2.4);if(n.type==="gate"){const wave=Math.sin(WORLD.time*n.speed+n.phase)*n.amp;if(n.axis==="x")n.x=n.baseX+wave;else n.y=n.baseY+wave}});
  for(const b of WORLD.balls){if(b.state!=="flying")continue;b.inField="";b.portalLock=Math.max(0,(b.portalLock||0)-dt);b.vy+=LAYOUT.gravity*WORLD.timeScale*dt;b.vx*=Math.max(0.984,1-0.55*dt);b.vy*=Math.max(0.992,1-0.22*dt);WORLD.fields.forEach(f=>applyField(b,f,dt));
    // Substep motion near the bats so fast drops cannot tunnel through them.
    const speedGuess=Math.hypot(b.vx,b.vy);
    const steps=speedGuess>720||b.y>400?3:1;
    const stepDt=dt/steps;
    let flipHit=false;
    for(let s=0;s<steps;s++){
      b.x+=b.vx*stepDt*WORLD.timeScale;b.y+=b.vy*stepDt*WORLD.timeScale;
      if(b.x-b.r<LAYOUT.leftWall){b.x=LAYOUT.leftWall+b.r;b.vx=Math.abs(b.vx)*LAYOUT.wallBounce}if(b.x+b.r>LAYOUT.rightWall){b.x=LAYOUT.rightWall-b.r;b.vx=-Math.abs(b.vx)*LAYOUT.wallBounce}if(b.y-b.r<54){b.y=54+b.r;b.vy=Math.abs(b.vy)*LAYOUT.topBounce}
      if(resolveFlippers(b))flipHit=true;
    }
    WORLD.pegs.forEach(n=>hitNode(b,n));WORLD.rails.forEach(r=>collideRail(b,r));resolveFlippers(b);
    WORLD.portals.forEach((p,i)=>{if(b.portalLock>0)return;const d=Math.hypot(b.x-p.x,b.y-p.y);if(d<18){const q=WORLD.portals[p.to];b.x=q.x+(i===0?-24:24);b.y=q.y+14;b.vx*=-1;b.vy+=110;b.portalLock=.7;burstParticles(p.x,p.y,18,"#9a8cff");SFX.redZone();}});
    const speed=Math.hypot(b.vx,b.vy),max=1450;if(speed>max){b.vx*=max/speed;b.vy*=max/speed}if(b.y<LAYOUT.pocketTop)b.enteredField=true;
    // Do not swallow the ball into a pocket while a bat is still holding it.
    if(!flipHit&&b.vy>0&&b.y+b.r>LAYOUT.pocketTop+10)b.state="pocket";
  }
}

function settleBalls(onSettled){for(const b of WORLD.balls){if(b.state!=="pocket")continue;if(!b.enteredField){b.state="lost";onSettled(b,null);continue}const p=WORLD.pockets.find(p=>b.x>=p.x0&&b.x<p.x0+p.w);if(p){b.x=p.cx;b.y=LAYOUT.pocketTop+25;b.state="settled";onSettled(b,p)}else{b.state="lost";onSettled(b,null)}}WORLD.balls=WORLD.balls.filter(b=>b.state!=="settled"&&b.state!=="lost");if(!WORLD.balls.length){WORLD.switches=0;WORLD.fields[2].active=false;WORLD.pegs.forEach(n=>n.armed=false)}}
function addBall(vx,vy){if(WORLD.balls.length>=LAYOUT.maxBalls)WORLD.balls.shift();WORLD.balls.push({x:LAYOUT.launcherX,y:LAYOUT.launcherY,vx,vy,r:LAYOUT.ballR,state:"flying",enteredField:false,trail:[],charge:0,portalLock:0})}
function launch(power){const p=Math.min(Math.max(power,.08),1),speed=LAYOUT.launchPowerMax*(.58+p*.58),angle=-Math.PI/2+(Math.random()-.5)*.11;SFX.launch(p);addBall(Math.cos(angle)*speed,Math.sin(angle)*speed)}
function phaseNudge(direction){const b=WORLD.balls.find(b=>b.state==="flying");if(!b||b.nudged)return false;b.vx+=direction*260;b.vy-=80;b.nudged=true;burstParticles(b.x,b.y,14,"#ff78bd");SFX.redZone();return true}
function burstParticles(x,y,n,color){for(let i=0;i<n;i++){const a=Math.random()*Math.PI*2,sp=60+Math.random()*230;WORLD.particles.push({x,y,vx:Math.cos(a)*sp,vy:Math.sin(a)*sp-40,life:.55+Math.random()*.55,maxLife:1.1,color,size:1.5+Math.random()*3})}}
function updateParticles(dt){for(const p of WORLD.particles){p.life-=dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=420*dt}WORLD.particles=WORLD.particles.filter(p=>p.life>0)}

/* extracted from play/null-shrine — shared catharsis kernel */
