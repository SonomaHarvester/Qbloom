#pragma once
#include <QObject>
#include <QString>

class Backend final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString greeting READ greeting CONSTANT)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
public:
    explicit Backend(QObject *parent = nullptr);
    ~Backend() override;
    QString greeting() const;
    int count() const { return m_count; }
    Q_INVOKABLE void increment();
    Q_INVOKABLE void reset();
signals:
    void countChanged();
private:
    void *m_handle = nullptr;
    int m_count = 0;
};
