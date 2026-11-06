#include "backend.h"
#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

extern "C" JNIEXPORT jint JNICALL Java_qbloom_app_Main_launch(JNIEnv *env, jclass, jobject javaBackend, jobjectArray javaArgs) {
    const int extra = env->GetArrayLength(javaArgs);
    QByteArray executable("qbloom_app");
    QVector<QByteArray> storage;
    storage.reserve(extra);
    for (int i = 0; i < extra; ++i) {
        auto arg = static_cast<jstring>(env->GetObjectArrayElement(javaArgs, i));
        const char *utf8 = env->GetStringUTFChars(arg, nullptr);
        storage.append(QByteArray(utf8));
        env->ReleaseStringUTFChars(arg, utf8);
        env->DeleteLocalRef(arg);
    }
    QVector<char *> argv;
    argv.append(executable.data());
    for (auto &arg : storage) argv.append(arg.data());
    int argc = argv.size();
    QGuiApplication app(argc, argv.data());
    Backend backend(env, javaBackend);
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
        if (backend.greeting() != QStringLiteral("Hello, world!") || greeting->property("text").toString() != backend.greeting() || !check(0)) return 4;
        if (!QMetaObject::invokeMethod(incrementButton, "clicked") || !check(1)) return 5;
        if (!QMetaObject::invokeMethod(incrementButton, "clicked") || !check(2)) return 6;
        if (!QMetaObject::invokeMethod(resetButton, "clicked") || !check(0) || notifications != 3) return 7;
        qInfo() << "PASS: Java-backed QML greeting and count transitions 0 -> 1 -> 2 -> 0";
        return 0;
    }
    return app.exec();
}
