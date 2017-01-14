#! /bin/bash

xcodebuild -scheme EonilGCDActor -configuration Debug clean build test
xcodebuild -scheme EonilGCDActor -configuration Release clean build
