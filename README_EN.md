English | [简体中文](./README.md)

> [!IMPORTANT]
> ## To everyone
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;Hey! Congratulations on reading this~ This is a modified version of NanoRocky based on the original author imsyy's homepage! The modified version adds more features, but also brings higher performance usage! (mainly from verbatim lyrics and seasonal effect rendering), and also adds security updates to enhance security.<p>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;NanoRocky is a Vue beginner. Because of his passion, he worked with his classmate Pizero to perfect this project. Therefore, the code may be very bad and may be full of bugs. You are welcome to give feedback when you encounter bugs, and you are also welcome to help!<p>
>#### About feedback and help
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;If you encounter any problems, please raise an issue on Github. If you need help, please post a discussion on Github. We will reply to you when we see it. Except for special circumstances, <b>please do not contact NanoRocky directly through other social contact! </b>NanoRocky is not a customer service, does not provide after-sales service, and does not have that much time to reply to private chats. Please understand!<p>
>### Finally, if you like this project, please give a STAR! Thank you very much~

<p>
<strong><h2>Homepage</h2></strong>
</p>

![Homepage](/screenshots/main.png)<p>
![Homepage](/screenshots/main1.png)<p>
![Homepage](/screenshots/main2.png)<p>

### 👀Demo

> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;Due to workbox caching, you may need to press `Ctrl` + `F5` to force refresh the browser cache to view the latest effects!

- [NanoRocky's Homepage](https://nanorocky.top/)

> If your project does not require Workbox local caching, such as when using a CDN or encountering an issue where subpath visits automatically redirect to the homepage, you can uncomment the following two lines in `vite.config.ts`:

```bash
selfDestroying: true,
injectRegister: false,
```

### 🎉 Functions

- [x] Loading animation
- [x] Site description
- [x] Hitokoto
- [x] Date and time
- [x] Live weather
- [x] Time progress bar
- [x] Music player
- [x] Mobile adaptation
- [x] Verbatim lyrics compatible

### ⚙️ Deployment

* **Installation** [node.js](https://nodejs.org/en-us/) **Environment**

  > node > 24.13.0 <p>
  > npm > 10.15.0

* Then run the `PowerShell` terminal with **administrator privileges** and `cd` to the project root directory
* In the `terminal` type:

```bash
# Install pnpm
npm install -g pnpm

# Install the dependencies
pnpm install

# Preview
pnpm dev

# Build
pnpm build
```

> Once the build is complete, the files in the `dist` folder can be uploaded to the server or imported and automatically deployed with one click using a hosting platform such as `Vercel`.


### ⚙️ Docker Deploy

> Installation and configuration of Docker will not be explained here, please solve it by yourself.

Single-container architecture, `admin-server` serves the main site, admin panel, and API:

```bash
# Copy env example
cp scripts/.env.deploy.example .env.deploy

# Build and start (pnpm build runs inside Docker)
docker compose --env-file .env.deploy up -d --build
```

- Main site: `http://localhost:12446/`
- Admin panel: `http://localhost:12446/admin`

### ⚙️ Vercel Deploy

> Other deployment platforms are roughly the same and will not be explained here.

1. Click `Fork` in the upper right corner of this repository to copy this repository to your `GitHub` account,
2. Copy the `/.env.example` file and rename it to `/.env` (Important)
3. Modify the configuration in the `/.env` file as needed
4. Click `Deploy` to successfully deploy

### Site Links

In `src/assets/siteLinks.json` you can customize the website links (to point to your own website):

```json
{
  "icon": "Blog",
  "name": "Blog",
  "link": "https://blog.your.domain/"
},
```

The icon of the `icon` website link can be added in `src/components/Links/index.vue`:

```js
// You can go to https://www.xicons.org to select and import it here
// The fa type is imported here
import {
  Link,
  Blog,
  CompactDisc,
  Cloud,
  Compass,
  Book,
  Fire,
  LaptopCode,
} from "@vicons/fa";

...

// Website link icon
const siteIcon = {
  Blog,
  Cloud,
  CompactDisc,
  Compass,
  Book,
  Fire,
  LaptopCode,
};
```

### Social Links

Social links can be customized in `src/assets/socialLinks.json`.

### Weather

Weather and region acquisition requires `Tencent Location Service` and `AutoNavi Open Platform` related APIs

- Go to [Tencent Location Service](https://lbs.qq.com/) or [AutoNavi Open Platform Console](https://console.amap.com/dev/index) to create a `Key` of the `Web Service` type, and fill the `Key` into the corresponding parameter in `.env`.
- Note: The FREE IP positioning interface of the AutoNavi Open Platform does not support IPV6. If you encounter an abnormality with the AutoNavi interface, please check whether the network environment has IPV6 and whether the system uses IPV6 first. You can also see whether the "remote address" is an IPV6 address in the browser developer options. The Tencent interface supports both IPV4 and IPV6.

You can also change other methods by yourself.

### Music

>This project uses the `Aplayer` music player based on `MetingJS` for quick song list customization
>\*Only supported in **Mainland China**

Please change the song related parameters in the `.env` file to customize the song list

```bash
# Songs API address (It is strongly recommended to build Meting-Api by yourself)
VITE_SONG_API = "https://metingapi.nanorocky.top/"
# Song server ( netease-netease, tencent-qq music )
VITE_SONG_SERVER = "netease"
VITE_SONG_SERVER_SECOND = "tencent"
# Playback type ( song-song, playlist-playlist, album-album, search-search, artist-artist )
VITE_SONG_TYPE = "playlist"
# Playback ID
VITE_SONG_ID = "3035221869"
VITE_SONG_ID_SECOND = "9518088898"
```

### Fonts

Now using` MiSans` and `HarmonyOS Sans` font, using font splitting to improve loading speed.

> `https://cdn-font.hyperos.mi.com/font/css?family=MiSans_VF:VF:Chinese_Simplify,Latin&display=swap` <p>
> `https://s1.hdslb.com/bfs/static/jinkela/long/font/regular.css`

### Website icon and website background

#### Website Background

You can modify the website background in `public/images`.<p>

If you want to add more local images as website backgrounds, you can rename the images to `background+number` and modify them:<p>

>· First edit `src/components/Background/index.vue`
```js
// Set a default value to prevent the wallpaper from failing when the JSON file cannot be loaded. You should try to ensure that the number of wallpapers is always no less than this default value.
let bgImageCount = 10; // Wallpapers for PC
let bgImageCountP = 2; // Mobile wallpaper
```

>· Then edit `public/images/config.json`
```js
{
  "bgImageCount": 10, // Wallpapers for PC
  "bgImageCountP": 2 // Mobile wallpaper
}
```
To add or reduce wallpapers later, you can edit `config.json` directly without recompiling the project. However, you must ensure that the number of wallpapers is always greater than or equal to the configuration in `index.vue`.

To configure the default wallpaper options, edit `src/store/index.js`

```js
coverType: "0", // Wallpaper Type
```

#### Website Icon

The website icon can be modified in `public/images/icon`.

#### Voice Interaction

>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;Voice interaction is divided into pre-generation and real-time generation.<p>
>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;Pre-generated audio needs to be generated in advance and placed in the `public/speechlocal/` path to replace the original audio. Pre-generated audio is designed for fixed notifications and has lower voice latency (it is recommended to use CDN or enable client caching for audio files).<p>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;The real-time generated voice is used for the music player to announce the song title. You need to build it yourself and fill it in `.env`. If you also use Azure, you can directly use [AzureSpeechAPI-by-PHP](https://github.com/NanoRocky/AzureSpeechAPI-by-PHP) to complete the API deployment.

#### More default settings

> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;For other default settings such as autoplay, word-by-word switch, voice interaction switch, etc., please edit `src/store/index.js`. However, these settings will only take effect for users who open the webpage for the first time after editing. To overwrite user settings, you need to clear the webpage data.

### Technology Stack

- [Vue](https://cn.vuejs.org/)
- [Vite](https://vitejs.cn/vite3-cn/)
- [Pinia](https://pinia.vuejs.org/zh/)
- [IconPark](https://iconpark.oceanengine.com/official)
- [xicons](https://xicons.org/)
- [TypeScript](https://www.typescriptlang.org/zh/)
- [Aplayer](https://aplayer.js.org/)

### API

- [韩小韩 WebAPI 接口](https://api.vvhan.com/)
- [搏天 API](https://api.btstu.cn/doc/sjbz.php)
- [教书先生 API](https://api.oioweb.cn/doc/weather/GetWeather)
- [高德开放平台](https://lbs.amap.com/)
- [腾讯位置服务](https://lbs.qq.com/)
- [Hitokoto 一言](https://hitokoto.cn/)
- [Meting API](https://github.com/injahow/meting-api)
- [Meting API 酪灰修改版](https://github.com/NanoRocky/meting-api)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=imsyy/home&type=Date)](https://star-history.com/#imsyy/home&Date)

## Special thanks
- [AMLL TTML Database](https://github.com/Steve-xmh/amll-ttml-db)
- [Meting API](https://github.com/injahow/meting-api)

### Thanks to the original author imsyy and the friends who helped with this project!
- [imsyy](https://github.com/imsyy/)
- [这个哔养得](https://github.com/pizeroLOL/)

<a title="SSL" target="_blank" href="https://myssl.com/seal/detail?domain=nanorocky.top"><img src="https://img.shields.io/badge/MySSL-Security Certification-brightgreen"></a>&nbsp;<a title="CDN" target="_blank" href="https://cdnjs.com/"><img src="https://img.shields.io/badge/CDN-Cloudflare-blue"></a>&nbsp;<a title="CDN2" target="_blank" href="https://cdnjs.com/"><img src="https://img.shields.io/badge/CDN-Tencent EdgeOne-blue"></a>&nbsp;<a title="Copyright" target="_blank" href="https://nanorocky.top/"><img src="https://img.shields.io/badge/Copyright%20%C2%A9%202023--2025-NanoRocky-red"></a>

