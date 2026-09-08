package com.genesis.gacha;

import android.animation.ValueAnimator;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.*;
import android.os.SystemClock;
import android.view.View;

/** Decorative fantasy ritual. Monotonic timing, capped redraws, no gameplay state. */
final class SanctumRitualView extends View {
    private final SharedPreferences prefs;
    private final Paint ink=new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path star=new Path();
    private Shader halo;
    private boolean active,attached;
    private float charge;
    private final long epoch=SystemClock.uptimeMillis();
    private final Runnable tick=()->{invalidate();schedule();};
    SanctumRitualView(Context c,SharedPreferences p){
        super(c);prefs=p;setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_NO);setClickable(false);
    }
    void setRunning(boolean on){active=on;removeCallbacks(tick);if(on)schedule();invalidate();}
    void setCharge(float amount){charge=Math.max(0,Math.min(1,amount));invalidate();}
    private boolean motion(){return active&&attached&&getWindowVisibility()==VISIBLE&&isShown()&&!prefs.getBoolean("reduceMotion",false)&&ValueAnimator.areAnimatorsEnabled();}
    private void schedule(){removeCallbacks(tick);if(motion())postDelayed(tick,33);}
    @Override protected void onAttachedToWindow(){super.onAttachedToWindow();attached=true;schedule();}
    @Override protected void onDetachedFromWindow(){attached=false;removeCallbacks(tick);super.onDetachedFromWindow();}
    @Override protected void onWindowVisibilityChanged(int v){super.onWindowVisibilityChanged(v);if(prefs!=null){removeCallbacks(tick);if(v==VISIBLE)schedule();}}
    @Override protected void onSizeChanged(int w,int h,int ow,int oh){
        float r=Math.max(1,Math.min(w,h)*.48f);
        halo=new RadialGradient(w*.5f,h*.51f,r,new int[]{0x554c326d,0x22382b53,0x00100b13},null,Shader.TileMode.CLAMP);
    }
    @Override protected void onDraw(Canvas c){
        super.onDraw(c);
        float t=motion()?(SystemClock.uptimeMillis()-epoch)/1000f:0;
        float pulse=.5f+.5f*(float)Math.sin(t*1.15);
        float r=Math.min(getWidth(),getHeight())*.405f,cx=getWidth()*.5f,cy=getHeight()*.51f;
        ink.setShader(halo);ink.setStyle(Paint.Style.FILL);ink.setAlpha(180+(int)(55*charge));c.drawRect(0,0,getWidth(),getHeight(),ink);ink.setShader(null);
        c.save();c.translate(cx,cy);c.scale(1,.86f);
        ink.setStyle(Paint.Style.STROKE);
        // Broad low-opacity strokes make a soft halo without per-frame blur buffers.
        for(int pass=0;pass<3;pass++){
            ink.setStrokeWidth((pass==0?7:pass==1?3:1)*getResources().getDisplayMetrics().density);
            ink.setColor(0xffd7b477);ink.setAlpha(pass==0?12:pass==1?28:125+(int)(40*pulse+40*charge));
            c.drawCircle(0,0,r,ink);c.drawCircle(0,0,r*.93f,ink);c.drawCircle(0,0,r*.74f,ink);
            c.save();c.rotate(t*2.2f+charge*16);pentagram(c,r*.69f);c.restore();
        }
        ink.setStrokeWidth(getResources().getDisplayMetrics().density);ink.setColor(0xfff1d39c);ink.setAlpha(140);
        c.save();c.rotate(-t*3.3f-charge*22);
        for(int i=0;i<40;i++){
            c.save();c.rotate(i*9);float a=r*.82f,b=r*.87f;
            // Abstract invented glyphs; individual strokes stay crisp at phone sizes.
            c.drawLine(-r*.018f,-a,r*.018f,-b,ink);
            if(i%3==0)c.drawLine(r*.018f,-b,r*.018f,-a,ink);
            else c.drawLine(-r*.018f,-b,r*.018f,-b,ink);
            c.restore();
        }c.restore();
        ink.setAlpha(100);
        for(int i=0;i<5;i++){
            c.save();c.rotate(i*72+t*2.2f+charge*16);c.drawCircle(0,-r*.69f,r*.037f,ink);c.restore();
        }
        c.restore();
        ink.setStyle(Paint.Style.FILL);
        for(int i=0;i<25;i++){
            float phase=(t*(.055f+(i%3)*.012f)+i*.173f)%1;
            double angle=i*2.39996+t*.045;
            float x=cx+(float)Math.cos(angle)*r*(.35f+(i%7)*.09f);
            float y=cy+r*.6f-phase*r*1.55f;
            ink.setColor(i%3==0?0xffc7b2ef:0xfff1d39c);ink.setAlpha((int)(100*Math.sin(Math.PI*phase)));
            c.drawCircle(x,y,(i%3+1)*getResources().getDisplayMetrics().density*.6f,ink);
        }
        ink.setStyle(Paint.Style.STROKE);ink.setColor(0xffdec799);ink.setAlpha((int)(charge*90));ink.setStrokeWidth(2);
        c.drawOval(cx-r*.28f,cy-r*(.15f+charge*.55f),cx+r*.28f,cy+r*.25f,ink);
    }
    private void pentagram(Canvas c,float r){
        star.reset();for(int i=0;i<=5;i++){double angle=(-90+(i*2%5)*72)*Math.PI/180;float x=(float)Math.cos(angle)*r,y=(float)Math.sin(angle)*r;if(i==0)star.moveTo(x,y);else star.lineTo(x,y);}star.close();c.drawPath(star,ink);
    }
}
