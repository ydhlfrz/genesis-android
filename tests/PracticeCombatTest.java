package com.genesis.gacha;
/** Standalone JVM regression test; run with javac/java, no Android dependency. */
public final class PracticeCombatTest {
 static int checks;
 static void check(boolean v,String message){checks++;if(!v)throw new AssertionError(message);}
 static PracticeCombat game(){PracticeCombat g=new PracticeCombat();g.resume();return g;}
 static void ticks(PracticeCombat g,int n){for(int i=0;i<n;i++)g.tick();}
 public static void main(String[] args){
  check(PracticeCombat.damage(154,1,40,false)==110,"basic damage");
  check(PracticeCombat.damage(154,1.8,40,false)==198,"skill damage");
  check(PracticeCombat.damage(154,1,40,true)==165,"critical");
  check(PracticeCombat.damage(170,1.3,84,false)==120,"boss damage");
  PracticeCombat g=game();g.bossTime=999;g.movement(1,1);double x=g.x,y=g.y;ticks(g,60);
  check(Math.abs(Math.hypot(g.x-x,g.y-y)-3.36)<.00001,"diagonal normalized");
  g=game();g.movement(-1,-1);ticks(g,1200);check(g.x>=.3&&g.y>=.3,"arena bounds");
  g=game();g.skillCooldown=3;g.pause();ticks(g,600);check(g.clock==0&&g.skillCooldown==3,"paused timer");
  g=game();g.attackHeld=true;g.skillPressed=true;g.movement(1,0);g.pause();check(!g.attackHeld&&!g.skillPressed&&g.mx==0,"clear input");
  g=game();g.x=5;g.y=5;g.bx=6;g.by=5;g.bossTime=999;g.attackHeld=true;g.tick();g.attackHeld=false;ticks(g,25);
  check(g.bossHp==6000-110||g.bossHp==6000-165,"one hit per swing");
  g=game();g.x=5;g.y=5;g.bx=4;g.by=5;g.bossTime=999;g.attackHeld=true;ticks(g,25);check(g.bossHp==6000,"cannot hit behind");
  g=game();g.skillPressed=true;g.tick();double cd=g.skillCooldown;g.skillPressed=true;g.tick();check(g.skillCooldown<cd,"no skill cooldown restart");
  g=game();g.dodgePressed=true;g.tick();double start=g.x;ticks(g,14);check(g.x-start>1.6&&g.x-start<1.8,"dodge distance");
  g=game();g.x=15.5;g.dodgePressed=true;ticks(g,16);check(g.x<=15.7,"dash wall");
  g=game();g.bx=g.x;g.by=g.y;g.bossPhase=2;g.bossTime=.08;g.action=3;g.actionTime=.07;g.tick();check(g.hp==855,"dodge immunity window");
  g=game();g.bx=g.x;g.by=g.y;g.bossPhase=2;g.bossTime=.08;ticks(g,5);check(g.hp==735,"one slam hit");
  g=game();g.bx=g.x;g.by=g.y;g.bossPhase=1;g.bossTime=.9;ticks(g,30);check(g.hp==855,"telegraph not damaging");
  g=game();g.hp=1;g.bx=g.x;g.by=g.y;g.bossPhase=2;g.bossTime=.08;g.tick();check(g.outcome.equals("Defeat")&&g.paused,"defeat stops");
  g.reset();check(g.hp==855&&g.bossHp==6000&&g.skillCooldown==0&&g.outcome.isEmpty()&&g.paused,"retry reset");
  g=game();g.bossHp=1;g.bx=g.x+1;g.by=g.y;g.bossTime=999;g.attackHeld=true;ticks(g,30);check(g.outcome.equals("Victory")&&g.paused,"victory stops");
  g=game();g.hp=g.bossHp=1;g.bx=g.x+1;g.by=g.y;g.action=1;g.actionTime=.15;g.bossPhase=2;g.bossTime=.08;g.tick();check(g.hp==0&&g.bossHp==0&&g.outcome.equals("Defeat"),"simultaneous hits");
  check(PracticeCombat.segmentDistance(1,0,0,0,2,0)==0,"swept collision");
  PracticeCombat a=game(),b=game();a.attackHeld=b.attackHeld=true;a.bossTime=b.bossTime=999;
  for(int i=0;i<300;i++){a.tick();a.tick();}ticks(b,600);check(a.clock==b.clock&&a.hp==b.hp&&a.bossHp==b.bossHp,"same ticks independent of render grouping");
  System.out.println("PASS: "+checks+" combat regression checks.");
 }
}
