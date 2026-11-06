from PySide6.QtCore import QObject, Property, Signal, Slot


class Backend(QObject):
    countChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._count = 0

    @Property(str, constant=True)
    def greeting(self):
        return "Hello, world!"

    @Property(int, notify=countChanged)
    def count(self):
        return self._count

    @Slot()
    def increment(self):
        self._count += 1
        self.countChanged.emit()

    @Slot()
    def reset(self):
        if self._count:
            self._count = 0
            self.countChanged.emit()
