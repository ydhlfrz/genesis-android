package com.genesis.gacha;

import android.animation.*;
import android.app.*;
import android.content.SharedPreferences;
import android.graphics.*;
import android.graphics.drawable.GradientDrawable;
import android.os.*;
import android.view.*;
import android.view.animation.LinearInterpolator;
import android.widget.*;
import org.json.*;
import java.util.*;

/** Renders confirmed results only. Never initiates an RPC or changes an outcome. */
final class GenesisPresentation {
    interface Assets { void add(LinearLayout parent,String path,int height); }
    static final String[] RARITIES={"Common","Uncommon","Rare","Special Rare","Super Rare","Super Special Rare","Epic","Legendary","Mythical","Primordial"};
    private static final int[] COLORS={0xffb8c3cc,0xff78cc98,0xff66b9ee,0xff58d6cd,0xff918aff,0xffd686ec,0xffc066f0,0xffffca70,0xffef91c6,0xffdce5ff};
    private final Activity activity;
    private final SharedPreferences prefs;
    private final GenesisAudio audio;
    private final Assets assets;
    private final Handler handler=new Handler(Looper.getMainLooper());
    private final ArrayList<Animator> animations=new ArrayList<>();
    private final ArrayList<RevealCard> cards=new ArrayList<>();
    private Dialog dialog;
    private FrameLayout stage;
    private ScrollView resultScroll;
    private SanctumRitualView ritual;
    private boolean introducing;
    private boolean closing,playing,foreground;
    private TextView counter;
    private Button playButton;

    GenesisPresentation(Activity a,SharedPreferences p,GenesisAudio s,Assets images){activity=a;prefs=p;audio=s;assets=images;}
    private int dp(int n){return Math.round(n*activity.getResources().getDisplayMetrics().density);}
    private boolean reduced(){return !foreground||prefs.getBoolean("reduceMotion",false)||!ValueAnimator.areAnimatorsEnabled();}
    private LinearLayout column(){LinearLayout p=new LinearLayout(activity);p.setOrientation(LinearLayout.VERTICAL);return p;}
    private TextView label(LinearLayout p,String text,int size,int color){TextView v=new TextView(activity);v.setText(text);v.setTextSize(size);v.setTextColor(color);v.setGravity(Gravity.CENTER);v.setPadding(dp(4),dp(6),dp(4),dp(6));p.addView(v);return v;}
    private Button action(LinearLayout p,String title,Runnable r){Button b=new Button(activity);b.setText(title);b.setAllCaps(false);p.addView(b,new LinearLayout.LayoutParams(-1,-2));b.setOnClickListener(v->r.run());return b;}
    private String slug(String s){return s.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+","-").replaceAll("^-|-$","");}
    private static JSONObject object(JSONObject o,String key){JSONObject v=o==null?null:o.optJSONObject(key);return v==null?new JSONObject():v;}
    private String name(JSONObject c){String s=c.optString("customName").trim();return s.isEmpty()?"UNNAMED HERO":s;}
    private int tier(JSONObject c){String rarity=object(c,"rarity").optString("name");for(int i=0;i<RARITIES.length;i++)if(RARITIES[i].equals(rarity))return i;return 0;}
    private void show(LinearLayout content,String title){
        LinearLayout shell=column();shell.setBackground(new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM,new int[]{0xff100d1c,0xff171019,0xff0c0a10}));
        shell.setPadding(dp(12),dp(8),dp(12),dp(10));
        shell.setOnApplyWindowInsetsListener((v,insets)->{v.setPadding(dp(12),insets.getSystemWindowInsetTop()+dp(8),dp(12),insets.getSystemWindowInsetBottom()+dp(10));return insets;});
        label(shell,"G E N E S I S",13,0xffd6ad62);label(shell,title,23,0xfff5ead8);
        stage=new FrameLayout(activity);shell.addView(stage,new LinearLayout.LayoutParams(-1,0,1));
        resultScroll=new ScrollView(activity);resultScroll.setClipToPadding(false);resultScroll.addView(content);stage.addView(resultScroll,new FrameLayout.LayoutParams(-1,-1));
        content.setPadding(dp(4),dp(12),dp(4),dp(12));
        action(shell,"Skip animation · Show results",this::finishAll);
        action(shell,"Continue",()->{if(dialog!=null)dialog.dismiss();});
        dialog=new Dialog(activity,android.R.style.Theme_Material_NoActionBar);
        dialog.setContentView(shell);dialog.setOnDismissListener(d->{closing=true;cancelAnimations();if(ritual!=null)ritual.setRunning(false);audio.stopEffects();audio.setScene(false);cards.clear();dialog=null;});
        dialog.show();if(dialog.getWindow()!=null)dialog.getWindow().setLayout(-1,-1);shell.requestApplyInsets();audio.setScene(true);
    }
    private void entrance(boolean multi){
        for(int i=0;i<cards.size();i++){
            RevealCard card=cards.get(i);card.setAlpha(0);card.setTranslationY(dp(32));
            AnimatorSet enter=new AnimatorSet();enter.playTogether(ObjectAnimator.ofFloat(card,"alpha",0,1),ObjectAnimator.ofFloat(card,"translationY",dp(32),0));
            enter.setStartDelay(i*65L);enter.setDuration(380);enter.setInterpolator(new android.view.animation.DecelerateInterpolator());track(enter);
        }
        if(!multi&&!cards.isEmpty())handler.postDelayed(()->{if(!closing)cards.get(0).reveal(null);},420);
        if(playButton!=null)playButton.setEnabled(true);
    }
    private void beginRitual(boolean multi){
        introducing=true;resultScroll.setVisibility(View.INVISIBLE);if(playButton!=null)playButton.setEnabled(false);
        ritual=new SanctumRitualView(activity,prefs);stage.addView(ritual,new FrameLayout.LayoutParams(-1,-1));ritual.setRunning(true);audio.play("ritual-rise");
        ValueAnimator charge=ValueAnimator.ofFloat(0,1);charge.setDuration(1600);charge.setInterpolator(new android.view.animation.AccelerateDecelerateInterpolator());
        charge.addUpdateListener(a->{float t=(float)a.getAnimatedValue();ritual.setCharge(t);ritual.setScaleX(1+t*.1f);ritual.setScaleY(1+t*.1f);ritual.setAlpha(t>.75f?(1-t)*4:1);});
        charge.addListener(new AnimatorListenerAdapter(){boolean cancelled;@Override public void onAnimationCancel(Animator a){cancelled=true;}@Override public void onAnimationEnd(Animator a){if(cancelled||closing)return;introducing=false;ritual.setRunning(false);ritual.setVisibility(View.GONE);resultScroll.setVisibility(View.VISIBLE);entrance(multi);}});track(charge);
    }
    void preview(int rarity){
        new AlertDialog.Builder(activity).setTitle("Choose race family").setItems(EmblemRevealView.FAMILIES,(d,index)->previewExample(rarity,index)).show();
    }
    private void previewExample(int rarity,int family){
        try{
            JSONObject c=new JSONObject();c.put("customName","Effect preview");c.put("race",EmblemRevealView.EXAMPLES[family]);c.put("baseRace",EmblemRevealView.EXAMPLES[family]);c.put("raceCategory",EmblemRevealView.FAMILIES[family]);c.put("class","Preview");c.put("rarity",new JSONObject().put("name",RARITIES[rarity]));
            summonInternal(Collections.singletonList(c),true);
        }catch(JSONException ignored){}
    }
    void summon(List<JSONObject> results){summonInternal(results,false);}
    private void summonInternal(List<JSONObject> results,boolean preview){
        close();closing=false;
        LinearLayout content=column();
        counter=label(content,"",14,0xffd6ad62);
        label(content,preview?"Presentation preview · No character created.":"Characters are already saved to your Collection.",12,0xffbda98c);
        boolean multi=results.size()>1;
        LinearLayout row=null;
        for(int i=0;i<results.size();i++){
            if(!multi||i%2==0){row=new LinearLayout(activity);row.setOrientation(LinearLayout.HORIZONTAL);content.addView(row);}
            RevealCard card=new RevealCard(results.get(i),i+1,multi);
            LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(0,dp(multi?320:470),1);lp.setMargins(dp(3),dp(4),dp(3),dp(4));
            row.addView(card,lp);cards.add(card);
        }
        if(multi){
            playButton=action(content,"Play reveal sequence",()->{
                if(playing||introducing)return;playing=true;playButton.setEnabled(false);next();
            });
            action(content,"Reveal all · Skip animation",this::finishAll);
            label(content,"Tap any card to reveal it individually.",12,0xffbda98c);
        }else action(content,"Skip animation",this::finishAll);
        show(content,preview?"Rarity effect preview":multi?"Summon ×"+results.size():"Summon result");
        updateCount();
        if(reduced())finishAll();else beginRitual(multi);
    }
    private void next(){
        if(closing||!playing)return;
        for(RevealCard c:cards)if(c.flipping){handler.postDelayed(this::next,150);return;}
        for(RevealCard c:cards)if(!c.revealed&&!c.flipping){
            c.requestRectangleOnScreen(new Rect(0,0,c.getWidth(),c.getHeight()),false);
            c.reveal(()->handler.postDelayed(this::next,200));return;
        }
        // An individually tapped card may still be revealing.
        for(RevealCard c:cards)if(c.flipping){handler.postDelayed(this::next,150);return;}
        playing=false;if(playButton!=null)playButton.setEnabled(false);
    }
    private void updateCount(){if(counter!=null){int n=0;for(RevealCard c:cards)if(c.revealed)n++;counter.setText(n+" / "+cards.size()+" revealed");}}
    private void track(Animator a){animations.add(a);a.addListener(new AnimatorListenerAdapter(){@Override public void onAnimationEnd(Animator x){animations.remove(x);}});a.start();}
    private void cancelAnimations(){handler.removeCallbacksAndMessages(null);for(Animator a:new ArrayList<>(animations))a.cancel();animations.clear();playing=false;}
    void finishAll(){
        cancelAnimations();audio.stopEffects();introducing=false;if(ritual!=null){ritual.setRunning(false);ritual.setVisibility(View.GONE);}if(resultScroll!=null)resultScroll.setVisibility(View.VISIBLE);
        for(RevealCard c:cards)c.finish();updateCount();if(playButton!=null)playButton.setEnabled(false);
    }
    void resume(){foreground=true;}
    void pause(){foreground=false;finishAll();}
    void close(){closing=true;cancelAnimations();audio.stopEffects();if(dialog!=null)dialog.dismiss();if(ritual!=null)ritual.setRunning(false);audio.setScene(false);cards.clear();counter=null;playButton=null;ritual=null;stage=null;resultScroll=null;introducing=false;}

    private final class RevealCard extends FrameLayout {
        final JSONObject character;
        final int rarity;
        final LinearLayout back,front;
        final EmblemRevealView emblem;
        final View badge;
        boolean revealed,flipping;
        RevealCard(JSONObject c,int number,boolean compact){
            super(activity);character=c;rarity=tier(c);setCameraDistance(dp(8000));
            GradientDrawable border=new GradientDrawable();border.setColor(0xff201726);border.setCornerRadius(dp(14));border.setStroke(dp(1),0xff796644);setBackground(border);setElevation(dp(5));
            back=column();back.setGravity(Gravity.CENTER);addView(back,new FrameLayout.LayoutParams(-1,-1));
            assets.add(back,"media/branding/genesis-mark.png",compact?120:190);
            label(back,"GENESIS",18,0xffd6ad62);label(back,"Character "+number+" · Tap to reveal",12,0xffc4b69a);
            front=column();front.setGravity(Gravity.CENTER);front.setVisibility(View.GONE);addView(front,new FrameLayout.LayoutParams(-1,-1));
            assets.add(front,"media/rarities/"+slug(RARITIES[rarity])+".png",compact?55:85);badge=front.getChildAt(0);
            emblem=new EmblemRevealView(activity,c,rarity,assets,compact?150:240);front.addView(emblem,new LinearLayout.LayoutParams(-1,dp(compact?150:240)));
            label(front,name(c),compact?13:20,0xfff5ead8);
            label(front,c.optString("race")+" · "+c.optString("class"),12,0xffc6b9cf);
            label(front,"CP "+c.optInt("combatPower")+" · "+RARITIES[rarity],12,COLORS[rarity]);
            setContentDescription("Unrevealed character "+number);setFocusable(true);setOnClickListener(v->reveal(null));
        }
        void finish(){flipping=false;revealed=true;setAlpha(1);setTranslationY(0);setScaleX(1);setScaleY(1);setRotationY(0);back.setVisibility(View.GONE);front.setVisibility(View.VISIBLE);emblem.settle();badge.setScaleX(1);badge.setScaleY(1);for(int i=0;i<front.getChildCount();i++)front.getChildAt(i).setAlpha(1);setContentDescription(name(character)+", "+RARITIES[rarity]+", "+character.optString("race")+", CP "+character.optInt("combatPower"));}
        void reveal(Runnable done){
            if(closing||introducing||revealed||flipping)return;
            if(reduced()){finish();updateCount();if(done!=null)done.run();return;}
            for(RevealCard other:cards)if(other!=this&&other.flipping)return;
            flipping=true;emblem.frame(0);badge.setAlpha(0);audio.play("flip");
            ValueAnimator flip=ValueAnimator.ofFloat(0,1);flip.setDuration(480);final boolean[] turned={false};
            flip.addUpdateListener(a->{float t=(float)a.getAnimatedValue();if(t>=.5f&&!turned[0]){turned[0]=true;back.setVisibility(View.GONE);front.setVisibility(View.VISIBLE);}setRotationY(t<.5f?t*180:(t-1)*180);float lift=(float)Math.sin(Math.PI*t);setTranslationY(-dp(9)*lift);setScaleX(1+.035f*lift);setScaleY(1+.035f*lift);});
            flip.addListener(new AnimatorListenerAdapter(){boolean cancelled;@Override public void onAnimationCancel(Animator a){cancelled=true;}@Override public void onAnimationEnd(Animator a){
                if(cancelled||closing)return;
                setRotationY(0);setTranslationY(0);setScaleX(1);setScaleY(1);revealed=true;updateCount();
                setContentDescription(name(character)+", "+RARITIES[rarity]+", "+character.optString("race")+", CP "+character.optInt("combatPower"));
                GradientDrawable revealedBorder=new GradientDrawable(GradientDrawable.Orientation.TL_BR,new int[]{0xff2c2135,0xff17131c});revealedBorder.setCornerRadius(dp(14));revealedBorder.setStroke(dp(1),COLORS[rarity]);setBackground(revealedBorder);
                for(int index=2;index<front.getChildCount();index++){View text=front.getChildAt(index);ObjectAnimator fade=ObjectAnimator.ofFloat(text,"alpha",0,1);fade.setStartDelay((index-2)*85L);fade.setDuration(320);track(fade);}
                audio.play("rarity-"+(rarity+1));
                ValueAnimator badgeIn=ValueAnimator.ofFloat(0,1);badgeIn.setDuration(550);badgeIn.addUpdateListener(a->{float t=(float)a.getAnimatedValue();badge.setAlpha(Math.min(1,t*2));float size=.82f+.18f*t+.055f*(float)Math.sin(Math.PI*t);badge.setScaleX(size);badge.setScaleY(size);});track(badgeIn);
                animateEmblem(emblem,1250+rarity*110,()->{badge.setAlpha(1);badge.setScaleX(1);badge.setScaleY(1);flipping=false;if(done!=null)done.run();});
            }});track(flip);
        }
    }
    private void animateEmblem(EmblemRevealView emblem,long duration,Runnable done){
        if(reduced()){emblem.settle();if(done!=null)done.run();return;}
        ValueAnimator a=ValueAnimator.ofFloat(0,1);a.setDuration(duration);a.setInterpolator(new LinearInterpolator());
        a.addUpdateListener(v->emblem.frame((float)v.getAnimatedValue()));
        a.addListener(new AnimatorListenerAdapter(){boolean cancelled;@Override public void onAnimationCancel(Animator v){cancelled=true;}@Override public void onAnimationEnd(Animator v){emblem.settle();if(!cancelled&&!closing&&done!=null)done.run();}});track(a);
    }
    private void animateSigil(Sigil v,long duration,Runnable done){
        if(reduced()){v.setVisibility(View.GONE);if(done!=null)done.run();return;}
        ValueAnimator a=ValueAnimator.ofFloat(0,1);a.setDuration(duration);a.setInterpolator(new LinearInterpolator());
        a.addUpdateListener(x->{v.progress=(float)x.getAnimatedValue();v.invalidate();});
        a.addListener(new AnimatorListenerAdapter(){boolean cancelled;@Override public void onAnimationCancel(Animator x){cancelled=true;}@Override public void onAnimationEnd(Animator x){v.setVisibility(View.GONE);if(!cancelled&&!closing&&done!=null)done.run();}});track(a);
    }
    void progression(String kind,JSONObject before,JSONObject after,String slot){
        close();closing=false;LinearLayout content=column();
        String title=kind.equals("train")?"Training complete":kind.equals("upgrade")?"Upgrade complete":"Evolution complete";
        FrameLayout frame=new FrameLayout(activity);content.addView(frame,new LinearLayout.LayoutParams(-1,dp(230)));
        SanctumRitualView backdrop=new SanctumRitualView(activity,prefs);frame.addView(backdrop,new FrameLayout.LayoutParams(-1,-1));
        EmblemRevealView picture=new EmblemRevealView(activity,after,tier(after),assets,230);frame.addView(picture,new FrameLayout.LayoutParams(-1,-1));
        Sigil effect=new Sigil(tier(after),kind);frame.addView(effect,new FrameLayout.LayoutParams(-1,-1));
        label(content,name(after),23,0xfff5ead8);
        if(kind.equals("train"))label(content,"Level "+object(before,"progression").optInt("level",1)+" → "+object(after,"progression").optInt("level",1),18,0xff83d5b5);
        if(kind.equals("evolution")){
            String[] stages={"Base","Awakened","Ascended","Transcendent"};
            label(content,stages[Math.max(0,Math.min(3,object(before,"progression").optInt("stage")))]+" → "+stages[Math.max(0,Math.min(3,object(after,"progression").optInt("stage")))],18,0xffd4a6ff);
        }
        if(kind.equals("upgrade")){
            int old=slot.equals("weapon")?before.optInt("weaponUpgrade"):object(object(before,"equipment"),slot).optInt("upgrade");
            int now=slot.equals("weapon")?after.optInt("weaponUpgrade"):object(object(after,"equipment"),slot).optInt("upgrade");
            label(content,slot.toUpperCase(Locale.ROOT)+" +"+old+" → +"+now,18,0xffffca70);
        }
        label(content,"CP "+before.optInt("combatPower")+" → "+after.optInt("combatPower"),16,0xffd6ad62);
        label(content,"Saved to your account.",13,0xffbda98c);
        action(content,"Skip animation",()->{cancelAnimations();effect.setVisibility(View.GONE);audio.stopEffects();});
        show(content,title);audio.play(kind);animateEmblem(picture,kind.equals("evolution")?2300:1250,null);animateSigil(effect,kind.equals("evolution")?2300:1250,null);
    }

    /** Ten geometric signatures, plus three progression motions. No bitmap allocation per frame. */
    private final class Sigil extends View {
        final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);
        final Path path=new Path();
        final int tier;final String kind;float progress;
        Sigil(int t,String k){super(activity);tier=t;kind=k;setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);setClickable(false);}
        @Override protected void onDraw(Canvas c){
            super.onDraw(c);float t=progress;
            float cx=getWidth()/2f,cy=getHeight()/2f,r=Math.min(getWidth(),getHeight())*.36f;
            paint.setColor(kind.equals("train")?0xff83d5b5:kind.equals("upgrade")?0xffffca70:COLORS[tier]);
            paint.setStyle(Paint.Style.STROKE);paint.setStrokeWidth(dp(2));
            paint.setAlpha((int)(190*Math.sin(Math.PI*t)));
            c.save();c.translate(cx,cy);
            if(kind.equals("train")){
                for(int i=0;i<12;i++){float x=(i%4-1.5f)*r*.5f,y=r-((t+i/12f)%1)*2*r;c.drawLine(x,y,x,y+dp(14),paint);}
                c.drawArc(-r,-r,r,r,90,-360*t,false,paint);
            }else if(kind.equals("upgrade")){
                for(int i=0;i<16;i++){double a=i*Math.PI/8;float d=r*(.1f+t);c.drawLine((float)Math.cos(a)*d,(float)Math.sin(a)*d,(float)Math.cos(a)*(d+dp(10)),(float)Math.sin(a)*(d+dp(10)),paint);}
                polygon(c,4,r*(.7f+.2f*t),45+t*30);
            }else if(kind.equals("evolution")){
                for(int i=0;i<3;i++){c.save();c.rotate(i*60+t*100);c.drawOval(-r,-r*.32f,r,r*.32f,paint);c.restore();}
                polygon(c,6,r*(.8f+.2f*t),-t*60);
            }else switch(tier){
                case 0:c.drawCircle(0,0,r*(.6f+.35f*t),paint);break;
                case 1:for(int i=0;i<6;i++){c.save();c.rotate(i*60+t*35);c.drawOval(-r*.13f,-r,-r*.13f+r*.26f,-r*.52f,paint);c.restore();}break;
                case 2:for(int i=0;i<3;i++)c.drawCircle(0,0,r*(.3f+((t+i*.25f)%.7f)),paint);break;
                case 3:c.save();c.rotate(t*90);for(int i=0;i<4;i++)c.drawArc(-r,-r,r,r,i*90,55,false,paint);c.restore();polygon(c,4,r*.8f,-t*60);break;
                case 4:polygon(c,4,r,t*70);polygon(c,4,r*.72f,-t*90);break;
                case 5:polygon(c,6,r,t*45);for(int i=0;i<6;i++){c.save();c.rotate(i*60-t*50);c.drawCircle(0,-r*.74f,dp(5),paint);c.restore();}break;
                case 6:polygon(c,3,r,t*70);polygon(c,3,r,-t*70+180);c.drawCircle(0,0,r*.55f,paint);break;
                case 7:for(int i=0;i<12;i++){c.save();c.rotate(i*30);c.drawLine(0,-r*.78f,0,-r*(1+.08f*t),paint);c.restore();}polygon(c,8,r*.75f,t*20);break;
                case 8:for(int i=0;i<3;i++){c.save();c.rotate(i*60+t*45);c.drawOval(-r,-r*.4f,r,r*.4f,paint);c.restore();}polygon(c,5,r*.68f,-t*45);break;
                default:c.drawCircle(0,0,r,paint);c.drawCircle(0,0,r*.85f,paint);polygon(c,10,r*.92f,t*25);polygon(c,5,r*.68f,-t*35);break;
            }
            c.restore();
        }
        private void polygon(Canvas c,int sides,float radius,float rotation){path.reset();for(int i=0;i<=sides;i++){double a=(rotation-90+i*360.0/sides)*Math.PI/180;float x=(float)Math.cos(a)*radius,y=(float)Math.sin(a)*radius;if(i==0)path.moveTo(x,y);else path.lineTo(x,y);}path.close();c.drawPath(path,paint);}
    }
}
