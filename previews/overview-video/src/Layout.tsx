import React from 'react';
import {AbsoluteFill,useCurrentFrame,useVideoConfig,Sequence,staticFile} from 'remotion';
import {Audio} from '@remotion/media';
import {C,clean,motion,linear,arabic} from './design';
import {Glyph,Icon} from './Icons';
export const Frame=({chapter,number,title,accent,children,dark=false}:{chapter:string;number:number;title:string;accent?:string;children:React.ReactNode;dark?:boolean})=>{
const f=useCurrentFrame();const {durationInFrames}=useVideoConfig();
return <AbsoluteFill dir="rtl" style={{background:dark?C.dark:C.paper,color:dark?'#EAF0FF':C.ink,fontFamily:'Plex',overflow:'hidden'}}>
<div style={{position:'absolute',top:59,left:86,right:86,display:'flex',justifyContent:'space-between',alignItems:'center',color:dark?'#8F9DBF':C.muted,fontSize:23}}><div style={{display:'flex',gap:12,alignItems:'center'}}><Glyph size={33}/><span>{clean(chapter)}</span></div><span style={{fontFamily:'Readex',fontSize:20}}>{arabic(number).padStart(2,'٠')}</span></div>
<div data-check="headline" style={{position:'absolute',right:86,left:86,top:135,fontFamily:'Readex',fontSize:78,fontWeight:650,lineHeight:1.34,opacity:motion(f,0,17),translate:`0 ${motion(f,0,22,24,0)}px`}}>{clean(title)}{accent&&<><br/><span style={{color:dark?'#5C93FF':C.blue}}>{clean(accent)}</span></>}</div>
{children}
<div style={{position:'absolute',left:86,right:86,bottom:52,height:3,background:dark?'#243256':'#E1E7F4',overflow:'hidden'}}><div style={{height:3,width:`${linear(f,0,durationInFrames,0,100)}%`,background:dark?'#5C93FF':C.blue}}/></div>
{f<12&&<div style={{position:'absolute',inset:0,background:C.blue,translate:`${motion(f,0,12,0,-110)}% 0`}}/>}
</AbsoluteFill>;
};
export const Copy=({kicker,title,body,foot,at=0}:{kicker?:string;title:string;body:string;foot?:string;at?:number})=>{
const f=useCurrentFrame();return <div data-check="copy" style={{position:'absolute',right:84,top:470,width:370,opacity:motion(f,at,at+16),translate:`${motion(f,at,at+20,24,0)}px 0`}}>
{kicker&&<div style={{fontSize:25,color:C.muted,marginBottom:24}}>{clean(kicker)}</div>}
<div style={{fontFamily:'Readex',fontWeight:620,fontSize:47,lineHeight:1.48,color:C.blue,marginBottom:24}}>{clean(title)}</div>
<div style={{fontSize:37,lineHeight:1.7,fontWeight:500}}>{clean(body)}</div>
{foot&&<div style={{fontSize:25,lineHeight:1.8,color:C.muted,borderTop:`2px solid ${C.line}`,paddingTop:22,marginTop:30}}>{clean(foot)}</div>}
</div>;
};
export const Phone=({children,dark=false,x=82,y=368,scale=1.13,tilt=0}:{children:React.ReactNode;dark?:boolean;x?:number;y?:number;scale?:number;tilt?:number})=>{
const f=useCurrentFrame();return <div data-phone="true" style={{position:'absolute',left:x,top:y,width:400,height:770,scale,transformOrigin:'top left',rotate:`${tilt}deg`,translate:`0 ${motion(f,4,27,25,0)}px`,opacity:motion(f,3,18),border:'7px solid #172039',borderRadius:43,background:dark?C.dark:'#fff',overflow:'hidden',direction:'rtl'}}>
<div style={{height:32,position:'relative',padding:'5px 22px 0',fontFamily:'Arial',fontWeight:600,fontSize:12,color:dark?'#EAF0FF':C.ink,display:'flex',justifyContent:'space-between',direction:'ltr'}}><span>٩ ٤١</span><div style={{display:'flex',gap:5,alignItems:'center'}}><svg width="15" height="12" viewBox="0 0 15 12"><path d="M1 11h2V7H1Zm4 0h2V5H5Zm4 0h2V3H9Zm4 0h2V0h-2Z" fill="currentColor"/></svg><Icon name="wifi" size={13}/><svg width="22" height="12" viewBox="0 0 25 12" fill="none" stroke="currentColor"><rect x="1" y="1" width="20" height="10" rx="2"/><path d="M23 4v4"/><rect x="3" y="3" width="16" height="6" fill="currentColor" stroke="none"/></svg></div></div>
<div style={{position:'absolute',inset:'32px 0 18px',overflow:'hidden'}}>{children}</div>
<div style={{position:'absolute',height:4,width:115,background:dark?'#EAF0FF':'#172039',bottom:7,left:'calc(50% - 57px)',borderRadius:9}}/>
</div>;
};
export const Tap=({x,y,at,hold=16}:{x:number;y:number;at:number;hold?:number})=>{const f=useCurrentFrame();if(f<at-11||f>at+hold)return null;return <div style={{position:'absolute',left:x-19,top:y-19,width:38,height:38,borderRadius:38,border:`2px solid ${C.blue}`,background:'#FFFFFFCC',scale:motion(f,at-10,at+hold,.5,1.6),opacity:f<at?motion(f,at-11,at-4):linear(f,at+2,at+hold,1,0),pointerEvents:'none',zIndex:30}}><div style={{position:'absolute',inset:9,borderRadius:20,background:C.blue}}/></div>;};
export const Focus=({x,y,w,h,show=true}:{x:number;y:number;w:number;h:number;show?:boolean})=>show?<div style={{position:'absolute',left:x,top:y,width:w,height:h,border:`2.5px solid ${C.blue}`,borderRadius:15,pointerEvents:'none',zIndex:20}}/>:null;
export const Sound=({at,file='click',volume=.26}:{at:number;file?:string;volume?:number})=>{const {fps}=useVideoConfig();return <Sequence from={at} durationInFrames={Math.round(2*fps)} layout="none" premountFor={fps}><Audio src={staticFile(`audio/${file}.wav`)} volume={volume} premountFor={fps}/></Sequence>;};
