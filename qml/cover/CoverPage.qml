import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    Column {
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.paddingLarge

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: Qt.resolvedUrl('../../images/harbour-dreamcastnow-client.svg')
            width: Theme.iconSizeLarge
            height: width
            sourceSize {
                width: width
                height: height
            }
        }

        Item {
            width: parent.width
            height: appWindow.loading ? busyIndicator.height : label.height
            Behavior on height { NumberAnimation { duration: 200 } }
            
            BusyIndicator {
                id: busyIndicator
                size: BusyIndicatorSize.Medium
                anchors.horizontalCenter: parent.horizontalCenter
                running: appWindow.loading
            }

            Label {
                id: label
                width: parent.width
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter

                opacity: appWindow.loading ? 0 : 1
                Behavior on opacity { FadeAnimator {} }
                text: qsTr("%Ln online", '', appWindow.onlineCount)
            }
        }
    }

    CoverActionList {
        enabled: !appWindow.loading
        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: appWindow.update()
        }
    }
}
