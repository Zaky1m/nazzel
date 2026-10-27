import {Composition,Folder} from 'remotion';
import {Film} from './Film';
import {Intro,SupportedSites,ThemeScene,ChannelScene,PrivacyScene,Outro} from './BrandScenes';
import {YouTubeShare,AndroidShare,ShareQuality,Background,SocialShare} from './ShareScenes';
import {HomeDownload,AudioDownload,PlaylistDownload,ManageDownloads} from './DownloadScenes';
import {SettingScene} from './SettingsScenes';
export const RemotionRoot=()=> <>
<Composition id="NazzelOverview" component={Film} width={1080} height={1350} fps={30} durationInFrames={6690}/>
<Folder name="Scenes">
<Composition id="Intro" component={Intro} width={1080} height={1350} fps={30} durationInFrames={180}/>
<Composition id="YouTubeShare" component={YouTubeShare} width={1080} height={1350} fps={30} durationInFrames={360}/>
<Composition id="AndroidShare" component={AndroidShare} width={1080} height={1350} fps={30} durationInFrames={210}/>
<Composition id="ShareQuality" component={ShareQuality} width={1080} height={1350} fps={30} durationInFrames={300}/>
<Composition id="Background" component={Background} width={1080} height={1350} fps={30} durationInFrames={210}/>
<Composition id="FacebookShare" component={SocialShare} defaultProps={{platform:'Facebook',number:6}} width={1080} height={1350} fps={30} durationInFrames={300}/>
<Composition id="InstagramShare" component={SocialShare} defaultProps={{platform:'Instagram',number:7}} width={1080} height={1350} fps={30} durationInFrames={300}/>
<Composition id="TikTokShare" component={SocialShare} defaultProps={{platform:'TikTok',number:8}} width={1080} height={1350} fps={30} durationInFrames={300}/>
<Composition id="HomeDownload" component={HomeDownload} width={1080} height={1350} fps={30} durationInFrames={330}/>
<Composition id="AudioDownload" component={AudioDownload} width={1080} height={1350} fps={30} durationInFrames={240}/>
<Composition id="PlaylistDownload" component={PlaylistDownload} width={1080} height={1350} fps={30} durationInFrames={420}/>
<Composition id="ManageDownloads" component={ManageDownloads} width={1080} height={1350} fps={30} durationInFrames={360}/>
<Composition id="SupportedSites" component={SupportedSites} width={1080} height={1350} fps={30} durationInFrames={540}/>
<Composition id="SettingsOverview" component={SettingScene} defaultProps={{kind:'overview'}} width={1080} height={1350} fps={30} durationInFrames={150}/>
<Composition id="DefaultQuality" component={SettingScene} defaultProps={{kind:'quality'}} width={1080} height={1350} fps={30} durationInFrames={240}/>
<Composition id="SharePreference" component={SettingScene} defaultProps={{kind:'ask'}} width={1080} height={1350} fps={30} durationInFrames={270}/>
<Composition id="SaveFolder" component={SettingScene} defaultProps={{kind:'folder'}} width={1080} height={1350} fps={30} durationInFrames={300}/>
<Composition id="Statistics" component={SettingScene} defaultProps={{kind:'stats'}} width={1080} height={1350} fps={30} durationInFrames={240}/>
<Composition id="AboutApp" component={SettingScene} defaultProps={{kind:'about'}} width={1080} height={1350} fps={30} durationInFrames={240}/>
<Composition id="VersionCheck" component={SettingScene} defaultProps={{kind:'version'}} width={1080} height={1350} fps={30} durationInFrames={270}/>
<Composition id="Theme" component={ThemeScene} width={1080} height={1350} fps={30} durationInFrames={210}/>
<Composition id="Channel" component={ChannelScene} width={1080} height={1350} fps={30} durationInFrames={210}/>
<Composition id="Privacy" component={PrivacyScene} width={1080} height={1350} fps={30} durationInFrames={300}/>
<Composition id="Outro" component={Outro} width={1080} height={1350} fps={30} durationInFrames={210}/>
</Folder></>;
