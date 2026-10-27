import React from 'react';
import {C} from './design';
import brandData from './brands.json';
export const Glyph=({size=56,color='white',tile=true}:{size?:number;color?:string;tile?:boolean})=><div style={{width:size,height:size,borderRadius:size*.225,background:tile?C.blue:undefined,flexShrink:0,display:'grid',placeItems:'center'}}><svg width={size} height={size} viewBox="0 0 100 100" fill="none" stroke={color} strokeWidth="8.5" strokeLinecap="round" strokeLinejoin="round"><path d="M24 48 C24 74 37 84 50 84 C63 84 76 74 76 48"/><path d="M50 15 V57 M34 41 L50 57 L66 41"/></svg></div>;
const paths:Record<string,React.ReactNode>={
share:<path d="M14 3l7 7-7 7v-5C7 12 4 15 3 20c0-9 4-13 11-13V3Z"/>,
send:<><path d="m22 2-7 20-4-9-9-4 20-7Z"/><path d="m22 2-11 11"/></>,
download:<path d="M12 3v12m-5-5 5 5 5-5M4 18v3h16v-3"/>,
home:<path d="m3 10 9-8 9 8v11h-6v-7H9v7H3Z"/>,
settings:<><path d="m9 3 1-2h4l1 2 3 2 2 .2 2 3-1 2v4l1 2-2 3-2 .2-3 2-1 2h-4l-1-2-3-2-2-.2-2-3 1-2v-4l-1-2 2-3L6 5Z"/><circle cx="12" cy="12" r="3"/></>,
folder:<path d="M3 6h7l2 3h9v12H3V6Z"/>,clipboard:<path d="M9 4H5v18h14V4h-4M9 2h6v5H9zM8 12h8m-8 4h6"/>,
check:<path d="m5 12 4 4 10-10"/>,close:<path d="m6 6 12 12M6 18 18 6"/>,play:<path d="m8 4 13 8-13 8Z"/>,pause:<path d="M8 4v16M16 4v16"/>,
heart:<path d="M20 4c-3-2-6 0-8 2-2-2-5-4-8-2-5 4 0 10 8 16 8-6 13-12 8-16Z"/>,comment:<path d="M21 11a9 9 0 0 1-9 9H4l-3 3V11a10 10 0 0 1 20 0Z"/>,
search:<><circle cx="10" cy="10" r="7"/><path d="m15 15 7 7"/></>,refresh:<path d="M21 10a9 9 0 1 0-2 8M21 3v7h-7"/>,
trash:<path d="M3 6h18M8 6V3h8v3M6 6l1 15h10l1-15M10 10v7m4-7v7"/>,
lock:<><rect x="5" y="10" width="14" height="12" rx="3"/><path d="M8 10V6a4 4 0 0 1 8 0v4"/></>,
shield:<><path d="m12 2 9 4v7c0 5-9 9-9 9s-9-4-9-9V6Z"/><path d="m7 12 3 3 7-7"/></>,
arrow:<path d="M4 12h16m-6-6 6 6-6 6"/>,chevron:<path d="m9 5 7 7-7 7"/>,bell:<path d="M5 17V9a7 7 0 0 1 14 0v8l2 2H3ZM10 22h4"/>,
music:<><path d="M9 18V5l12-3v13M9 8l12-3"/><ellipse cx="5" cy="19" rx="4" ry="3"/><ellipse cx="17" cy="16" rx="4" ry="3"/></>,
link:<path d="m10 7 3-3a5 5 0 0 1 7 7l-3 3M14 17l-3 3a5 5 0 0 1-7-7l3-3M8 16l8-8"/>,
eye:<><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12Z"/><circle cx="12" cy="12" r="3"/></>,moon:<path d="M20 16A9 9 0 0 1 8 4a9 9 0 1 0 12 12Z"/>,
sun:<><circle cx="12" cy="12" r="4"/><path d="M12 1v2m0 18v2M1 12h2m18 0h2M4 4l2 2m12 12 2 2M4 20l2-2M18 6l2-2"/></>,
volume:<path d="M3 9h4l6-6v18l-6-6H3ZM17 7c4 2 4 8 0 10"/>,wifi:<><path d="M2 6a16 16 0 0 1 20 0M5 10a11 11 0 0 1 14 0M9 14a5 5 0 0 1 6 0"/><circle cx="12" cy="18" r="1"/></>,
back:<path d="M20 12H4m6-6-6 6 6 6"/>,grid:<><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></>,user:<><circle cx="12" cy="7" r="4"/><path d="M4 22v-3a8 8 0 0 1 16 0v3"/></>,thumbs:<path d="M8 10 13 2c4 0 3 5 2 8h6v5l-3 7H8ZM3 10h5v12H3Z"/>,
};
export const Icon=({name,size=24,color='currentColor',fill=false,style}:{name:string;size?:number;color?:string;fill?:boolean;style?:React.CSSProperties})=><svg style={{flexShrink:0,...style}} width={size} height={size} viewBox="0 0 24 24" fill={fill?color:'none'} stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">{paths[name]||paths.grid}</svg>;
export const Brand=({name,size=52}:{name:string;size?:number})=>{
const st:React.CSSProperties={width:size,height:size,borderRadius:size*.26,display:'grid',placeItems:'center',flexShrink:0,overflow:'hidden'};
if(name==='Nazzel')return <Glyph size={size}/>;
const vector=(brandData as Record<string,{path:string;hex:string}>)[name];
if(vector&&name!=='Instagram'&&name!=='Telegram')return <div style={{...st,background:'#'+vector.hex}}><svg width={size*.65} height={size*.65} viewBox='0 0 24 24' fill={['Snapchat','Kick','Rumble'].includes(name)?'#111':'white'}><path d={vector.path}/></svg></div>;
if(name==='YouTube')return <div style={{...st,background:'#F00'}}><svg width={size*.64} viewBox="0 0 40 28"><rect width="40" height="28" rx="8" fill="white"/><path d="m16 7 12 7-12 7Z" fill="#f00"/></svg></div>;
if(name==='Instagram')return <div style={{...st,background:'linear-gradient(35deg,#FFC244,#F50065,#8C30CE)'}}><svg width={size*.63} viewBox="0 0 32 32" fill="none" stroke="white" strokeWidth="2.7"><rect x="2" y="2" width="28" height="28" rx="8"/><circle cx="16" cy="16" r="6.4"/><circle cx="24" cy="8" r="1" fill="white"/></svg></div>;
if(name==='TikTok')return <div style={{...st,background:'#080808'}}><svg width={size*.64} viewBox="0 0 30 34"><path d="M17 2h6c0 5 3 7 7 7v6c-3 0-6-1-7-2v12a9 9 0 1 1-9-9v6c-5-1-5 6-1 6 2 0 4-1 4-4Z" fill="#25F4EE" transform="translate(-1 1)"/><path d="M17 2h6c0 5 3 7 7 7v6c-3 0-6-1-7-2v12a9 9 0 1 1-9-9v6c-5-1-5 6-1 6 2 0 4-1 4-4Z" fill="white"/></svg></div>;
if(name==='Telegram')return <div style={{...st,background:'#229ED9',borderRadius:size/2}}><svg width={size*.62} viewBox="0 0 24 24" fill="white"><path d="M21.944 4.585a1.52 1.52 0 0 0-2.1-1.72L2.45 9.65c-1.25.49-1.23 1.18-.23 1.49l4.46 1.39 1.73 5.43c.21.59.11.83.73.83.48 0 .69-.22.96-.49l2.32-2.25 4.82 3.56c.89.49 1.53.24 1.75-.83l2.95-14.2ZM8.1 12.21l10.53-6.64c.53-.32 1.02-.15.62.21l-8.99 8.11-.35 3.75-1.81-5.43Z"/></svg></div>;
const colors:Record<string,string>={Facebook:'#0866FF',X:'#111',Dailymotion:'#151515',SoundCloud:'#FF5500',Reddit:'#FF4500',Pinterest:'#E60023',Snapchat:'#FFFC00',Twitch:'#9146FF',Vimeo:'#1AB7EA',Bluesky:'#1185FE',LinkedIn:'#0A66C2',Tumblr:'#35465C',VK:'#0077FF',Bilibili:'#00A1D6',Likee:'#EC477E',Rumble:'#85C742',Kick:'#53FC18',WhatsApp:'#25D366'};
const letters:Record<string,string>={Facebook:'f',X:'X',Dailymotion:'d',SoundCloud:'s',Reddit:'r',Pinterest:'P',Snapchat:'S',Twitch:'t',Vimeo:'v',Bluesky:'B',LinkedIn:'in',Tumblr:'t',VK:'VK',Bilibili:'b',Likee:'L',Rumble:'R',Kick:'K',WhatsApp:'W'};
return <div style={{...st,background:colors[name]||'#64748B',color:['Snapchat','Kick','Rumble'].includes(name)?'#101010':'#fff',fontFamily:'Arial',fontWeight:800,fontSize:size*.65}}>{letters[name]||name[0]}</div>;
};
