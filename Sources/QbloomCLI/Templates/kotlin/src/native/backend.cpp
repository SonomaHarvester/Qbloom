#include "backend.h"
#include <QDebug>
#include <QThread>

Backend::Backend(JNIEnv *env, jobject javaBackend, QObject *parent)
    : QObject(parent), m_env(env), m_javaBackend(env->NewGlobalRef(javaBackend)) {
    jclass type = env->GetObjectClass(javaBackend);
    m_greeting = env->GetMethodID(type, "greeting", "()Ljava/lang/String;");
    m_count = env->GetMethodID(type, "count", "()I");
    m_increment = env->GetMethodID(type, "increment", "()V");
    m_reset = env->GetMethodID(type, "reset", "()V");
    env->DeleteLocalRef(type);
    if (clearJavaException("method lookup") || !m_javaBackend || !m_greeting || !m_count || !m_increment || !m_reset)
        qFatal("Could not initialize Java backend methods");
}

Backend::~Backend() { m_env->DeleteGlobalRef(m_javaBackend); }

bool Backend::clearJavaException(const char *operation) const {
    if (!m_env->ExceptionCheck()) return false;
    qWarning() << "Java backend failed during" << operation;
    m_env->ExceptionDescribe();
    m_env->ExceptionClear();
    return true;
}

QString Backend::greeting() const {
    Q_ASSERT(QThread::currentThread() == thread());
    auto value = static_cast<jstring>(m_env->CallObjectMethod(m_javaBackend, m_greeting));
    if (clearJavaException("greeting") || !value) return {};
    const char *utf8 = m_env->GetStringUTFChars(value, nullptr);
    QString result = utf8 ? QString::fromUtf8(utf8) : QString();
    if (utf8) m_env->ReleaseStringUTFChars(value, utf8);
    m_env->DeleteLocalRef(value);
    clearJavaException("greeting conversion");
    return result;
}

int Backend::count() const {
    Q_ASSERT(QThread::currentThread() == thread());
    int result = m_env->CallIntMethod(m_javaBackend, m_count);
    if (clearJavaException("count")) return -1;
    return result;
}

void Backend::increment() {
    Q_ASSERT(QThread::currentThread() == thread());
    int before = count();
    m_env->CallVoidMethod(m_javaBackend, m_increment);
    if (!clearJavaException("increment") && count() != before) emit countChanged();
}

void Backend::reset() {
    Q_ASSERT(QThread::currentThread() == thread());
    int before = count();
    m_env->CallVoidMethod(m_javaBackend, m_reset);
    if (!clearJavaException("reset") && count() != before) emit countChanged();
}
