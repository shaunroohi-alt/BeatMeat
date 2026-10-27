#include "../Sources/Audio/BeatKernel.h"
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <memory>
#include <vector>
namespace {
using Engine=std::unique_ptr<BMEngine,decltype(&BMDestroy)>;
void check(bool ok,const char* msg){if(!ok){std::cerr<<"FAIL: "<<msg<<'\n';std::exit(1);}}
Engine make(){Engine e(BMCreate(48000),BMDestroy);check(bool(e),"create");return e;}
void play(BMEngine* e,bool session=false,bool loop=false,double a=0,double b=16,double q=4){BMTransport(e,120,1,session,loop,a,b,q);}
std::vector<float> render(BMEngine* e,size_t n){std::vector<float> l(n),r(n);BMRender(e,l.data(),r.data(),(uint32_t)n);for(size_t i=0;i<n;++i)check(std::isfinite(l[i])&&std::isfinite(r[i]),"finite render");return l;}
void constant(BMEngine* e,int t,int s,float value,double start=0,double length=16,bool loop=true){std::vector<float> data(128,value);check(BMLoadAudio(e,t,s,data.data(),data.data(),128,48000,start,length,loop),"load PCM");}
double rms(const std::vector<float>& x){double e=0;for(float s:x)e+=s*s;return std::sqrt(e/x.size());}
}
int main(){
 int cases=0;
 {auto e=make();play(e.get());auto x=render(e.get(),1000);check(rms(x)==0,"empty session is silent");check(std::abs(BMBeat(e.get())-1000./24000)<1.e-10,"transport advances exactly");++cases;}
 {auto e=make();constant(e.get(),0,0,.25f);auto x=render(e.get(),64);check(rms(x)==0,"stopped is silent");check(BMBeat(e.get())==0,"stopped transport does not advance");play(e.get());x=render(e.get(),64);check(std::abs(x[20]-.25)<1.e-7,"arrangement sample playback");++cases;}
 {auto e=make();constant(e.get(),0,0,.2f);constant(e.get(),1,0,.3f);play(e.get());auto x=render(e.get(),100);check(std::abs(x[50]-.5)<1.e-6,"tracks sum");++cases;}
 {auto e=make();constant(e.get(),0,0,.2f);constant(e.get(),0,1,.3f);play(e.get());auto x=render(e.get(),100);check(std::abs(x[50]-.5)<1.e-6,"arrangement overlapping clips sum");++cases;}
 {auto e=make();constant(e.get(),0,0,.2f,1,1);play(e.get());auto x=render(e.get(),72000);check(x[100]==0&&std::abs(x[25000]-.2)<1.e-6&&x[50000]==0,"placement begins and ends at beat bounds");++cases;}
 {auto e=make();std::vector<float> samples{0,.1f,.2f,.3f,.4f,.5f,.6f,.7f};check(BMLoadAudio(e.get(),0,0,samples.data(),nullptr,8,24000,0,4,0),"load mono resampling");play(e.get());auto x=render(e.get(),18);check(std::abs(x[1]-.05)<1.e-6&&std::abs(x[4]-.2)<1.e-6&&x[16]==0,"source-rate interpolation and nonloop end");++cases;}
 {auto e=make();constant(e.get(),0,0,.3f);play(e.get());BMSetTrack(e.get(),0,BMMute,1);render(e.get(),8000);check(rms(render(e.get(),100))<1.e-8,"mute settles to silence");++cases;}
 {auto e=make();constant(e.get(),0,0,.2f);constant(e.get(),1,0,.3f);BMSetTrack(e.get(),0,BMSolo,1);play(e.get());render(e.get(),8000);check(std::abs(render(e.get(),10)[0]-.2)<1.e-6,"solo isolates one track");++cases;}
 {auto e=make();constant(e.get(),0,0,.3f);BMSetTrack(e.get(),0,BMPan,1);play(e.get());render(e.get(),8000);check(rms(render(e.get(),100))<1.e-7,"pan right attenuates left");++cases;}
 {auto e=make();constant(e.get(),0,0,.3f);play(e.get(),true);check(rms(render(e.get(),100))==0,"session waits for clip launch");BMLaunch(e.get(),0,0);render(e.get(),96000);check(std::abs(render(e.get(),10)[0]-.3)<1.e-6,"session launches and loops clip");check(BMActiveSlot(e.get(),0)==0,"active slot published");++cases;}
 {auto e=make();constant(e.get(),0,0,.25f);play(e.get(),true);BMSeek(e.get(),1);render(e.get(),1);BMLaunch(e.get(),0,0);auto x=render(e.get(),71999);check(rms(x)==0,"quantized launch waits until next bar");x=render(e.get(),2);check(std::abs(x[0]-.25)<1.e-6,"quantized launch starts on sample grid boundary");++cases;}
 {auto e=make();constant(e.get(),0,0,.2f);constant(e.get(),0,1,.3f);play(e.get(),false,false,0,16,0);BMLaunch(e.get(),0,1);auto x=render(e.get(),100);check(std::abs(x[20]-.3)<1.e-6,"one Session override suppresses track Arrangement");check(BMHasSessionOverride(e.get())==1,"override state published");BMLaunch(e.get(),0,-1);x=render(e.get(),100);check(rms(x)==0,"Session stop retains silent override");BMBackToArrangement(e.get());x=render(e.get(),100);check(std::abs(x[20]-.5)<1.e-6&&BMHasSessionOverride(e.get())==0,"Back to Arrangement restores placement");++cases;}
 {auto e=make();play(e.get(),false,true,2,3);BMSeek(e.get(),2);render(e.get(),36000);check(std::abs(BMBeat(e.get())-2.5)<1.e-8,"transport loops at specified beat bounds");++cases;}
 {auto e=make();BMSetMIDIClip(e.get(),0,0,0,4,1);BMSetNote(e.get(),0,0,0,69,1,0,1);play(e.get());auto x=render(e.get(),48000);check(rms(std::vector<float>(x.begin()+100,x.begin()+23000))>.1,"MIDI synth produces tone");check(rms(std::vector<float>(x.begin()+25000,x.end()))==0,"MIDI note ends at duration");++cases;}
 {auto e=make();BMSetMIDIClip(e.get(),0,0,0,1,1);BMSetNote(e.get(),0,0,0,60,1,0,.5);play(e.get(),true,false,0,16,0);BMLaunch(e.get(),0,0);auto x=render(e.get(),48000);check(rms(std::vector<float>(x.begin()+25000,x.begin()+35000))>.05,"Session MIDI clips loop notes");++cases;}
 {auto e=make();std::vector<float> impulse(24001,0);impulse[0]=.3f;check(BMLoadAudio(e.get(),0,0,impulse.data(),nullptr,(int64_t)impulse.size(),48000,0,4,0),"impulse load");BMSetTrack(e.get(),0,BMDelaySend,1);play(e.get());auto x=render(e.get(),48002);check(x[0]>.29&&x[24000]>.1,"tempo quarter-note delay return");++cases;}
 {auto e=make();std::vector<float> data(32,.2f);data[1]=std::numeric_limits<float>::quiet_NaN();check(BMLoadAudio(e.get(),0,0,data.data(),nullptr,32,48000,0,4,1),"invalid samples sanitized");BMSetTrack(e.get(),0,BMGain,std::numeric_limits<double>::quiet_NaN());BMTransport(e.get(),std::numeric_limits<double>::infinity(),1,0,1,0,std::numeric_limits<double>::quiet_NaN(),4);auto x=render(e.get(),100);check(rms(x)>.1,"bad control values replaced with usable defaults");++cases;}
 {auto e=make();float value=0;check(!BMLoadAudio(e.get(),0,0,&value,nullptr,INT64_MAX,48000,0,4,1),"PCM memory cap rejects before dereferencing oversized buffer");check(!BMLoadAudio(e.get(),-1,0,&value,nullptr,2,48000,0,4,1),"invalid track rejected");check(BMCreate(-1)==nullptr,"invalid sample rate rejected");++cases;}
 {auto e=make();constant(e.get(),0,0,.2f);check(BMAudioBytes(e.get())==128*2*sizeof(float),"PCM memory accounted");BMClearClip(e.get(),0,0);check(BMAudioBytes(e.get())==0,"PCM memory released");play(e.get());check(rms(render(e.get(),100))==0,"cleared clip silent");++cases;}
 {auto e=make();constant(e.get(),0,0,.2f);BMSeek(e.get(),8);render(e.get(),0);check(BMBeat(e.get())==8,"seek applied and published even with empty audio block");++cases;}
 {auto e=make();constant(e.get(),0,0,.2f);play(e.get());render(e.get(),64);BMSetTrack(e.get(),0,BMGain,.5);auto x=render(e.get(),6000);double maxStep=0;for(size_t i=1;i<x.size();++i)maxStep=std::max(maxStep,std::abs((double)x[i]-x[i-1]));check(x[0]>.19&&std::abs(x.back()-.1)<1.e-6&&maxStep<.001,"gain changes glide without zipper steps");++cases;}
 {auto a=make(),b=make();for(auto* e:{a.get(),b.get()}){BMSetMIDIClip(e,0,0,0,4,1);BMSetNote(e,0,0,0,57,.8,0,3);play(e);BMSetTrack(e,0,BMDelaySend,.5);}auto whole=render(a.get(),10000);std::vector<float> pieces;while(pieces.size()<whole.size()){auto x=render(b.get(),std::min((size_t)37,whole.size()-pieces.size()));pieces.insert(pieces.end(),x.begin(),x.end());}check(whole==pieces,"audio independent of callback block size");++cases;}
 std::cout<<"PASS: "<<cases<<" BeatMeat DSP and transport scenarios\n";
}
