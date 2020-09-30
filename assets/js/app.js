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
var videoStreamTrack = null
var mute = false
let Hooks = {}
var callList = []
var before_ids = []
var currentBroadcast = null
var localAudioTrack = null
var myId
function createEmptyVideoTrack({ width, height }) {
    const canvas = Object.assign(document.createElement('canvas'), { width, height });
    canvas.getContext('2d').fillRect(0, 0, width, height);

    const stream = canvas.captureStream();
    const track = stream.getVideoTracks()[0];

    return Object.assign(track, { enabled: false });
};


Hooks.Main = {
    mounted() {
        const pushEvent = (id) => {
            myId = id
            this.pushEvent("active", { "peer-id": id })
        }

        peer = new Peer({ host: "inoffice-peerjs.herokuapp.com", secure: true });
        peer.on('open', function (id) {
            console.log('peer open')
            navigator.mediaDevices.getUserMedia({ video: false, audio: true }).then(function (stream) {
                let audioTrack = stream.getAudioTracks()[0]
                localAudioTrack = audioTrack
                let videoTrack = createEmptyVideoTrack({ width: 500, height: 500 })
                const mediaStream = new MediaStream([audioTrack, videoTrack]);

                localStream = mediaStream
                pushEvent(id)

            }).catch(function (err) {
                console.log('Failed to get local stream', err);
            });
        });
        peer.on('error', function (err) {
            console.log('error')

            document.getElementById('error-peerjs').style.visibility = "visible";
            console.log(err)
        });
        peer.on('close', function (err) {
            console.log('close')
            console.log(err)
        });
        peer.on('call', function (call) {
            console.log('Answering incoming call from ' + call.peer);
            console.log(peer)
            call.answer(localStream)
            callList.push(call)

            call.on('stream', function (remoteStream) {

                console.log('connected from someone calling')
                var audio = document.getElementById(call.peer);
                if (audio == null) {
                    var video = document.createElement('video')
                    video.autoplay = 'autoplay';
                    video.height = "100%"
                    video.width = "100%"
                    video.srcObject = remoteStream
                    video.className = 'peer-songs'
                    video.control = 'control'
                    video.style.display = "none"
                    video.id = call.peer
                    document.getElementById('song').appendChild(video);
                }




            });
            call.on('close', function () {
                console.log('answering connection close')

            });
            call.on('error', function () {
                console.log('answering connection error')

            });
        });

    }
}
Hooks.Notification = {
    mounted() {
        const subscibeEvent = (sub) => {
            this.pushEvent("subscribe-notification", sub)
        }
        navigator.serviceWorker.register('/sw.js').then(function (reg) {
            reg.pushManager.getSubscription().then(function (sub) {
                if (sub == undefined) {
                    document.getElementById('sub-btn').style.display = "block";
                } else {
                    document.getElementById('sub-btn').style.display = "none";
                    subscibeEvent(sub)
                }
            })
        })
    }
}


Hooks.IsMuted = {
    updated() {
        let is_muted = document.getElementById("is_muted").getAttribute("is_muted")
        if (is_muted == "true") {
            localStream.getAudioTracks()[0].enabled = false
        } else {
            localStream.getAudioTracks()[0].enabled = true
        }
    }
}
Hooks.ChatList = {
    updated() {
        const ids = document.getElementsByClassName("peer-ids");
        var afterId = []
        for (var i = 0; i < ids.length; i++) {
            const id = ids[i].getAttribute("peer-id")
            afterId.push(id)
        }
        var removedIds = before_ids.filter(function (id) {
            return afterId.indexOf(id) == -1;
        });

        var addedIds = afterId.filter(function (id) {
            return before_ids.indexOf(id) == -1;
        });
        for (var i = 0; i < removedIds.length; i++) {
            const id = removedIds[i]
            const song = document.getElementById(id);
            if (song) {
                song.remove()
            }
            call = callList.find(call => call.peer == id)
            if (call) {
                call.close()
            }
            callList = callList.filter(call => call.peer != id)
        }
        if (afterId[afterId.length - 1] == myId) {
            for (var i = 0; i < addedIds.length; i++) {
                const id = addedIds[i]
                if (id != myId) {
                    var call = peer.call(id, localStream);
                    call.on('stream', function (remoteStream) {
                        console.log('connected to calling ' + id + ', ' + myId)

                        var audio = document.getElementById(id);
                        if (audio == null) {
                            let broadcastId = null
                            let selectedBroadcast = document.getElementById("selected-broadcast")
                            if (selectedBroadcast) {
                                broadcastId = selectedBroadcast.getAttribute("peer-id")
                            }
                            var video = document.createElement('video')
                            video.autoplay = 'autoplay';
                            video.srcObject = remoteStream
                            video.height = "100%"
                            video.width = "100%"
                            video.className = 'peer-songs'
                            video.id = id
                            if (broadcastId == id) {
                                video.style.display = "block"

                            } else {
                                video.style.display = "none"

                            }
                            video.control = 'control'

                            document.getElementById('song').appendChild(video);
                        }
                        console.log('play sound')

                    });
                    call.on('close', function () {
                        console.log('call connection close')


                    });
                    call.on('error', function () {
                        console.log('call connection error')
                    });

                    callList.push(call)
                }

            }
        }

    },
    beforeUpdate() {
        before_ids = []
        var ids = document.getElementsByClassName("peer-ids");
        for (var i = 0; i < ids.length; i++) {
            const id = ids[i].getAttribute("peer-id")
            before_ids.push(id)
        }
        console.log('before update')

    }
}

Hooks.BroadCastList = {
    mounted() {
        console.log('mounted')
    },
    updated() {
        let selectedBroadcast = document.getElementById("selected-broadcast")
        if (selectedBroadcast) {
            let id = selectedBroadcast.getAttribute("peer-id")
            let video = document.getElementById(id)
            if (video) {
                video.style.display = "block"
            }
            currentBroadcast = id
            if (myId == id) {
                if (videoStreamTrack) {
                    for (var i = 0; i < callList.length; i++) {
                        const call = callList[i]
                        call.peerConnection.getSenders()[1].replaceTrack(videoStreamTrack)
                    }
                }
            }
        } else {
            currentBroadcast = null
        }

    },
    beforeUpdate() {
        if (currentBroadcast) {
            let video = document.getElementById(currentBroadcast)
            if (video) {
                video.style.display = "none"
            }
        }
        if (myId == currentBroadcast) {
            console.log('disabled!')
            if (videoStreamTrack) {
                videoStreamTrack.enabled = false

            }
        }
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
    console.log(localStream.getVideoTracks())
    if (localStream && mute) {
        localStream.getAudioTracks()[0].enabled = false
        // videoStreamTrack.enabled = false

        muteBtn.innerHTML = "Unmute"
    } else {
        localStream.getAudioTracks()[0].enabled = true
        // videoStreamTrack.enabled = true
        muteBtn.innerHTML = "Mute"
    }
}


window.startScreenSharing = function () {
    try {
        gtag('event', 'live',
            {
                'share_screen': "true",

            });
    } catch (e) {
        console.log('e')
    }


    if (!videoStreamTrack) {
        navigator.mediaDevices.getDisplayMedia({ video: true, audio: false }).then(function (videoStream) {
            var screenVideoTrack = videoStream.getVideoTracks()[0];
            videoStreamTrack = screenVideoTrack
            const mediaStream = new MediaStream([localAudioTrack, videoStreamTrack]);
            localStream = mediaStream
            document.getElementById("share-screen-btn").click()
        }).catch(function (err) {
            console.log('Failed to get video stream', err);
        });
    } else {
        videoStreamTrack.enabled = true
        document.getElementById("share-screen-btn").click()
        //videoStreamTrack.enabled = true
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


