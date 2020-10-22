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
var localVideoCameraTrack = null
var mute = false
let Hooks = {}
var callList = []
var before_ids = []
var currentBroadcast = null
var localAudioTrack = null
var myId
var showNotification = false
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
        const connectedEvent = (id) => {
            this.pushEvent("connected", { "peer-id": id })
        }
        if (!peer) {
            peer = new Peer({ host: "inoffice-peerjs.herokuapp.com", secure: true });
            peer.on('open', function (id) {
                console.log('peer open')
                console.log(id)
                navigator.mediaDevices.getUserMedia({ video: false, audio: true }).then(function (stream) {
                    let audioTrack = stream.getAudioTracks()[0]
                    localAudioTrack = audioTrack
                    let videoTrack = createEmptyVideoTrack({ width: 500, height: 500 })

                    let videoCameraTrack = null
                    if (localVideoCameraTrack) {
                        videoCameraTrack = localVideoCameraTrack
                    } else {
                        videoCameraTrack = createEmptyVideoTrack({ width: 500, height: 500 })
                    }

                    const mediaStream = new MediaStream([audioTrack, videoTrack, videoCameraTrack]);

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
                        let audioTrack = remoteStream.getAudioTracks()[0]
                        let videoTrack = remoteStream.getVideoTracks()[0]
                        let videoCameraTrack = remoteStream.getVideoTracks()[1]
                        const audioStream = new MediaStream([audioTrack]);
                        const videoStream = new MediaStream([videoTrack]);
                        const videoCameraStream = new MediaStream([videoCameraTrack]);

                        var video = document.createElement('video')
                        video.autoplay = 'autoplay';
                        video.height = "100%"
                        video.width = "100%"
                        video.srcObject = videoStream
                        video.className = 'peer-songs'
                        video.control = 'control'
                        video.style.display = "none"
                        video.setAttribute('playsinline', 'playsinline');
                        video.id = call.peer

                        var videoCamera = document.getElementById(`${call.peer}-camera`)
                        videoCamera.srcObject = videoCameraStream

                        var audio = document.createElement('audio')
                        audio.autoplay = 'autoplay';
                        audio.height = "100%"
                        audio.width = "100%"
                        audio.srcObject = audioStream
                        audio.className = 'peer-songs audio-peer'
                        audio.control = 'control'
                        audio.style.display = "none"
                        audio.id = `${call.peer}-audio`
                        document.getElementById('song').appendChild(video);
                        document.getElementById('song').appendChild(audio);
                        document.getElementById('song').appendChild(videoCamera);

                        var audio = document.getElementById(`${call.peer}-audio`);
                        var promise = audio.play();

                        if (promise !== undefined) {
                            promise.then(_ => {

                                // Autoplay started!
                            }).catch(error => {
                                // Show something in the UI that the video is muted
                                alert('Audio autoplay disabled')
                            });
                        }
                        connectedEvent(call.peer)
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
}
Hooks.Notification = {
    mounted() {
        const subscibeEvent = (sub) => {
            this.pushEvent("subscribe-notification", sub)
        }
        const showButton = () => {
            this.pushEvent("show_sub_btn")
        }
        const hideButton = () => {
            this.pushEvent("hide_sub_btn")
        }
        if (navigator.serviceWorker) {
            navigator.serviceWorker.register('/sw.js').then(function (reg) {

                reg.pushManager.getSubscription().then(function (sub) {
                    if (sub == undefined) {
                        showButton()
                    } else {
                        hideButton()
                        subscibeEvent(sub)
                    }
                })
            })
        }

    }
}


Hooks.IsMuted = {
    updated() {
        let is_muted = document.getElementById("is_muted").getAttribute("is_muted")
        if (is_muted == "true") {
            console.log('muting the mic')
            localStream.getAudioTracks()[0].enabled = false
        } else {
            localStream.getAudioTracks()[0].enabled = true
        }
    }
}
Hooks.ChatList = {

    updated() {
        const toggleMute = (id) => {
            this.pushEvent("toggle-mute", {})
        }
        const connectedEvent = (id) => {
            this.pushEvent("connected", { "peer-id": id })
        }
        const disconnectedEvent = (id) => {
            this.pushEvent("disconnected", { "peer-id": id })
        }

        const ids = document.getElementsByClassName("peer-ids");
        var afterId = []
        for (var i = 0; i < ids.length; i++) {
            const id = ids[i].getAttribute("peer-id")
            afterId.push(id)
        }
        var removedIds = before_ids.filter(function (id) {
            return afterId.indexOf(id) == -1;
        });
        console.log(before_ids)
        console.log('remove id')
        console.log(removedIds.length)


        var addedIds = afterId.filter(function (id) {
            return before_ids.indexOf(id) == -1;
        });

        var playLeaveSound = false

        for (var i = 0; i < removedIds.length; i++) {
            const id = removedIds[i]
            const video = document.getElementById(id);
            const song = document.getElementById(`${id}-audio`);
            if (video) {
                video.remove()
            }
            if (song) {
                song.remove()
                playLeaveSound = true;
            }
            call = callList.find(call => call.peer == id)
            if (call) {
                call.close()
            }
            disconnectedEvent(id)
            callList = callList.filter(call => call.peer != id)
        }


        if (before_ids.length > 1 && ids.length === 1) {
            let is_muted = document.getElementById("is_muted").getAttribute("is_muted")
            if (is_muted == "false") {
                toggleMute()
            }
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

                            let audioTrack = remoteStream.getAudioTracks()[0]
                            let videoTrack = remoteStream.getVideoTracks()[0]
                            let videoCameraTrack = remoteStream.getVideoTracks()[1]
                            const audioStream = new MediaStream([audioTrack]);
                            const videoStream = new MediaStream([videoTrack]);
                            const videoCameraStream = new MediaStream([videoCameraTrack]);

                            var video = document.createElement('video')
                            video.autoplay = 'autoplay';
                            video.height = "100%"
                            video.width = "100%"
                            video.srcObject = videoStream
                            video.className = 'peer-songs'
                            video.setAttribute('playsinline', 'playsinline');
                            video.control = 'control'

                            if (broadcastId == id) {
                                video.style.display = "block"

                            } else {
                                video.style.display = "none"

                            }

                            var videoCamera = document.getElementById(`${call.peer}-camera`)
                            videoCamera.srcObject = videoCameraStream


                            video.id = id
                            var audio = document.createElement('audio')
                            audio.autoplay = 'autoplay';
                            audio.height = "100%"
                            audio.width = "100%"
                            audio.srcObject = audioStream
                            audio.className = 'peer-songs audio-peer'
                            audio.control = 'control'
                            audio.style.display = "none"
                            audio.id = `${call.peer}-audio`
                            document.getElementById('song').appendChild(video);
                            document.getElementById('song').appendChild(audio);
                            console.log('play sound')
                            connectedEvent(id)
                        }



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
        const stopSharing = (sub) => {
            this.pushEvent("stop-sharing-screen", sub)
        }

        let selectedBroadcast = document.getElementById("selected-broadcast")
        if (selectedBroadcast) {
            let id = selectedBroadcast.getAttribute("peer-id")
            let video = document.getElementById(id)
            if (video) {
                video.style.display = "block"
                var promise = video.play();

                if (promise !== undefined) {
                    promise.then(_ => {
                        document.getElementById("play-in-line").style.display = "none"
                        // Autoplay started!
                    }).catch(error => {
                        document.getElementById("play-in-line").style.display = "flex"
                        // Show something in the UI that the video is muted
                        alert('Video autoplay disabled')
                    });
                }


            }
            currentBroadcast = id
            if (myId == id) {
                if (videoStreamTrack) {
                    for (var i = 0; i < callList.length; i++) {
                        const call = callList[i]
                        call.peerConnection.getSenders()[1].replaceTrack(videoStreamTrack)
                    }

                    videoStreamTrack.onended = function () {
                        videoStreamTrack = null
                        var vid = document.getElementById("self-video")
                        if (vid) {
                            vid.remove()
                        }
                        stopSharing()

                    };

                }
            } else {
                var vid = document.getElementById("self-video")
                vid.style.display = "none"
            }
        } else {
            currentBroadcast = null
            var vid = document.getElementById("self-video")
            if (vid) {
                vid.style.display = "none"
            }
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
Hooks.IsSharingCamera = {
    updated() {
        console.log('after share camera')

        var isShareCamera = document.getElementById("is-share-camera").getAttribute("is-share-camera")
        if (isShareCamera == 'true') {
            if (localVideoCameraTrack) {
                localVideoCameraTrack.enabled = true
                for (var i = 0; i < callList.length; i++) {
                    const call = callList[i]
                    call.peerConnection.getSenders()[2].replaceTrack(localVideoCameraTrack)
                }

            }
        } else {
            localVideoCameraTrack.enabled = false
        }
    },
}
var nudgeLength = 0;
Hooks.NudgeList = {
    updated() {
        var nudges = document.getElementsByClassName("nudge")
        if (nudges && nudges.length > nudgeLength) {
            let audio = document.getElementById("nudge-sound")
            audio.play()
            nudgeLength = nudges.length
        }

    }
}
var joinsLength = 0;
Hooks.JoinNotificationList = {
    updated() {
        var joins = document.getElementsByClassName("join-item")
        console.log(joins)
        if (joins && joins.length > joinsLength) {
            let audio = document.getElementById("notification-sound")
            audio.volume = 0.4;
            audio.play()
            joinsLength = joins.length
        }

    }
}
var leaveLength = 0;
Hooks.LeaveNotificationList = {
    updated() {
        var leaves = document.getElementsByClassName("leave-item")
        if (leaves && leaves.length > leaveLength) {
            let audio = document.getElementById("leave-notification-sound")
            audio.play()
            leaveLength = leaves.length
        }

    }
}


window.toggleMute = function () {
    mute = !mute
    var muteBtn = document.getElementById("mute-btn")
    if (localStream && mute) {
        localAudioTrack.enabled = false
        // videoStreamTrack.enabled = false

        //muteBtn.innerHTML = "Unmute"
    } else {
        localAudioTrack.enabled = true
        // videoStreamTrack.enabled = true
        // muteBtn.innerHTML = "Mute"
    }
}

window.toggleCamera = function () {
    try {
        gtag('event', 'share_camera',
            {
                'share_camera': "true",

            });
    } catch (e) {
        console.log('e')
    }

    if (localVideoCameraTrack) {
        localVideoCameraTrack.enabled = true;
        document.getElementById('share-camera').click();
    } else {
        navigator.mediaDevices.getUserMedia({ video: true, audio: false }).then(function (stream) {
            let videoCameraTrack = stream.getVideoTracks()[0]
            localVideoCameraTrack = videoCameraTrack
            let videoCameraStream = new MediaStream([videoCameraTrack]);
            //video stream track can be null. Please handle this and also update the screen sharing to include local video
            let localVideoStreamTrack = null;

            if (videoStreamTrack) {
                localVideoStreamTrack = videoStreamTrack
            } else {
                localVideoStreamTrack = createEmptyVideoTrack({ width: 500, height: 500 })
            }

            const mediaStream = new MediaStream([localAudioTrack, localVideoStreamTrack, localVideoCameraTrack]);
            localStream = mediaStream
            document.getElementById(`${myId}-camera`).srcObject = videoCameraStream
            document.getElementById('share-camera').click();
        }).catch(function (err) {
            console.log('Failed to get local stream', err);
        });
    }


}


window.playVideo = function () {
    let selectedBroadcast = document.getElementById("selected-broadcast")
    if (selectedBroadcast) {
        let broadcastId = selectedBroadcast.getAttribute("peer-id")
        let video = document.getElementById(broadcastId)
        if (video) {
            video.play()
            document.getElementById("play-in-line").style.display = "none"

        } else {

            alert('gone')
        }
    }
}

window.startScreenSharing = function () {
    try {
        gtag('event', 'share_screen',
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
            var videoCameraTrack = null
            if (localVideoCameraTrack) {
                videoCameraTrack = localVideoCameraTrack
            } else {
                videoCameraTrack = createEmptyVideoTrack({ width: 500, height: 500 })
            }
            const mediaStream = new MediaStream([localAudioTrack, videoStreamTrack, videoCameraTrack]);
            localStream = mediaStream
            document.getElementById("share-screen-btn").click()



            var vid = document.getElementById("self-video")
            if (!vid) {
                var video = document.createElement('video')
                video.autoplay = 'autoplay';
                video.height = "100%"
                video.width = "100%"
                video.srcObject = mediaStream
                video.className = 'peer-songs'
                video.muted = "muted"
                video.control = 'control'
                video.style.display = "block"
                video.id = "self-video"
                video.setAttribute('playsinline', 'playsinline');
                document.getElementById('song').appendChild(video);
            }


        }).catch(function (err) {
            console.log('Failed to get video stream', err);
        });
    } else {
        videoStreamTrack.enabled = true
        document.getElementById("share-screen-btn").click()
        var vid = document.getElementById("self-video")
        vid.style.display = "block"
        vid.play()
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


