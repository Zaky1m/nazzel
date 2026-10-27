import React from 'react';
import {Img,staticFile,useCurrentFrame} from 'remotion';
import {C,Palette,light,clean,small,arabic,motion,linear} from './design';
import {Glyph,Icon,Brand} from './Icons';
import {Tap} from './Layout';
export const T=({children,style}:{children:React.ReactNode;style?:React.CSSProperties})=><span data-text="true" style={style}>{typeof children==='string'?clean(children):children}</span>;
export const Thumb=({file='lake',style}:{file?:string;style?:React.CSSProperties})=><Img src={staticFile('media/'+file+'.jpg')} style={{width:'100%',height:'100%',objectFit:'cover',...style}}/>;
export const Chip=({label,on=false,p=light}:{label:string;on?:boolean;p?:Palette})=><div style={{padding:'8px 13px',borderRadius:30,border:'1px solid '+(on?p.accent:p.line),background:on?p.accent:'transparent',color:on?p.onAccent:p.mute,fontSize:15,fontWeight:on?600:400,whiteSpace:'nowrap'}}><T>{label}</T></div>;
export const Button=({label='نزل',p=light}:{label?:string;p?:Palette})=><div style={{background:p.accent,color:p.onAccent,borderRadius:14,padding:'13px 16px',display:'flex',gap:9,alignItems:'center',justifyContent:'center',fontFamily:'Readex',fontSize:18,fontWeight:600}}><Icon name="download" size={22}/><T>{label}</T></div>;
export const AppChrome=({children,title='نزل',tab=0,p=light,channel=false,channelFrame=999}:{children:React.ReactNode;title?:string;tab?:number;p?:Palette;channel?:boolean;channelFrame?:number})=><div style={{position:'absolute',inset:0,background:p.bg,color:p.text,fontFamily:'Plex'}}>
<div style={{height:62,padding:'12px 18px',display:'flex',gap:9,alignItems:'center',fontFamily:'Readex',fontSize:26,fontWeight:650}}>{title==='نزل'&&<Glyph size={30}/>}<T>{title}</T></div>
<div style={{position:'absolute',inset:'64px 0 74px',overflow:'hidden'}}>{children}</div>
{channel&&<ChannelPill frame={channelFrame}/>}
<div style={{position:'absolute',bottom:0,left:0,right:0,height:72,borderTop:'1px solid '+p.line,background:p.bg,display:'flex',alignItems:'center',justifyContent:'space-around'}}>{['الرئيسية','التحميلات','الإعدادات'].map((v,i)=><div key={v} style={{display:'flex',flexDirection:'column',alignItems:'center',gap:3,color:tab===i?p.accent:p.mute,fontSize:12}}><div style={{width:63,height:33,borderRadius:30,display:'grid',placeItems:'center',background:tab===i?p.raise:undefined}}><Icon name={['home','download','settings'][i]} size={24}/></div><T>{v}</T></div>)}</div>
</div>;
export const ChannelPill=({frame}:{frame:number})=>{
const width=52+202*(motion(frame,8,27)-motion(frame,120,150));
return <div style={{position:'absolute',bottom:89,right:15,height:52,width,borderRadius:28,background:'#229ED9',overflow:'hidden',display:'flex',alignItems:'center',zIndex:9,color:'white'}}><Brand name="Telegram" size={52}/><div style={{fontSize:12,whiteSpace:'nowrap',paddingLeft:13,opacity:motion(frame,19,34)-motion(frame,115,138)}}><T>انضم لقناتنا لمزيد من التطبيقات</T></div></div>;
};
export const QualitySheet=({selected='720',audio=false,p=light,full=false}:{selected?:string;audio?:boolean;p?:Palette;full?:boolean})=><div style={{position:'absolute',bottom:0,left:0,right:0,background:p.bg,borderRadius:full?'0':'26px 26px 0 0',padding:'11px 18px 18px',color:p.text}}>
{!full&&<div style={{height:4,width:40,borderRadius:9,background:p.line,margin:'0 auto 18px'}}/>}
{!full&&<div style={{display:'flex',alignItems:'center',gap:9,fontFamily:'Readex',fontSize:25,marginBottom:18}}><Glyph size={30}/><T>نزل</T></div>}
<div style={{display:'flex',gap:12,alignItems:'center',marginBottom:17}}><div style={{width:87,height:55,borderRadius:10,overflow:'hidden',flexShrink:0}}><Thumb/></div><div style={{flex:1,minWidth:0}}><T style={{fontWeight:600,fontSize:17,display:'block',lineHeight:1.5}}>رحلة إلى البحيرة</T><div style={{fontSize:13,color:p.mute,marginTop:4}}>YouTube</div></div></div>
<div style={{display:'flex',gap:7,flexWrap:'wrap',marginBottom:17}}>{['1080','720','480'].map(v=><Chip key={v} label={v+small('p')} on={selected===v} p={p}/>)}<Chip label="صوت فقط" on={audio} p={p}/></div>
{audio&&<div style={{fontSize:13,color:p.mute,margin:'-3px 0 13px'}}>{small('M4A')}</div>}
<Button p={p}/>
</div>;
export const HomeUI=({filled=true,ready=true,audio=false,p=light,channelFrame=999}:{filled?:boolean;ready?:boolean;audio?:boolean;p?:Palette;channelFrame?:number})=><AppChrome p={p} channel channelFrame={channelFrame}>
<div style={{padding:'0 17px'}}>
<div style={{height:51,borderRadius:14,border:'1px solid '+p.line,background:p.surface,display:'flex',alignItems:'center',justifyContent:'space-between',padding:'0 14px',color:p.mute,fontSize:15}}><T>{filled?'رابط فيديو يوتيوب':'الصق رابط الفيديو'}</T><Icon name={filled?'close':'clipboard'} size={21}/></div>
{ready&&<div style={{marginTop:16,background:p.surface,borderRadius:18,padding:13}}>
<div style={{height:174,borderRadius:12,overflow:'hidden'}}><Thumb/></div>
<div style={{fontWeight:600,fontSize:19,marginTop:13}}><T>رحلة إلى البحيرة</T></div><div style={{fontSize:13,color:p.mute,marginTop:3}}>YouTube</div>
<div style={{display:'flex',gap:7,flexWrap:'wrap',marginTop:16,marginBottom:14}}>{['1080','720','480'].map(v=><Chip key={v} label={v+small('p')} on={!audio&&v==='720'} p={p}/>)}<Chip label="صوت فقط" on={audio} p={p}/></div>
<Button p={p}/>
</div>}
{!filled&&<div style={{marginTop:109,textAlign:'center',color:p.mute}}><Icon name="link" size={56}/><div style={{fontSize:19,marginTop:18}}><T>شارك رابط فيديو أو الصقه هنا</T></div></div>}
</div>
</AppChrome>;
export const PlaylistUI=({selected=4,scroll=0,p=light}:{selected?:number;scroll?:number;p?:Palette})=><AppChrome p={p}>
<div style={{padding:'0 17px'}}>
<div style={{height:45,borderRadius:14,border:'1px solid '+p.line,background:p.surface,padding:'10px 14px',fontSize:14,color:p.mute,display:'flex',justifyContent:'space-between'}}><T>رابط قائمة يوتيوب</T><Icon name="close" size={19}/></div>
<div style={{display:'flex',gap:11,alignItems:'center',margin:'18px 0'}}><div style={{width:83,height:55,borderRadius:10,overflow:'hidden'}}><Thumb file="mountain"/></div><div><T style={{display:'block',fontSize:18,fontWeight:600}}>رحلات تستحق الحفظ</T><T style={{display:'block',color:p.mute,fontSize:13}}>٦ مقاطع</T></div></div>
<div style={{display:'flex',gap:7,marginBottom:11}}><Chip label="الأعلى" p={p}/><Chip label={'720'+small('p')} on p={p}/><Chip label="صوت فقط" p={p}/></div>
<div style={{display:'flex',justifyContent:'space-between',margin:'8px 0',fontSize:13,color:p.mute}}><T>{'محدد '+arabic(selected)+' من ٦'}</T><T style={{color:p.accent}}>تحديد الكل</T></div>
<div style={{height:281,overflow:'hidden'}}><div style={{translate:`0 ${-scroll}px`}}>{['هدوء البحيرة','بين الجبال','الطريق إلى البحر','غروب الشمس','رحلة في الطبيعة','يوم جديد'].map((s,i)=><div key={s} style={{height:75,display:'flex',alignItems:'center',gap:9,borderBottom:'1px solid '+p.line}}><div style={{width:23,height:23,borderRadius:24,border:'1.5px solid '+(i<selected?p.accent:p.line),background:i<selected?p.accent:'transparent',color:p.onAccent,display:'grid',placeItems:'center',flexShrink:0}}>{i<selected&&<Icon name="check" size={15}/>}</div><div style={{width:68,height:42,borderRadius:7,overflow:'hidden',flexShrink:0}}><Thumb file={['lake','mountain','coast'][i%3]}/></div><T style={{fontSize:15,fontWeight:500}}>{s}</T></div>)}</div></div>
</div>
<div style={{position:'absolute',bottom:0,right:0,left:0,padding:'10px 17px 12px',background:p.bg,borderTop:'1px solid '+p.line}}><Button label={'نزل المحدد '+arabic(selected)} p={p}/></div>
</AppChrome>;
export const DownloadsUI=({p=light,batch=false,progress=.6,actions=false,confirm=false}:{p?:Palette;batch?:boolean;progress?:number;actions?:boolean;confirm?:boolean})=><AppChrome title="التحميلات" tab={1} p={p} channel>
<div style={{padding:'0 16px'}}>
<div style={{display:'flex',gap:5,alignItems:'center',justifyContent:'space-between',marginBottom:15}}><div style={{display:'flex',gap:5}}><Chip label="الكل" on p={p}/><Chip label="شغال" p={p}/><Chip label="خلص" p={p}/></div><Icon name="trash" size={20} color={p.mute}/></div>
{batch&&<div style={{padding:'12px 12px 7px',background:p.raise,borderRadius:15,marginBottom:10}}><T style={{display:'block',fontWeight:600,fontSize:17}}>رحلات تستحق الحفظ</T><div style={{display:'flex',justifyContent:'space-between',fontSize:13,marginTop:8,color:p.mute}}><T>١ من ٤ اكتمل</T><T style={{color:p.accent}}>إلغاء الكل</T></div></div>}
{['رحلة إلى البحيرة','بين الجبال','الطريق إلى البحر'].map((s,i)=><div key={s} style={{background:p.surface,borderRadius:16,padding:12,marginBottom:11}}>
<div style={{display:'flex',gap:11,alignItems:'center'}}><div style={{width:78,height:49,overflow:'hidden',borderRadius:9,flexShrink:0}}><Thumb file={['lake','mountain','coast'][i]}/></div><div style={{flex:1,minWidth:0}}><T style={{fontWeight:600,fontSize:15,display:'block'}}>{s}</T><div style={{fontSize:12,color:p.mute,marginTop:4}}>YouTube</div></div></div>
<div style={{fontSize:13,color:i===0?C.green:p.mute,marginTop:10}}><T>{i===0?'تم الحفظ في المعرض':i===1?'جار التحميل':'في الانتظار'}</T></div>
{i===1&&<div style={{height:4,background:p.line,borderRadius:4,margin:'10px 0'}}><div style={{height:4,width:(progress*100)+'%',background:p.accent,borderRadius:4}}/></div>}
<div style={{display:'flex',alignItems:'center',gap:15,marginTop:11,color:p.mute}}>{i===0?<><div style={{padding:'5px 12px',borderRadius:9,background:p.raise,color:p.accent,display:'flex',gap:6,alignItems:'center'}}><Icon name="play" size={17}/><T style={{fontSize:13}}>تشغيل</T></div><Icon name="share" size={19}/><Icon name="trash" size={19}/></>:<T style={{fontSize:13,color:p.accent}}>إلغاء</T>}</div>
</div>)}
{actions&&<div style={{fontSize:12,color:p.mute,textAlign:'center',paddingTop:10}}><T>أعد المحاولة عند تعذر التحميل</T></div>}
</div>
{confirm&&<><div style={{position:'absolute',inset:0,background:'#0B1B3A60'}}/><div style={{position:'absolute',top:170,left:25,right:25,padding:23,borderRadius:25,background:p.bg,color:p.text}}><T style={{fontFamily:'Readex',fontSize:22,display:'block'}}>حذف الكل</T><T style={{fontSize:16,display:'block',marginTop:14,lineHeight:1.8}}>ستحذف الملفات المكتملة من مكان حفظها أيضا</T><div style={{marginTop:25,display:'flex',justifyContent:'flex-end',gap:30,color:p.accent,fontSize:17}}><T>إبقاء</T><T>حذف</T></div></div></>}
</AppChrome>;
const rowStyle:React.CSSProperties={padding:'12px 0',borderBottom:'1px solid '+light.line};
export const SettingsUI=({focus='',ask=true,quality='720',folder=false,checking=false,newVersion=false,p=light}:{focus?:string;ask?:boolean;quality?:string;folder?:boolean;checking?:boolean;newVersion?:boolean;p?:Palette})=>{
const f=useCurrentFrame();const focusStyle=(name:string):React.CSSProperties=>({outline:focus===name?'2px solid '+p.accent:undefined,outlineOffset:5,borderRadius:8});
return <AppChrome title="الإعدادات" tab={2} p={p}>
<div style={{padding:'0 17px',fontSize:15}}>
<T style={{display:'block',fontSize:12,color:p.mute,marginBottom:7}}>التحميل</T>
<div style={{padding:'2px 14px',borderRadius:18,background:p.surface}}>
<div style={{...rowStyle,borderColor:p.line,...focusStyle('quality')}}><T style={{fontWeight:600,display:'block',marginBottom:10}}>الجودة الافتراضية</T><div style={{display:'flex',gap:6}}>{['الأعلى','720','480','360'].map(v=><Chip key={v} label={v==='الأعلى'?v:v+small('p')} on={v===quality} p={p}/>)}</div></div>
<div style={{...rowStyle,borderColor:p.line,display:'flex',alignItems:'center',gap:12,...focusStyle('ask')}}><div style={{flex:1}}><T style={{fontSize:14,fontWeight:600,display:'block'}}>اسأل عن الجودة عند المشاركة</T><T style={{fontSize:11,color:p.mute,lineHeight:1.5,display:'block',marginTop:4}}>{ask?'تظهر نافذة اختيار الجودة فوق التطبيق':'ينزل بأعلى جودة مباشرة'}</T></div><div style={{width:49,height:29,borderRadius:30,background:ask?p.accent:p.line,padding:4,flexShrink:0}}><div style={{height:21,width:21,borderRadius:22,background:ask?p.onAccent:p.mute,translate:ask?'0 0':'-20px 0'}}/></div></div>
<div style={{padding:'12px 0',display:'flex',alignItems:'center',justifyContent:'space-between',...focusStyle('folder')}}><div><T style={{display:'block',fontWeight:600}}>مكان الحفظ</T><div style={{fontSize:11,color:p.mute,marginTop:4,fontFamily:'Arial'}}><T>{folder?'المجلد الذي اخترته':'Download Nazzel'}</T></div></div><Icon name="folder" size={22} color={p.mute}/></div>
</div>
<T style={{display:'block',fontSize:12,color:p.mute,margin:'14px 0 6px'}}>الإحصائيات</T>
<div style={{padding:'0 14px',borderRadius:18,background:p.surface,...focusStyle('stats')}}>
<div style={{padding:'12px 0',display:'flex',justifyContent:'space-between',borderBottom:'1px solid '+p.line}}><T>حملت حتى الآن</T><T style={{color:p.mute}}>١٣٧</T></div>
<div style={{padding:'12px 0',display:'flex',justifyContent:'space-between',alignItems:'center'}}><T>محفوظ في المعرض</T><T style={{color:p.mute,fontSize:12}}>٤٨ ملفا</T></div>
<div style={{fontSize:11,color:p.mute,paddingBottom:11}}>٢ جيجابايت</div>
</div>
<T style={{display:'block',fontSize:12,color:p.mute,margin:'14px 0 6px'}}>عن التطبيق</T>
<div style={{padding:13,borderRadius:17,background:p.surface,fontSize:12,lineHeight:1.8,...focusStyle('about')}}><T style={{display:'block'}}>نزل لا يجمع بيانات عنك ولا يرسلها لأي جهة</T><T style={{display:'block',marginTop:7,color:p.mute}}>حمل فقط المحتوى الذي يحق لك تحميله</T></div>
<div style={{marginTop:18,display:'flex',alignItems:'center',justifyContent:'center',gap:12,color:p.mute,fontSize:12,...focusStyle('version')}}><T>الإصدار ١ ٣ ٠</T><Icon name="refresh" size={19} style={{rotate:checking?(f*9)+'deg':'0deg'}}/></div>
{newVersion&&<T style={{display:'block',fontSize:12,color:p.accent,textAlign:'center',marginTop:8}}>نسخة جديدة متاحة</T>}
</div>
{folder&&<><div style={{position:'absolute',inset:0,background:p.bg,zIndex:5,padding:21,color:p.text}}><div style={{display:'flex',gap:18,alignItems:'center',marginBottom:30}}><Icon name="back"/><T style={{fontSize:21}}>اختيار مجلد</T></div><div style={{fontSize:15,color:p.mute,marginBottom:22}}><T>وحدة التخزين الداخلية</T></div>{['Download','Movies','Music','Nazzel'].map(v=><div key={v} style={{padding:'18px 4px',borderBottom:'1px solid '+p.line,display:'flex',gap:16,alignItems:'center'}}><Icon name="folder" color={p.accent}/>{v}</div>)}<div style={{position:'absolute',bottom:20,left:20,right:20,background:p.accent,color:p.onAccent,borderRadius:24,padding:13,textAlign:'center'}}><T>استخدام هذا المجلد</T></div></div><Tap x={180} y={523} at={170}/></>}
</AppChrome>;
};
