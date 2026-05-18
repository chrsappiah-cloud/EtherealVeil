fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios archive

```sh
[bundle exec] fastlane ios archive
```

Build archive and export IPA

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload IPA to TestFlight

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload metadata and screenshots (no binary)

### ios deliver_submit

```sh
[bundle exec] fastlane ios deliver_submit
```

Upload metadata, screenshots, and submit for App Store review

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

Submit latest build for App Store review

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
