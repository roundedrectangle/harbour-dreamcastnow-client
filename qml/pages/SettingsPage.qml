import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            bottomPadding: Theme.paddingLarge

            PageHeader {
                title: qsTr("Settings")
            }

            TextSwitch {
                text: qsTr("Show background")
                checked: config.showBackground
                automaticCheck: false
                onClicked: config.showBackground = !checked
            }

            ComboBox {
                label: qsTr("Separators")
                menu: ContextMenu {
                    MenuItem { text: qsTr("Disabled") }
                    MenuItem { text: qsTr("Enabled") }
                    MenuItem { text: qsTr("Enabled with more spacing") }
                }
                currentIndex: config.separators
                onCurrentIndexChanged: config.separators = currentIndex
            }

            TextSwitch {
                visible: config.notifications !== '[]' || config.dcNetNotifications !== '[]'
                text: qsTr("Show subscription notifications in Events")
                description: qsTr("If disabled, subscription notifications will only be briefly shown and you won't see them in the Events view.")
                checked: !config.transientNotifications
                automaticCheck: false
                onClicked: config.transientNotifications = checked
            }

            Repeater {
                model: [
                    {
                        section: "Dreamcast Now",
                        hostKey: 'host',
                        defaultHost: 'https://dreamcast.online',
                        pathKey: 'pagePath',
                        defaultPath: '/now/api/users.json',
                        notificationsKey: 'notifications'
                    },
                    {
                        section: "DCNet",
                        hostKey: 'dcNetHost',
                        defaultHost: 'https://dcnet.flyca.st',
                        pathKey: 'dcNetPath',
                        defaultPath: '/status/api/players',
                        notificationsKey: 'dcNetNotifications'
                    }
                ]

                Column {
                    width: parent.width

                    SectionHeader { text: modelData.section }

                    TextField {
                        id: hostField
                        label: qsTr("Base URL, without a slash in the end")
                        text: config[modelData.hostKey]
                        onFocusChanged: if (!focus) config[modelData.hostKey] = text

                        rightItem: IconButton {
                            onClicked: hostField.text = modelData.defaultHost

                            width: icon.width
                            height: icon.height
                            icon.source: "image://theme/icon-splus-remove"
                            opacity: hostField.text === modelData.defaultHost ? 0 : 1
                            Behavior on opacity { FadeAnimator {} }
                        }
                    }

                    TextField {
                        id: pathField
                        label: qsTr("Page path")
                        text: config[modelData.pathKey]
                        onFocusChanged: if (!focus) config[modelData.pathKey] = text

                        rightItem: IconButton {
                            onClicked: pathField.text = modelData.defaultPath

                            width: icon.width
                            height: icon.height
                            icon.source: "image://theme/icon-splus-remove"
                            opacity: pathField.text === modelData.defaultPath ? 0 : 1
                            Behavior on opacity { FadeAnimator {} }
                        }
                    }

                    Item { width:1; height: Theme.paddingMedium }

                    Button {
                        id: resetNotificationsButton
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: config[modelData.notificationsKey] !== '[]'
                        text: qsTr("Reset subscriptions")
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        topPadding: Theme.paddingMedium
                        visible: resetNotificationsButton.visible
                        text: qsTr("Once a player you are subcribed to goes online, you will receive a notification. You are currently subscribed to the following players: %1.")
                                .arg(JSON.parse(config[modelData.notificationsKey]).join(', '))
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.Wrap
                    }
                }
            }

            Repeater {
                model: [
                    {
                        text: qsTr("Auto-update"),
                        intervalText: qsTr("Auto-update interval, in seconds: %1"),
                        invalidIntervalText: qsTr("Auto-update interval, in seconds"),
                        key: 'autoUpdate',
                        intervalKey: 'updateInterval',
                        defaultInterval: '30'
                    },
                    {
                        text: qsTr("Auto-update in background"),
                        intervalText: qsTr("Background auto-update interval, in seconds: %1"),
                        invalidIntervalText: qsTr("Background auto-update interval, in seconds"),
                        key: 'backgroundAutoUpdate',
                        intervalKey: 'backgroundUpdateInterval',
                        defaultInterval: '1800'
                    }
                ]

                Column {
                    width: parent.width

                    TextSwitch {
                        text: modelData.text
                        checked: config[modelData.key]
                        onCheckedChanged: config[modelData.key] = checked
                    }

                    TextField {
                        id: updateIntervalField
                        height: config[modelData.key] ? implicitHeight : 0
                        Behavior on height { NumberAnimation { duration: 200 } }
                        opacity: config[modelData.key] ? 1 : 0
                        Behavior on opacity { FadeAnimator {} }

                        label: validator.regExp.test(text)
                            ? modelData.intervalText.arg(Format.formatDuration(Number(text)))
                            : modelData.invalidIntervalText
                        inputMethodHints: Qt.ImhDigitsOnly // ImhDigitsOnly and ImhFormattedNumbersOnly seem to have no difference
                        validator: RegExpValidator { regExp: /^[1-9]\d*$/ }
                        text: config[modelData.intervalKey]
                        onFocusChanged: if (!focus && validator.regExp.test(text)) config[modelData.intervalKey] = Number(text)

                        rightItem: IconButton {
                            onClicked: updateIntervalField.text = modelData.defaultInterval

                            width: icon.width
                            height: icon.height
                            icon.source: "image://theme/icon-splus-remove"
                            opacity: updateIntervalField.text == modelData.defaultInterval ? 0 : 1
                            Behavior on opacity { FadeAnimator {} }
                        }
                    }
                }
            }
        }
    }
}
