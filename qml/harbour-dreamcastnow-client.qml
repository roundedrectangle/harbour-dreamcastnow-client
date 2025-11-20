import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import Nemo.Configuration 1.0
import "js/dom-parser.js" as DomParser

ApplicationWindow {
    id: appWindow
    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    property bool loading: true
    property int onlineCount

    property string defaultBackground: config.host + '/static/img/games/backgrounds/UNKNOWN.jpg'

    function getNodeBackgroundFromStyle(node) {
        var style = node.getAttribute('style')
        if (!style) return ''
        return parseUrl(new RegExp(/(\/[a-zA-Z0-9]+)+\.[a-z]+/g).exec(style)[0])
    }

    function parseUrl(url) {
        if (url.indexOf('//') === 0) return 'https:' + url
        if (url.indexOf('/') === 0) return config.host + url
        return url
    }

    function s(a) {
        return a.trim()
            .replace(/&nbsp;/g, ' ') // non-break space, currently just replace with normal space
            .replace(/&amp;/g, '&')
            .replace(/&lt;/g, '<')
            .replace(/&quot;/g, '"')
            .replace(/&#039;/g, "'")
            .replace(/&#x27;/g, "'")
    }

    function appendPlayer(node, status) {
        var player = {
            avatar: parseUrl(node.getElementsByClassName('player_info__icon')[0].getAttribute('src')),
            username: s(node.getElementsByClassName('player_info__username')[0].textContent()),
            playing: s(node.getElementsByClassName('player_info__playing')[0].textContent()),
            level: s(node.getElementsByClassName('player_info__level')[0].textContent()),

            status: status || ''
        }

        var lastSeenNode = node.getElementsByClassName('player_info__last_seen')[0]
        player.lastSeen = lastSeenNode.textContent().trim()
        player.lastSeenBold = lastSeenNode.getElementsByTagName('strong').length > 0

        player.recentlyPlayed = [];
        node.getElementsByClassName('recently_played__game').forEach(function(gameNode) {
            var imgNode = gameNode.getElementsByTagName('img')[0]
            if (imgNode)
                player.recentlyPlayed.push({gameIcon: parseUrl(imgNode.getAttribute('src'))})
        })

        var backgroundNode = node.getElementsByClassName('player_background')[0]
        player.background = (backgroundNode ? getNodeBackgroundFromStyle(backgroundNode) : '') || defaultBackground

        usersModel.append(player)
    }

    function update() {
        var request = new XMLHttpRequest();

        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status >= 200 && request.status <= 300) {
                    var dom = new DomParser.Dom(request.response)

                    var h2Tags = dom.getElementsByTagName('h2')

                    onlineCount = h2Tags[0].textContent().replace(/\D+/g, '')

                    usersModel.clear()

                    h2Tags[0].parentNode.getElementsByClassName('player_card').forEach(function(node) {
                        appendPlayer(node, 'online')
                    })
                    h2Tags[1].parentNode.getElementsByClassName('player_card').forEach(function(node) {
                        appendPlayer(node)
                    })

                    appWindow.loading = false
                }
            }
        }

        request.open('GET', config.host + config.pagePath)
        request.send()
    }

    ListModel {
        id: usersModel
    }

    Connections {
        target: config
        onHostChanged: {
            loading = true
            update()
        }
        onPagePathChanged: {
            loading = true
            update()
        }
    }

    Component.onCompleted: update()

    ConfigurationGroup {
        id: config
        path: '/apps/harbour-dreamcastnow-client/'

        property string host: 'https://dreamcast.online'
        property string pagePath: '/now/'
        property bool autoUpdate: true
        property real updateInterval: 30 // while real value can't be customized in the app, it can be by editing dconf value manually
        property bool backgroundAutoUpdate: true
        property real backgroundUpdateInterval: 1800 // 30 minutes
        property bool showBackground: true
        property int separators: 0 // 0 - no, 1 - separators, 2 - with padding
    }
}
