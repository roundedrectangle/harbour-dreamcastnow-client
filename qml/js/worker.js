Qt.include("emoji.js")

var model, host, pagePath

function parseUrl(url) {
    if (url.indexOf('//') === 0) return 'https:' + url
    if (url.indexOf('/') === 0) return host + url
    return url
}

WorkerScript.onMessage = function(message) {
    model = message.model
    host = message.host
    pagePath = message.pagePath

    var request = new XMLHttpRequest()

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
                    var users = data.users
                    users.sort(function (user) { return user.online ? -1 : 1 })
                    users.forEach(function (user) {
                        var recentGames = []
                        user.recent_games.forEach(function(game) {
                            recentGames.push({gameIcon: host + '/static/img/games/covers/US/' + game.id + '.jpg'})
                        })

                        model.append({
                            username: user.username,
                            avatar: parseUrl(user.avatar),
                            flagImagePath: getEmojiPath(user.flag),
                            status: user.online ? 'online' : '',
                            level: user.level,
                            playing: user.current_game_display,
                            lastSeen: user.last_seen,
                            lastSeenBold: false, // TODO
                            background: host + '/static/img/games/backgrounds/' + (user.current_game || 'UNKNOWN') + '.jpg',
                            recentlyPlayed: recentGames
                        })
                    })

                    WorkerScript.sendMessage({type: 'onlineCount', count: data.online_count})
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
