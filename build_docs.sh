
#!/bin/bash

# Docs by jazzy
# https://github.com/realm/jazzy
# ------------------------------

git submodule update --remote

jazzy --objc -o ./ --author 'Criptext, Inc.' --author_url https://criptext.com --github_url https://github.com/Criptext/Monkey-SDK-iOS --umbrella-header 'MonkeyKit/Example/Pods/Target Support Files/MonkeyKit/MonkeyKit.h' --framework-root MonkeyKit/ --module MonkeyKit --readme MonkeyKit/README.md
