#include "backend.h"
#include "libqbloom_go.h"
#include <QDebug>

Backend::Backend(QObject *parent) : QObject(parent), m_handle(GoNewState()) {
    if (m_handle == 0 || GoCount(m_handle, &m_count) != 0)
        qFatal("Could not create the Go backend state");
}

Backend::~Backend() { GoDestroyState(m_handle); }

QString Backend::greeting() const {
    char *value = GoGreeting();
    if (!value) return {};
    const QString result = QString::fromUtf8(value);
    GoFreeString(value);
    return result;
}

void Backend::increment() {
    int next = 0;
    if (GoIncrement(m_handle, &next) != 0) {
        qWarning("GoIncrement failed: invalid backend handle");
        return;
    }
    m_count = next;
    emit countChanged();
}

void Backend::reset() {
    int next = 0;
    if (GoReset(m_handle, &next) != 0) {
        qWarning("GoReset failed: invalid backend handle");
        return;
    }
    if (m_count == next) return;
    m_count = next;
    emit countChanged();
}
