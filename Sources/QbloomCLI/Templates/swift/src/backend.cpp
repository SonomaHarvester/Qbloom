#include "backend.h"
#include "swift_backend.h"
#include <QDebug>
#include <QThread>

Backend::Backend(QObject *parent) : QObject(parent), m_handle(qbloom_swift_new()) {
    if (!m_handle || (m_count = qbloom_swift_count(m_handle)) < 0)
        qFatal("Could not create the Swift backend state");
}

Backend::~Backend() { qbloom_swift_destroy(m_handle); }

QString Backend::greeting() const {
    Q_ASSERT(QThread::currentThread() == thread());
    char value[64] = {};
    if (qbloom_swift_greeting(m_handle, value, sizeof(value)) != 0) return {};
    return QString::fromUtf8(value);
}

void Backend::increment() {
    Q_ASSERT(QThread::currentThread() == thread());
    const int next = qbloom_swift_increment(m_handle);
    if (next < 0) { qWarning("Swift increment failed"); return; }
    if (next == m_count) return;
    m_count = next;
    emit countChanged();
}

void Backend::reset() {
    Q_ASSERT(QThread::currentThread() == thread());
    const int next = qbloom_swift_reset(m_handle);
    if (next < 0) { qWarning("Swift reset failed"); return; }
    if (next == m_count) return;
    m_count = next;
    emit countChanged();
}
