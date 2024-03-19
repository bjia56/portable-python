import multiprocessing
import pkgutil
import sys

import test_deps


RED = '\u001b[31m'
GREEN = '\u001b[32m'
RESET = '\u001b[0m'


def failed(msg):
    print(f"{RED}{msg}{RESET}")


def succeeded(msg):
    print(f"{GREEN}{msg}{RESET}")


def import_with_timeout(mod_name):
    q = multiprocessing.Queue()
    p = multiprocessing.Process(target=test_deps.import_module, args=(mod_name, q))
    p.start()

    p.join(10)
    if p.is_alive():
        p.terminate()
        p.join()
        failed(f"Importing {mod_name} timed out after 10 seconds")
    else:
        result = q.get()
        if result:
            failed(f"Importing {mod_name} failed with exception:\n{result}")
        else:
            succeeded(f"Importing {mod_name} succeeded")


if __name__ == "__main__":
    # Get a list of all available modules
    available_modules = set()
    for m in pkgutil.iter_modules():
        available_modules.add(m.name)
    for m in sys.builtin_module_names:
        available_modules.add(m)
    available_modules = list(available_modules)
    available_modules.sort()
    print("Available modules:", [m for m in available_modules])

    for mod in available_modules:
        import_with_timeout(mod)

    # test urllib can use the bundled certifi CAs
    import urllib.request
    urllib.request.urlopen('https://github.com')