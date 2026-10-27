import {useCurrentFrame} from 'remotion';
import {Frame,Copy,Phone,Tap,Focus,Sound} from './Layout';
import {SocialFeed,ShareOptions,Platform} from './SocialUI';
import {QualitySheet} from './AppUI';
import {motion} from './design';
export const YouTubeShare=()=>{
const f=useCurrentFrame();const second=f>=138;
return <Frame chapter="التحميل من المشاركة" number={2} title="ابدأ من يوتيوب" accent="ثم افتح خيارات المشاركة">
<Phone><SocialFeed/>{second?<><ShareOptions at={138}/><Focus x={13} y={518} w={76} h={88} show={f>165}/><Tap x={49} y={558} at={250}/></>:<><Focus x={140} y={432} w={96} h={49} show={f>25}/><Tap x={185} y={455} at={105}/></>}</Phone>
{second?<Copy key="second" at={138} kicker="الخطوة الثانية" title="اضغط مشاركة مجددا" body="من الخيارات اختر مشاركة لفتح قائمة تطبيقات الهاتف" foot="موضع هذا الخيار قد يظهر باسم المزيد بحسب التطبيق"/>:<Copy key="first" kicker="الخطوة الأولى" title="اضغط مشاركة" body="افتح الفيديو الذي تريد حفظه ثم اضغط زر المشاركة أسفله"/>}
<Sound at={105}/><Sound at={250}/></Frame>;
};
export const AndroidShare=()=> <Frame chapter="التحميل من المشاركة" number={3} title="من قائمة التطبيقات" accent="اختر نزل">
<Phone><SocialFeed/><ShareOptions android/><Focus x={276} y={468} w={85} h={95}/><Tap x={319} y={513} at={90}/></Phone>
<Copy kicker="الخطوة الثالثة" title="ابحث عن الأيقونة الزرقاء" body="اختر نزل من قائمة المشاركة في أندرويد" foot="يمكن تثبيت نزل في قائمة أندرويد إذا كان هاتفك يدعم ذلك"/><Sound at={90}/></Frame>;
export const ShareQuality=()=>{
const f=useCurrentFrame();return <Frame chapter="التحميل من المشاركة" number={4} title="اختر الجودة" accent="ثم اضغط نزل">
<Phone><SocialFeed/><div style={{position:'absolute',inset:0,background:'#0007'}}/><div style={{position:'absolute',inset:0,translate:`0 ${motion(f,0,20,330,0)}px`}}><QualitySheet selected={f<100?'720':'1080'}/></div><Tap x={323} y={572} at={100}/><Tap x={193} y={656} at={230}/><Focus x={14} y={544} w={357} h={55} show={f>30&&f<190}/></Phone>
{f<180?<Copy title="الجودة التي تناسبك" body="تظهر الجودات المتاحة للفيديو نفسه لتختار منها قبل التحميل" foot="تختلف الجودات المتاحة من فيديو إلى آخر"/>:<Copy key="download" at={180} title="نزل وواصل المشاهدة" body="اضغط نزل فتغلق النافذة ويبدأ التحميل وأنت داخل يوتيوب"/>}<Sound at={100}/><Sound at={230}/></Frame>;
};
export const Background=()=> <Frame chapter="التحميل من المشاركة" number={5} title="واصل ما تفعله" accent="والتحميل يتابع في الخلفية">
<Phone><SocialFeed notification/></Phone><Copy title="التقدم في الإشعار" body="تابع التحميل أو ألغ العملية من الإشعار حتى مع إغلاق واجهة نزل" foot="تجد الملف بعد اكتماله في المعرض ومجلد الحفظ"/><Sound at={22} file="ding" volume={.16}/></Frame>;
export const SocialShare=({platform,number}:{platform:Platform;number:number})=>{
const f=useCurrentFrame();const stage=f<78?0:f<155?1:f<225?2:3;
const names={YouTube:'يوتيوب',Facebook:'فيسبوك',Instagram:'إنستجرام',TikTok:'تيك توك'};
const details=[['افتح المشاركة','اضغط زر المشاركة في الفيديو'],[platform==='TikTok'?'اختر المزيد':platform==='Instagram'?'اختر مشاركة إلى':'اختر مشاركة','افتح قائمة المشاركة خارج المنصة'],['اختر نزل','من تطبيقات أندرويد اختر الأيقونة الزرقاء'],['الجودة ثم نزل','تظهر نافذة الجودة فوق المنصة ويبدأ التحميل']];
return <Frame chapter="التحميل من المشاركة" number={number} title={'ومن '+names[platform]} accent="نفس النتيجة بخطوات بسيطة">
<Phone dark={platform==='Instagram'||platform==='TikTok'}><SocialFeed platform={platform}/>{stage===1&&<ShareOptions platform={platform} at={78}/>} {stage===2&&<ShareOptions platform={platform} android at={155}/>} {stage===3&&<><div style={{position:'absolute',inset:0,background:'#0007'}}/><QualitySheet/></>}
{stage===0&&<Tap x={platform==='Facebook'?60:29} y={platform==='Facebook'?609:478} at={60}/>}
{stage===1&&<Tap x={49} y={platform==='Facebook'?560:platform==='Instagram'?550:556} at={140}/>}
{stage===2&&<Tap x={319} y={513} at={210}/>}
{stage===3&&<Tap x={193} y={656} at={278}/>}
</Phone><Copy key={stage} at={[0,78,155,225][stage]} kicker={'الخطوة '+['الأولى','الثانية','الثالثة','الرابعة'][stage]} title={details[stage][0]} body={details[stage][1]} foot={platform==='Instagram'?'للمنشورات العامة المتاحة دون تسجيل دخول':undefined}/>
<Sound at={60}/><Sound at={140}/><Sound at={210}/><Sound at={278}/></Frame>;
};
