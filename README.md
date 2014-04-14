# Hendrix

Peer-to-peer (p2p) chat

## About

This is an attempt to create a p2p chat for web that reminds of old-good IRC. The core difference from many alternatives that are around the web is peer-to-peer architecture. In other words, chatting should be completely server-less. This can be done to a level where only server is so called connection broker that doesn't receive any data, but only points one peer to another.

Work in progress. **Star the repo if you would like this to take off!**

## Development Setup

First of all, clone the repo. After that, check that you have `wget` installed and execute `collect_vendor.sh` from root directory of the repo. The script should download 3rd-party scripts and put them into `static/vendor/` directory. Next, you will need to compile CoffeeScript and Sass files. Check that you have `coffee` and `sass` installed. Then execute `watch_static.sh` script so files are watched and hence built. Check that you have `*.js` files in `static/scripts/` directory and `*.css` files in `static/styles/` directory. You can use the script to develop too — it will watch for file changes and automatically rebuild! Finally, run server with `run_server.sh` script. You will need Python 3 for it. Alternatively, use any HTTP server that can server static files. Now you can open Hendrix by going to `http://127.0.0.1:8000/` in your browser!

## Used Technologies

* Bootstrap,
* CoffeeScript,
* Director,
* Lo-Dash,
* Marked,
* PeerJS,
* React,
* Sass,
* Store.js;
