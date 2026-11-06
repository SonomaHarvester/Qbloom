import sys
from pathlib import Path

from PySide6.QtCore import QMetaObject, QObject, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from .backend import Backend


def smoke_test(app, engine, backend):
    root = engine.rootObjects()[0]
    greeting = root.findChild(QObject, "greetingLabel")
    counter = root.findChild(QObject, "counterLabel")
    increment_button = root.findChild(QObject, "incrementButton")
    reset_button = root.findChild(QObject, "resetButton")
    if not all((greeting, counter, increment_button, reset_button)):
        return 3

    notifications = []
    backend.countChanged.connect(lambda: notifications.append(backend.count))

    def check(expected):
        app.processEvents()
        return backend.count == expected and counter.property("text") == str(expected)

    if backend.greeting != "Hello, world!" or greeting.property("text") != backend.greeting or not check(0):
        return 4
    if not QMetaObject.invokeMethod(increment_button, "clicked") or not check(1):
        return 5
    if not QMetaObject.invokeMethod(increment_button, "clicked") or not check(2):
        return 6
    if not QMetaObject.invokeMethod(reset_button, "clicked") or not check(0):
        return 7
    if notifications != [1, 2, 0]:
        return 8
    print("PASS: PySide6 QML buttons and count transitions 0 -> 1 -> 2 -> 0")
    return 0


def main():
    app = QGuiApplication(sys.argv)
    backend = Backend()
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)
    qml = Path(__file__).resolve().parent.parent / "qml" / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml)))
    if not engine.rootObjects():
        return 2
    if "--smoke-test" in sys.argv:
        return smoke_test(app, engine, backend)
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
