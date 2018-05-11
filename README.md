# Tootle
![tootle_pres-16](https://user-images.githubusercontent.com/37731582/39925915-d4b46306-552d-11e8-9d1a-c4e138f181b1.png)

Simple [Mastodon](https://github.com/tootsuite/mastodon) client designed for elementary OS.

![Tootle Screenshot](https://raw.githubusercontent.com/bleakgrey/tootle/master/data/screenshot.png)

## Building and Installation

First of all you'll need some dependencies to build and run the app:
* meson
* valac
* libgtk-3-dev
* libsoup2.4-dev
* libgranite-dev
* libjson-glib-dev

Then run these commands to build and install it:

    meson build --prefix=/usr
    cd build
    sudo ninja install
    com.github.bleakgrey.tootle
    
## Contributing

If you feel like contributing, you're always welcome to help the project in many ways:
* Reporting any issues
* Suggesting ideas and functionality
* Submitting pull requests
* Donating with [LiberaPay](https://liberapay.com/bleakgrey/) to help project development and keeping the developer happy

<a href="https://liberapay.com/bleakgrey/donate"><img alt="Donate using Liberapay" src="https://liberapay.com/assets/widgets/donate.svg"></a>
