# test importing every module
import pkgutil
import traceback
all_mods = [m.name for m in pkgutil.iter_modules()]
print("All modules: ", all_mods)
for m in all_mods:
    try:
        __import__(m)
        print("Imported: ", m)
    except Exception as e:
        print("Failed to import: ", m)
        print(traceback.format_exc())

# test urllib can use the bundled certifi CAs
import urllib.request
urllib.request.urlopen('https://github.com')