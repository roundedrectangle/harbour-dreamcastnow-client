import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import Nemo.Configuration 1.0
import Nemo.Notifications 1.0

ApplicationWindow {
    id: appWindow
    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    property string error
    property bool loading: true
    property bool everLoaded
    property bool refreshing
    property int onlineCount

    onLoadingChanged: if (!loading) everLoaded = true

    Notification {
        id: notification
        appIcon: Qt.resolvedUrl("../images/harbour-dreamcastnow-client.svg")
        appName: "Dreamfish Now (%1)".arg(config.useDcNet ? "DCNet" : "Dreamcast Now")
        isTransient: config.transientNotifications
        onReplacesIdChanged: replacesId = 0
    }

    WorkerScript {
        id: worker
        source: Qt.resolvedUrl("js/worker.js")

        onMessage:
            if (messageObject.type === 'onlineCount')
                onlineCount = messageObject.count
            else if (messageObject.type === 'notification') {
                var player = messageObject.player
                if (player.playing)
                    notification.body = qsTr("%1 is now playing %2", "notification").arg(player.name).arg(player.playing)
                else
                    notification.body = qsTr("%1 is now online", "notification").arg(player.name)
                notification.icon = player.avatar // TODO: HTTP(s) URL doesn't work as an icon here
                notification.publish()
            } else {
                if (messageObject !== 'loaded') {
                    usersModel.clear()
                    error = messageObject
                }
                loading = refreshing = false
            }
    }

    function update() {
        worker.sendMessage({
           model: usersModel,
           isDcNet: config.useDcNet,
           host: config.useDcNet ? config.dcNetHost : config.host,
           pagePath: config.useDcNet ? config.dcNetPath : config.pagePath,
           notifications: (config.showSubscriptionNotificationsOnStart || everLoaded)
                          ? JSON.parse(config.useDcNet ? config.dcNetNotifications : config.notifications)
                          : []
       })
    }

    function reloadUpdate() {
        everLoaded = false
        loading = true
        update()
    }

    ListModel { id: usersModel }

    Connections {
        target: config
        onHostChanged: reloadUpdate()
        onPagePathChanged: reloadUpdate()
    }

    Component.onCompleted: update()

    ConfigurationGroup {
        id: config
        path: '/apps/harbour-dreamcastnow-client'

        // UI
        property bool showBackground: true
        property int separators: 0 // 0 - no, 1 - separators, 2 - with padding

        property bool useDcNet
        property bool showSubscriptionNotificationsOnStart: true
        property bool transientNotifications: true

        property string host: 'https://dreamcast.online'
        property string pagePath: '/now/api/users.json'
        property string notifications: '[]'

        property string dcNetHost: 'https://dcnet.flyca.st'
        property string dcNetPath: '/status/api/players'
        property string dcNetNotifications: '[]'

        // auto updating
        property bool autoUpdate: true
        property real updateInterval: 30 // while real value can't be customized in the app, it can be by editing dconf value manually
        property bool backgroundAutoUpdate: true
        property real backgroundUpdateInterval: 1800 // 30 minutes
    }
}
