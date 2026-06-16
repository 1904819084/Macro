def select_torch_device(gpu_enabled):
    return "cuda:0" if gpu_enabled else "cpu"
