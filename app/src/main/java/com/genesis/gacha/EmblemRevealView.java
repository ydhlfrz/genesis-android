package com.genesis.gacha;

import android.content.Context;
import android.graphics.*;
import android.view.View;
import android.widget.*;
import org.json.JSONObject;
import java.util.Locale;

/** Finite reveal choreography. Every frame is driven by its owner's cancellable animator. */
final class EmblemRevealView extends FrameLayout {
    static final String[] FAMILIES={"Mortal","Fae","Beast","Undead","Celestial","Infernal","Divine","Draconic","Eldritch","Ancient","Elemental","Spirit","Construct","Special Bloodline"};
    static final String[] EXAMPLES={"Human","Elf","Leonin","Ghost","Angel","Oni","God","Dragonkin","Voidborn","Asgardian","Slime","Spiritborn","Golem","Targaryen"};
    private static final int[] TIER_COLORS={0xffb9ccd7,0xff80d69e,0xff70caff,0xff60e4d5,0xffa796ff,0xffed9def,0xffba7cff,0xffffd27c,0xfff2a2da,0xffe1e5ff};
    private final LinearLayout emblem;
    private final Field back,glints;
    private final int tier,family;
    private float phase=1;
    private final float density;
    EmblemRevealView(Context c,JSONObject character,int rarity,GenesisPresentation.Assets assets,int height){
        super(c);density=getResources().getDisplayMetrics().density;tier=Math.max(0,Math.min(9,rarity));
        String name=character.optString("raceCategory","Mortal");int match=0;
        for(int i=0;i<FAMILIES.length;i++)if(FAMILIES[i].equals(name)){match=i;break;}family=match;
        setClipChildren(false);setClipToPadding(false);
        back=new Field(c,false);addView(back,new FrameLayout.LayoutParams(-1,-1));
        emblem=new LinearLayout(c);emblem.setOrientation(LinearLayout.VERTICAL);emblem.setGravity(android.view.Gravity.CENTER);
        addView(emblem,new FrameLayout.LayoutParams(-1,-1));
        String race=character.optString("baseRace",character.optString("race","Unknown"));
        String slug=race.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+","-").replaceAll("^-|-$","");
        assets.add(emblem,"media/races/"+slug+".png",Math.round(height*.72f));
        glints=new Field(c,true);addView(glints,new FrameLayout.LayoutParams(-1,-1));
        setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_NO);
    }
    void frame(float value){
        phase=Math.max(0,Math.min(1,value));float pop=Math.min(1,phase/.23f);
        float ease=1-(float)Math.pow(1-pop,3);float scale=.64f+.36f*ease+.065f*(float)Math.sin(Math.PI*pop);
        emblem.setScaleX(scale);emblem.setScaleY(scale);emblem.setAlpha(Math.min(1,phase/.1f));
        emblem.setRotation(-5*(1-ease));emblem.setTranslationY((1-ease)*12*density+(float)Math.sin(phase*Math.PI*2)*2*density);
        back.invalidate();glints.invalidate();
    }
    void settle(){phase=1;emblem.setScaleX(1);emblem.setScaleY(1);emblem.setRotation(0);emblem.setTranslationY(0);emblem.setAlpha(1);back.invalidate();glints.invalidate();}

    private final class Field extends View {
        final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
        final Path path=new Path();
        final boolean foreground;
        Shader aura;
        Field(Context c,boolean front){super(c);foreground=front;setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_NO);}
        @Override protected void onSizeChanged(int w,int h,int ow,int oh){
            int rgb=TIER_COLORS[tier]&0x00ffffff;
            aura=new RadialGradient(w*.5f,h*.5f,Math.max(1,Math.min(w,h)*.49f),new int[]{0x55000000|rgb,0x26000000|rgb,rgb},new float[]{0,.48f,1},Shader.TileMode.CLAMP);
        }
        @Override protected void onDraw(Canvas c){
            super.onDraw(c);float r=Math.min(getWidth(),getHeight())*.43f,t=phase;
            float energy=(float)Math.sin(Math.PI*Math.min(1,t));
            if(!foreground){p.setStyle(Paint.Style.FILL);p.setShader(aura);p.setAlpha((int)(85+170*energy));c.drawRect(0,0,getWidth(),getHeight(),p);p.setShader(null);}
            c.save();c.translate(getWidth()*.5f,getHeight()*.5f);
            p.setStrokeCap(Paint.Cap.ROUND);p.setColor(TIER_COLORS[tier]);
            if(!foreground){
                p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(density);p.setAlpha((int)(28+100*energy));
                float expanding=Math.min(1,t/.38f);c.drawCircle(0,0,r*(.45f+.48f*expanding),p);
                if(t<.62f){p.setAlpha((int)(100*(1-t/.62f)));c.drawCircle(0,0,r*(.38f+t),p);}
                rarity(c,r,t,energy);
                family(c,r,t,energy);
            }else{
                // Highlights live outside the centre so the race artwork remains legible.
                p.setStyle(Paint.Style.FILL);int count=10+tier*3;
                for(int i=0;i<count;i++){
                    float seed=(i*.618034f)%1;double angle=i*2.39996+t*(.35+tier*.04);
                    float radius=r*(.74f+.22f*seed+.1f*(float)Math.sin(t*4+i));
                    float x=(float)Math.cos(angle)*radius,y=(float)Math.sin(angle)*radius;
                    float shine=Math.max(0,(float)Math.sin(t*5.5+i*1.7))*energy;
                    p.setColor(i%3==0?0xffffefd4:TIER_COLORS[tier]);p.setAlpha((int)(180*shine));
                    c.drawCircle(x,y,density*(.7f+seed),p);
                    if(i%5==0){p.setStrokeWidth(density*.7f);c.drawLine(x-3*density,y,x+3*density,y,p);c.drawLine(x,y-3*density,x,y+3*density,p);}
                }
            }
            c.restore();
        }
        private void rarity(Canvas c,float r,float t,float e){
            p.setColor(TIER_COLORS[tier]);p.setAlpha((int)(155*e));p.setStrokeWidth(density*1.1f);p.setStyle(Paint.Style.STROKE);
            switch(tier){
                case 0: c.drawArc(-r,-r,r,r,-90+t*50,115,false,p);break;
                case 1: for(int i=0;i<6;i++){c.save();c.rotate(i*60+t*25);c.drawOval(-r*.07f,-r,r*.07f,-r*.77f,p);c.restore();}break;
                case 2: shards(c,r,t,8,e);break;
                case 3: for(int i=0;i<3;i++)c.drawArc(-r,-r,r,r,i*120-t*65,75,false,p);break;
                case 4: shards(c,r,t,12,e);orbit(c,r,t,2);break;
                case 5: orbit(c,r,t,3);shards(c,r*.87f,t,6,e);break;
                case 6: // Rune fragments emerge in a spiral, then drift outwards.
                    for(int i=0;i<10;i++){c.save();c.rotate(i*36+70*t);float y=-r*(.65f+.35f*t);c.drawLine(-r*.05f,y,r*.05f,y-r*.09f,p);c.drawLine(r*.05f,y-r*.09f,r*.05f,y+r*.035f,p);c.restore();}shards(c,r,t,9,e);break;
                case 7: // Gold corona with broad translucent shafts behind the emblem.
                    p.setStyle(Paint.Style.FILL);p.setAlpha((int)(50*e));for(int i=0;i<12;i++){c.save();c.rotate(i*30+t*8);path.reset();path.moveTo(-r*.035f,-r*.52f);path.lineTo(-r*.07f,-r*1.05f);path.lineTo(r*.07f,-r*1.05f);path.lineTo(r*.035f,-r*.52f);path.close();c.drawPath(path,p);c.restore();}break;
                case 8: // Sweeping aurora ribbons.
                    for(int i=0;i<3;i++){c.save();c.rotate(i*60+t*28);p.setStrokeWidth(density*(4-i));p.setAlpha((int)((45+i*22)*e));c.drawOval(-r,-r*.5f,r,r*.5f,p);c.restore();}shards(c,r,t,8,e);break;
                default: // Eclipse horizon and orbiting star field.
                    p.setStrokeWidth(density*3);p.setAlpha((int)(65*e));c.drawCircle(0,0,r*.85f,p);p.setStrokeWidth(density);p.setAlpha((int)(180*e));c.drawArc(-r*.87f,-r*.87f,r*.87f,r*.87f,t*90,245,false,p);orbit(c,r,t,3);shards(c,r,t,15,e);break;
            }
        }
        private void orbit(Canvas c,float r,float t,int count){p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(density);for(int i=0;i<count;i++){c.save();c.rotate(i*60+t*45);c.drawOval(-r,-r*.38f,r,r*.38f,p);c.restore();}}
        private void shards(Canvas c,float r,float t,int count,float e){
            p.setStyle(Paint.Style.FILL);p.setAlpha((int)(110*e));
            for(int i=0;i<count;i++){c.save();c.rotate(i*360f/count+t*(i%2==0?30:-18));float d=r*(.73f+.24f*t),w=r*.025f;path.reset();path.moveTo(0,-d-r*.12f);path.lineTo(w,-d);path.lineTo(0,-d+r*.035f);path.lineTo(-w,-d);path.close();c.drawPath(path,p);c.restore();}
        }
        private void family(Canvas c,float r,float t,float e){
            p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(density*1.3f);p.setAlpha((int)(130*e));
            switch(family){
                case 1: // Fae: drifting leaf contours.
                    p.setColor(0xff9de6b5);p.setAlpha((int)(130*e));for(int i=0;i<5;i++){c.save();c.rotate(i*72-t*25);c.drawOval(-r*.04f,-r*.85f,r*.04f,-r*.69f,p);c.restore();}break;
                case 2: // Beast: swept claw-like streaks, without impact imagery.
                    for(int side=-1;side<=1;side+=2)for(int i=0;i<3;i++){float x=side*r*(.62f+i*.08f);c.drawLine(x,-r*.3f,x-side*r*.12f,r*.3f,p);}break;
                case 3: case 8: case 11: // Undead, Eldritch, Spirit: wisps with distinct palettes.
                    p.setColor(family==3?0xff92dfc3:family==8?0xff9c8cde:0xffacdef3);p.setAlpha((int)(90*e));
                    for(int i=0;i<3;i++){path.reset();float x=(i-1)*r*.67f;path.moveTo(x,r*.7f);path.cubicTo(x+r*.4f*(float)Math.sin(t*4+i),r*.1f,x-r*.3f,-r*.2f,x,-r*.85f);c.drawPath(path,p);}break;
                case 4: case 6: // Celestial and Divine: fan of feather-light rays.
                    p.setColor(family==4?0xffb9dfff:0xffffe1a2);p.setAlpha((int)(110*e));for(int i=0;i<7;i++){c.save();c.rotate((i-3)*18);c.drawLine(0,-r*.74f,0,-r*(.9f+.09f*(float)Math.sin(t*3+i)),p);c.restore();}break;
                case 5: case 7: case 13: // Infernal / Draconic / Special Bloodline: rising embers.
                    p.setColor(family==5?0xffff9868:family==7?0xfff4be70:0xffde9cb3);p.setAlpha((int)(135*e));p.setStyle(Paint.Style.FILL);
                    for(int i=0;i<10;i++){float x=(float)Math.sin(i*2.4)*r*.8f,y=r*.75f-((t*.8f+i*.137f)%1)*r*1.5f;c.drawCircle(x,y,density*(i%2+1),p);}break;
                case 9: case 12: // Ancient / Construct: orbiting engraved plates.
                    for(int i=0;i<6;i++){c.save();c.rotate(i*60-t*20);c.drawRect(-r*.04f,-r*.92f,r*.04f,-r*.82f,p);c.restore();}break;
                case 10: for(int i=0;i<2;i++)c.drawArc(-r,-r*.7f,r,r*.7f,i*180+t*75,110,false,p);break;
                default: c.drawArc(-r*.83f,-r*.83f,r*.83f,r*.83f,45-t*30,90,false,p);c.drawArc(-r*.83f,-r*.83f,r*.83f,r*.83f,225-t*30,90,false,p);break;
            }
        }
    }
}
