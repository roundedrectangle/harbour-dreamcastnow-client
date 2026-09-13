Qt.include("emoji.js")

function s(str) {
    // Remove non-breakable spaces
    return str.replace('\u00a0', ' ')
}

WorkerScript.onMessage = function(message) {
    var model = message.model
    var isDcNet = message.isDcNet
    var host = message.host
    var pagePath = message.pagePath
    var notifications = message.notifications

    var previousPlayerNames = []
    if (notifications.length > 0)
        for (var i=0; i < model.count; i++)
            previousPlayerNames.push(model.get(i).name)

    var request = new XMLHttpRequest()

    // only for dcnow
    function parseUrl(url) {
        if (url.indexOf('//') === 0) return 'https:' + url
        if (url.indexOf('/') === 0) return host + url
        return url
    }
    function parseDuration(str) {
        var res = 0
        s(str).split(', ').forEach(function (part) {
            var subparts = part.split(' ')
            var k = 0
            switch (subparts[1].replace(/s$/, '')) {
            case 'day':
                k = 3600*24
                break
            case 'hour':
                k = 3600
                break
            case 'minute':
                k = 60
                break
            }
            res += subparts[0] * k
        })
        return res
    }

    function processPlayer(player) {
        model.append(player)

        if (notifications.indexOf(player.name) !== -1 && previousPlayerNames.indexOf(player.name) == -1)
            WorkerScript.sendMessage({'type': 'notification', player: player})
    }

    request.onreadystatechange = function() {
        if (request.readyState === XMLHttpRequest.DONE) {
            if (request.status >= 200 && request.status <= 300) {
                model.clear()

                console.log(request.status, request.responseText)
                try {
                    var data = JSON.parse(request.responseText)
                } catch (e) {
                    console.error("JSON parse error", e)
                    WorkerScript.sendMessage('jsonParseError')
                    return
                }

                try {
                    if (isDcNet) {
                        data.forEach(function (user) {
                            processPlayer({
                                name: user.name,
                                username: user.loginName || '',
                                avatar: user.thumbnail,
                                flagImagePath: user.geoloc && user.geoloc.country ? getFlagEmojiPath(user.geoloc.country) : '',
                                status: 'online',
                                level: '',
                                playing: user.gameName,
                                lastSeen: user.date || 0,
                                lastSeenStartedPlaying: true,
                                background: '',
                                recentlyPlayed: []
                            })
                        })

                        WorkerScript.sendMessage({'type': 'onlineCount', count: data.length})
                    } else {
                        var users = data.users
                        users.sort(function (user) { return user.online ? -1 : 1 })
                        users.forEach(function (user) {
                            var recentGames = []
                            user.recent_games.forEach(function(game) {
                                recentGames.push({gameIcon: host + '/static/img/games/covers/US/' + game.id + '.jpg'})
                            })

                            processPlayer({
                                name: s(user.username),
                                username: '',
                                avatar: parseUrl(user.avatar),
                                flagImagePath: getEmojiPath(user.flag),
                                status: user.online ? 'online' : '',
                                level: s(user.level),
                                playing: s(user.current_game_display),
                                lastSeen: (Date.now() - parseDuration(user.last_seen) * 1000), //"20\u00a0minutes"
                                lastSeenStartedPlaying: false,
                                background: host + '/static/img/games/backgrounds/' + (user.current_game || 'UNKNOWN') + '.jpg',
                                recentlyPlayed: recentGames
                            })
                        })

                        WorkerScript.sendMessage({type: 'onlineCount', count: data.online_count})
                    }
                } catch (e1) {
                    console.error("Error", e1)
                    WorkerScript.sendMessage('error')
                    return
                }

                model.sync()
                WorkerScript.sendMessage('loaded')
            } else {
                console.log("Invalid HTTP response", request.status)
                WorkerScript.sendMessage('httpError')
            }
        }
    }

    request.open('GET', host + pagePath)
    request.send()
}
