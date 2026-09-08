#!/usr/bin/env python3
"""Original synthesized Genesis soundtrack/SFX. Requires Python + numpy, not needed to build APK.
All compositions are generated here; no recordings, samples, or third-party music.
PCM mono 22050 Hz: short effects fit SoundPool's decoded sample limit.
"""
from pathlib import Path
import numpy as np
import wave

ROOT=Path(__file__).resolve().parents[1]/'app/src/main/assets/audio'
ROOT.mkdir(parents=True,exist_ok=True)
SR=22050
rng=np.random.default_rng(165)
def hz(m):return 440*2**((m-69)/12)
def tone(m,dur,voice=0):
    t=np.arange(round(dur*SR))/SR;f=hz(m)
    attack=np.minimum(1,t/(.018 if voice!=3 else .22))
    env=attack*np.exp(-t/(.32+voice*.21))*np.minimum(1,(dur-t)/.08)
    if voice%4==0:y=np.sin(2*np.pi*f*t)+.22*np.sin(2*np.pi*f*2*t)
    elif voice%4==1:y=np.sin(2*np.pi*f*t+1.2*np.exp(-t*6)*np.sin(2*np.pi*f*2*t))
    elif voice%4==2:y=np.sin(2*np.pi*f*t)+.3*np.sin(2*np.pi*f*3*t)+.12*np.sin(2*np.pi*f*5*t)
    else:y=np.sin(2*np.pi*f*t)*(.8+.2*np.cos(2*np.pi*3*t))+.2*np.sin(2*np.pi*(f*1.003)*t)
    return y*env*.32

def add(y,clip,start,gain=1):
    start=round(start*SR);n=min(len(clip),len(y)-start)
    if n>0:y[start:start+n]+=clip[:n]*gain

def save(name,y,peak=.65):
    y=np.nan_to_num(y);mx=np.max(np.abs(y))
    if mx>0:y=y*peak/mx
    # Tiny fades prevent boundary clicks (music uses circular overlap below).
    n=min(220,len(y)//8);y[:n]*=np.linspace(0,1,n);y[-n:]*=np.linspace(1,0,n)
    with wave.open(str(ROOT/(name+'.wav')),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(SR);f.writeframes((y*32767).astype('<i2').tobytes())

def reverb(y):
    dry=y.copy()
    for delay,gain in [(.09,.18),(.19,.12),(.31,.07)]:
        n=round(delay*SR);y[n:]+=dry[:-n]*gain
    return y

# Distinct motifs and instruments for all ten tiers.
motifs=[(62,), (62,69), (65,69,74), (62,67,74,79), (69,72,77),
        (65,72,77,81), (62,69,72,77,81), (50,62,69,74,78),
        (57,64,69,76,81,88), (38,50,62,69,74,81,86)]
for tier,notes in enumerate(motifs,1):
    y=np.zeros(round((1.05+tier*.13)*SR))
    for i,n in enumerate(notes):add(y,tone(n,.8+tier*.07,(tier-1)%4),i*(.075+tier*.006),.8)
    if tier>=7:add(y,tone(notes[0]-12,1.7,3),0,.5)
    save('rarity-'+str(tier),reverb(y),.55)

# Soft filtered rush for the physical card turn.
t=np.arange(int(.23*SR))/SR
noise=rng.normal(0,.3,len(t));noise=np.convolve(noise,np.ones(9)/9,mode='same')
save('flip',noise*np.sin(np.pi*t/.23)**2,.24)
# Gentle ritual charge, with a soft tonal swell and filtered air.
t=np.arange(round(1.65*SR))/SR
noise=np.convolve(rng.normal(0,1,len(t)),np.ones(31)/31,mode='same')
env=np.sin(np.pi*t/1.65)**2
rise=(.17*noise+.18*np.sin(2*np.pi*(110*t+19*t*t))+.09*np.sin(2*np.pi*220*t))*env
save('ritual-rise',rise,.38)
for name,notes,voice in [('train',[62,65,69,74],0),('upgrade',[50,57,62,69,74],2),('evolution',[50,57,62,65,69,74,81],3)]:
    y=np.zeros(round((2.7 if name=='evolution' else 1.6)*SR))
    for i,n in enumerate(notes):add(y,tone(n,1.1,voice),i*(.17 if name=='evolution' else .10))
    save(name,reverb(y),.55)

# 32-second D-minor ambient loop: four original pad voicings, bell responses.
duration=32;y=np.zeros(duration*SR)
chords=[(38,50,57,65),(36,48,55,64),(34,46,53,62),(33,45,52,62)]
for j,chord in enumerate(chords):
    t=np.arange(12*SR)/SR
    env=np.sin(np.pi*t/12)**2
    for n in chord:
        f=hz(n);pad=(np.sin(2*np.pi*f*t)+.18*np.sin(2*np.pi*f*2*t)+.12*np.sin(2*np.pi*(f+.16)*t))*env*.075
        idx=(np.arange(len(t))+j*8*SR)%len(y)
        np.add.at(y,idx,pad)
    for i,n in enumerate([chord[2]+12,chord[3]+12,chord[1]+24,chord[2]+12]):
        clip=tone(n,2.6,1)*.10;idx=(np.arange(len(clip))+round((j*8+1+i*1.6)*SR))%len(y);np.add.at(y,idx,clip)
save('sanctum',y,.46)
print('Generated',len(list(ROOT.glob('*.wav'))),'original PCM assets')
