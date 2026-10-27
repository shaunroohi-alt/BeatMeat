#include "BeatKernel.h"
#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <limits>
#include <memory>
#include <new>
#include <vector>
namespace {
constexpr double pi=3.14159265358979323846;
constexpr uint64_t maxBytes=256ull*1024*1024;
struct Note {int pitch=-1;double velocity=0,start=0,duration=0;};
struct Clip {
 int kind=0;double start=0,length=4,sourceRate=48000;bool loop=true;
 std::vector<float> left,right;std::array<Note,BM_MAX_NOTES> notes{};
 uint64_t bytes()const{return (left.size()+right.size())*sizeof(float);}
};
struct Track {
 std::array<Clip,BM_MAX_SLOTS> clips;
 std::array<std::atomic<double>,6> params;
 std::atomic<int> request{-2},publishedSlot{-1};std::atomic<double> meter{0};std::atomic<bool> publishedOverride{false};
 int active=-1,pending=-2;double launchElapsed=0,pendingElapsed=0,smoothGain=1,smoothPan=0,filterL=0,filterR=0;
 bool overrideArrangement=false,primed=false;
 Track(){const double defaults[]={1,0,0,0,0,20000};for(size_t i=0;i<6;++i)params[i].store(defaults[i]);}
};
inline double finite(double x,double fallback){return std::isfinite(x)?x:fallback;}
inline double bounded(double x,double a,double b,double fallback){return std::clamp(finite(x,fallback),a,b);}
inline bool valid(int t,int s){return t>=0&&t<BM_MAX_TRACKS&&s>=0&&s<BM_MAX_SLOTS;}
}
struct BMEngine {
 double fs=48000,beat=0,elapsed=0;size_t delayPos=0;
 std::array<Track,BM_MAX_TRACKS> tracks;
 std::vector<double> delayL,delayR;
 std::atomic<double> bpm{120},publishedBeat{0},seek{-1},loopStart{0},loopEnd{16},quantum{4};
 std::atomic<bool> playing{false},sessionMode{false},loop{false},back{false};
 std::atomic<uint64_t> audioBytes{0};
 explicit BMEngine(double rate):fs(rate),delayL((size_t)std::ceil(rate*3.1)+1,0),delayR(delayL.size(),0){}
};
namespace {
void audio(const Clip& c,double localBeat,double bpm,double& l,double& r){
 if(c.left.size()<2)return;
 double frame=localBeat*60./bpm*c.sourceRate;
 if(c.loop)frame=std::fmod(std::max(0.,frame),(double)c.left.size());
 if(frame<0||frame>=(double)c.left.size())return;
 const auto i=(size_t)frame;
 const size_t j=i+1<c.left.size()?i+1:(c.loop?0:i);
 const double f=frame-(double)i;
 l+=(double)c.left[i]+f*((double)c.left[j]-c.left[i]);
 r+=(double)c.right[i]+f*((double)c.right[j]-c.right[i]);
}
void midi(const Clip& c,double beat,double bpm,double& l,double& r){
 double sample=0;
 for(const auto& n:c.notes){
  if(n.pitch<0||beat<n.start||beat>=n.start+n.duration)continue;
  const double seconds=(beat-n.start)*60./bpm;
  const double remaining=(std::min(n.start+n.duration,c.length)-beat)*60./bpm;
  const double envelope=std::min({1.,seconds/.003,remaining/.008});
  const double hz=440.*std::pow(2.,(n.pitch-69)/12.);
  sample+=.18*n.velocity*envelope*std::sin(2*pi*hz*seconds);
 }
 l+=sample;r+=sample;
}
void clipSample(const Clip& c,double localBeat,double bpm,bool session,double& l,double& r){
 if(c.kind==0||localBeat<0)return;
 if(session&&c.loop)localBeat=std::fmod(localBeat,c.length);
 else if(localBeat>=c.length)return;
 if(c.kind==1)audio(c,localBeat,bpm,l,r);else if(c.kind==2)midi(c,localBeat,bpm,l,r);
}
}
extern "C" {
BMEngine* BMCreate(double fs){
 if(!std::isfinite(fs)||fs<8000||fs>384000)return nullptr;
 try{return new BMEngine(fs);}catch(const std::exception&){return nullptr;}
}
void BMDestroy(BMEngine* e){delete e;}
int BMLoadAudio(BMEngine* e,int t,int s,const float* l,const float* r,int64_t frames,double sourceFs,double start,double length,int loop){
 if(!e||!valid(t,s)||!l||frames<2||!std::isfinite(sourceFs)||sourceFs<1000||sourceFs>384000)return 0;
 if((uint64_t)frames>maxBytes/(2*sizeof(float)))return 0;
 auto& c=e->tracks[(size_t)t].clips[(size_t)s];
 const uint64_t requested=(uint64_t)frames*2*sizeof(float),old=c.bytes(),total=e->audioBytes.load();
 if(total-old+requested>maxBytes)return 0;
 try{
  std::vector<float> left((size_t)frames),right((size_t)frames);
  for(size_t i=0;i<(size_t)frames;++i){left[i]=std::isfinite(l[i])?l[i]:0;const float rv=r?r[i]:l[i];right[i]=std::isfinite(rv)?rv:0;}
  c=Clip{};c.kind=1;c.left=std::move(left);c.right=std::move(right);c.sourceRate=sourceFs;
  c.start=bounded(start,0,1.e8,0);c.length=bounded(length,1./64,1.e6,4);c.loop=loop!=0;
  e->audioBytes.store(total-old+requested);return 1;
 }catch(const std::exception&){return 0;}
}
void BMSetMIDIClip(BMEngine* e,int t,int s,double start,double length,int loop){
 if(!e||!valid(t,s))return;
 auto& c=e->tracks[(size_t)t].clips[(size_t)s];
 const uint64_t old=c.bytes();c=Clip{};c.kind=2;c.start=bounded(start,0,1.e8,0);c.length=bounded(length,1./64,1.e6,4);c.loop=loop!=0;
 e->audioBytes.fetch_sub(old);
}
void BMSetNote(BMEngine* e,int t,int s,int index,int pitch,double velocity,double start,double duration){
 if(!e||!valid(t,s)||index<0||index>=BM_MAX_NOTES)return;
 auto& c=e->tracks[(size_t)t].clips[(size_t)s];if(c.kind!=2)return;
 auto& n=c.notes[(size_t)index];n.pitch=pitch<0?-1:std::clamp(pitch,0,127);
 n.velocity=bounded(velocity,0,1,0);n.start=bounded(start,0,c.length,0);n.duration=bounded(duration,1./1024,c.length,1./4);
}
void BMClearClip(BMEngine* e,int t,int s){
 if(!e||!valid(t,s))return;
 auto& c=e->tracks[(size_t)t].clips[(size_t)s];const auto bytes=c.bytes();c=Clip{};e->audioBytes.fetch_sub(bytes);
}
void BMSetTrack(BMEngine* e,int t,int p,double v){
 if(!e||t<0||t>=BM_MAX_TRACKS||p<0||p>=6)return;
 static constexpr double lo[]={0,-1,0,0,0,20},hi[]={2,1,1,1,1,20000},defaults[]={1,0,0,0,0,20000};
 e->tracks[(size_t)t].params[(size_t)p].store(bounded(v,lo[p],hi[p],defaults[p]),std::memory_order_relaxed);
}
void BMTransport(BMEngine* e,double bpm,int playing,int session,int loop,double start,double end,double quantum){
 if(!e)return;
 const double a=bounded(start,0,1.e8,0),b=bounded(end,a+1./64,1.e8+1,16);
 e->bpm.store(bounded(bpm,20,300,120));e->sessionMode.store(session!=0);e->loopStart.store(a);e->loopEnd.store(b);e->loop.store(loop!=0);
 e->quantum.store(bounded(quantum,0,16,4));e->playing.store(playing!=0);
}
void BMSeek(BMEngine* e,double beat){if(e)e->seek.store(bounded(beat,0,1.e8,0));}
void BMLaunch(BMEngine* e,int t,int s){if(e&&t>=0&&t<BM_MAX_TRACKS&&s>=-1&&s<BM_MAX_SLOTS)e->tracks[(size_t)t].request.store(s);}
void BMBackToArrangement(BMEngine* e){if(e)e->back.store(true);}
int BMHasSessionOverride(const BMEngine* e){if(!e)return 0;for(const auto& t:e->tracks)if(t.publishedOverride.load())return 1;return 0;}
double BMBeat(const BMEngine* e){return e?e->publishedBeat.load():0;}
double BMMeter(const BMEngine* e,int t){return e&&t>=0&&t<BM_MAX_TRACKS?e->tracks[(size_t)t].meter.load():0;}
int BMActiveSlot(const BMEngine* e,int t){return e&&t>=0&&t<BM_MAX_TRACKS?e->tracks[(size_t)t].publishedSlot.load():-1;}
uint64_t BMAudioBytes(const BMEngine* e){return e?e->audioBytes.load():0;}
void BMRender(BMEngine* e,float* left,float* right,uint32_t frames){
 if(!e||(frames>0&&(!left||!right)))return;
 const double seek=e->seek.exchange(-1);if(seek>=0)e->beat=seek;
 const bool playing=e->playing.load(),session=e->sessionMode.load();
 const double bpm=e->bpm.load(),step=bpm/(60.*e->fs),quantum=e->quantum.load();
 const bool loop=e->loop.load();const double loopStart=e->loopStart.load();
 const double loopEnd=std::max(loopStart+1./64,e->loopEnd.load());
 if(e->back.exchange(false))for(auto& t:e->tracks){t.overrideArrangement=false;t.active=-1;t.pending=-2;t.publishedSlot.store(-1);t.publishedOverride.store(false);}
 bool anySolo=false;
 std::array<double,BM_MAX_TRACKS> peaks{};
 for(auto& t:e->tracks){
  anySolo|=t.params[BMSolo].load()>.5;
  const int request=t.request.exchange(-2);
  if(request!=-2){
   const double until=quantum>0?std::max(0.,std::ceil((e->beat-1.e-9)/quantum)*quantum-e->beat):0;
   t.pending=request;t.pendingElapsed=e->elapsed+(playing?until:0.);
  }
 }
 const double smoothing=std::exp(-1./(e->fs*.005));
 const auto delayLength=std::min(e->delayL.size()-1,std::max((size_t)1,(size_t)(e->fs*60/bpm)));
 for(uint32_t i=0;i<frames;++i){
  double outL=0,outR=0,sendL=0,sendR=0;
  for(size_t ti=0;ti<e->tracks.size();++ti){
   auto& t=e->tracks[ti];
   if(t.pending!=-2&&e->elapsed+step*.5>=t.pendingElapsed){
    t.active=t.pending;t.pending=-2;t.launchElapsed=e->elapsed;t.overrideArrangement=true;
    t.publishedSlot.store(t.active);t.publishedOverride.store(true);
   }
   double l=0,r=0;
   if(playing){
    if(t.overrideArrangement||session){
     if(t.active>=0){const auto& c=t.clips[(size_t)t.active];const double local=e->elapsed-t.launchElapsed;
      clipSample(c,local,bpm,true,l,r);
      if(!c.loop&&local>=c.length){t.active=-1;t.publishedSlot.store(-1);}
     }
    }else for(const auto& c:t.clips)clipSample(c,e->beat-c.start,bpm,false,l,r);
   }
   const bool audible=t.params[BMMute].load()<=.5&&(!anySolo||t.params[BMSolo].load()>.5);
   const double gain=audible?t.params[BMGain].load():0,pan=t.params[BMPan].load();
   if(!t.primed){t.smoothGain=gain;t.smoothPan=pan;t.primed=true;}
   t.smoothGain=gain+smoothing*(t.smoothGain-gain);t.smoothPan=pan+smoothing*(t.smoothPan-pan);
   const double cutoff=t.params[BMLowpass].load();
   if(cutoff<19999){const double c=std::exp(-2*pi*cutoff/e->fs);t.filterL=l+c*(t.filterL-l);t.filterR=r+c*(t.filterR-r);l=t.filterL;r=t.filterR;}else{t.filterL=l;t.filterR=r;}
   l*=t.smoothGain*(t.smoothPan>0?std::cos(t.smoothPan*pi*.5):1.);
   r*=t.smoothGain*(t.smoothPan<0?std::cos(t.smoothPan*pi*.5):1.);
   peaks[ti]=std::max(peaks[ti],std::max(std::abs(l),std::abs(r)));
   outL+=l;outR+=r;const double send=t.params[BMDelaySend].load();sendL+=l*send;sendR+=r*send;
  }
  if(playing){
   const size_t read=(e->delayPos+e->delayL.size()-delayLength)%e->delayL.size();
   const double dl=e->delayL[read],dr=e->delayR[read];
   e->delayL[e->delayPos]=sendL+.32*dr;e->delayR[e->delayPos]=sendR+.32*dl;
   e->delayPos=(e->delayPos+1)%e->delayL.size();outL+=.4*dl;outR+=.4*dr;
   e->beat+=step;e->elapsed+=step;
   if(loop&&e->beat>=loopEnd)e->beat=loopStart+std::fmod(e->beat-loopStart,loopEnd-loopStart);
  }
  left[i]=(float)std::clamp(finite(outL,0),-1.,1.);right[i]=(float)std::clamp(finite(outR,0),-1.,1.);
 }
 e->publishedBeat.store(e->beat);
 for(size_t t=0;t<e->tracks.size();++t)e->tracks[t].meter.store(peaks[t]);
}
}
