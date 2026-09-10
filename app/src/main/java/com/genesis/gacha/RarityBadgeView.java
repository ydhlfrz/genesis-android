package com.genesis.gacha;

import android.content.Context;
import android.graphics.*;
import android.view.View;

/** Original scalable metal/ribbon badges. Stars and labels always match the five-tier standard. */
final class RarityBadgeView extends View {
 private static final String[] NAMES={"COMMON","RARE","SUPER RARE","EPIC","MYTHIC"};
 private static final int[] COLORS={0xffa5b5bd,0xff49bfea,0xff807cf2,0xffd061dd,0xffffc465};
 private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
 private final Path path=new Path();
 private final int tier;
 RarityBadgeView(Context c,int tier){super(c);this.tier=Math.max(0,Math.min(4,tier));setContentDescription(NAMES[this.tier]+", "+(this.tier+3)+" stars");setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_YES);}
 private void star(Canvas c,float x,float y,float r){path.reset();for(int i=0;i<10;i++){double a=-Math.PI/2+i*Math.PI/5;float d=i%2==0?r:r*.45f;float xx=x+(float)Math.cos(a)*d,yy=y+(float)Math.sin(a)*d;if(i==0)path.moveTo(xx,yy);else path.lineTo(xx,yy);}path.close();p.setColor(0xffffe5a0);c.drawPath(path,p);}
 @Override protected void onDraw(Canvas c){super.onDraw(c);float scale=Math.min(getWidth()/360f,getHeight()/82f);c.save();c.translate((getWidth()-360*scale)/2,(getHeight()-82*scale)/2);c.scale(scale,scale);int color=COLORS[tier];
  p.setShader(new LinearGradient(0,0,0,82,new int[]{0xffe3e7dd,0xff515f65,0xff101c24,0xffb7bbae},null,Shader.TileMode.CLAMP));c.drawRoundRect(25,7,335,75,13,13,p);p.setShader(null);
  p.setColor(0xff121e28);c.drawRoundRect(31,13,329,69,9,9,p);
  p.setShader(new LinearGradient(0,14,0,70,new int[]{color,0xff202b39,0xff162331},new float[]{0,.4f,1},Shader.TileMode.CLAMP));c.drawRoundRect(35,16,325,66,7,7,p);p.setShader(null);
  // Tier-dependent wing ornaments and central gem; no imported artwork.
  for(int side=-1;side<=1;side+=2){c.save();if(side==1){c.translate(360,0);c.scale(-1,1);}for(int j=0;j<=tier;j++){path.reset();path.moveTo(41,27+j*5);path.lineTo(9-j*2,16+j*8);path.lineTo(22,36+j*7);path.lineTo(41,49+j*3);path.close();p.setColor(j%2==0?color:0xffacb6b8);c.drawPath(path,p);}c.restore();}
  path.reset();path.moveTo(180,0);path.lineTo(190,10);path.lineTo(180,20);path.lineTo(170,10);path.close();p.setColor(color);c.drawPath(path,p);p.setColor(0xfffaffed);c.drawCircle(178,6,2,p);
  p.setTypeface(Typeface.create(Typeface.SANS_SERIF,Typeface.BOLD));p.setTextAlign(Paint.Align.CENTER);p.setTextSize(19);p.setColor(0xfffaf3df);c.drawText(NAMES[tier],180,39,p);
  int count=tier+3;for(int i=0;i<count;i++)star(c,180+(i-(count-1)/2f)*17,56,6);
  c.restore();
 }
}
