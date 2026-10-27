import {useCurrentFrame} from 'remotion';
import {Frame,Copy,Phone,Sound} from './Layout';
import {Glyph,Brand,Icon} from './Icons';
import {HomeUI,T} from './AppUI';
import {C,motion,light,dark} from './design';
export const Intro=()=>{
const f=useCurrentFrame();return <Frame chapter="نزل" number={1} title="شاهد ثم شارك" accent="واترك الباقي لنزل">
<div style={{position:'absolute',top:420,left:440,scale:motion(f,10,40,.7,1)}}><Glyph size={200}/></div>
<div style={{position:'absolute',top:665,left:86,right:86,textAlign:'center',fontFamily:'Readex',fontSize:114,fontWeight:650,opacity:motion(f,25,50)}}><T>نزل</T></div>
<div style={{position:'absolute',top:840,left:86,right:86,textAlign:'center',fontSize:42,color:C.muted,opacity:motion(f,45,65)}}><T>الفيديو والصوت على هاتفك</T></div>
<div style={{position:'absolute',top:1030,left:200,right:200,display:'flex',justifyContent:'space-between'}}>{['YouTube','Facebook','Instagram','TikTok'].map((v,i)=><div key={v} style={{translate:`0 ${motion(f,40+i*6,60+i*6,25,0)}px`,opacity:motion(f,40+i*6,60+i*6)}}><Brand name={v} size={90}/></div>)}</div><Sound at={20} file="whoosh" volume={.16}/></Frame>;
};
const sites=[['YouTube','يوتيوب'],['Facebook','فيسبوك'],['Instagram','إنستجرام'],['TikTok','تيك توك'],['X','إكس'],['Dailymotion','ديلي موشن'],['SoundCloud','ساوند كلاود'],['Reddit','ريديت'],['Pinterest','بنترست'],['Snapchat','سناب شات'],['Twitch','تويتش'],['Vimeo','فيميو'],['Bluesky','بلوسكاي'],['LinkedIn','لينكدإن'],['Tumblr','تمبلر'],['VK','في كي'],['Bilibili','بيلي بيلي'],['Likee','لايكي'],['Rumble','رمبل'],['Kick','كيك']];
export const SupportedSites=()=>{
const f=useCurrentFrame();const page=f<270?0:1;const local=f-page*270;return <Frame chapter="المواقع المدعومة" number={13} title="عشرون منصة" accent="في تطبيق واحد">
<div key={page} data-check="site-list" style={{position:'absolute',left:86,right:86,top:408,display:'grid',gridTemplateColumns:'1fr 1fr',columnGap:45,rowGap:20}}>{sites.slice(page*10,page*10+10).map(([name,label],i)=><div key={name} style={{height:112,borderBottom:'1px solid '+C.line,display:'flex',gap:20,alignItems:'center',opacity:motion(local,i*3,i*3+15),translate:`0 ${motion(local,i*3,i*3+20,15,0)}px`}}><Brand name={name} size={65}/><div><T style={{display:'block',fontSize:32,fontWeight:600}}>{label}</T><span style={{fontFamily:'Arial',fontSize:18,color:C.muted}}>{name}</span></div></div>)}</div>
<div style={{position:'absolute',top:1130,left:86,right:86,fontSize:29,lineHeight:1.8,color:C.muted,textAlign:'center'}}><T>للمحتوى العام المتاح دون تسجيل دخول</T><br/><T>{page===0?'١ من ٢':'٢ من ٢'}</T></div>
<Sound at={270} file="whoosh" volume={.13}/></Frame>;
};
export const ThemeScene=()=> <Frame chapter="مظهر التطبيق" number={21} title="فاتح أو داكن" accent="يتبع مظهر هاتفك">
<Phone x={111} y={418} scale={.94}><HomeUI p={light}/></Phone><Phone x={590} y={418} scale={.94} dark><HomeUI p={dark}/></Phone>
<div style={{position:'absolute',top:1172,left:111,width:376,textAlign:'center',fontSize:36,display:'flex',alignItems:'center',justifyContent:'center',gap:15}}><Icon name="sun" size={34} color={C.blue}/><T>أبيض وأزرق</T></div>
<div style={{position:'absolute',top:1172,left:590,width:376,textAlign:'center',fontSize:36,display:'flex',alignItems:'center',justifyContent:'center',gap:15}}><Icon name="moon" size={34} color={C.blue}/><T>كحلي هادئ</T></div></Frame>;
export const ChannelScene=()=>{
const f=useCurrentFrame();return <Frame chapter="تواصل وتحديثات" number={22} title="تطبيقات أكثر" accent="على قناتنا في تليجرام"><Phone><HomeUI filled={false} ready={false} channelFrame={f}/></Phone><Copy title="زر صغير حين تحتاجه" body="تظهر دعوة الانضمام لخمس ثوان ثم تعود إلى أيقونة ثابتة" foot="تجد الزر في الرئيسية والتحميلات ويفتح القناة عند الضغط عليه"/><Sound at={25} file="whoosh" volume={.12}/></Frame>;
};
export const PrivacyScene=()=>{
const f=useCurrentFrame();return <Frame chapter="تجربة نزل" number={23} title="مساحة لك وحدك" accent="خالية تماما من الإعلانات" dark>
<div style={{position:'absolute',top:375,left:86,right:86,textAlign:'center',fontFamily:'Readex',fontWeight:700,fontSize:242,lineHeight:1.3,color:'#5C93FF',scale:motion(f,10,35,.85,1)}}>٠</div>
<div style={{position:'absolute',top:692,left:86,right:86,textAlign:'center',fontSize:50,fontWeight:600}}><T>إعلانات</T></div>
<div style={{position:'absolute',top:840,left:115,right:115,display:'flex',flexDirection:'column',gap:29}}>{[['shield','بلا حساب أو تتبع'],['download','التحميل بالكامل على جهازك'],['lock','روابطك وملفاتك تبقى لك']].map(([icon,text],i)=><div key={text} style={{display:'flex',alignItems:'center',gap:24,fontSize:40,opacity:motion(f,40+i*18,60+i*18)}}><Icon name={icon} color="#5C93FF" size={40}/><T>{text}</T></div>)}</div>
<div style={{position:'absolute',left:115,right:115,top:1157,fontSize:26,color:'#8F9DBF',lineHeight:1.8}}><T>يتصل هاتفك مباشرة بالمواقع لتنزيل المحتوى</T></div><Sound at={25} file="ding" volume={.13}/></Frame>;
};
export const Outro=()=>{
const f=useCurrentFrame();return <Frame chapter="نزل" number={24} title="احفظ ما تحب" accent="بخطوات تعرفها الآن">
<div style={{position:'absolute',top:426,left:440,scale:motion(f,4,35,.8,1)}}><Glyph size={200}/></div>
<div style={{position:'absolute',top:680,left:86,right:86,textAlign:'center',fontFamily:'Readex',fontSize:108,fontWeight:650}}><T>نزل</T></div>
<div style={{position:'absolute',top:865,left:150,right:150,textAlign:'center',fontSize:43,lineHeight:1.7,color:C.muted}}><T>شارك الرابط واختر الجودة</T><br/><T>واترك التحميل لهاتفك</T></div>
<div style={{position:'absolute',left:260,right:260,top:1083,height:78,borderRadius:23,background:C.blue,color:'white',display:'flex',alignItems:'center',justifyContent:'center',gap:15,fontSize:32}}><Icon name="share" size={30}/><T>ابدأ بمشاركة رابطك</T></div>
<div style={{position:'absolute',left:86,right:86,top:1200,textAlign:'center',fontSize:24,color:C.muted}}><T>لأندرويد ١٠ وأحدث</T></div><Sound at={24} file="ding" volume={.18}/></Frame>;
};
