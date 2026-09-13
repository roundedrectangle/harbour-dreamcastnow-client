import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    Timer {
        // Keep this here to only update when this page is active
        running: (Qt.application.state === Qt.ApplicationActive) ? config.backgroundAutoUpdate : (config.autoUpdate && page.status == PageStatus.Active)
        repeat: true
        interval: ((Qt.application.state === Qt.ApplicationActive) ? config.updateInterval : config.backgroundUpdateInterval) * 1000
        onTriggered: if (!loading && !refreshing) update()
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        model: usersModel

        PullDownMenu {
            busy: appWindow.refreshing && !appWindow.loading

            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push("AboutPage.qml")
            }
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push("SettingsPage.qml")
            }
            MenuItem {
                text: config.useDcNet ? qsTr("Use Dreamcast Now") : qsTr("Use DCNet")
                onClicked: {
                    config.useDcNet = !config.useDcNet
                    appWindow.loading = true
                    appWindow.update()
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                enabled: !appWindow.loading && !appWindow.refreshing
                onClicked: {
                    if (appWindow.error) {
                        appWindow.error = ''
                        appWindow.loading = true
                    }

                    appWindow.refreshing = true
                    appWindow.update()
                }
            }
        }

        header: PageHeader {
            title: "Dreamfish Now"
            description: config.useDcNet ? "DCNet" : "Dreamcast Now"
        }

        section.property: 'status'
        section.delegate: SectionHeader {
            text: loading ? '' : (section ? qsTr("%Ln online", '', onlineCount) : qsTr("Offline"))
        }

        delegate: Item {
            width: parent.width
            height: listItem.height + (separator.visible ? (separator.height + separator.anchors.topMargin*2) : 0)

            ListItem {
                id: listItem
                contentHeight: contentColumn.height
                hidden: loading

                Loader {
                    active: config.showBackground && !!background
                    anchors.fill: parent
                    sourceComponent: Component {
                        Image {
                            anchors.fill: parent
                            source: background
                            fillMode: Image.PreserveAspectCrop

                            Rectangle {
                                anchors.fill: parent
                                color: Theme.overlayBackgroundColor
                                opacity: Theme.opacityOverlay
                                visible: parent.status == Image.Ready
                            }
                        }
                    }
                }

                Column {
                    id: contentColumn
                    x: Theme.horizontalPageMargin
                    topPadding: Theme.paddingMedium
                    bottomPadding: Theme.paddingMedium
                    width: parent.width - 2*x
                    spacing: Theme.paddingMedium

                    Row {
                        width: parent.width
                        spacing: Theme.paddingLarge

                        Column {
                            id: textColumn
                            width: parent.width - (avatarImage.visible ? (avatarImage.width + parent.spacing) : 0)
                            spacing: Theme.paddingSmall

                            Row {
                                width: parent.width
                                spacing: Theme.paddingSmall

                                Label {
                                    width: Math.min(implicitWidth, parent.width - (flagImage.visible ? (parent.spacing + flagImage.width) : 0))
                                    text: name
                                    font.pixelSize: Theme.fontSizeMedium
                                    truncationMode: TruncationMode.Fade
                                }

                                Image {
                                    id: flagImage
                                    width: Theme.fontSizeMedium * 1.15
                                    height: width
                                    sourceSize {
                                        width: width
                                        height: height
                                    }
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: flagImagePath ? (Qt.resolvedUrl("../js/emoji/") + flagImagePath) : ''
                                    visible: status != Image.Error && status != Image.Null
                                }
                            }

                            Label {
                                width: parent.width
                                visible: !!username
                                text: '@' + username
                                font.pixelSize: Theme.fontSizeExtraSmallBase
                                color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                                truncationMode: TruncationMode.Fade
                            }

                            Label {
                                width: parent.width
                                text: level
                                color: highlighted ? Theme.primaryColor : Theme.highlightColor
                                font.pixelSize: Theme.fontSizeSmall
                                truncationMode: TruncationMode.Fade
                                visible: !!text
                            }

                            Label {
                                width: parent.width
                                text: qsTr("Playing %1").arg(playing)
                                color: level
                                       ? (highlighted ? Theme.secondaryColor : Theme.secondaryHighlightColor)
                                       : (highlighted ? Theme.primaryColor : Theme.highlightColor)
                                font.pixelSize: Theme.fontSizeSmall
                                truncationMode: TruncationMode.Fade
                                visible: !!playing
                            }

                            Label {
                                visible: !!lastSeen
                                width: parent.width
                                wrapMode: Text.Wrap
                                font.pixelSize: Theme.fontSizeSmall
                                text: {
                                    var date = Format.formatDate(new Date(lastSeen), Formatter.TimeElapsed)
                                    date = date[0].toLowerCase() + date.slice(1)
                                    return (lastSeenStartedPlaying ? qsTr("Started playing %1", "time") : qsTr("Last seen %1", "time")).arg(date)
                                }
                                color: highlighted ? Theme.secondaryColor : Theme.secondaryHighlightColor
                            }
                        }

                        Image {
                            id: avatarImage
                            visible: status != Image.Error && status != Image.Null
                            width: Theme.iconSizeExtraLarge
                            height: width
                            source: avatar
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.paddingSmall
                        visible: recentlyPlayed.count > 0

                        Label {
                            anchors.topMargin: visible ? Theme.paddingLarge : 0
                            font.pixelSize: Theme.fontSizeMedium
                            text: qsTr("Played recently:")
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.paddingMedium
                            Repeater {
                                model: recentlyPlayed
                                Image {
                                    width: Theme.iconSizeLarge
                                    height: width
                                    source: gameIcon
                                }
                            }
                        }
                    }
                }

                menu: Component {
                    ContextMenu {
                        MenuItem {
                            property string notificationsKey: config.useDcNet ? 'dcNetNotifications' : 'notifications'
                            property bool notificationsEnabled: JSON.parse(config[notificationsKey]).indexOf(name) > -1
                            text: notificationsEnabled ? qsTr("Unsubscribe") : qsTr("Subscribe")
                            onClicked: {
                                var notifications = JSON.parse(config[notificationsKey])
                                if (notificationsEnabled) {
                                    var i = notifications.indexOf(name)
                                    if (i === -1) return
                                    notifications.splice(i, 1)
                                } else
                                    notifications.push(name)

                                config[notificationsKey] = JSON.stringify(notifications)
                            }
                        }
                    }
                }
            }

            Separator {
                id: separator
                anchors.top: listItem.bottom
                anchors.topMargin: config.separators > 1 ? Theme.paddingSmall : height
                width: parent.width
                horizontalAlignment: Qt.AlignCenter
                color: Theme.primaryColor
                visible: config.separators > 0 && listItem.height > 0
            }
        }

        ViewPlaceholder {
            enabled: !loading && listView.count === 0
            text: {
                if (!error) return qsTr("No players")
                switch (error) {
                case 'httpError':
                    return qsTr("Unexpected HTTP status code")
                case 'jsonParseError':
                    return qsTr("Couldn't parse the response as JSON")
                default:
                    return qsTr("Unknown error")
                }
            }

            hintText: qsTr("Try again by pulling down to refresh")
        }

        VerticalScrollDecorator {}
    }

    BusyLabel {
        running: loading
    }
}
