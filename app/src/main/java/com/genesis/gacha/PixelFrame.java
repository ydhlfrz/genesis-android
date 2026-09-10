package com.genesis.gacha;

import android.content.Context;
import android.graphics.*;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.StateListDrawable;
import android.widget.TextView;

/** Resolution-independent stepped RPG frames; no external texture or font download. */
final class PixelFrame extends Drawable {
 static final int INK=0xff121919,PANEL=0xff1d2626,GOLD=0xffc69a55,TEXT=0xffeee1c2,MUTED=0xffb8b39e;
 private final Paint paint=new Paint();
 private final float unit;
 private final int fill,edge;
 PixelFrame(Context context,int fill,int edge){unit=Math.max(1,context.getResources().getDisplayMetrics().density);this.fill=fill;this.edge=edge;}
 private void block(Canvas c,float x,float y,float w,float h,int color){paint.setColor(color);c.drawRect(x*unit,y*unit,(x+w)*unit,(y+h)*unit,paint);}
 @Override public void draw(Canvas c){Rect b=getBounds();c.save();c.translate(b.left,b.top);c.scale(unit,unit);float w=b.width()/unit,h=b.height()/unit;
  paint.setShader(null);paint.setColor(0xff070d10);c.drawRoundRect(1,3,w-1,h,8,8,paint);
  paint.setShader(new LinearGradient(0,0,0,h,new int[]{0xffe1dec8,edge,0xff344245,0xff8d9286},new float[]{0,.23f,.7f,1},Shader.TileMode.CLAMP));c.drawRoundRect(1,1,w-1,h-2,7,7,paint);paint.setShader(null);
  paint.setColor(0xff09171c);c.drawRoundRect(4,4,w-4,h-5,5,5,paint);
  paint.setShader(new LinearGradient(0,6,0,h-6,new int[]{fill,0xff152026},null,Shader.TileMode.CLAMP));c.drawRoundRect(6,6,w-6,h-7,4,4,paint);paint.setShader(null);
  paint.setColor(0x557effdc);c.drawRect(10,7,w-10,8,paint);
  for(int side=0;side<2;side++){float x=side==0?6:w-6;paint.setColor(0xffbcb7a0);c.drawCircle(x,6,2,paint);paint.setColor(0xff515c5c);c.drawCircle(x,h-7,2,paint);}
  c.restore();
 }
 static void pressMotion(android.view.View view){android.animation.StateListAnimator states=new android.animation.StateListAnimator();android.animation.AnimatorSet press=new android.animation.AnimatorSet();press.playTogether(android.animation.ObjectAnimator.ofFloat(view,"scaleX",.97f),android.animation.ObjectAnimator.ofFloat(view,"scaleY",.97f));press.setDuration(85);android.animation.AnimatorSet release=new android.animation.AnimatorSet();release.playTogether(android.animation.ObjectAnimator.ofFloat(view,"scaleX",1f),android.animation.ObjectAnimator.ofFloat(view,"scaleY",1f));release.setDuration(140);states.addState(new int[]{android.R.attr.state_pressed,android.R.attr.state_enabled},press);states.addState(new int[]{},release);view.setStateListAnimator(states);}
 @Override public void setAlpha(int alpha){paint.setAlpha(alpha);}
 @Override public void setColorFilter(ColorFilter filter){paint.setColorFilter(filter);}
 @Override public int getOpacity(){return PixelFormat.TRANSLUCENT;}
 static Drawable button(Context c){StateListDrawable states=new StateListDrawable();states.addState(new int[]{-android.R.attr.state_enabled},new PixelFrame(c,0xff1b2020,0xff52564d));states.addState(new int[]{android.R.attr.state_pressed},new PixelFrame(c,0xff57462c,0xfff4d494));states.addState(new int[]{android.R.attr.state_focused},new PixelFrame(c,0xff33433e,0xffebca87));states.addState(new int[]{},new PixelFrame(c,0xff293332,GOLD));return states;}
 static void type(TextView v){v.setTypeface(Typeface.create(Typeface.SANS_SERIF,Typeface.BOLD));v.setTextColor(TEXT);v.setIncludeFontPadding(false);}
}
