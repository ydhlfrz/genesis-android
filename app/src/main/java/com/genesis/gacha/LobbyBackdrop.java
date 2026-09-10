package com.genesis.gacha;

import android.graphics.*;
import android.graphics.drawable.Drawable;

/** Original native fantasy hall illustration; intentionally quiet behind the controls. */
final class LobbyBackdrop extends Drawable {
 private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
 private final Path path=new Path();
 private void rect(Canvas c,float x,float y,float w,float h,int color){p.setShader(null);p.setColor(color);c.drawRect(x,y,x+w,y+h,p);}
 @Override public void draw(Canvas canvas){Rect b=getBounds();canvas.save();canvas.translate(b.left,b.top);canvas.scale(b.width()/1000f,b.height()/500f);
  p.setShader(new LinearGradient(0,0,0,500,new int[]{0xff081620,0xff223038,0xff111b20},null,Shader.TileMode.CLAMP));canvas.drawRect(0,0,1000,500,p);p.setShader(null);
  // Moonlit opening, distant towers and battlements.
  p.setColor(0xffbed2ca);canvas.drawCircle(568,102,30,p);p.setColor(0xff152934);canvas.drawCircle(580,94,29,p);
  for(int i=0;i<35;i++){p.setColor(i%3==0?0xff809594:0xff445e6c);canvas.drawRect(260+(i*79%480),36+(i*37%205),262+(i*79%480),38+(i*37%205),p);}
  for(int i=0;i<9;i++){float x=255+i*57,y=245-(i*31%70);rect(canvas,x,y,42,110,0xff15232c);for(int j=0;j<3;j++)rect(canvas,x+j*15,y-9,9,12,0xff15232c);rect(canvas,x+17,y+22,6,10,0xff566358);}
  // Stone floor converges on the central dais.
  p.setShader(new LinearGradient(0,335,0,500,0xff293638,0xff0e171b,Shader.TileMode.CLAMP));canvas.drawRect(0,335,1000,500,p);p.setShader(null);p.setColor(0xff3b4948);p.setStrokeWidth(1);
  for(int i=-5;i<=5;i++)canvas.drawLine(500+i*30,335,500+i*160,500,p);
  for(int i=0;i<5;i++)canvas.drawLine(0,350+i*i*8,1000,350+i*i*8,p);
  p.setColor(0xff101b1c);canvas.drawOval(320,342,690,444,p);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(3);p.setColor(0xff786848);canvas.drawOval(328,346,682,439,p);p.setStyle(Paint.Style.FILL);
  // Massive pillars, lintel and hanging banners.
  for(int side=0;side<2;side++){float x=side==0?196:752;rect(canvas,x,0,52,370,0xff273238);rect(canvas,x+6,0,8,370,0xff424b48);rect(canvas,x+44,0,8,370,0xff111b23);rect(canvas,x-14,335,80,32,0xff37403d);rect(canvas,x-18,29,88,20,0xff414840);
   for(int j=1;j<8;j++)rect(canvas,x,j*43,52,2,0xff131e24);
   float banner=side==0?135:822;path.reset();path.moveTo(banner,44);path.lineTo(banner+37,44);path.lineTo(banner+37,212);path.lineTo(banner+18,235);path.lineTo(banner,212);path.close();p.setColor(0xff472c36);canvas.drawPath(path,p);rect(canvas,banner+16,59,4,122,0xff8b704d);
   float torch=side==0?276:726;p.setShader(new RadialGradient(torch,238,58,new int[]{0x66e7ae55,0x00965b25},null,Shader.TileMode.CLAMP));canvas.drawCircle(torch,238,58,p);p.setShader(null);rect(canvas,torch-3,240,6,31,0xff665236);p.setColor(0xffc39850);canvas.drawOval(torch-5,219,torch+5,245,p);
  }
  path.reset();path.moveTo(236,90);path.quadTo(500,-95,764,90);path.lineTo(764,0);path.lineTo(236,0);path.close();p.setColor(0xff313c3e);canvas.drawPath(path,p);p.setStyle(Paint.Style.STROKE);p.setColor(0xff716548);p.setStrokeWidth(4);path.reset();path.moveTo(248,87);path.quadTo(500,-81,752,87);canvas.drawPath(path,p);p.setStyle(Paint.Style.FILL);
  // Readability vignette.
  p.setShader(new RadialGradient(500,245,580,new int[]{0x0010181d,0xbb060b10},new float[]{.15f,1},Shader.TileMode.CLAMP));canvas.drawRect(0,0,1000,500,p);p.setShader(null);canvas.restore();
 }
 @Override public void setAlpha(int alpha){p.setAlpha(alpha);}
 @Override public void setColorFilter(ColorFilter filter){p.setColorFilter(filter);}
 @Override public int getOpacity(){return PixelFormat.OPAQUE;}
}
