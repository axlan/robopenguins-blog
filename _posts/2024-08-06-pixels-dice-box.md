---
title: Pixels Dice Box
author: jon
layout: post
categories:
  - Hardware
  - Software
  - Electronic Art
  - IoT
  - WLED
image: 2024/dice-box/finished_thumb_wide.webp
featured: true
---

I made an IoT dice box to combine two of my favorite open source LED projects, [Pixels Dice](https://gamewithpixels.com/) and [WLED](https://kno.wled.ge/).

I've wanted to sink my teeth into a more significant hardware project for awhile and actually give it a little polish. This builds on my previous [Pixels Dice library work]({% post_url 2024-03-26-pixel-dice-arduino_lib %}), to make something that is both functional, and nice to look at.

### TFT GUI
<iframe width="1583" height="620" src="https://www.youtube.com/embed/VNsHq1TbiW8" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### Multiple Die Controlling Different Segments
<iframe width="1583" height="620" src="https://www.youtube.com/embed/oCDr44C-qwM" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

# Using the WLED Software

This blog post is mostly going to focus on the development and build process.

See the README at: <https://github.com/axlan/WLED/tree/v0.15.0-pixel-dice/usermods/pixels_dice_tray> for a full guide on how to setup and use all the functionality. That branch also has the full source for this usermod.

You can download the release for the compatible boards from: <https://github.com/axlan/WLED/releases/tag/v0.15.0-pixel-dice>

Or use the web installer: <https://axlan.github.io/WLED-WebInstaller/>

Unfortunately, it doesn't work on vanilla ESP32 chips, and I've only tested it working on the ESP32-S3. If you get an ESP32-S3 dev board or a [LILYGO T-QT Pro](https://www.lilygo.cc/products/t-qt-pro), you should be able to use this software without installing anything or writing any code.

## High Level Features

* Several LED effects that respond to die rolls
  * Effect color and parameters can be modified like any other effect
  * Different die can be set to control different segments
* An optional GUI on a TFT screen with custom button controls
  * Gives die connection and roll
  * Can do basic LED effect controls
  * Can display custom info for different roll types (ie. RPG stats/spell info)
<p float="left">
<img src="https://github.com/axlan/WLED/raw/v0.15.0-pixel-dice/usermods/pixels_dice_tray/images/status.webp" width="30%">
<img src="https://github.com/axlan/WLED/raw/v0.15.0-pixel-dice/usermods/pixels_dice_tray/images/effect.webp" width="30%">
<img src="https://github.com/axlan/WLED/raw/v0.15.0-pixel-dice/usermods/pixels_dice_tray/images/info.webp" width="30%">
</p>
* Publish MQTT events from die rolls for remote logging/actions
  * Also report the selected roll type
<img class="center" src="https://github.com/axlan/WLED/raw/v0.15.0-pixel-dice/usermods/pixels_dice_tray/images/roll_plot.png" width="100%">
* Control settings through the WLED web

# Building the Box

## Finding the Box

When I started the project, I had a general idea that I wanted to find a nice looking box I could hide a bunch of electronics in. After going to a few local thrift stores (I miss the days of yore when I could wander thrift stores looking for project inspiration), I had a couple candidates.
[<img class="center" src="{{ site.image_host }}/2024/dice-box/boxes_thumb.webp" width="80%">]({{ site.image_host }}/2024/dice-box/boxes.jpg)

These both seemed viable, and I went back and forth for a few days. Eventually, I decided the wood box was a little too small, and integrating the die chargers would be too close a fit. So the red jewelry box won out!

[<img class="center" src="{{ site.image_host }}/2024/dice-box/jewel_box_thumb.webp" height="50%" width="50%">]({{ site.image_host }}/2024/dice-box/jewel_box.jpg)

## Deciding on the Electronics

Another thing I needed to decide was what to actually put in the box. The only thing I knew I wanted going in was the dice chargers, and a ESP32 to connect the dice to the Wifi.

I had been considering things like capacitive touch buttons, and purely using the dice themselves as inputs. In the end, I decided to focus the interface design around a [LILYGO T-QT Pro](https://www.lilygo.cc/products/t-qt-pro) board I had available. Adding an LED strip seemed like a no brainer since what goes better with LED dice then more LEDs? I wanted it to be able to take USB-C power, since I wanted it to be able to be powered by my phone. In addition, I decided to throw a battery pack in there.

[<img class="center" src="{{ site.image_host }}/2024/dice-box/schematic_thumb.webp" width="100%">]({{ site.image_host }}/2024/dice-box/schematic.jpg)
[<img class="center" src="{{ site.image_host }}/2024/dice-box/wiring_thumb.webp" height="50%" width="50%">]({{ site.image_host }}/2024/dice-box/wiring.jpg)

As you can see, I needed to "modify" the battery to fit.

Actually getting the USB-C ports working with my phone was a bit difficult. I bought a pack of male and female USB-C receptacles with solder pads. The male side for connecting to the dice chargers worked fine, but the female side that connects to the power source didn't.

I finally spent the time to actually read how USB-C works and how the devices determine which side is a power source/sink. <https://hackaday.com/2023/01/04/all-about-usb-c-resistors-and-emarkers/> was a fairly helpful article. Eventually, I realized that the female side didn't have any resistors to indicate it was a power sink. Basically the same issue discussed here <https://electronics.stackexchange.com/questions/595590/jrc-b008-for-usb-c-microcontroller-power-supply>.

It is surprisingly hard to find adapters to purchase with the needed resistors. After looking through what I had lying around, I realized that certain USB-C to USB-A adapters need to have these resistors. I tried cutting one of the OTG phone adapters I had, but it was totally potted in epoxy. Eventually, I found this strange adapter:
[<img class="center" src="{{ site.image_host }}/2024/dice-box/cursed_adapter_thumb.webp" height="50%" width="50%">]({{ site.image_host }}/2024/dice-box/cursed_adapter.jpg)
[<img class="center" src="{{ site.image_host }}/2024/dice-box/inside_adapter_thumb.webp" height="50%" width="50%">]({{ site.image_host }}/2024/dice-box/inside_adapter.jpg)
I have no idea what it's from, but it was easy enough to extract the board I needed.

## Putting it Together

From there the build was pretty straight forward. The jewelry box was cardboard with a layer of fabric, so it wasn't too hard to cut slots for the various peripherals. I got some nice right angle adapters for the USB-C connectors, and started putting things together.

[<img class="center" src="{{ site.image_host }}/2024/dice-box/base_thumb.webp" height="50%" width="50%">]({{ site.image_host }}/2024/dice-box/base.jpg)
[<img class="center" src="{{ site.image_host }}/2024/dice-box/charging_thumb.webp" height="50%" width="50%">]({{ site.image_host }}/2024/dice-box/charging.jpg)

I wanted to put some art in the box, so I found the dice related art. I had them printed and laminated at my local office store for a couple bucks and mounted them in the box.

[<img class="center" src="{{ site.image_host }}/2024/dice-box/inside_thumb.webp" height="50%" width="50%">]({{ site.image_host }}/2024/dice-box/inside.jpg)
[<img class="center" src="{{ site.image_host }}/2024/dice-box/finished_thumb.webp" height="50%" width="50%">]({{ site.image_host }}/2024/dice-box/finished.jpg)

# Writing the Software

From my previous project [Writing an Arduino library for Pixel Dice]({% post_url 2024-03-26-pixel-dice-arduino_lib %}) I already had the core functionality for getting the data from the dice.

I had also made a full dice controller application <https://github.com/axlan/Pixels-Dice-ESP32-Gateway> that combined my library examples with <https://github.com/tzapu/WiFiManager>. It provided a GUI to configure the ESP32 Wifi and the dices MQTT connection.

For this project I mostly wanted to add LED controls and polish the UI. Initially, I considered going with an exotic control scheme where the position of the two dice when a button was pressed would be the control mechanism, but in the end I decided to keep it a bit simpler. If I wanted to do elaborate controls based on setting the dice to certain positions, I could do that off device base on the MQTT events.

My first decision was whether to build on <https://github.com/axlan/Pixels-Dice-ESP32-Gateway> or try to add the functionality I wanted to [WLED](https://kno.wled.ge/). I've mentioned [WLED in many previous write ups](https://www.robopenguins.com/categories.html#WLED). It has the best useability of pretty much any embedded project I've used.
 * It can be installed through from a website
 * It supports a wide variety of devices
 * It makes initial configuration very easy
   * The Wifi credentials can be set as part of the installation process
   * If the Wifi doesn't connect it makes an ad-hoc access point for initial configuration
   * It supports mDNS for LAN discovery
 * It has an app to simplify the mobile setup
 * It supports a wide variety of protocols
 * Most of it's functionality (like which pins it uses, or what kinds of buttons are connected) can be configured

Even if I'm only using a subset of it's total capabilities, building off of WLED seemed like the way to go.

One of the many nice things is that WLED has a concept called ["usermods"](https://github.com/Aircoookie/WLED/blob/main/usermods/readme.md). These are basically extensions that can add special features (usually hardware specific), that don't make sense to include in the main build.

I had used these in the past, but they had really expanded on the interface since I'd last made one. For example you can add snippets of Javascript to your C++ code to modify the HTML for the config settings page in the web UI.

As a warmup I made a somewhat small usermod to integrate the TFT screen on the [LILYGO T-QT Pro](https://www.lilygo.cc/products/t-qt-pro) to show basic status information: <https://github.com/Aircoookie/WLED/pull/4072>. This refamiliarized myself with the portion of the WLED codebase I'd be working with.

## Working out of a VSCode devcontainer

WLED uses the PlatformIO framework to handle library and cross-compiler management. When I tried to build the code directly I appeared to end up with incompatible library versions. To avoid needing to figure out the issues on my host PC, I decided to use a [devcontainer](https://code.visualstudio.com/docs/devcontainers/containers). These are basically managed Docker images that let you start from a clean build environment managed by VSCode. While the software part of the build worked great in the container, I ran into issues accessing the serial port. I eventually figured it out:

```javascript
// To give the container access to a device serial port, you can uncomment one of the following lines.
// Note: If running on Windows, you will have to do some additional steps:
// https://stackoverflow.com/questions/68527888/how-can-i-use-a-usb-com-port-inside-of-a-vscode-development-container
//
// You can explicitly just forward the port you want to connect to. Replace `/dev/ttyACM0` with the serial port for
// your device. This will only work if the device is plugged in from the start without reconnecting. Adding the
// `dialout` group is needed if read/write permissions for the port are limited to the dialout user.
// "runArgs": ["--device=/dev/ttyACM0", "--group-add", "dialout"],
//
// Alternatively, you can give more comprehensive access to the host system. This will expose all the host devices to
// the container. Adding the `dialout` group is needed if read/write permissions for the port are limited to the
// dialout user. This could allow the container to modify unrelated serial devices, which would be a similar level of
// risk to running the build directly on the host.
"runArgs": ["--privileged", "-v", "/dev/bus/usb:/dev/bus/usb", "--group-add", "dialout"],
```
Still, it's a bit annoying that I needed to restart the container when the COM port re-enumerates.

## Developing the usermod

I tried to thoroughly document my code in <https://github.com/axlan/WLED/tree/v0.15.0-pixel-dice/usermods/pixels_dice_tray>, so take a look there as a starting place for using this mod or making complex WLED usermods. Here I'll talk through some points of particular interest. These are are sort of "meta" features that streamline the process of adding higher level features.

### Effect Metadata

WLED has a concept of LED effects/modes. These are animation or behaviors that run on segments of LEDs. They can be customized with parameters like speed, color, intensity, etc.

To make them discoverable, and determine how they're handled in the UI, they have a [meta data string associated with them](https://kno.wled.ge/interfaces/json-api/#effect-metadata). The simplest example from my code was:

```cpp
// Name - DieSimple
// Parameters -
//   * Selected Die (custom1)
// Colors - Uses color1 and color2
// Palette - Not used
// Flags - Effect is optimized for use on 1D LED strips.
// Defaults - Selected Die set to 0xFF (USER_ANY_DIE)
static const char _data_FX_MODE_SIMPLE_DIE[] PROGMEM =
    "DieSimple@,,Selected Die;!,!;;1;c1=255";
```

This means that when I bring this effect up in the UI it only shows the parameters I specified:

[<img class="center" src="{{ site.image_host }}/2024/dice-box/simple_ui_thumb.webp" width="80%">]({{ site.image_host }}/2024/dice-box/simple_ui.png)

### Customizing the Config Page

To let you customize the look of your configuration settings, you can specify Javascript code to run as the page renders

```cpp
// Slightly annoying that you can't put text before an element.
// The an item on the usermod config page has the following HTML:
// ```html
// Die 0
// <input type="hidden" name="DiceTray:die_0" value="text">
// <input type="text" name="DiceTray:die_0" value="*" style="width:250px;" oninput="check(this,'DiceTray')">
// ```
// addInfo let's you add data before or after the two input fields.
//
// To work around this, add info text to the end of the preceding item.
//
// See addInfo in wled00/data/settings_um.htm for details on what this function does.
oappend(SET_F(
    "addInfo('DiceTray:ble_scan_duration',1,'<br><br><i>Set to \"*\" to "
    "connect to any die.<br>Leave Blank to disable.</i><br><i "
    "class=\"warn\">Saving will replace \"*\" with die names.</i>','');"));
```

where `addInfo` is defined in the javascript for rendering the page.
```javascript
function addInfo(name,el,txt, txt2="") {
  let obj = d.getElementsByName(name);
  if (!obj.length) return;
  if (typeof el === "string" && obj[0]) obj[0].placeholder = el;
  else if (obj[el]) {
    if (txt!="") obj[el].insertAdjacentHTML('afterend', '&nbsp;'+txt);
    if (txt2!="") obj[el].insertAdjacentHTML('beforebegin', txt2 + '&nbsp;');  //add pre texts
  }
}
```

### Formatting Text for a Tiny Screen

The tiny screen makes its use a bit limited. Mostly as a proof of concept I wanted a way to show arbitrary pieces of formatted text. This would be useful if I wanted to reuse this project as a puzzle box, or something like that in the future. For now I'm using it to provide basic stats for the pathfinder game I play in (see [Pathfinder Lore Letters]({% post_url 2023-09-23-lore-letters %})).

Formatting text for the 128x128 screen is pretty tedious, so I wrote a quick and dirty Python script <https://github.com/axlan/WLED/blob/v0.15.0-pixel-dice/usermods/pixels_dice_tray/generate_roll_info.py> that turns a very simple markdown language into C++ functions that draw the text to screen. For example the string

```python
f'''\
$COLOR({TFT_RED})
Barb Chain
$COLOR({TFT_WHITE})
Atk/CMD {BASE_ATK_BONUS + SPELL_ABILITY_MOD}
Range: {short_range()}
$WRAP(1)
$SIZE(1)
Summon {1 + math.floor((CASTER_LEVEL-1)/3)} chains. Make a melee atk 1d6 or a trip CMD=AT. On a hit make Will save or shaken 1d4 rnds.
'''
```

generates

```cpp
static void PrintRoll0() {
  tft.setTextColor(63488);
  tft.println("Barb Chain");
  tft.setTextColor(65535);
  tft.println("Atk/CMD 12");
  tft.println("Range: 70");
  tft.setTextSize(1);
  tft.println("Summon 3 chains. Make");
  tft.println("a melee atk 1d6 or a ");
  tft.println("trip CMD=AT. On a hit");
  tft.println("make Will save or sha");
  tft.println("ken 1d4 rnds.");
}
```

which draws

<img src="https://github.com/axlan/WLED/raw/v0.15.0-pixel-dice/usermods/pixels_dice_tray/images/info.webp" width="30%">

## Trying to Run on the ESP32

The [LILYGO T-QT Pro](https://www.lilygo.cc/products/t-qt-pro) board I'm using uses a ESP32-S3, so that's what I was initially testing with. However, I wanted to make this as easy to set up as possible, so I tried to get it working on the original ESP32 as well.

First, the BLE stack requires a lot of flash. I had to make a special partitioning plan to even fit the build on 4MB devices. This only has 64KB of file system space, which is limited, but still functional.

The bigger issue is that the build consistently crashes if the BLE scan task starts up. It's a bit unclear to me exactly what is failing since the backtrace is showing an exception in new[] memory allocation in the UDP stack. There appears to be a ton of heap available, so my guess is that this is a synchronization issue of some sort from the tasks running in parallel. I tried messing with the task core affinity a bit but didn't make much progress. It's not really clear what difference between the ESP32S3 and ESP32 would cause this difference.

At the end of the day, its generally not advised to run the BLE and Wifi at the same time anyway (though it appears to work without issue on the ESP32S3). I tried modifying the code to turn off the Wifi when the BLE discovery scans were running, but still hit crashes. While it's possible the issue is relatively simple, it was also possible it might be extremely complicated. Rather then spend an unknown amount of time chasing this, I decided just to make this usermod esp32-s3 only.

## Setting up a Web Installer

One interesting feature of WLED that I hadn't looked into before was its web installer <https://install.wled.me/>. This is based on the <https://esphome.github.io/esp-web-tools/>, which is an implementation of the Espressif board flashing tools in Javascript. Apparently browsers have a serial port API these days.

The basics are pretty simple, you put some Json metadata about your builds (the versions, feature variants, and different targets) along with the binaries on your web server. The esp-web-tools talks to the board over serial, and tried to pick the right variant to flash.

The WLED project hosts their page from this github repo <https://github.com/Aircoookie/WLED-WebInstaller>, so I made a fork for my usermod <https://github.com/axlan/WLED-WebInstaller>.

This was fairly straightforward for esp8266 and esp32 boards, but now that there's a lot more variants (esp32c3, esp32s2, esp32s3), and that these variants can have different RAM and flash capabilities, the matrix of builds has gotten a lot more complex.

One thing that threw me for a loop was the binary "pieces" that need to be flashed. At first my binaries weren't through the web installer so I captured what Platform IO was doing:

```
--chip esp32s3 --port "/dev/ttyACM0" --baud 921600 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 8MB
0x0000 /workspaces/WLED/.pio/build/t_qt_pro_8MB/bootloader.bin
0x8000 /workspaces/WLED/.pio/build/t_qt_pro_8MB/partitions.bin
0xe000 /home/vscode/.platformio/packages/framework-arduinoespressif32/tools/partitions/boot_app0.bin
0x10000 .pio/build/t_qt_pro_8MB/firmware.bin
```

Basically, these are artifacts needed for the startup process <https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/startup.html>

While it seems like some of these pieces are common across boards, it seemed most robust if I used all of these artifacts for the flashing process.

# Conclusion

This is the biggest project I've done in quite awhile. I really wanted to give it as much polish as possible, but even so I had to figure out where to call it quits. I decided to try to make it as simple to use as possible, but my idea of simple is probably a bit skewed. I decided not to go with a more arcane interface, and mostly just lean into the already great WLED UI. I'm disappointed I wasn't able to get it running on all ESP32 variants, but I needed to stop somewhere.

Looking forward to using it at my next game, and hopefully it adds some sparkle to the game.
