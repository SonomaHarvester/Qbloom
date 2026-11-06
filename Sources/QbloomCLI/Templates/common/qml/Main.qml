import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 420
    height: 300
    minimumWidth: 280
    minimumHeight: 220
    visible: true
    title: {{QML_NAME}}

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16
        Label {
            objectName: "greetingLabel"
            text: backend.greeting
            font.pixelSize: 26
            Layout.alignment: Qt.AlignHCenter
        }
        Label {
            objectName: "counterLabel"
            text: backend.count.toString()
            font.pixelSize: 24
            Layout.alignment: Qt.AlignHCenter
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Button {
                objectName: "incrementButton"
                text: "Increment"
                Accessible.name: "Increment counter"
                onClicked: backend.increment()
            }
            Button {
                objectName: "resetButton"
                text: "Reset"
                Accessible.name: "Reset counter"
                onClicked: backend.reset()
            }
        }
    }
}
