import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qbloom.Rust

ApplicationWindow {
    id: window
    width: 420
    height: 300
    minimumWidth: 280
    minimumHeight: 220
    visible: true
    title: {{QML_NAME}}
    property int observedCountChanges: 0

    Backend { id: backend }
    Connections {
        target: backend
        function onCountChanged() { window.observedCountChanges += 1 }
    }
    Timer {
        interval: 100
        running: Qt.application.arguments.indexOf("--smoke-test") !== -1
        repeat: false
        onTriggered: {
            if (backend.greeting !== "Hello, world!" || greetingLabel.text !== "Hello, world!" || backend.count !== 0 || counterLabel.text !== "0") {
                console.error("Rust smoke: initial backend contract failed")
                Qt.exit(1)
                return
            }
            incrementButton.clicked()
            if (backend.count !== 1 || counterLabel.text !== "1") {
                console.error("Rust smoke: first increment failed")
                Qt.exit(1)
                return
            }
            incrementButton.clicked()
            if (backend.count !== 2 || counterLabel.text !== "2") {
                console.error("Rust smoke: second increment failed")
                Qt.exit(1)
                return
            }
            resetButton.clicked()
            if (backend.count !== 0 || counterLabel.text !== "0" || window.observedCountChanges !== 3) {
                console.error("Rust smoke: reset or count notifications failed")
                Qt.exit(1)
                return
            }
            console.log("Rust Qt Quick smoke passed: 0 -> 1 -> 2 -> 0")
            Qt.exit(0)
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16
        Label {
            id: greetingLabel
            objectName: "greetingLabel"
            text: backend.greeting
            font.pixelSize: 26
            Layout.alignment: Qt.AlignHCenter
        }
        Label {
            id: counterLabel
            objectName: "counterLabel"
            text: backend.count.toString()
            font.pixelSize: 24
            Layout.alignment: Qt.AlignHCenter
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Button {
                id: incrementButton
                objectName: "incrementButton"
                text: "Increment"
                Accessible.name: "Increment counter"
                onClicked: backend.increment()
            }
            Button {
                id: resetButton
                objectName: "resetButton"
                text: "Reset"
                Accessible.name: "Reset counter"
                onClicked: backend.reset()
            }
        }
    }
}
