package com.genesis.gacha;
public class CombatPolishTest {
 static int n;static void check(boolean b){n++;if(!b)throw new AssertionError("check "+n);}
 static PracticeCombat g(){PracticeCombat g=new PracticeCombat();g.resume();g.bossTime=999;return g;}
 public static void main(String[] args){
 PracticeCombat g=g();g.action=1;g.actionTime=.70;g.pressAttack();g.attackHeld=false;for(int i=0;i<4;i++)g.tick();check(g.action==1&&g.actionTime<.05);
 g=g();g.action=2;g.actionTime=.1;g.pressAttack();g.attackHeld=false;for(int i=0;i<50;i++)g.tick();check(g.action==0);
 g=g();g.pressAttack();g.pause();check(g.attackBuffer==0);
 g=g();g.x=g.bx;g.y=g.by;g.tick();check(Math.hypot(g.x-g.bx,g.y-g.by)>=.94999);
 g=g();g.x=.3;g.y=.3;g.bx=.65;g.by=.65;g.tick();check(Math.hypot(g.x-g.bx,g.y-g.by)>=.94999&&g.x>=.3&&g.y>=.3);
 g=g();g.bx=g.x+1;g.by=g.y;g.pressAttack();for(int i=0;i<30;i++)g.tick();check(g.damageDealt==6000-g.bossHp&&g.hitSerial==1);
 g=g();g.bx=g.x;g.by=g.y;g.bossPhase=2;g.bossTime=.08;g.action=3;g.actionTime=.07;for(int i=0;i<3;i++)g.tick();check(g.dodges==1&&g.hp==855);
 g=g();g.bossPhase=1;g.pattern=1;g.bossTime=.5;g.tick();double dx=g.chargeX,dy=g.chargeY;g.bossTime=.3;g.y=9;g.tick();check(g.chargeX==dx&&g.chargeY==dy);
 g.damageTaken=20;g.damageDealt=100;g.dodges=3;g.reset();check(g.damageDealt==0&&g.damageTaken==0&&g.dodges==0&&g.hitSerial==0);
 g=g();g.bx=g.x;g.by=g.y;g.hp=5;g.bossPhase=2;g.bossTime=.05;g.tick();check(g.damageTaken==5);
 System.out.println("PASS: "+n+" polish checks.");
 }
}
