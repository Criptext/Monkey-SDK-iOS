
#!/bin/bash

# Docs by jazzy
# https://github.com/realm/jazzy
# ------------------------------

git submodule update --remote

#jazzy -o ./ --source-directory Cartography/ --readme Cartography/README.md -a 'Robert Böhnke' -u 'https://twitter.com/ceterum_censeo' -m 'Cartography' -g 'https://github.com/robb/Cartography'


jazzy --objc -o ./ --author 'Criptext, Inc.' --author_url https://criptext.com --github_url https://github.com/Criptext/Monkey-SDK-iOS --umbrella-header 'MonkeyKit/Example/Pods/Target Support Files/MonkeyKit/MonkeyKit.h' --framework-root MonkeyKit/ --module MonkeyKit --readme MonkeyKit/README.md

#/Users/Gianni/Downloads/jazzy/bin/jazzy --objc --author 'Criptext, Inc.' --author_url https://criptext.com --github_url https://github.com/Criptext/Monkey-SDK-iOS --framework-root MonkeyKit/MonkeyKit/ --module MonkeyKit
