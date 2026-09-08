package com.genesis.gacha;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.res.AssetFileDescriptor;
import android.media.*;
import android.os.Handler;
import android.os.Looper;
import java.util.*;

/** Activity-owned audio; no network, background playback, or gameplay state. */
final class GenesisAudio {
    private final Context context;
    private final SharedPreferences prefs;
    private final AudioManager manager;
    private final SoundPool pool;
    private final Map<String,Integer> sounds=new HashMap<>();
    private final Set<Integer> loaded=new HashSet<>();
    private final Set<Integer> streams=new HashSet<>();
    private final Handler handler=new Handler(Looper.getMainLooper());
    private MediaPlayer music;
    private boolean foreground,focused,prepared,closed;
    private final AudioAttributes attributes=new AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build();
    private final AudioFocusRequest focus;

    GenesisAudio(Context c,SharedPreferences p) {
        context=c; prefs=p; manager=(AudioManager)c.getSystemService(Context.AUDIO_SERVICE);
        focus=new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(attributes).setOnAudioFocusChangeListener(change->{
                focused=change==AudioManager.AUDIOFOCUS_GAIN;
                if(focused) sync(); else { pauseMusic(); stopEffects(); }
            },handler).build();
        pool=new SoundPool.Builder().setMaxStreams(4).setAudioAttributes(attributes).build();
        pool.setOnLoadCompleteListener((s,id,status)->{if(status==0)loaded.add(id);});
        String[] names={"rarity-1","rarity-2","rarity-3","rarity-4","rarity-5","rarity-6","rarity-7","rarity-8","rarity-9","rarity-10","flip","train","upgrade","evolution"};
        for(String name:names)try(AssetFileDescriptor fd=c.getAssets().openFd("audio/"+name+".wav")){
            sounds.put(name,pool.load(fd,1));
        }catch(Exception ignored){/* Missing audio must never block gameplay. */}
        try(AssetFileDescriptor fd=c.getAssets().openFd("audio/sanctum.wav")){
            music=new MediaPlayer();music.setAudioAttributes(attributes);
            music.setDataSource(fd.getFileDescriptor(),fd.getStartOffset(),fd.getLength());
            music.setLooping(true);music.setOnPreparedListener(m->{if(!closed){prepared=true;sync();}});
            music.setOnErrorListener((m,what,extra)->{prepared=false;return true;});
            music.prepareAsync();
        }catch(Exception ignored){if(music!=null)music.release();music=null;}
    }
    void resume(){if(closed)return;foreground=true;settingsChanged();}
    void pause(){foreground=false;pauseMusic();stopEffects();if(focused)manager.abandonAudioFocusRequest(focus);focused=false;}
    void settingsChanged(){
        if(closed)return;
        boolean wants=(prefs.getBoolean("music",true)&&prefs.getInt("musicVolume",35)>0)
            ||(prefs.getBoolean("sound",true)&&prefs.getInt("sfxVolume",65)>0);
        if(foreground&&wants&&!focused)focused=manager.requestAudioFocus(focus)==AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
        if(!wants){manager.abandonAudioFocusRequest(focus);focused=false;stopEffects();}
        if(!prefs.getBoolean("sound",true)||prefs.getInt("sfxVolume",65)==0)stopEffects();
        sync();
    }
    private void sync(){
        if(music==null||!prepared||closed)return;
        if(foreground&&focused&&prefs.getBoolean("music",true)){
            float v=Math.max(0,Math.min(100,prefs.getInt("musicVolume",35)))/100f;
            music.setVolume(v,v);if(!music.isPlaying())music.start();
        }else pauseMusic();
    }
    private void pauseMusic(){if(music!=null&&prepared&&music.isPlaying())music.pause();}
    void play(String name){
        if(closed||!foreground||!focused||!prefs.getBoolean("sound",true))return;
        Integer id=sounds.get(name);if(id==null||!loaded.contains(id))return;
        float v=Math.max(0,Math.min(100,prefs.getInt("sfxVolume",65)))/100f;
        if(v<=0)return;
        final int stream=pool.play(id,v,v,1,0,1f);
        streams.add(stream);handler.postDelayed(()->streams.remove(stream),4000);
    }
    void stopEffects(){for(int stream:streams)pool.stop(stream);streams.clear();}
    void close(){if(closed)return;pause();closed=true;handler.removeCallbacksAndMessages(null);pool.release();if(music!=null){music.release();music=null;}}
}
