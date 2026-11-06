#include "backend.h"

QString Backend::greeting() const { return QStringLiteral("Hello, world!"); }

void Backend::increment() {
    ++m_count;
    emit countChanged();
}

void Backend::reset() {
    if (m_count == 0) return;
    m_count = 0;
    emit countChanged();
}
