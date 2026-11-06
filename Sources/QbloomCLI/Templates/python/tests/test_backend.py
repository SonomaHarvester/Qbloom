import unittest

from qbloom_app.backend import Backend


class BackendTests(unittest.TestCase):
    def test_contract_and_notifications(self):
        backend = Backend()
        changes = []
        backend.countChanged.connect(lambda: changes.append(backend.count))
        self.assertEqual(backend.greeting, "Hello, world!")
        self.assertEqual(backend.count, 0)
        backend.increment()
        backend.increment()
        backend.reset()
        self.assertEqual(changes, [1, 2, 0])
        self.assertEqual(backend.count, 0)


if __name__ == "__main__":
    unittest.main()
