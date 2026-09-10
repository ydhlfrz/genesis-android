package com.genesis.gacha;

import android.animation.*;
import android.content.*;
import android.app.AlertDialog;
import android.view.*;
import android.widget.*;
import org.json.JSONObject;
import java.util.*;

/** Results and decisions remain inside the Sanctum workspace. No dialog/page for reveal. */
final class SanctumPanel extends LinearLayout {
 private final GenesisPresentation.Assets assets;
 private final GenesisPresentation.DecisionHandler decisions;
 private final GenesisAudio audio;
 private final android.content.SharedPreferences prefs;
 private final List<JSONObject> results;
 private final Map<String,String> states;
 private final FrameLayout stage;
 private final LinearLayout badgeHost;
 private Animator idleMotion;
 private final TextView info,counter;
 private final Button keep,discard,previous,next;
 private SanctumRitualView ritual;
 private EmblemRevealView emblem;
 private Animator animation;
 private int index=0;
 private boolean revealed=false,saving=false,alive=true,paused=false,stopping=false;
 SanctumPanel(Context c,android.content.SharedPreferences prefs,GenesisAudio audio,GenesisPresentation.Assets assets,List<JSONObject> results,Map<String,String> states,GenesisPresentation.DecisionHandler decisions){
  super(c);this.prefs=prefs;this.audio=audio;this.assets=assets;this.results=new ArrayList<>(results);this.states=states;this.decisions=decisions;
  setOrientation(VERTICAL);setPadding(dp(8),dp(6),dp(8),dp(6));setBackground(new PixelFrame(c,PixelFrame.PANEL,PixelFrame.GOLD));
  counter=label("SANCTUM",12);badgeHost=new LinearLayout(c);badgeHost.setOrientation(VERTICAL);badgeHost.setVisibility(GONE);addView(badgeHost,new LayoutParams(-1,-2));stage=new FrameLayout(c);stage.setCameraDistance(dp(8000));addView(stage,new LayoutParams(-1,0,1));stage.setMinimumHeight(dp(80));
  info=label("",11);LinearLayout controls=new LinearLayout(c);addView(controls,new LayoutParams(-1,dp(44)));
  previous=button(controls,"‹",()->display(index-1));keep=button(controls,"Keep",()->save(true));discard=button(controls,"Discard",()->{
   if(!revealed){reveal();return;}if(saving)return;
   JSONObject character=this.results.get(index);
   new AlertDialog.Builder(getContext()).setTitle("Discard character?").setMessage(character.optString("race")+" · "+rarity(character)+"\nThis cannot be undone. History remains.").setNegativeButton("Cancel",null).setPositiveButton("Discard",(d,w)->save(false)).show();
  });next=button(controls,"›",()->display(index+1));
  stage.setOnClickListener(v->reveal());display(0);
 }
 private int dp(int n){return Math.round(n*getResources().getDisplayMetrics().density);}
 private TextView label(String text,int size){TextView v=new TextView(getContext());PixelFrame.type(v);v.setText(text);v.setTextSize(size);v.setGravity(Gravity.CENTER);v.setPadding(0,dp(3),0,dp(3));addView(v,new LayoutParams(-1,-2));return v;}
 private Button button(LinearLayout row,String title,Runnable run){Button b=new Button(getContext());PixelFrame.type(b);b.setText(title);b.setTextSize(11);b.setAllCaps(false);b.setPadding(0,0,0,0);b.setBackground(PixelFrame.button(getContext()));if(!prefs.getBoolean("reduceMotion",false))PixelFrame.pressMotion(b);row.addView(b,new LayoutParams(0,-1,title.length()==1?.45f:1));b.setOnClickListener(v->run.run());return b;}
 private String rarity(JSONObject c){JSONObject r=c.optJSONObject("rarity");return r==null?"Common":r.optString("name","Common");}
 private int tier(JSONObject c){String name=rarity(c);if(name.equals("Mythic"))return 8;String[] tiers={"Common","Uncommon","Rare","Special Rare","Super Rare","Super Special Rare","Epic","Legendary","Mythical","Primordial"};for(int i=0;i<tiers.length;i++)if(tiers[i].equals(name))return i;return 0;}
 private String id(){return results.get(index).optString("serverRegistryId");}
 private void stop(){stopping=true;if(idleMotion!=null){idleMotion.cancel();idleMotion=null;}if(emblem!=null)emblem.setTranslationY(0);if(animation!=null){animation.cancel();animation=null;}if(ritual!=null)ritual.setRunning(false);stopping=false;}
 private void display(int position){
  if(saving)return;stop();stage.removeAllViews();emblem=null;badgeHost.removeAllViews();badgeHost.setVisibility(GONE);
  if(results.isEmpty()){counter.setText("SUMMONING SANCTUM");info.setText("Choose a summon on the right");ritual=new SanctumRitualView(getContext(),prefs);stage.addView(ritual,new FrameLayout.LayoutParams(-1,-1));ritual.setRunning(hasWindowFocus());keep.setEnabled(false);discard.setEnabled(false);previous.setEnabled(false);next.setEnabled(false);return;}
  index=Math.max(0,Math.min(results.size()-1,position));revealed=false;counter.setText("CHARACTER "+(index+1)+" / "+results.size()+" · Tap to reveal");info.setText("Result saved · Awaiting your choice");
  ritual=new SanctumRitualView(getContext(),prefs);stage.addView(ritual,new FrameLayout.LayoutParams(-1,-1));ritual.setRunning(hasWindowFocus());
  LinearLayout back=new LinearLayout(getContext());back.setGravity(Gravity.CENTER);back.setOrientation(VERTICAL);stage.addView(back,new FrameLayout.LayoutParams(-1,-1));assets.add(back,"media/branding/genesis-mark.png",65);
  previous.setEnabled(index>0);next.setEnabled(index+1<results.size());keep.setEnabled(false);discard.setEnabled(false);
  if(states.containsKey(id())||prefs.getBoolean("reduceMotion",false)){showResult();return;}
  reveal();
 }
 private void reveal(){
  if(results.isEmpty()||revealed||saving||animation!=null)return;
  if(prefs.getBoolean("reduceMotion",false)||!ValueAnimator.areAnimatorsEnabled()){showResult();return;}
  audio.play("ritual-rise");ValueAnimator rise=ValueAnimator.ofFloat(0,1);animation=rise;rise.setDuration(950);
  rise.addUpdateListener(a->{float t=(float)a.getAnimatedValue();ritual.setCharge(t);stage.setScaleX(1-.08f*(float)Math.sin(Math.PI*t));stage.setRotationY(t>.72f?(t-.72f)/.28f*90:0);});
  rise.addListener(new AnimatorListenerAdapter(){boolean cancelled;@Override public void onAnimationCancel(Animator a){cancelled=true;}@Override public void onAnimationEnd(Animator a){animation=null;stage.setScaleX(1);stage.setRotationY(0);if(!cancelled&&alive)showResult();}});rise.start();
 }
 private void showResult(){
  stop();stage.setScaleX(1);stage.setRotationY(0);stage.removeAllViews();revealed=true;JSONObject c=results.get(index);int tier=tier(c);
  badgeHost.removeAllViews();badgeHost.setVisibility(VISIBLE);String slug=rarity(c).toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+","-");assets.add(badgeHost,"media/rarities/"+(c.optBoolean("legacy",true)?"":"v2/")+slug+".png",38);
  ritual=new SanctumRitualView(getContext(),prefs);ritual.setAlpha(.3f);stage.addView(ritual,new FrameLayout.LayoutParams(-1,-1));ritual.setRunning(hasWindowFocus());
  emblem=new EmblemRevealView(getContext(),c,tier,assets,100);stage.addView(emblem,new FrameLayout.LayoutParams(-1,-1));
  counter.setText((index+1)+" / "+results.size()+"  ·  "+rarity(c));info.setText(c.optString("race")+" · "+c.optString("class")+"\nCP "+c.optInt("combatPower"));
  String state=states.get(id());keep.setText("Keep");discard.setText("Discard");keep.setEnabled(state==null);discard.setEnabled(state==null);if(state!=null){info.append(" · "+state);emblem.settle();startIdle();return;}
  if(prefs.getBoolean("reduceMotion",false)){emblem.settle();return;}
  audio.play("rarity-"+(tier+1));ValueAnimator glow=ValueAnimator.ofFloat(0,1);animation=glow;glow.setDuration(700+tier*65);glow.addUpdateListener(a->{if(emblem!=null)emblem.frame((float)a.getAnimatedValue());});glow.addListener(new AnimatorListenerAdapter(){@Override public void onAnimationEnd(Animator a){animation=null;if(emblem!=null)emblem.settle();if(alive&&!stopping&&!paused)startIdle();}});glow.start();
 }
 private void save(boolean choice){if(!revealed||saving||results.isEmpty()||states.containsKey(id()))return;saving=true;keep.setEnabled(false);discard.setEnabled(false);previous.setEnabled(false);next.setEnabled(false);info.setText("Genesis connecting…");final String key=id();
  decisions.decide(results.get(index),choice,error->{saving=false;if(error==null)states.put(key,choice?"Kept":"Discarded");if(!alive)return;previous.setEnabled(index>0);next.setEnabled(index+1<results.size());if(error==null){info.setText((choice?"Kept · In Collection":"Discarded")+" · "+(index+1)+" / "+results.size());}else{info.setText("Connection interrupted · Retry the same choice");keep.setEnabled(choice);discard.setEnabled(!choice);}});
 }
 private void startIdle(){if(!alive||paused||stopping||emblem==null||prefs.getBoolean("reduceMotion",false)||!ValueAnimator.areAnimatorsEnabled())return;if(idleMotion!=null)idleMotion.cancel();android.animation.ObjectAnimator idle=android.animation.ObjectAnimator.ofFloat(emblem,"translationY",0,-dp(2),0);idle.setDuration(3200);idle.setRepeatCount(ValueAnimator.INFINITE);idleMotion=idle;idle.start();}
 void pause(){paused=true;stop();if(emblem!=null)emblem.settle();}
 @Override protected void onAttachedToWindow(){super.onAttachedToWindow();alive=true;if(ritual!=null&&!revealed)ritual.setRunning(hasWindowFocus());}
 @Override public void onWindowFocusChanged(boolean focus){super.onWindowFocusChanged(focus);if(ritual!=null)ritual.setRunning(focus);}
 void resume(){paused=false;if(ritual!=null)ritual.setRunning(hasWindowFocus());if(!results.isEmpty()&&!revealed)showResult();else if(revealed)startIdle();}
 @Override protected void onDetachedFromWindow(){alive=false;stop();super.onDetachedFromWindow();}
}
