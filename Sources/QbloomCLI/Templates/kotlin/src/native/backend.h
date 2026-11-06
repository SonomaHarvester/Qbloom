#pragma once
#include <jni.h>
#include <QObject>
#include <QString>

class Backend final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString greeting READ greeting CONSTANT)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
public:
    Backend(JNIEnv *env, jobject javaBackend, QObject *parent = nullptr);
    ~Backend() override;
    QString greeting() const;
    int count() const;
    Q_INVOKABLE void increment();
    Q_INVOKABLE void reset();
signals:
    void countChanged();
private:
    bool clearJavaException(const char *operation) const;
    JNIEnv *m_env;
    jobject m_javaBackend;
    jmethodID m_greeting;
    jmethodID m_count;
    jmethodID m_increment;
    jmethodID m_reset;
};
