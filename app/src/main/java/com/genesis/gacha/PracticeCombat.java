package com.genesis.gacha;

/** Local practice simulation. No account, network, inventory or reward dependencies. */
final class PracticeCombat {
 static final double STEP=1.0/60.0;
 static final int MAX_HP=855, MAX_BOSS_HP=6000;
 double x=4,y=5,bx=11,by=5,fx=1,fy=0,mx,my,clock,actionTime;
 double skillCooldown,dodgeCooldown,bossTime=.6,chargeX,chargeY,hitFlash,bossFlash;
 int hp=MAX_HP,bossHp=MAX_BOSS_HP,action,bossPhase,pattern; // action: idle/slash/skill/dodge
 boolean paused=true,attackHeld,skillPressed,dodgePressed,playerHit,bossHit;
 double attackBuffer,damageTextTime,bossDamageTextTime;
 int damageDealt,damageTaken,dodges,lastDamage,lastBossDamage,hitSerial,dodgeSerial;
 boolean bossEvaded;
 void pressAttack(){if(!paused){attackHeld=true;attackBuffer=.12;}}
 String bossCue(){return bossPhase==1?(pattern==0?"GROUND SLAM · MOVE OUT":"RUNE CHARGE · SIDESTEP"):bossPhase==2?"DANGER":bossPhase==3?"WARDEN RECOVERING · ATTACK":"KEEP MOVING";}
 String outcome="";
 private long rng=163;
 void movement(double dx,double dy){double length=Math.hypot(dx,dy);mx=length>1?dx/length:dx;my=length>1?dy/length:dy;}
 void clearInput(){attackBuffer=0;mx=my=0;attackHeld=skillPressed=dodgePressed=false;}
 void pause(){paused=true;clearInput();}
 void resume(){if(outcome.isEmpty())paused=false;}
 void reset(){x=4;y=5;bx=11;by=5;fx=1;fy=0;clock=actionTime=skillCooldown=dodgeCooldown=0;
  bossTime=.6;chargeX=chargeY=hitFlash=bossFlash=0;hp=MAX_HP;bossHp=MAX_BOSS_HP;
  attackBuffer=damageTextTime=bossDamageTextTime=0;damageDealt=damageTaken=dodges=lastDamage=lastBossDamage=hitSerial=dodgeSerial=0;bossEvaded=false;action=bossPhase=pattern=0;playerHit=bossHit=false;outcome="";rng=163;paused=true;clearInput();}
 static int damage(double attack,double coefficient,double defense,boolean crit){
  return Math.max(1,(int)Math.floor(attack*coefficient*100/(100+Math.max(0,defense))*(crit?1.5:1)+.5));
 }
 private boolean critical(){rng=(rng*1664525+1013904223L)&0xffffffffL;return rng/4294967296.0<.0807;}
 private static double clamp(double v,double lo,double hi){return Math.max(lo,Math.min(hi,v));}
 private void faceMovement(){if(Math.hypot(mx,my)>.05){double n=Math.hypot(mx,my);fx=mx/n;fy=my/n;}}
 void tick(){
  if(paused||!outcome.isEmpty())return;
  final double dt=STEP;clock+=dt;skillCooldown=Math.max(0,skillCooldown-dt);dodgeCooldown=Math.max(0,dodgeCooldown-dt);
  damageTextTime=Math.max(0,damageTextTime-dt);bossDamageTextTime=Math.max(0,bossDamageTextTime-dt);
  hitFlash=Math.max(0,hitFlash-dt);bossFlash=Math.max(0,bossFlash-dt);
  boolean canCancel=action==0||(action==1&&actionTime<.15)||(action==2&&actionTime<.25);
  if(dodgePressed&&dodgeCooldown<=0&&canCancel){faceMovement();action=3;actionTime=0;dodgeCooldown=2;}
  else if(skillPressed&&skillCooldown<=0&&action==0){faceMovement();action=2;actionTime=0;playerHit=false;skillCooldown=6*(1-.036);}
  else if((attackHeld||attackBuffer>0)&&action==0){faceMovement();action=1;actionTime=0;playerHit=false;attackBuffer=0;}
  skillPressed=dodgePressed=false;attackBuffer=Math.max(0,attackBuffer-dt);
  double speed=3.36;if(action==3){x+=fx*7.2*dt;y+=fy*7.2*dt;}
  else {if(action!=0){double start=action==1?.15:.25;speed=(actionTime>=start&&actionTime<start+(action==1?.10:.15))?0:speed*.4;}else faceMovement();x+=mx*speed*dt;y+=my*speed*dt;}
  x=clamp(x,.3,15.7);y=clamp(y,.3,9.7);
  actionTime+=dt;
  int toBoss=0,toPlayer=0;
  if(action==1||action==2){double start=action==1?.15:.25,end=start+(action==1?.10:.15);
   double dx=bx-x,dy=by-y,d=Math.hypot(dx,dy),radius=action==1?1.3:1.8;
   double dot=d<.001?1:(dx*fx+dy*fy)/d;
   if(!playerHit&&actionTime>=start&&actionTime<end&&d<=radius+.65&&dot>=Math.cos(Math.toRadians(action==1?45:75))){toBoss=damage(154,action==1?1:1.8,40,critical());playerHit=true;}
  }
  // Boss phases: approach/rest, telegraph, active, recovery. One hit per attack.
  bossTime-=dt;
  if(bossPhase==0){double dx=x-bx,dy=y-by,d=Math.hypot(dx,dy);
   if(d>2){bx+=dx/d*2*dt;by+=dy/d*2*dt;}
   if(d<=2&&bossTime<=0){bossPhase=1;bossTime=pattern==0?.9:1.1;bossHit=false;bossEvaded=false;aimCharge();}
  }else if(bossPhase==1){if(pattern==1&&bossTime>.35)aimCharge();if(bossTime<=0){bossPhase=2;bossTime=pattern==0?.10:.5;}}
  else if(bossPhase==2){double oldX=bx,oldY=by;
   if(pattern==1){bx=clamp(bx+chargeX*8*dt,.65,15.35);by=clamp(by+chargeY*8*dt,.65,9.35);}
   double dist=pattern==0?Math.hypot(x-bx,y-by):segmentDistance(x,y,oldX,oldY,bx,by);
   boolean invulnerable=action==3&&actionTime>=.05&&actionTime<.20;
   if(!bossHit&&!bossEvaded&&invulnerable&&dist<=(pattern==0?2.2+.3:.6+.3)){bossEvaded=true;dodges++;dodgeSerial++;}
   if(!bossHit&&dist<=(pattern==0?2.2+.3:.6+.3)&&!invulnerable){toPlayer=damage(170,pattern==0?1.3:1,84,false);bossHit=true;}
   if(bossTime<=0){bossPhase=3;bossTime=pattern==0?1:1.2;}
  }else if(bossPhase==3&&bossTime<=0){bossPhase=0;bossTime=bossHp<=3000?.4:.6;pattern=1-pattern;}
  separateBodies();
  if(toBoss>0){lastBossDamage=Math.min(bossHp,toBoss);damageDealt+=lastBossDamage;bossDamageTextTime=.65;hitSerial++;bossHp=Math.max(0,bossHp-toBoss);bossFlash=.15;}
  if(toPlayer>0){lastDamage=Math.min(hp,toPlayer);damageTaken+=lastDamage;damageTextTime=.65;hitSerial++;hp=Math.max(0,hp-toPlayer);hitFlash=.15;}
  if(action!=0&&actionTime>=(action==1?.8/1.1:action==2?.75:.25)){action=0;actionTime=0;}
  if(hp==0||bossHp==0){outcome=hp==0?"Defeat":"Victory";pause();}
 }
 private void aimCharge(){double d=Math.hypot(x-bx,y-by);chargeX=d<.001?1:(x-bx)/d;chargeY=d<.001?0:(y-by)/d;}
 private void separateBodies(){
  double dx=x-bx,dy=y-by,d=Math.hypot(dx,dy);if(d>=.95)return;
  double nx=d<.00001?-1:dx/d,ny=d<.00001?0:dy/d;
  x=clamp(bx+nx*.95,.3,15.7);y=clamp(by+ny*.95,.3,9.7);
  dx=x-bx;dy=y-by;d=Math.hypot(dx,dy);
  if(d<.95){nx=d<.00001?nx:dx/d;ny=d<.00001?ny:dy/d;bx=clamp(x-nx*.95,.65,15.35);by=clamp(y-ny*.95,.65,9.35);}
 }
 static double segmentDistance(double x,double y,double ax,double ay,double bx,double by){double dx=bx-ax,dy=by-ay,n=dx*dx+dy*dy;double t=n==0?0:clamp(((x-ax)*dx+(y-ay)*dy)/n,0,1);return Math.hypot(x-ax-t*dx,y-ay-t*dy);}
}
