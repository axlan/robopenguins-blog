---
title: NodeMCU Development
author: jon
layout: post
categories:
  - Hardware
image: 2020/NodeMCUv1.0-pinout.jpg
---

I'm starting another electronic art project, and decided to use the NodeMCU for the processor. It's cheap, easy to setup, and has WiFi. However, when I previously used the board (see [Wreath Pixel Display]({% post_url 2017-07-04-wreath-pixel-display %})) I wasn't very happy with the development environment. Here I'll go through the new setup I settled on for this project.

# Why this board?

Over the years I've gone back and forth on what I think is an appropriate control board for a small simple project.

Using a small microcontroller on a protoboard or soldering wires directly is probably the cheapest and smallest option. For example I did this in the [Book Safe Project]({% post_url 2012-04-08-book-safe %}). However, I've come to appreciate being able to do the initial development without needing to do any soldering. Using a development board also tends to hold up better.

When it comes to development boards, there are overwhelming options. My main criteria these days is that it's cheap, and that it is common enough to have a lot of peripheral libraries already existing. Generally this has made me look for Arduino compatible boards that offer a good value. I've never been a big fan of actual Arduinos because of the weird form factor, the cost, and the pretty lousy IDE.

NodeMCU is relatively small, cheap, Arduino compatible, and common enough that theirs plenty of support and documentation. The main feature is that it can connect to a WiFi network out of the box and is configured with some very beginner friendly code. It is based on the ESP8266 chip which is amazing in it's own right and has other compatible boards that are smaller and cheaper if needed. I went with this particular board since it breaks out enough pins for most microcontroller projects and comes with all the peripherals you need to connect to it out of the box. You can find them for $7 individually on Amazon, and even cheaper in bulk. For this project the WiFi functionality isn't strictly necessary, but being able to reprogram the board over WiFi (Using over the air (OTA) updates) is very nice for something I plan to hang on a wall and is worth it for me at this price. The only thing I needed to get started was a laptop and a micro USB cable.

# VSCode + PlatformIO

Previously I've mostly used the Arduino IDE to develop for this board. There are libraries that give you examples for doing everything from web servers to IOT applications that can be searched and installed in the IDE. [Here](https://www.teachmemicro.com/intro-nodemcu-arduino/) is a good guide for setting this all up. It works OK for smaller projects, but is missing a lot of quality of life features I'd expect from an IDE. Basic things like project or regex search.

To address some of these I've tried using the [Visual Studio Code](https://code.visualstudio.com/) with an Ardiuno extension. VSCode is my go to IDE. It's cross platform, extremely configurable, and supports pretty much any programming language with extensions. I still might suggest a heavier weight IDE like IntelliJ or the full Visual Studio if you are working on a project that fits into their support, but VSCode is amazing for weirder projects that don't have that level of IDE support.

The [Arduino extension](https://marketplace.visualstudio.com/items?itemName=vsciot-vscode.vscode-arduino) is OK, and would probably be fine if I was developing for a standard board, but I found its support for generating bin files for OTA updates a bit lacking. Also builds would take a minute since it didn't handle incremental builds well.

This time I looked around a bit and decided to give [PlatformIO](https://platformio.org/) a shot. It presents itself with a pretty lofty mission of being a unified environment for embedded development. They provide a pretty elaborate extension to VSCode as the IDE. I've had a very positive initial experience setting it up.

# Setup

1. Install VSCode - <https://code.visualstudio.com/Download>
2. Install the PlatformIO IDE extension - <https://platformio.org/platformio-id>
3. Make a new project - <https://docs.platformio.org/en/latest/ide/vscode.html#quick-start> here I selected the `NodeMCU 1.0 (ESP-12E Module)` for the board. Technically my board is labeled as `NodeMCUv3` but after looking under the "Boards" section of the PlatformIO tab, it seemed compatible and was at least targeting the ESP8266.
4. Find the serial port - Plug in the NodeMCU board and install the serial driver if needed. For windows instructions see <https://medium.com/@cilliemalan/installing-nodemcu-drivers-on-windows-d9bffdbad52> . Note the serial port the board comes up as. For windows it will be COMX where X is a number.

# Setting up over the air (OTA) updates

Open up the `platformio.ini` file in the new project. Add the following lines:

```
monitor_port = COMX
upload_port = COMX
lib_deps = 
    EasyOTA
```

Where COMX is the serial port of the board.

I found EasyOTA by going to the as the PlatformIO home tab and searching in the library section. It got the job done, though there might be better libraries out there.

Next I replaced `main.cpp` with the following code:

```cpp
#include <JeVe_EasyOTA.h> 

#define WIFI_SSID        "MY_SSID"
#define WIFI_PASSWORD    "MY_PASS"
#define ARDUINO_HOSTNAME "ota-project"
EasyOTA OTA(ARDUINO_HOSTNAME);

void setup() {
  Serial.begin(9600);
  // This callback will be called when EasyOTA has anything to tell you.
  OTA.onMessage([](const String& message, int line) {
    Serial.println(message);
  });
  OTA.addAP(WIFI_SSID, WIFI_PASSWORD);
}

void loop() {
  OTA.loop();
}
```

changing the WIFI_SSID, WIFI_PASSWORD, and ARDUINO_HOSTNAME. The ARDUINO_HOSTNAME wouldn't resolve for me, and I traced this down to the issue that it's using a service called mDNS which is natively supported on OSX and only partially supported on windows. To see my device I could use the [Service Browser Android App](https://play.google.com/store/apps/details?id=com.druk.servicebrowser&hl=en_US), or install the Bonjour SDK for Windows found [here](https://developer.apple.com/download/more/?=Bonjour%20SDK%20for%20Windows) (you'll need an Apple login, though the insall can also be found at <https://www.softpedia.com/get/Programming/SDK-DDK/Bonjour-SDK.shtml>).

Under "Project Tasks" choose "Upload and Monitor". This builds the project and attempts to upload the results to the configured serial port. After a minute or so it should finish and start monitoring the serial port for messages coming from the board. You should see something like:

```
--- Miniterm on COM4  9600,8,N,1 ---
--- Quit: Ctrl+C | Menu: Ctrl+T | Help: Ctrl+T followed by Ctrl+H ---
�L��슅�Trying WIFI_SSID
IP 192.168.1.123
SSID WIFI_SSID
```

Where the IP is the IP your router assigned to the board. If you don't want to worry about this value ever changing you may want to look at how to assign a static IP address for your specific model of router. Either way this IP will let you reference the board going forward.

Change the `upload_port` in `platformio.ini` to the IP address for your board and add the line: `upload_protocol = espota`

Now when you upload, it should be able to use the WiFi. As long as your project continues to have `OTA.loop()` called in it's loop it should continue to support OTA updates. One thing to look out for is that if your code ends up in an infinite loop, `OTA.loop()` might not end up getting called, preventing you from updating. During development I found it useful to add a waiting period just running the OTA loop to allow an update after a restart even if the code got into an infinite loop or crash. 

If you suspect the IP address might not be right, the board isn't connecting to the WiFi, or isn't taking OTA updates you can always repeat the initial upload process with the board connected to the computer and the upload_port changed back to the serial port.

From there you can program mostly as you would for any other Arduino target. PlatformIO has some of it's own quirks in building code, but at least for me was mostly just more sensible then the normal Arduino IDE. <https://arduino-esp8266.readthedocs.io/en/latest/libraries.html> lists some of the special concerns for this platform.

You can also see the code for [Wreath Pixel Display]({% post_url 2017-07-04-wreath-pixel-display %}) in <https://github.com/axlan/Sound-Catcher/tree/master/arduino/NodeMCU/SoundCatcherNoTimer> . This includes a basic logging framework as well as a modular settings page framework.
