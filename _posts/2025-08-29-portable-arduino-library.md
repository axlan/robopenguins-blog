---
title: Writing a Portable Arduino Library with Interrupts
author: jon
layout: post
categories:
  - Hardware
  - Software
  - IoT
image: 2025/arduino_irq_thumb.webp
---

I want to be able to write Arduino code that is portable between different microcontrollers. To do this I want to understand how the Arduino framework handles hardware resources and interrupts.

# Why Bother

As I've gained more skills, I've increasingly struggled with how much effort I should put in to making my hobby code useful to other people. Making something work for my narrow use case is much easier than:
 * Making it work as a library that can easily be incorporated into other projects
 * Publishing the library
 * Having clear and well documented interfaces
 * Avoid or hide complex language or system features
 * Work across a variety of platforms or use cases
 * Making it as efficient as possible
 * Handling and communicating all the error cases including user error
 * For embedded code, allowing log messages to be enabled, disabled, or processed with user specified callbacks

I'm not sure how often other people find my code useful. I don't know how much more useful it would be if I put in the huge amount of effort to fulfill all the points mentioned above.

It's especially tricky for embedded code. So much depends on the specific hardware and platform someone is working on. It seems most non-trivial libraries would just write totally different implementations for the different platforms.

One way to get a better sense of how far I should go is by assuming I'm serving a particular narrow audience. Here's what I generally have in mind:
 * Has a solid understanding of the hardware the project targets
 * Has a solid understanding of the programming language and toolchain
 * Is doing something with the same hardware or very similar
 * Reads the code directly to get a basic understanding of what it does

This at least gives me a baseline for how detailed the documentation and comments I write should be.

As for putting my code into easy to use libraries, I've made efforts in the past for an embedded project:

[Writing an Arduino library for Pixel Dice]({% post_url 2024-03-26-pixel-dice-arduino_lib %})

This library can easily be imported into an Arduino or PlatformIO project. It only targets ESP32 family chips though, so anything that actually interacts with hardware is able to take advantage of the Espressif hardware abstraction layer (HAL).

# What I Mean by Portable Arduino Code

Hypothetically, the Arduino framework hides all of the device specific hardware features behind its own abstraction layer. The simplest example is general purpose input and output (GPIO). While each microcontroller may have different details on how you configure a pin to output a digital signal, the Arduino framework hides this behind the functions:
 * [pinMode()](https://docs.arduino.cc/language-reference/en/functions/digital-io/pinMode/)
 * [digitalWrite()](https://docs.arduino.cc/language-reference/en/functions/digital-io/digitalwrite/)

This abstraction comes at a cost though.
 * It may obfuscate what is happening under the hood
 * It may be much less efficient than interfacing with the hardware directly (see [Arduino Fast digitalWrite](https://roboticsbackend.com/arduino-fast-digitalwrite/)).
 * It may use resources like memory or device peripherals unnecessarily
 * It may not expose the full functionality for the particular device being targeted

What makes this even more complicated, is that this can change over time. For instance [analogWrite()](https://docs.arduino.cc/language-reference/en/functions/analog-io/analogWrite/). For Atmel microcontroller based boards, one of the microcontroller's timers is used to turn the output on and off on the digital pins (<https://github.com/arduino/ArduinoCore-avr/blob/master/cores/arduino/wiring_analog.c>). When Espressif boards were first supported by the Arduino framework, it seems like [analogWrite()](https://docs.arduino.cc/language-reference/en/functions/analog-io/analogWrite/) wasn't supported at all, and the recommendation was to use the Espressif LED control library [ledc](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/peripherals/ledc.html). This meant any library that supported ESP32 and AVR boards that used [analogWrite()](https://docs.arduino.cc/language-reference/en/functions/analog-io/analogWrite/) either needed to use C macros to call the correct functions depending on the platform the library was being built for. However, in 2021, the Arduino library updated the `analogWrite()` call for ESP32 boards to use the `ledc` under the hood <https://github.com/espressif/arduino-esp32/blob/3.3.0/cores/esp32/esp32-hal-ledc.c#L772>.

So if you are writing a library, you either need to know how this all works and assume that the library will give a cryptic error if used with old builds of the Arduino framework, or you need to keep using C macros to write separate code for Espressif processors.

Since the Arduino framework has been ported to many different architectures (<https://en.wikipedia.org/wiki/List_of_Arduino_boards_and_compatible_systems>) you would need to understand what portions of the library may be architecture specific, add the C macros with the architecture specific code, and set the `architectures` section in the library's [library.properties file](https://arduino.github.io/arduino-cli/0.35/library-specification/#libraryproperties-file-format). On top of that, since the compilers are often different, you'd either need to use C macros around any features not supported by older compilers, or only write code that

# Writing an Arduino Motor Controller HAL

This section discusses the code in: <https://github.com/axlan/wheel-hal>

While working on [Making a Turtle Bot 1: Hacking a Mint Cleaner]({% post_url 2025-08-21-making-a-turtle-bot-pt1 %}) I needed to send PWM signals to a motor controller, and get the feedback from an encoder to measure wheel speed.

There are plenty of libraries that do this like <https://github.com/ArminJo/PWMMotorControl>, but they didn't support the particular controller I was using. Also, even though it claims to support ESP32, looking at the code there's `#error Encoder interrupts for ESP32 not yet supported`. This goes to my previous section on how difficult writing a general library is. I could make a fork of that library, but I couldn't test all the existing functionality and platforms. Instead, I decided to just write a new one from scratch with exactly the abstraction that I wanted.

For the motor controller class, there wasn't anything particularly complicated. As I previously mentioned, [analogWrite()](https://docs.arduino.cc/language-reference/en/functions/analog-io/analogWrite/) should now work across the platforms I'm interested in, and that's the only hardware interface that class uses.

The encoder was another story though. To accurately measure how many times the encoder triggers, you need to use a hardware interface. The ideal mechanism in a microcontroller is to use a hardware counter. For example, the Atmega328p has a 16bit counter that can be used to count the encoder ticks without needing to interrupt the CPU. This level of access isn't provided by the Arduino framework (and might interfere with the framework using that peripheral for other reasons), so we need to use [attachInterrupt()](https://docs.arduino.cc/language-reference/en/functions/external-interrupts/attachInterrupt/), to maintain the count.

To support multiple independent encoders (for example one for the left wheel, and one for the right), each instance of the encoder class needs the interrupt to update the correct count. When I initially designed this for the ESP32, this was easy to do using the overload of `attachInterrupt()` in `FunctionalInterrupt.h` that takes a `std::function<void(void)>` (See: <https://github.com/espressif/arduino-esp32/blob/master/libraries/ESP32/examples/GPIO/FunctionalInterrupt/FunctionalInterrupt.ino>). This lets the class pass itself to the interrupt so its internal count can be updated.

## What's the Deal with ESP32 IRAM_ATTR / ESP_INTR_FLAG_IRAM

One of the first "gotchas" you find when writing interrupts for the Espressif platforms is that you need to put the handler code in RAM. This is done by marking the interrupt handler function with the `IRAM_ATTR` attribute.

The purpose of this is to avoid the interrupt code needing to be read from flash which might be extremely slow (100's of milliseconds) if it's blocked by another flash operation.

To make the code portable, I'd need to create a special macro to set this attribute only if it's available, like:

```cpp
// For ESP32 platforms, interrupt code should be in IRAM.
#ifdef IRAM_ATTR
#define WHEEL_HAL_IRAM_ATTR IRAM_ATTR
#else
#define WHEEL_HAL_IRAM_ATTR
#endif

void WHEEL_HAL_IRAM_ATTR handleEncoderInterrupt() {
  // Interrupt Code...
}
```

However, when I started digging into how the ESP32 Arduino framework implemented `attachInterrupt()`, I realized it didn't actually use `IRAM_ATTR` internally.

I asked StackOverflow and Reddit about this with mixed results:
 * <https://stackoverflow.com/questions/79729333/does-the-arduino-library-load-its-internal-interrupts-in-iram-on-the-esp32>
 * <https://old.reddit.com/r/esp32/comments/1ml9nc6/why_doesnt_the_arduino_library_use_iram_attr_for/>

Until I had dug in here, I hadn't realized that `IRAM_ATTR` only actually does something if the interrupt is registered with the `ESP_INTR_FLAG_IRAM` flag (See: <https://github.com/espressif/arduino-esp32/blob/3.3.0/cores/esp32/esp32-hal-gpio.c#L193> + <https://github.com/espressif/arduino-esp32/blob/3.3.0/cores/esp32/esp32-hal.h#L48>).

See <https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/system/intr_alloc.html#iram-safe-interrupt-handlers> for the documentation on how this all actually works.

So after all of this, my understanding is that for the ESP32, there's no point in marking the interrupt handler `IRAM_ATTR` if you're using `attachInterrupt()`. The exception is if the ESP32 build uses the `-DCONFIG_ARDUINO_ISR_IRAM=1` compiler flag, where the code will crash if the interrupt handler isn't marked with `IRAM_ATTR`.

This differs from ESP8266 builds where the interrupt handler is actually in RAM <https://github.com/esp8266/Arduino/blob/3.1.2/cores/esp8266/core_esp8266_wiring_digital.cpp#L134> / <https://arduino-esp8266.readthedocs.io/en/3.0.1/reference.html#interrupts> and the `IRAM_ATTR` attributes are always required.

## AVR GCC Issues

As part of making this blog post, I decided to actually test the compilation for an ATmega target.

The first issue I hit was that the AVR compiler didn't support some of the standard c++ C libraries like `cmath`. This was easy enough to fix by just using the c library names like `math.h`.

The next one however was that I hadn't realized `FunctionalInterrupt.h` is not part of the common Arduino framework, and was added in the ESP32/ESP8266 implementations.

To get around this, I could reimplement the functional interrupt logic, or write N functions where N is the max number of encoder instances that can be used.

Since I'm going through this exercise, I made the change to support up to four encoders: <https://github.com/axlan/wheel-hal/commit/2ee7ed4002750455c6b2b85879413dbf6164258c>

# Conclusion

Writing this logic for this library took maybe 15 minutes. Understanding all the specific intricacies for just two architectures took at least a day. This highlights how leaky its abstractions can be once you try to do anything moderately complicated with the hardware.

While it was worthwhile to learn some of the internal intricacies of the Arduino framework, going forward I'll stick to just targeting the architecture I'm actually using for a project.

In a way, this is what's best supported by the Arduino library specification itself. The [library.properties file](https://arduino.github.io/arduino-cli/0.35/library-specification/#libraryproperties-file-format) `architectures` entry either is `*` if there's no architecture specific code, or it needs to enumerate the supported platforms explicitly. The big asterisk on that asterisk is that you might be surprised by what turns out to technically be architecture specific.

Short of a revolution in how embedded development is done, it seems that easily portable code remains a pipe dream.
