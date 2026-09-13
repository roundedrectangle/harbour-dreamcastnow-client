import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            bottomPadding: Theme.paddingLarge

            PageHeader {
                title: "Dreamfish Now"
            }

            Image {
                source: Qt.resolvedUrl('../../images/harbour-dreamcastnow-client.svg')
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.iconSizeExtraLarge * 2
                height: width
                sourceSize {
                    width: width
                    height: height
                }
            }

            Column {
                width: parent.width
                spacing: Theme.paddingMedium
                topPadding: Theme.paddingLarge

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    text: qsTr("This project is licensed under GNU GPL 3.0. Copyright (c) 2025 roundedrectangle")
                }

                ButtonLayout {
                    Button {
                        text: "GitHub"
                        onClicked: Qt.openUrlExternally('https://github.com/roundedrectangle/harbour-dreamcastnow-client')
                    }
                }

                SectionHeader { text: qsTr("Translations") }

                DetailItem {
                    label: qsTr("Italian")
                    value: "legacychimera247"
                }
            }
        }
    }
}
