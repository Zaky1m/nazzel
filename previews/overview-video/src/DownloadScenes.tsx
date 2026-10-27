import {useCurrentFrame} from 'remotion';
import {Frame,Copy,Phone,Tap,Sound,Focus} from './Layout';
import {HomeUI,PlaylistUI,DownloadsUI} from './AppUI';
import {linear,motion} from './design';
export const HomeDownload=()=>{
const f=useCurrentFrame();return <Frame chapter="التحميل داخل التطبيق" number={9} title="رابط واحد" accent="والباقي داخل نزل">
<Phone><HomeUI filled={f>48} ready={f>97}/><Tap x={38} y={89} at={48}/><Tap x={193} y={532} at={275}/></Phone>
{f<155?<Copy title="الصق رابط الفيديو" body="افتح نزل والصق الرابط في الحقل لتظهر المعاينة والجودات المتاحة"/>:<Copy key="clipboard" at={155} title="أو انسخه وافتح التطبيق" body="يتعرف نزل على الرابط الجديد في الحافظة ويجهز المعاينة تلقائيا" foot="الأيقونة داخل الحقل تتحول من لصق إلى مسح عند إدخال رابط"/>}<Sound at={48}/><Sound at={275}/></Frame>;
};
export const AudioDownload=()=>{
const f=useCurrentFrame();return <Frame chapter="التحميل داخل التطبيق" number={10} title="فيديو أو صوت" accent="اختر ما تريد حفظه">
<Phone><HomeUI audio={f>95}/><Tap x={67} y={474} at={95}/><Focus x={17} y={449} w={354} h={65}/></Phone>
<Copy title="خيار صوت فقط" body="إذا وفر الموقع مسارا صوتيا مستقلا يمكنك حفظ الصوت وحده" foot="يحفظ الصوت بصيغة M4A دون تحويل إلى MP3"/><Sound at={95}/></Frame>;
};
export const PlaylistDownload=()=>{
const f=useCurrentFrame();const stage=f<125?0:f<270?1:2;
return <Frame chapter="قوائم التشغيل" number={11} title="قائمة كاملة" accent="أو المقاطع التي تختارها">
<Phone><PlaylistUI selected={f<110?6:4} scroll={motion(f,205,268,0,155)}/><Tap x={348} y={480} at={110}/><Tap x={185} y={565} at={345}/><Focus x={14} y={535} w={357} h={65} show={stage===2}/></Phone>
{stage===0?<Copy title="أدخل رابط القائمة" body="تظهر مقاطع قائمة يوتيوب لتحدد ما تريد منها أو تختارها كلها"/>:stage===1?<Copy key="quality" at={125} title="جودة واحدة للقائمة" body="حدد الجودة المناسبة وتابع المقاطع التي اخترتها قبل بدء التحميل" foot="يدعم أيضا الألبومات والمنشورات التي تضم أكثر من فيديو"/>:<Copy key="sticky" at={270} title="زر التحميل في متناولك" body="يبقى زر نزل المحدد ثابتا أسفل الشاشة أثناء تمرير القائمة"/>}<Sound at={110}/><Sound at={345}/></Frame>;
};
export const ManageDownloads=()=>{
const f=useCurrentFrame();const stage=f<125?0:f<250?1:2;
return <Frame chapter="إدارة التحميلات" number={12} title="كل تحميلاتك" accent="في مكان واحد">
<Phone><DownloadsUI batch progress={linear(f,0,300,.1,.94)} actions confirm={f>280}/>{stage===0&&<Focus x={16} y={245} w={353} h={132}/>} {stage===1&&<Tap x={48} y={103} at={210}/>} {stage===2&&<Tap x={25} y={25} at={278}/>}</Phone>
{stage===0?<Copy title="تابع كل مقطع" body="تظهر القائمة مجمعة مع تقدم كل فيديو ويمكنك إلغاء مقطع أو إلغاء الكل"/>:stage===1?<Copy key="actions" at={125} title="تشغيل ومشاركة وحذف" body="شغل الملفات المكتملة أو شاركها وأعد المحاولة عند تعذر التحميل"/>:<Copy key="delete" at={250} title="حذف الكل مع تأكيد" body="نظف العناصر الظاهرة دفعة واحدة وانتبه إلى حذف الملفات المكتملة من مجلدها أيضا"/>}<Sound at={210}/><Sound at={278}/></Frame>;
};
