# test ssl is linked correctly
import ssl

# test urllib can use the bundled certifi CAs
import urllib.request
urllib.request.urlopen('https://github.com')

# test ctypes is linked correctly
import ctypes