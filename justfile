app := "Sleepless"
app_bundle := "build" / app + ".app"

build:
    swift build -c release
    mkdir -p {{app_bundle}}/Contents/MacOS
    mkdir -p {{app_bundle}}/Contents/Resources
    cp .build/release/{{app}} {{app_bundle}}/Contents/MacOS/{{app}}
    cp Info.plist {{app_bundle}}/Contents/
    cp assets/AppIcon.icns {{app_bundle}}/Contents/Resources/AppIcon.icns

test:
    swift test

run: build
    open {{app_bundle}}

install: build setup-sudoers
    cp -r {{app_bundle}} /Applications/
    @echo "Installed to /Applications/{{app}}.app"

setup-sudoers:
    bash scripts/setup-sudoers.sh

clean:
    swift package clean
    rm -rf build
