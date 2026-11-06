#include "backend.h"
#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    Backend backend;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.loadFromModule("{{MODULE_URI}}", "Main");
    if (engine.rootObjects().isEmpty()) return 2;

    if (app.arguments().contains(QStringLiteral("--smoke-test"))) {
        QObject *window = engine.rootObjects().first();
        QObject *greeting = window->findChild<QObject*>("greetingLabel");
        QObject *counter = window->findChild<QObject*>("counterLabel");
        QObject *incrementButton = window->findChild<QObject*>("incrementButton");
        QObject *resetButton = window->findChild<QObject*>("resetButton");
        if (!greeting || !counter || !incrementButton || !resetButton) return 3;
        int notifications = 0;
        QObject::connect(&backend, &Backend::countChanged, &app, [&notifications] { ++notifications; });
        auto check = [&](int expected) {
            app.processEvents();
            return backend.count() == expected && counter->property("text").toString() == QString::number(expected);
        };
        if (backend.greeting() != QStringLiteral("Hello, world!") ||
            greeting->property("text").toString() != backend.greeting() || !check(0)) return 4;
        if (!QMetaObject::invokeMethod(incrementButton, "clicked") || !check(1)) return 5;
        if (!QMetaObject::invokeMethod(incrementButton, "clicked") || !check(2)) return 6;
        if (!QMetaObject::invokeMethod(resetButton, "clicked") || !check(0) || notifications != 3) return 7;
        qInfo() << "PASS: Swift-backed QML greeting and count transitions 0 -> 1 -> 2 -> 0";
        return 0;
    }
    return app.exec();
}
