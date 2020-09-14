// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import { Socket } from "phoenix"
import NProgress from "nprogress"
import { LiveSocket } from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

var peer
var localStream = null
var mute = false
let Hooks = {}
var callList = []
Hooks.Main = {
    mounted() {
        const pushEvent = (id) => {
            this.pushEvent("active", { "peer-id": id })
        }
        peer = new Peer();
        peer.on('open', function (id) {
            console.log('peer open')
            navigator.mediaDevices.getUserMedia({ video: false, audio: true }).then(function (stream) {
                localStream = stream
                pushEvent(id)
            }).catch(function (err) {
                console.log('Failed to get local stream', err);
            });
        });
        peer.on('error', function (err) {
            console.log('error')
            console.log(err)
        });
        peer.on('close', function (err) {
            console.log('close')
            console.log(err)
        });
        peer.on('call', function (call) {
            console.log('Answering incoming call from ' + call.peer);

            call.answer(localStream)
            callList.push(call)

            call.on('stream', function (remoteStream) {

                console.log('connected from someone calling')

                var sound = document.createElement('audio')
                sound.autoplay = 'autoplay';
                sound.srcObject = remoteStream
                sound.className = 'peer-songs'
                sound.control = 'control'

                document.getElementById('song').appendChild(sound);


            });
            call.on('close', function () {
                console.log('connection close')

            });
            call.on('error', function () {
                console.log('connection close')

            });
        });


    }
}
Hooks.ChatList = {
    updated() {
        const ids = document.getElementsByClassName("peer-ids");
        for (var i = 0; i < ids.length; i++) {
            const id = ids[i].getAttribute("peer-id")
            var call = peer.call(id, localStream);
            call.on('stream', function (remoteStream) {
                console.log('connected to calling')

                var sound = document.createElement('audio')
                sound.autoplay = 'autoplay';
                sound.srcObject = remoteStream
                sound.className = 'peer-songs'
                sound.control = 'control'
                document.getElementById('song').appendChild(sound);
                console.log('play sound')

            });
            callList.push(call)
        }
    },
    beforeUpdate() {
        const song = document.getElementById('song')
        song.innerHTML = '';
        for (var i = 0; i < callList.length; i++) {
            const call = callList[i]
            call.close()
            console.log('close connection ', call.peer)
        }
        callList = []
        console.log('before update')
    }
}
Hooks.AudioList = {
    mounted() {
        console.log('mounted')
    },
    updated() {
        console.log('after audio update')

        console.log(document.getElementById("song").getElementsByClassName("peer-songs"))
    },
    beforeUpdate() {
        console.log('before audio update')

        console.log(document.getElementById("song").getElementsByClassName("peer-songs"))
    }
}

window.toggleMute = function () {
    mute = !mute
    var muteBtn = document.getElementById("mute-btn")

    if (localStream && mute) {
        localStream.getAudioTracks()[0].enabled = false
        muteBtn.innerHTML = "Unmute"
    } else {
        localStream.getAudioTracks()[0].enabled = true
        muteBtn.innerHTML = "Mute"
    }
}


let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: { _csrf_token: csrfToken } })

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

