app := "Sleepless"
build_dir := "build"
app_bundle := build_dir / app + ".app"

build:
    mkdir -p {{app_bundle}}/Contents/MacOS
    cp Info.plist {{app_bundle}}/Contents/
    swiftc Sources/main.swift -o {{app_bundle}}/Contents/MacOS/{{app}} -framework Cocoa

install: build
    cp -r {{app_bundle}} /Applications/
    @echo "Installed to /Applications/{{app}}.app"

clean:
    rm -rf {{build_dir}}

run: build
    open {{app_bundle}}
