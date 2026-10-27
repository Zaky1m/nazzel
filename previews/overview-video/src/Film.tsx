import {Series,useVideoConfig,staticFile} from 'remotion';
import {Audio} from '@remotion/media';
import {Intro,SupportedSites,ThemeScene,ChannelScene,PrivacyScene,Outro} from './BrandScenes';
import {YouTubeShare,AndroidShare,ShareQuality,Background,SocialShare} from './ShareScenes';
import {HomeDownload,AudioDownload,PlaylistDownload,ManageDownloads} from './DownloadScenes';
import {SettingScene} from './SettingsScenes';
export const Film=()=>{const {fps}=useVideoConfig();return <>
<Audio src={staticFile('bgm/bed.mp3')} volume={.52} premountFor={fps}/>
<Series>
<Series.Sequence name="Opening" durationInFrames={6*fps} premountFor={fps}><Intro/></Series.Sequence>
<Series.Sequence name="YouTube sharing" durationInFrames={12*fps} premountFor={fps}><YouTubeShare/></Series.Sequence>
<Series.Sequence name="Choose Nazzel" durationInFrames={7*fps} premountFor={fps}><AndroidShare/></Series.Sequence>
<Series.Sequence name="Quality overlay" durationInFrames={10*fps} premountFor={fps}><ShareQuality/></Series.Sequence>
<Series.Sequence name="Background download" durationInFrames={7*fps} premountFor={fps}><Background/></Series.Sequence>
<Series.Sequence name="Facebook sharing" durationInFrames={10*fps} premountFor={fps}><SocialShare platform="Facebook" number={6}/></Series.Sequence>
<Series.Sequence name="Instagram sharing" durationInFrames={10*fps} premountFor={fps}><SocialShare platform="Instagram" number={7}/></Series.Sequence>
<Series.Sequence name="TikTok sharing" durationInFrames={10*fps} premountFor={fps}><SocialShare platform="TikTok" number={8}/></Series.Sequence>
<Series.Sequence name="Paste or clipboard" durationInFrames={11*fps} premountFor={fps}><HomeDownload/></Series.Sequence>
<Series.Sequence name="Audio only" durationInFrames={8*fps} premountFor={fps}><AudioDownload/></Series.Sequence>
<Series.Sequence name="Playlists" durationInFrames={14*fps} premountFor={fps}><PlaylistDownload/></Series.Sequence>
<Series.Sequence name="Download management" durationInFrames={12*fps} premountFor={fps}><ManageDownloads/></Series.Sequence>
<Series.Sequence name="Twenty supported platforms" durationInFrames={18*fps} premountFor={fps}><SupportedSites/></Series.Sequence>
<Series.Sequence name="Settings overview" durationInFrames={5*fps} premountFor={fps}><SettingScene kind="overview"/></Series.Sequence>
<Series.Sequence name="Default quality" durationInFrames={8*fps} premountFor={fps}><SettingScene kind="quality"/></Series.Sequence>
<Series.Sequence name="Sharing preference" durationInFrames={9*fps} premountFor={fps}><SettingScene kind="ask"/></Series.Sequence>
<Series.Sequence name="Save folder" durationInFrames={10*fps} premountFor={fps}><SettingScene kind="folder"/></Series.Sequence>
<Series.Sequence name="Local statistics" durationInFrames={8*fps} premountFor={fps}><SettingScene kind="stats"/></Series.Sequence>
<Series.Sequence name="About app" durationInFrames={8*fps} premountFor={fps}><SettingScene kind="about"/></Series.Sequence>
<Series.Sequence name="Version check" durationInFrames={9*fps} premountFor={fps}><SettingScene kind="version"/></Series.Sequence>
<Series.Sequence name="System theme" durationInFrames={7*fps} premountFor={fps}><ThemeScene/></Series.Sequence>
<Series.Sequence name="Telegram channel" durationInFrames={7*fps} premountFor={fps}><ChannelScene/></Series.Sequence>
<Series.Sequence name="No ads and on device" durationInFrames={10*fps} premountFor={fps}><PrivacyScene/></Series.Sequence>
<Series.Sequence name="Closing" durationInFrames={7*fps} premountFor={fps}><Outro/></Series.Sequence>
</Series></>;};
