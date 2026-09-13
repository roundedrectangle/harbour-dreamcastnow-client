import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import Nemo.Configuration 1.0

ApplicationWindow {
    id: appWindow
    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    property string error
    property bool loading: true
    property bool refreshing
    property int onlineCount

    WorkerScript {
        id: worker
        source: Qt.resolvedUrl("js/worker.js")

        onMessage:
            if (messageObject.type === 'onlineCount')
                onlineCount = messageObject.count
            else {
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
           pagePath: config.useDcNet ? config.dcNetPath : config.pagePath
       })
    }

    ListModel { id: usersModel }

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
        path: '/apps/harbour-dreamcastnow-client'

        property string host: 'https://dreamcast.online'
        property string pagePath: '/now/api/users.json'
        property string dcNetHost: 'https://dcnet.flyca.st'
        property string dcNetPath: '/status/api/players'
        property bool useDcNet
        property bool autoUpdate: true
        property real updateInterval: 30 // while real value can't be customized in the app, it can be by editing dconf value manually
        property bool backgroundAutoUpdate: true
        property real backgroundUpdateInterval: 1800 // 30 minutes
        property bool showBackground: true
        property int separators: 0 // 0 - no, 1 - separators, 2 - with padding
    }
}
