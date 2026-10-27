#ifndef BEATMEAT_KERNEL_H
#define BEATMEAT_KERNEL_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
#define BM_MAX_TRACKS 16
#define BM_MAX_SLOTS 8
#define BM_MAX_NOTES 64
typedef struct BMEngine BMEngine;
typedef enum BMTrackParameter {
 BMGain=0, BMPan=1, BMMute=2, BMSolo=3, BMDelaySend=4, BMLowpass=5
} BMTrackParameter;
// Structural clip calls copy data. Call only with the audio renderer stopped.
BMEngine* BMCreate(double sampleRate);
void BMDestroy(BMEngine* engine);
int BMLoadAudio(BMEngine*,int track,int slot,const float* left,const float* right,int64_t frames,double sourceSampleRate,double startBeat,double lengthBeats,int loop);
void BMSetMIDIClip(BMEngine*,int track,int slot,double startBeat,double lengthBeats,int loop);
void BMSetNote(BMEngine*,int track,int slot,int index,int pitch,double velocity,double startBeat,double durationBeats);
void BMClearClip(BMEngine*,int track,int slot);
// These controls are atomic and safe while rendering.
void BMSetTrack(BMEngine*,int track,int parameter,double value);
void BMTransport(BMEngine*,double bpm,int playing,int sessionMode,int loop,double loopStartBeat,double loopEndBeat,double launchQuantumBeats);
void BMSeek(BMEngine*,double beat);
void BMLaunch(BMEngine*,int track,int slot); // -1 stops a track at next quantization boundary
void BMBackToArrangement(BMEngine*);
int BMHasSessionOverride(const BMEngine*);
void BMRender(BMEngine*,float* left,float* right,uint32_t frames);
double BMBeat(const BMEngine*);
double BMMeter(const BMEngine*,int track);
int BMActiveSlot(const BMEngine*,int track);
uint64_t BMAudioBytes(const BMEngine*);
#ifdef __cplusplus
}
#endif
#endif
