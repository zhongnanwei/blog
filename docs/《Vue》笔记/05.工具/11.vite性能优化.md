---
title: webpack、vite性能优化
date: 2023-05-24 15:40:43
permalink: /pages/bccb11/
categories:
  - 《Vue》笔记
  - 工具
tags:
  - 
author: 
  name: Arthas
  link: https://github.com/zhongnanwei
---

## 压缩代码

代码压缩是提升性能的重要部分，它有以下几个好处：

- 减少页面的加载时间，这对于用户来说是非常重要的，因为他们希望能够尽快地访问页面内容，而不是等待很长时间。
- 减少对网络带宽的占用，对于那些使用移动设备访问网站的用户来说，这一点尤为重要。
- 增强代码安全性，压缩代码可以使源代码难以被恶意用户和攻击者窃取和阅读，从而增强代码的安全性。

### WebPack 压缩代码

- UglifyJSPlugin:压缩js

````js
// webpack.config.js
const UglifyJsPlugin = require("uglifyjs-webpack-plugin")

module.exports = {
  plugins: [new UglifyJsPlugin()],
}
````

- OptimizeCSSAssetsPlugin:压缩css

````js
// webpack.config.js
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin")

module.exports = {
  optimization: {
    minimizer: [new OptimizeCSSAssetsPlugin({})],
  },
}
````

### vite压缩

Vite 中默认开启了代码压缩，下面是 Vite 的默认配置，一般情况下不需要修改。

````js
// vite.config.js
import { defineConfig } from "vite"
export default defineConfig({
  build: {
    minify: "esbuild", // boolean | 'terser' | 'esbuild'
  },
})
````

如果需要，可以通过修改 minify 选项更改压缩方式。默认为 Esbuild，它比 terser 快 20-40 倍，压缩率只差 1%-2%。

## 压缩打包体积

- WebPack 开启 GZIP

````js
// webpack.config.js
const CompressionPlugin = require("compression-webpack-plugin")

module.exports = {
  plugins: [
    new CompressionPlugin({
      algorithm: "gzip",
      test: /\.(js|css|html|svg)$/,
      threshold: 10240,
      minRatio: 0.8,
    }),
  ],
}
````

- Vite 开启 GZIP

````js
// vite.config.js
import { defineConfig } from "vite"
import vue from "@vitejs/plugin-vue"
import viteCompression from "vite-plugin-compression"

export default defineConfig({
  plugins: [
    vue(),
    viteCompression({
      threshold: 10240, // the unit is Bytes
    }),
  ],
})
````

- 在服务器中开启 GZIP
⚠ 注意，在开启 gzip 之前，需要确保 Web 服务器已经开启了对应的 gzip 支持。

````sh
# nginx
server {
  gzip on;
  gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
  gzip_min_length 10240;
  gzip_comp_level 6;
}
````

````js
// node.js
const compression = require("compression")

app.use(compression())
````

## 压缩图片

### WebPack 压缩图片

在 Webpack 中，可以通过 image-webpack-loader 对图片进行压缩和优化处理。

````js
// webpack.config.js
module.exports = {
  module: {
    rules: [
      {
        test: /\.(png|jpe?g|gif)$/i,
        use: [
          {
            loader: "file-loader",
            options: {
              name: "[name].[ext]",
              outputPath: "images/",
              publicPath: "images/",
            },
          },
          {
            loader: "image-webpack-loader",
            options: {
              mozjpeg: {
                quality: 80,
              },
              pngquant: {
                quality: [0.65, 0.9],
                speed: 4,
              },
              gifsicle: {
                interlaced: false,
              },
              webp: {
                quality: 75,
              },
            },
          },
        ],
      },
    ],
  },
}
````

## Vite 压缩图片

在 Vite 中常用的图片压缩插件有 imagemin 和 squoosh，下面以 squoosh 为例：

````js
// vite.config.js
const { defineConfig } = require("vite")
const vue = require("@vitejs/plugin-vue")
const squooshPlugin = require("vite-plugin-squoosh")

module.exports = defineConfig({
  plugins: [
    vue(),
    squooshPlugin({
      // Specify codec options.
      codecs: {
        mozjpeg: { quality: 30, smoothing: 1 },
        webp: { quality: 25 },
        avif: { cqLevel: 20, sharpness: 1 },
        jxl: { quality: 30 },
        wp2: { quality: 40 },
        oxipng: { level: 3 },
      },
      // Do not encode .wp2 and .webp files.
      exclude: /.(wp2|webp)$/,
      // Encode png to webp.
      encodeTo: [{ from: /.png$/, to: "webp" }],
    }),
  ],
})
````

## 避免额外的 HTTP 请求

### 图片使用 LazyLoad 懒加载

- Vue 中实现图片懒加载

````js
// main.js
import Vue from "vue"
import VueLazyload from "vue-lazyload"

Vue.use(VueLazyload)
````

````vue
<template>
  <img v-lazy="imgUrl" alt="图片" />
</template>
````

- React 中实现图片懒加载

````js
import React from "react"
import LazyLoad from "react-lazyload"

function MyComponent() {
  return (
    <div>
      <LazyLoad>
        <img src='path/to/image' alt='image' />
      </LazyLoad>
    </div>
  )
}
````

- 原生 JS 实现图片懒加载
原生 JS 实现图片懒加载可以使用 Element.getBoundingClientRect() 方法，该方法会返回元素的大小及其相对于视口的位置。然后判断图片是否出现在页面上。

````html
<img class="lazyload" data-src="真实图片地址" />
<img class="lazyload" data-src="真实图片地址" />
<img class="lazyload" data-src="真实图片地址" />
````

````js
// 获取需要懒加载的图片元素
const lazyloadImages = document.querySelectorAll(".lazyload")
// 获取视口高度和宽度
const windowHeight = window.innerHeight
const windowWidth = window.innerWidth

// 判断一个元素是否在视口内
function isInViewport(element) {
  const rect = element.getBoundingClientRect()
  return rect.top >= 0 && rect.left >= 0 && rect.bottom <= windowHeight && rect.right <= windowWidth
}

// 监听窗口的滚动事件
window.addEventListener("scroll", function () {
  lazyloadImages.forEach(img => {
    if (isInViewport(img)) {
      img.src = img.dataset.src
      img.classList.remove("lazyload")
    }
  })
})
````

### 使用 CSS3 代替简单图片

可以利用 CSS3 代替一些简单的图片，这样就可以减少一些图片请求，提高页面加载速度。

### 使用 Data URI

将小图片转为 Data URI 格式，直接嵌入 CSS 或 HTML 中，可以避免请求。

- Webpack 中将小图片转换为 base64
在 Webpack 中，可以使用 url-loader 或者 file-loader 将小图片转换成 base64 编码的 Data URI 格式。这两个 loader 都是用于处理文件的，可以将文件转换成模块，以便在代码中引用。

其中，url-loader 和 file-loader 的主要区别在于处理方式不同。url-loader 在处理图片时，会先判断图片大小是否超过指定的限制，如果超过了限制，则使用 file-loader 进行处理；如果没有超过限制，则将图片转换成 base64 编码的 Data URI 格式，并嵌入到代码中，以减少 HTTP 请求次数。

````js
// webpack.config.js
module.exports = {
  module: {
    rules: [
      {
        test: /\.(png|jpg|gif)$/,
        use: [
          {
            loader: "url-loader",
            options: {
              limit: 8192, // 小于 8KB 的图片会被转换成 base64 编码的 Data URI 格式
              fallback: "file-loader", // 超过 8KB 的图片使用 file-loader 进行处理
            },
          },
        ],
      },
    ],
  },
}
````

- Vite 中将小图片转换为 base64

````js
// vite.config.js
module.exports = {
  build: {
    assetsInlineLimit: 8192, // 小于 8KB 的图片会被转换成 base64 编码的 Data URI 格式
  },
}
````

## 使用 HTTP/2

HTTP/2 是一种新的协议，相比 HTTP/1.1，可以更快地传输数据。 HTTP/1.1 的 Headers 采用的是文本格式，并且每一次请求都会带上一些完全相同的数据，而 HTTP/2 采用的是二进制编码，并且对 Headers 进行了 HPack 压缩，进而提升了传输效率。不仅如此，HTTP/2 还可以同时发送多个请求和响应，因此可以通过合并和压缩资源，减少请求的数量，提高页面加载速度。
HTTP/2 是向下兼容的，当浏览器不支持的时候会自动切换到 HTTP/1.1。但需要在服务器端和客户端同时配置才能生效。

可以通过以下步骤来升级到 HTTP/2：

1. 使用 HTTPS：HTTP/2 只支持加密连接，因此需要使用 HTTPS 来使用 HTTP/2。
2. 在服务器端启用 HTTP/2：需要在服务器端启用 HTTP/2，以便前端可以使用该协议。常见的 Web 服务器，如 Nginx 和 Apache，都支持 HTTP/2。

## 避免重绘（Repaint）和重排（Reflow）

- 重绘（Repaint） 就是浏览器使用新的样式重新渲染一个元素。改变元素的以下样式通常会触发重绘，应当尽量避免：background、border、border-radius
、box-shadow、color、visibility、outline。如果需要改变元素的某些 CSS 属性，尽量一次性改变，减少触发重绘的次数。
- 重排（Reflow） 就是浏览器重新渲染部分或全部页面，通常是当元素的尺寸发生改变或者浏览器的一些行为影响到页面布局而触发的
如果需要改变元素位置或尺寸，可以使用以下属性避免重排：position: fixed | absolute 使元素脱离文档流、transform 属性不会触发避免重排

## 使用节流防抖

[节流防抖](/pages/0f6a0ac99b62ede5)

## 使用服务端渲染（SSR） 

SSR（Server-Side Rendering，服务端渲染）是指将 Web 页面的生成过程从浏览器端转移到服务器端完成的一种技术。

在传统的 SPA（Single Page Application，单页应用）中，浏览器需要先下载 HTML、CSS、JavaScript 文件，并在客户端执行 JavaScript 代码，才能生成页面内容。这样的过程需要加载大量的 JavaScript 代码，会导致首屏渲染时间较长，影响用户体验。而通过 SSR 技术，服务器可以将页面的 HTML、CSS 和 JavaScript 代码预先生成好，并将渲染好的 HTML 代码直接返回给浏览器，从而加快页面加载速度，提高用户体验。
  SSR 在性能提升上有以下优点[五分钟了解 SPA 与 SSR](https://www.jianshu.com/p/6dc04b5b823e)：

- 提高页面加载速度：SSR 可以将渲染页面的工作从浏览器端转移到服务器端，减少浏览器的工作量，从而加快页面加载速度。
- 提高首屏渲染速度：SSR 可以将页面的渲染过程提前到服务器端完成，使得页面在浏览器端显示的速度更快，从而提高用户体验。
- 更好的可访问性：通过 SSR 技术，我们可以生成更符合 Web 标准的 HTML 页面，从而使得页面具有更好的可访问性。

## 使用 Web Workers

使用 Web Workers 可以将一些任务放在后台线程中执行，以避免阻塞主线程。主线程通常用于处理用户界面的更新和响应用户的操作，如果在主线程中执行耗时的任务，会导致用户界面出现卡顿或失去响应。使用 Web Workers 可以将这些耗时的任务放在后台线程中执行，从而避免阻塞主线程。Web Workers 可以与主线程进行通信，使得后台线程可以向主线程发送消息，而主线程也可以向后台线程发送消息。这种通信可以通过 postMessage 方法实现。

  Web Workers 的使用有一定的限制，例如它们不能访问 DOM 和一些浏览器 API。但是，如果应用程序需要处理大量数据或进行复杂的计算，使用 Web Workers 可以提高应用程序的性能和响应速度。

  以下是一个使用 Web Workers 的实际案例和代码示例：
假设我们有一个应用程序需要处理大量的数据，例如计算数组中所有元素的平均值。由于数据量很大，如果在主线程中执行这个任务，会导致页面出现卡顿或失去响应。因此，我们可以使用 Web Workers 将这个任务放在后台线程中执行，从而避免阻塞主线程。

````html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Web Workers Example</title>
  </head>
  <body>
    <p>计算数组中所有元素的平均值：</p>
    <p id="result"></p>
    <script>
      // 创建 Web Worker
      const worker = new Worker("worker.js")
      // 发送消息给 Web Worker
      worker.postMessage([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
      // 监听 Web Worker 的消息
      worker.onmessage = function (event) {
        // 将计算结果显示在页面上
        document.getElementById("result").textContent = event.data
      }
    </script>
  </body>
</html>
````

````js
// worker.js
// 监听主线程的消息
onmessage = function (event) {
  // 计算数组中所有元素的平均值
  const sum = event.data.reduce((a, b) => a + b, 0)
  const average = sum / event.data.length
  // 发送计算结果给主线程
  postMessage(average)
}
````

## 异步加载 JS 和 CSS

使用异步加载可以提高页面响应速度，具体来说，可以采取以下措施：

- 将 JavaScript 脚本放在页面底部，或者使用 defer 或 async 属性延迟 JavaScript 加载和执行。
- 将 CSS 样式通过 link 标签异步加载，也可以使用 JavaScript 动态加载样式表。

## 使用 CDN

服务器的位置是固定的，负载也是有限的。通常访客区域距离服务器越远，打开网站速度越慢。如果在高峰时间段，网站访问量很大，服务器无法负载，也会导致访问速度下降。

因此，我们可以将某些资源放到 CDN 上，这样就可以减少对服务器的 HTTP 请求。从而提高页面加载速度。
