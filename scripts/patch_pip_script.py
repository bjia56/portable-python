import sys

# adapted from https://stackoverflow.com/a/57567228
new_shebang = """#!/bin/sh
"true" '''\\'
exec "$(dirname "$0")"/python "$0" "$@"
'''"""

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <pip_script>")
        sys.exit(1)

    with open(sys.argv[1], "r") as f:
        lines = f.readlines()

    script = ""
    for line in lines:
        if line.startswith("#!"):
            # replace the shebang of the script with a relative path to the python interpreter
            script += new_shebang + "\n"
        else:
            script += line

    with open(sys.argv[1], "w") as f:
        f.write(script)
