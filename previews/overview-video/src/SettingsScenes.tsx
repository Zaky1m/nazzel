import {useCurrentFrame} from 'remotion';
import {Frame,Copy,Phone,Tap,Sound} from './Layout';
import {SettingsUI} from './AppUI';
export type SettingKind='overview'|'quality'|'ask'|'folder'|'stats'|'about'|'version';
const data:Record<SettingKind,{number:number;title:string;accent:string;lead:string;body:string;foot?:string}>={
overview:{number:14,title:'إعدادات واضحة',accent:'تجربة تناسب استخدامك',lead:'كل خيار في مكانه',body:'خيارات التحميل ثم الإحصائيات ومعلومات التطبيق ورقم الإصدار'},
quality:{number:15,title:'الجودة الافتراضية',accent:'اخترها مرة واحدة',lead:'حدد الجودة مسبقا',body:'الأعلى أو ٧٢٠ أو ٤٨٠ أو ٣٦٠ بحسب ما يناسب استخدامك',foot:'عند توفر أكثر من جودة يبدأ الاختيار من تفضيلك المحفوظ'},
ask:{number:16,title:'الجودة عند المشاركة',accent:'اسأل أولا أو نزل مباشرة',lead:'نافذة لاختيار الجودة',body:'اترك الخيار مفعلا لتظهر نافذة الجودات فوق التطبيق الذي تشارك منه'},
folder:{number:17,title:'مكان الحفظ',accent:'ملفاتك حيث تريد',lead:'اختر مجلد الحفظ',body:'اضغط مكان الحفظ واختر مجلدا من منتقي أندرويد',foot:'المجلد الافتراضي Nazzel داخل Download للفيديو والصوت'},
stats:{number:18,title:'إحصائياتك',accent:'محفوظة على هاتفك',lead:'أرقام مفيدة لك',body:'اعرف عدد التحميلات السابقة والملفات المحفوظة وحجمها الإجمالي',foot:'هذه الإحصائيات محلية ولا تحتاج إلى حساب'},
about:{number:19,title:'عن التطبيق',accent:'معلومات واضحة',lead:'خصوصيتك وحقوق المحتوى',body:'يشرح هذا القسم أن نزل لا يجمع بياناتك ويذكرك بتحميل ما يحق لك تحميله فقط',foot:'المنشورات الخاصة أو التي تتطلب تسجيل الدخول غير مدعومة'},
version:{number:20,title:'رقم الإصدار',accent:'وفحص التحديثات',lead:'اضغط أيقونة التحديث',body:'تعرض نتيجة الفحص وتخبرك عند توفر إصدار أحدث',foot:'فحص فقط دون تنزيل التحديث أو تثبيته من داخل التطبيق'},
};
export const SettingScene=({kind='overview'}:{kind?:SettingKind})=>{
const f=useCurrentFrame();const d=data[kind];const off=kind==='ask'&&f>=140;const folder=kind==='folder'&&f>=95&&f<232;
return <Frame chapter="الإعدادات خطوة بخطوة" number={d.number} title={d.title} accent={d.accent}>
<Phone><SettingsUI focus={kind==='overview'?'':kind} quality={kind==='quality'&&f<95?'الأعلى':'720'} ask={!off} folder={folder} checking={kind==='version'&&f>90&&f<158}/>
{kind==='quality'&&<Tap x={239} y={141} at={95}/>}
{kind==='ask'&&<Tap x={54} y={214} at={140}/>}
{kind==='folder'&&<Tap x={63} y={292} at={90}/>}
{kind==='version'&&<Tap x={134} y={614} at={90}/>}
{kind==='version'&&f>172&&<div style={{position:'absolute',bottom:83,left:18,right:18,padding:15,background:'#E1EAFF',borderRadius:10,fontSize:14,color:'#0B1B3A',textAlign:'center'}}>لديك أحدث إصدار</div>}
</Phone>
{off?<Copy key="off" at={140} title="أو أعلى جودة مباشرة" body="عند إيقاف الخيار تبدأ المشاركة التحميل بأعلى جودة دون نافذة لاختيار الجودة" foot="يمكنك إعادة تفعيل نافذة الجودة في أي وقت"/>:<Copy title={d.lead} body={d.body} foot={d.foot}/>}
{['quality','folder','version'].includes(kind)&&<Sound at={kind==='quality'?95:90}/>}{kind==='ask'&&<Sound at={140}/>}
</Frame>;
};
