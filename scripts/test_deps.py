import importlib
import traceback

def import_module(module_name, queue):
    try:
        importlib.import_module(module_name)
        queue.put(None)
    except Exception:
        queue.put(traceback.format_exc())
