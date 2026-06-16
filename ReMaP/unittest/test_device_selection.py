import unittest
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from remap.device import select_torch_device


class DeviceSelectionTest(unittest.TestCase):
    def test_uses_cpu_when_gpu_is_disabled(self):
        self.assertEqual(select_torch_device(0), "cpu")
        self.assertEqual(select_torch_device(False), "cpu")

    def test_uses_cuda_when_gpu_is_enabled(self):
        self.assertEqual(select_torch_device(1), "cuda:0")
        self.assertEqual(select_torch_device(True), "cuda:0")


if __name__ == "__main__":
    unittest.main()
