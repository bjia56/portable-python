import multiprocessing
import pkgutil

import test_deps


def import_with_timeout(mod_name):
    q = multiprocessing.Queue()
    p = multiprocessing.Process(target=test_deps.import_module, args=(mod_name, q))
    p.start()

    p.join(10)
    if p.is_alive():
        p.terminate()
        p.join()
        print(f"Importing {mod_name} timed out after 10 seconds")
    else:
        result = q.get()
        if result:
            print(f"Importing {mod_name} failed with exception:\n{result}")
        else:
            print(f"Importing {mod_name} succeeded")


if __name__ == "__main__":
    # Get a list of all available modules
    available_modules = list(pkgutil.iter_modules())
    print("Available modules:", [m.name for m in available_modules])

    for mod in available_modules:
        import_with_timeout(mod.name)

    # test urllib can use the bundled certifi CAs
    import urllib.request
    urllib.request.urlopen('https://github.com')