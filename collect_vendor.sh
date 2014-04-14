set -e

mkdir -p static/vendor/
wget http://github.com/flatiron/director/raw/v1.2.2/build/director.js -O static/vendor/director-1.2.2.js
wget http://github.com/lodash/lodash/raw/2.4.1/lodash.js -O static/vendor/lodash-2.4.1.js
wget http://github.com/chjj/marked/raw/v0.3.2/lib/marked.js -O static/vendor/marked-0.3.2.js
wget http://github.com/peers/peerjs/raw/0.3.8/dist/peer.js -O static/vendor/peer-0.3.8.js
wget http://fb.me/react-with-addons-0.10.0.js -O static/vendor/react-with-addons-0.10.0.js
wget http://github.com/marcuswestin/store.js/raw/v1.3.16/store.js -O static/vendor/store-1.3.16.js
