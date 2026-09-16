package com.genesis.gacha;

import android.app.Activity;
import android.app.AlertDialog;
import android.os.Bundle;
import android.graphics.*;
import android.view.*;
import android.widget.*;

/** Standalone, local-only Adventure practice. No API calls or account writes. */
public final class PracticeActivity extends Activity {
 private final PracticeCombat game=new PracticeCombat();
 private Arena arena;private AlertDialog menu;private Button attack,skill,dodge;
 private android.media.ToneGenerator tones;private boolean sound=true;private int heardHit,heardDodge;
 private boolean foreground;private int uiTicks;
 private int dp(float n){return Math.round(n*getResources().getDisplayMetrics().density);}
 @Override public void onCreate(Bundle saved){super.onCreate(saved);
  setVolumeControlStream(android.media.AudioManager.STREAM_MUSIC);try{tones=new android.media.ToneGenerator(android.media.AudioManager.STREAM_MUSIC,35);}catch(RuntimeException ignored){}
  if(getActionBar()!=null)getActionBar().hide();
  getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
  LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setBackgroundColor(0xff101d24);
  root.setOnApplyWindowInsetsListener((v,insets)->{v.setPadding(insets.getSystemWindowInsetLeft(),insets.getSystemWindowInsetTop(),insets.getSystemWindowInsetRight(),insets.getSystemWindowInsetBottom());return insets;});
  LinearLayout top=new LinearLayout(this);top.setGravity(Gravity.CENTER_VERTICAL);root.addView(top,new LinearLayout.LayoutParams(-1,dp(48)));
  Button back=button(top,"Lobby");back.setOnClickListener(v->leave());
  TextView title=new TextView(this);title.setText("ADVENTURE · PRACTICE\nHuman Warrior · No account rewards");title.setTextColor(0xffe8d6a8);title.setTextSize(12);title.setGravity(Gravity.CENTER);top.addView(title,new LinearLayout.LayoutParams(0,-1,1));
  Button audio=button(top,"SFX On");audio.setOnClickListener(v->{sound=!sound;audio.setText(sound?"SFX On":"SFX Off");if(!sound&&tones!=null)tones.stopTone();});
  Button pause=button(top,"Pause");pause.setOnClickListener(v->showMenu());
  arena=new Arena();root.addView(arena,new LinearLayout.LayoutParams(-1,0,1));
  LinearLayout controls=new LinearLayout(this);controls.setGravity(Gravity.CENTER_VERTICAL);root.addView(controls,new LinearLayout.LayoutParams(-1,dp(56)));
  TextView hint=new TextView(this);hint.setText("Drag the left stick\nHold Attack · Tap skill / dodge");hint.setTextColor(0xffc6d2d4);hint.setTextSize(11);hint.setPadding(dp(12),0,0,0);controls.addView(hint,new LinearLayout.LayoutParams(0,-1,1));
  attack=button(controls,"Attack");skill=button(controls,"Slash");dodge=button(controls,"Dodge");
  attack.setOnTouchListener((v,e)->{if(e.getActionMasked()==MotionEvent.ACTION_DOWN){if(foreground)game.pressAttack();v.setPressed(true);return true;}if(e.getActionMasked()==MotionEvent.ACTION_UP||e.getActionMasked()==MotionEvent.ACTION_CANCEL){game.attackHeld=false;if(e.getActionMasked()==MotionEvent.ACTION_CANCEL)game.attackBuffer=0;v.setPressed(false);if(e.getActionMasked()==MotionEvent.ACTION_UP)v.performClick();return true;}return true;});
  attack.setOnClickListener(v->{});
  skill.setOnClickListener(v->{if(!game.paused)game.skillPressed=true;});dodge.setOnClickListener(v->{if(!game.paused)game.dodgePressed=true;});
  setContentView(root);root.requestApplyInsets();
 }
 private Button button(LinearLayout parent,String label){Button b=new Button(this);b.setText(label);b.setTextSize(11);b.setAllCaps(false);b.setTextColor(0xfff1dfac);b.setBackgroundTintList(android.content.res.ColorStateList.valueOf(0xff30434b));b.setMinWidth(dp(72));b.setMinimumHeight(dp(48));parent.addView(b,new LinearLayout.LayoutParams(-2,-1));return b;}
 private void leave(){game.pause();finish();}
 private void showMenu(){
  game.pause();if(tones!=null)tones.stopTone();if(attack!=null)attack.setPressed(false);if(arena!=null)arena.releaseInput();if(menu!=null&&menu.isShowing())return;
  boolean ended=!game.outcome.isEmpty();
  menu=new AlertDialog.Builder(this).setTitle(ended?game.outcome:"Ruined Sanctum · Practice")
   .setMessage(ended?String.format(java.util.Locale.ROOT,"Time: %.1f s\nDamage dealt: %d\nDamage taken: %d\nDodge evasions: %d\n\nNo account rewards or penalties.",game.clock,game.damageDealt,game.damageTaken,game.dodges):"Move with the left stick. Face the Warden to attack. Avoid the marked area before it strikes.\n\nTraining hero and graphics are placeholders.")
   .setPositiveButton(ended?"Retry":"Play",(d,w)->{if(ended){game.reset();heardHit=heardDodge=0;}arena.resetClock();arena.releaseInput();if(foreground)game.resume();})
   .setNegativeButton("Lobby",(d,w)->leave()).setCancelable(false).create();menu.show();
 }
 @Override protected void onResume(){super.onResume();foreground=true;if(arena!=null){arena.start();showMenu();}}
 @Override protected void onPause(){foreground=false;if(tones!=null)tones.stopTone();game.pause();if(arena!=null)arena.stop();super.onPause();}
 @Override protected void onDestroy(){if(arena!=null)arena.stop();if(menu!=null)menu.dismiss();if(tones!=null){tones.release();tones=null;}super.onDestroy();}
 @Override public void onBackPressed(){showMenu();}
 private void labels(){if(++uiTicks%6!=0)return;skill.setText(game.skillCooldown>0?"Slash "+String.format(java.util.Locale.ROOT,"%.1fs",game.skillCooldown):"Slash");dodge.setText(game.dodgeCooldown>0?"Dodge "+String.format(java.util.Locale.ROOT,"%.1fs",game.dodgeCooldown):"Dodge");}
 private final class Arena extends View implements Choreographer.FrameCallback {
  final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);long last;double accumulator;boolean running;
  float scale,ox,oy,jx,jy,jr,knobX,knobY;int joystick=-1;
  Arena(){super(PracticeActivity.this);setContentDescription("Practice arena. Drag the lower left joystick to move.");setFocusable(true);}
  void resetClock(){last=0;accumulator=0;}
  void releaseInput(){joystick=-1;knobX=knobY=0;game.clearInput();}
  void start(){if(running)return;running=true;resetClock();Choreographer.getInstance().postFrameCallback(this);}
  void stop(){running=false;Choreographer.getInstance().removeFrameCallback(this);resetClock();releaseInput();}
  @Override protected void onDetachedFromWindow(){stop();super.onDetachedFromWindow();}
  @Override public void doFrame(long now){if(!running)return;
   if(last!=0&&!game.paused){accumulator+=Math.min(.1,(now-last)/1e9);while(accumulator>=PracticeCombat.STEP){game.tick();accumulator-=PracticeCombat.STEP;}}
   else accumulator=0;last=now;
   if(game.hitSerial!=heardHit){heardHit=game.hitSerial;if(sound&&tones!=null&&!game.paused)tones.startTone(android.media.ToneGenerator.TONE_PROP_BEEP,45);}
   if(game.dodgeSerial!=heardDodge){heardDodge=game.dodgeSerial;if(sound&&tones!=null&&!game.paused)tones.startTone(android.media.ToneGenerator.TONE_PROP_ACK,65);}
   labels();invalidate();
   if(!game.outcome.isEmpty()&&(menu==null||!menu.isShowing()))showMenu();
   if(running)Choreographer.getInstance().postFrameCallback(this);
  }
  void color(int c){paint.setColor(c);paint.setStyle(Paint.Style.FILL);}
  void text(Canvas c,String s,float x,float y,float size,int col){color(col);paint.setTextSize(dp(size));paint.setTextAlign(Paint.Align.LEFT);c.drawText(s,x,y,paint);}
  void disk(Canvas c,float x,float y,float r,int col){color(col);c.drawCircle(x,y,r,paint);}
  @Override protected void onSizeChanged(int w,int h,int oldW,int oldH){releaseInput();scale=Math.max(1,Math.min((w-dp(16))/16f,(h-dp(38))/10f));ox=(w-16*scale)/2;oy=dp(30)+(h-dp(30)-10*scale)/2;jr=dp(37);jx=dp(58);jy=h-dp(48);}
  @Override protected void onDraw(Canvas c){super.onDraw(c);c.drawColor(0xff111e25);
   c.save();c.translate(ox,oy);c.scale(scale,scale);
   color(0xff24383d);c.drawRect(0,0,16,10,paint);paint.setStrokeWidth(.025f);color(0xff354a4c);
   for(int i=0;i<=16;i++)c.drawLine(i,0,i,10,paint);for(int j=0;j<=10;j++)c.drawLine(0,j,16,j,paint);
   paint.setStyle(Paint.Style.STROKE);paint.setColor(0xffb49155);paint.setStrokeWidth(.10f);c.drawRect(0,0,16,10,paint);c.drawCircle(8,5,2.8f,paint);paint.setStyle(Paint.Style.FILL);
   float bx=(float)game.bx,by=(float)game.by;
   if(game.bossPhase==1||game.bossPhase==2){
    int danger=game.bossPhase==1?0x88eeaa44:0xaaff6644;
    if(game.pattern==0){disk(c,bx,by,2.2f,danger);paint.setStyle(Paint.Style.STROKE);paint.setColor(0xffffd887);paint.setStrokeWidth(.05f);c.drawCircle(bx,by,2.2f,paint);paint.setStyle(Paint.Style.FILL);}
    else {double dx=game.chargeX,dy=game.chargeY;double angle=Math.toDegrees(Math.atan2(dy,dx));c.save();c.rotate((float)angle,bx,by);color(danger);c.drawRect(bx,by-.6f,bx+4,by+.6f,paint);color(0xffffd887);c.drawRect(bx,by-.04f,bx+4,by+.04f,paint);c.restore();}
   }
   // Geometric placeholder characters, intentionally independent of sprite assets.
   disk(c,bx,by+.4f,.8f,0x88000000);color(game.bossFlash>0?0xfff9dc9a:0xff8b9596);c.drawRoundRect(bx-.65f,by-.65f,bx+.65f,by+.55f,.15f,.15f,paint);disk(c,bx,by-.55f,.43f,0xffb0b8b5);disk(c,bx-.17f,by-.59f,.08f,0xff66e9e0);disk(c,bx+.17f,by-.59f,.08f,0xff66e9e0);
   float px=(float)game.x,py=(float)game.y;disk(c,px,py+.3f,.44f,0x99000000);disk(c,px,py,.33f,game.hitFlash>0?0xffffe0ac:game.action==3?0xff80ecf2:0xff5593c1);disk(c,px,py-.28f,.22f,0xffe6bd86);
   color(0xffe6dbb2);paint.setStrokeWidth(.10f);c.drawLine(px+(float)game.fx*.3f,py+(float)game.fy*.3f,px+(float)game.fx*.8f,py+(float)game.fy*.8f,paint);
   if((game.action==1&&game.actionTime>=.15&&game.actionTime<.25)||(game.action==2&&game.actionTime>=.25&&game.actionTime<.40)){float r=game.action==1?1.3f:1.8f;float sweep=game.action==1?90:150;float angle=(float)Math.toDegrees(Math.atan2(game.fy,game.fx));paint.setColor(0xaa9aeeff);paint.setStyle(Paint.Style.STROKE);paint.setStrokeWidth(.09f);c.drawArc(px-r,py-r,px+r,py+r,angle-sweep/2,sweep,false,paint);paint.setStyle(Paint.Style.FILL);}
   c.restore();
   text(c,game.bossCue(),getWidth()*.40f,dp(44),10,game.bossPhase==3?0xff8de7b0:0xffffca77);
   if(game.damageTextTime>0)text(c,"-"+game.lastDamage,ox+px*scale,oy+py*scale-dp(24)-(float)(.65-game.damageTextTime)*dp(22),14,0xffffc3a0);
   if(game.bossDamageTextTime>0)text(c,"-"+game.lastBossDamage,ox+bx*scale,oy+by*scale-dp(28)-(float)(.65-game.bossDamageTextTime)*dp(22),14,0xffa6efff);
   color(0xff26383c);c.drawRect(dp(8),dp(5),getWidth()*.31f,dp(13),paint);color(0xff72c49a);c.drawRect(dp(8),dp(5),dp(8)+(getWidth()*.31f-dp(8))*game.hp/PracticeCombat.MAX_HP,dp(13),paint);
   text(c,"HP "+game.hp+" / "+PracticeCombat.MAX_HP,dp(8),dp(27),10,0xffe6e4cb);
   float left=getWidth()*.40f,right=getWidth()-dp(8);color(0xff26383c);c.drawRect(left,dp(5),right,dp(13),paint);color(0xffd19563);c.drawRect(left,dp(5),left+(right-left)*game.bossHp/PracticeCombat.MAX_BOSS_HP,dp(13),paint);
   text(c,"STONE WARDEN  "+game.bossHp,left,dp(27),10,0xffe6e4cb);
   disk(c,jx,jy,jr,0xaa15262e);paint.setColor(0xffbda477);paint.setStyle(Paint.Style.STROKE);paint.setStrokeWidth(dp(2));c.drawCircle(jx,jy,jr,paint);paint.setStyle(Paint.Style.FILL);disk(c,jx+knobX*jr,jy+knobY*jr,jr*.38f,0xccd3c299);
  }
  @Override public boolean onTouchEvent(MotionEvent e){int action=e.getActionMasked(),idx=e.getActionIndex();
   if(action==MotionEvent.ACTION_CANCEL){releaseInput();return true;}
   if(game.paused){releaseInput();return true;}
   if((action==MotionEvent.ACTION_DOWN||action==MotionEvent.ACTION_POINTER_DOWN)&&joystick<0&&Math.hypot(e.getX(idx)-jx,e.getY(idx)-jy)<=jr*1.6){joystick=e.getPointerId(idx);getParent().requestDisallowInterceptTouchEvent(true);}
   if((action==MotionEvent.ACTION_UP||action==MotionEvent.ACTION_POINTER_UP)&&e.getPointerId(idx)==joystick){joystick=-1;knobX=knobY=0;game.movement(0,0);performClick();return true;}
   int i=e.findPointerIndex(joystick);if(i>=0){float dx=(e.getX(i)-jx)/jr,dy=(e.getY(i)-jy)/jr,n=(float)Math.hypot(dx,dy);knobX=n>1?dx/n:dx;knobY=n>1?dy/n:dy;game.movement(knobX,knobY);}return true;
  }
  @Override public boolean performClick(){super.performClick();return true;}
 }
}
