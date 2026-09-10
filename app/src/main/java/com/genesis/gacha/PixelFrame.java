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
 @Override public void draw(Canvas c){Rect b=getBounds();c.save();c.translate(b.left,b.top);float w=b.width()/unit,h=b.height()/unit;
  block(c,0,0,w,h,INK);block(c,3,3,w-6,h-6,fill);
  block(c,7,1,w-14,2,edge);block(c,7,h-3,w-14,2,edge);block(c,1,7,2,h-14,edge);block(c,w-3,7,2,h-14,edge);
  block(c,6,5,w-12,1,0xff67583e);block(c,5,6,1,h-12,0xff67583e);block(c,6,h-6,w-12,1,0xff080d0e);block(c,w-6,6,1,h-12,0xff080d0e);
  for(int x=0;x<2;x++)for(int y=0;y<2;y++){float xx=x==0?2:w-10,yy=y==0?2:h-10;block(c,xx,yy,8,2,edge);block(c,xx,yy,2,8,edge);block(c,xx+3,yy+3,3,3,0xffe6c382);}
  c.restore();
 }
 @Override public void setAlpha(int alpha){paint.setAlpha(alpha);}
 @Override public void setColorFilter(ColorFilter filter){paint.setColorFilter(filter);}
 @Override public int getOpacity(){return PixelFormat.TRANSLUCENT;}
 static Drawable button(Context c){StateListDrawable states=new StateListDrawable();states.addState(new int[]{-android.R.attr.state_enabled},new PixelFrame(c,0xff1b2020,0xff52564d));states.addState(new int[]{android.R.attr.state_pressed},new PixelFrame(c,0xff57462c,0xfff4d494));states.addState(new int[]{android.R.attr.state_focused},new PixelFrame(c,0xff33433e,0xffebca87));states.addState(new int[]{},new PixelFrame(c,0xff293332,GOLD));return states;}
 static void type(TextView v){v.setTypeface(Typeface.MONOSPACE);v.setTextColor(TEXT);v.setIncludeFontPadding(false);}
}
