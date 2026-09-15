package com.genesis.gacha;

import android.content.Context;
import android.graphics.*;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.StateListDrawable;
import android.widget.TextView;

/** Resolution-independent stepped RPG frames; no external texture or font download. */
final class PixelFrame extends Drawable {
 static final int INK=0xff121919,PANEL=0xff1d2626,GOLD=0xffc69a55,TEXT=0xffeee1c2,MUTED=0xffb8b39e;
 private final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);
 private final float unit;
 private final int fill,edge;
 PixelFrame(Context context,int fill,int edge){unit=Math.max(1,context.getResources().getDisplayMetrics().density);this.fill=fill;this.edge=edge;}
 private void block(Canvas c,float x,float y,float w,float h,int color){paint.setColor(color);c.drawRect(x*unit,y*unit,(x+w)*unit,(y+h)*unit,paint);}
 @Override public void draw(Canvas c){Rect b=getBounds();c.save();c.translate(b.left,b.top);c.scale(unit,unit);float w=b.width()/unit,h=b.height()/unit;if(w<12||h<12){c.restore();return;}
  paint.setShader(null);paint.setColor(0xff080f14);c.drawRoundRect(0,2,w,h,7,7,paint);
  paint.setShader(new LinearGradient(0,0,0,h,new int[]{edge,0xff35434a},null,Shader.TileMode.CLAMP));c.drawRoundRect(0,0,w,h-2,7,7,paint);paint.setShader(null);
  paint.setShader(new LinearGradient(0,0,0,h,new int[]{fill,0xff152029},null,Shader.TileMode.CLAMP));c.drawRoundRect(1.5f,1.5f,w-1.5f,h-3.5f,5,5,paint);paint.setShader(null);
  paint.setColor(0x407effdc);c.drawRect(12,3,w-12,4,paint);
  paint.setColor(edge);c.drawRect(6,6,12,7,paint);c.drawRect(w-12,6,w-6,7,paint);c.drawRect(6,h-9,12,h-8,paint);c.drawRect(w-12,h-9,w-6,h-8,paint);c.restore();
 }
 static void pressMotion(android.view.View view){android.animation.StateListAnimator states=new android.animation.StateListAnimator();android.animation.AnimatorSet press=new android.animation.AnimatorSet();press.playTogether(android.animation.ObjectAnimator.ofFloat(view,"scaleX",.97f),android.animation.ObjectAnimator.ofFloat(view,"scaleY",.97f));press.setDuration(85);android.animation.AnimatorSet release=new android.animation.AnimatorSet();release.playTogether(android.animation.ObjectAnimator.ofFloat(view,"scaleX",1f),android.animation.ObjectAnimator.ofFloat(view,"scaleY",1f));release.setDuration(140);states.addState(new int[]{android.R.attr.state_pressed,android.R.attr.state_enabled},press);states.addState(new int[]{},release);view.setStateListAnimator(states);}
 @Override public void setAlpha(int alpha){paint.setAlpha(alpha);}
 @Override public void setColorFilter(ColorFilter filter){paint.setColorFilter(filter);}
 @Override public int getOpacity(){return PixelFormat.TRANSLUCENT;}
 static Drawable button(Context c){StateListDrawable states=new StateListDrawable();states.addState(new int[]{-android.R.attr.state_enabled},new PixelFrame(c,0xff1b2020,0xff52564d));states.addState(new int[]{android.R.attr.state_pressed},new PixelFrame(c,0xff57462c,0xfff4d494));states.addState(new int[]{android.R.attr.state_focused},new PixelFrame(c,0xff33433e,0xffebca87));states.addState(new int[]{},new PixelFrame(c,0xff293332,GOLD));return states;}
 static void type(TextView v){v.setTypeface(Typeface.create(Typeface.SANS_SERIF,Typeface.NORMAL));v.setTextColor(TEXT);v.setIncludeFontPadding(false);}
}
