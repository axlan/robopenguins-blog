---
title: Socket Data Timestamping
author: jon
layout: post
categories:
  - Software
  - Work
image: 2025/pixel-art-stopwatch_thumb.webp
---

Another work rabbit hole. Here, I explore trying to determine the precise absolute time, a network packet is received.

- [Motivation](#motivation)
- [Measuring Network Latency Directly](#measuring-network-latency-directly)
- [Clock Syncing](#clock-syncing)
  - [PPS Capture](#pps-capture)
  - [GPSd](#gpsd)
  - [chrony](#chrony)
  - [Using GPS Synced Device as Time Server](#using-gps-synced-device-as-time-server)
- [Host Time Stamping](#host-time-stamping)
  - [HW Time Stamping](#hw-time-stamping)
  - [Python (FusionEngine) Time Stamping](#python-fusionengine-time-stamping)
- [tcp\_dump Time Stamping](#tcp_dump-time-stamping)
- [TCP Vs. UDP Time Stamping](#tcp-vs-udp-time-stamping)

# Motivation

Since PointOne's positioning engine (FusionEngine) may be used to position real-time devices, there was a concern about the latency of the output.

For the purpose of this article, when I talk about latency, I’m referring to the time between when a raw measurement (GNSS, IMU, etc.) is generated, and when the FusionEngine output incorporating it is received by the host.

This time combines:
1. Any delay in the time the raw measurement took to get to the device (e.x. serial transmit time from the receiver)
2. The time the positioning engine took to process the data and generate the message
3. The time the message took to be sent over the transport (e.x. TCP)
4. The time the delay before the host was able to generate the timestamp
5. The accuracy of the host's time stamping clock.

While we can use profiling to measure some elements of these items, in some ways it’s most useful to measure the latency components 1-3 above. This leaves the task of minimizing sources 4-5, to get the value we care about.

# Measuring Network Latency Directly

While it wasn’t the focus of the experiments we’ve done, one objective might be to either directly measure the transport latency, or to exclude it from the message latency to give the portion that’s unavoidable from our application.

For general latency analysis, tools like ss, can give some idea of the network latency (where 192.168.1.180 is the IP of the FusionEngine):

`ss -t -u -i state all '( src = inet:192.168.1.180:* | dst = inet:192.168.1.180:* )'`

<https://man7.org/linux/man-pages/man8/ss.8.html>

tcp_dump / wireshark could be used as well.

To look at individual message latency, the same techniques for timestamp capture and clock syncing could be used to measure the Tx timestamps. It would take some setup, but it shouldn’t be too hard to setup such an experiment if needed.

For the rest of this article, we’ll assume that we want to include the network latency in our measurements.

# Clock Syncing

The main observations that kicked off this analysis is that:
1. We can sync a computers system clock to a GPS receiver with ~1us accuracy
2. We can use this clock to timestamp network packets

Generally we only care about the latency within a couple milliseconds, so this lets us have an accurate measure between messages that can have their origin tied back to a GPS time.

Before diving in, it is worth pointing out that the local GPS sync isn’t necessary. NTP or PTP alone should be able to generally give ~1ms accuracy. However, this will depend on network and local clock conditions. Having the GPS sync avoids these concerns.

## PPS Capture

Linux PPS capture is a very poorly supported feature. The main issue is that it is implemented as a kernel driver that must load the pin configuration from the device tree. See:

<https://docs.kernel.org/driver-api/pps.html>

<https://github.com/torvalds/linux/blob/master/drivers/pps/pps.c>

So you need:
 * A system that has a suitable GPIO pin
 * The ability to include the PPS GPIO driver in the kernel or as a module
 * The device tree to map the pin to the driver

However, the Raspberry Pi OS has a special mechanism that some of the device tree parameters can be loaded at boot instead of needing to be compiled into the device tree:

<https://www.raspberrypi.com/documentation/computers/config_txt.html>

With this, a PPS driver can be mapped to a pin by adding the following to  /boot/firmware/config.txt:

`dtoverlay=pps-gpio,gpiopin=18`

The other issue with using the PPS GPIO driver is that the pin can’t be used for anything else. For testing, I used a jumper to connect the PPS from a receiver to GPIO pins 15 and 18 on the raspi. This let me use libgpiod <https://github.com/brgl/libgpiod/tree/master?tab=readme-ov-file> to cross check the timestamps on the pulses. libgpiod would also let my other applications trigger off PPS events.

For my testing I built the gpiomon tool from source (the package in the Raspberry Pi OS package manager didn’t include the capability to select the time-stamping source):
```sh
$ ./gpiomon -E realtime -e rising -c /dev/gpiochip0 15
2025-07-08T17:14:38.999999730Z  rising  gpiochip0 15 "GPIO15"
2025-07-08T17:14:39.999999537Z  rising  gpiochip0 15 "GPIO15
```

Alternatively, I could use the pps-tools application to get similar results from the PPS driver:
```sh
sudo ppstest /dev/pps0
trying PPS source "/dev/pps0"
found PPS source "/dev/pps0"
ok, found 1 source(s), now start fetching data...
source 0 - assert 1751994957.000002862, sequence: 566741 - clear  0.000000000, sequence: 0
source 0 - assert 1751994957.999999477, sequence: 566742 - clear  0.000000000, sequence: 0
```

**NOTE**: These timestamps show my system clock is already synchronized to the PPS within a couple microseconds.

## GPSd

The main tool for doing this is gpsd <https://gpsd.gitlab.io/gpsd/> .

Even though it’s pretty much the main application for this task, I found gpsd fairly hard to use since it doesn’t give a ton of useful diagnostics, and makes a lot of assumptions on how it’s going to be used.

<https://gpsd.gitlab.io/gpsd/gpsd-time-service-howto.html>

A lot of the complexity here is that GPSd abstracts that the source of the “PPS” might be the serial port that that the receiver is using to send data.

In my experience, when using the PPS driver, it is actually easier to use the chrony NTP application to handle the PPS directly. The only tradeoff is that chrony will need to get the base time over NTP which should only be an issue in a LAN that’s not connected to the internet.

## chrony

Installing chrony <https://chrony-project.org/doc/4.4/chrony.conf.html>  and setting it up as a systemd service allows it to be used as both an NTP client and as a server for other devices.

To setup chrony to sync with a PPS, I can just add the following to /etc/chrony/chrony.conf:
refclock PPS /dev/pps0 refid PPS precision 1e-9

With that included I can reset chrony and check that it’s using the PPS:
```sh
jdiamond@raspberrypi:~ $ sudo systemctl restart chrony
jdiamond@raspberrypi:~ $ chronyc sources -v

  .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
 / .- Source state '*' = current best, '+' = combined, '-' = not combined,
| /             'x' = may be in error, '~' = too variable, '?' = unusable.
||                                                 .- xxxx [ yyyy ] +/- zzzz
||      Reachability register (octal) -.           |  xxxx = adjusted offset,
||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
||                                \     |          |  zzzz = estimated error.
||                                 |    |           \
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
#* PPS                           0   4   377    12   +213ns[ +155ns] +/-  114ns
^- 24-229-44-105-static.cmt>     1   7   377     5  +5966us[+5966us] +/-   45ms
^- time.gslb.hypernoc.io         2   8   377   201  +3800us[+3800us] +/-   37ms
^- clover0.mattnordhoffdns.>     2   8   377   203   -454us[ -454us] +/-   53ms
^- 72-46-53-234.dia-static.>     3   8   377   202   -257us[ -257us] +/-   57ms
jdiamond@raspberrypi:~ $ chronyc tracking
Reference ID    : 50505300 (PPS)
Stratum         : 1
Ref time (UTC)  : Tue Jul 08 18:15:40 2025
System time     : 0.000000060 seconds fast of NTP time
Last offset     : +0.000000082 seconds
RMS offset      : 0.000002157 seconds
Frequency       : 5.430 ppm fast
Residual freq   : +0.000 ppm
Skew            : 0.006 ppm
Root delay      : 0.000000001 seconds
Root dispersion : 0.000012997 seconds
Update interval : 16.0 seconds
Leap status     : Normal
jdiamond@raspberrypi:~ $ sudo ppstest /dev/pps0
trying PPS source "/dev/pps0"
found PPS source "/dev/pps0"
ok, found 1 source(s), now start fetching data...
source 0 - assert 1751998644.000004773, sequence: 570416 - clear  0.000000000, sequence: 0
source 0 - assert 1751998645.000003319, sequence: 570417 - clear  0.000000000, sequence: 0
source 0 - assert 1751998646.000001164, sequence: 570418 - clear  0.000000000, sequence: 0
```

## Using GPS Synced Device as Time Server

Since chrony can be used as an NTP server, sycing other PCs is as simple as adding an allow entry to the chrony config <https://chrony-project.org/doc/4.4/chrony.conf.html#allow> .

With that other PCs on the LAN can use the the raspi as their timeserver. If the other PC is also using chrony, this can be done by adding the raspi as a server entry in the other PCs chrony config:

`server 192.168.1.197 iburst prefer`

Where 192.168.1.197 is the raspi IP address.

The raspi also supports PTP if the PC has the hardware to support it.

# Host Time Stamping

To get the time of reception of a network packet, there’s generally 3 sources you can use:
1. Network interface hardware time stamping - This is added by the NIC’s own clock and processor, so should not be affected by CPU load.
2. Kernel software time stamping - Timestamp added by kernel when getting data from the network driver. May be impacted by high CPU or flood of system calls.
3. User space time stamping - Affected by processing delays within the process, and overall CPU load.

One additional thing to keep in mind, is that if diagnostics are enabled, we expect a lot of small messages to be generated with sensor data for playback. This may make it harder for the host to keep up, and may impact the latency of the networking overall. When trying to evaluate the performance of a customer interface, it should be more representative to use the default FE interface which has diagnostics turned off by default. If latency is a concern, configuring a UDP interface with just the desired data is even better.

## HW Time Stamping

While HW time stamping is ideal, it has a few challenges.

First, only some network hardware and drivers support it.

The Raspberry Pi 5 is a hardware platform that supports HW box.

To check if your network interface supports hardware time stamping:<br>
`sudo ethtool -T <interface_name>`<br>
Look for 'hardware-transmit' and 'hardware-receive' capabilities.

In addition, HW timestamping needs to be explicitly enabled. This can be done by
tools like hwstamp_ctl or tcpdump.<br>
`sudo hwstamp_ctl -i eth0 -r 1`<br>
`timeout 1 sudo tcpdump -j adapter_unsynced -i eth0 > /dev/null`

The last piece is that the network adapter uses it’s own clock that needs to be synced. This can could be done using PTP, but to use the system clock that’s synced to GPS, you need to use the command:<br>
`sudo phc2sys -s CLOCK_REALTIME -c eth0 -O0 -m`

## Python (FusionEngine) Time Stamping

There’s some helper functions I wrote for providing timestamps when collecting data in Python:

<https://github.com/PointOneNav/fusion-engine-client/blob/master/python/fusion_engine_client/utils/socket_timestamping.py>

This allows collecting the kernel, or hw timestamps associated with network data.

For time stamping FusionEngine message, we have the application:

<https://github.com/PointOneNav/fusion-engine-client/blob/master/python/fusion_engine_client/applications/p1_capture.py>

# tcp_dump Time Stamping

Instead of using a Python script to capture the data from the device, tcp_dump can be used instead.

<https://www.tcpdump.org/manpages/tcpdump.1.html>

For an example of capturing all traffic from 192.168.1.180:

`sudo tcpdump -i any -nn -w /tmp/capture.pcap src 192.168.1.180`

One issue is that this will not start and TCP connections. To establish TCP connections to log, you can use netcat:

`netcat 192.168.1.180 30200 > /dev/null`

In addition, you can use hardware timestamps by adding the CLI argument `-j adapter_unsynced`

The captured log has all the raw data, connection information, and timestamps for all the connections to the device. To extract the data and times stamps, you can use the python library:

<https://scapy.readthedocs.io/en/stable/api/scapy.utils.html>

# TCP Vs. UDP Time Stamping

There's no foolproof way to measure TCP latency. The HW/kernel time stamping is much more accurate, but the kernel will combine messages together if the user application waits too long before reading the socket and use the later timestamp. This means it's still impossible to differentiate the user script taking too long and the other sources of data latency.

To have TCP timestamping be as accurate as possible, you'd have a thread that just handled capturing the data with the timestamp which passed them to a separate thread for logging.

However, since UDP messages are packet based, they are not affected by this. I've found that even with diagnostics generating a ton of messages, the timestamps remain accurate even with second long gaps between reading the socket.

Doing a UDP capture with kernel timestamps (for example ./fusion_engine_client/applications/p1_capture.py udp://:33333 --log-timestamp-source=kernel-sw) should be the gold standard in evaluating latency since it seems that it should fairly unambiguously detect "real" latency either from the network or the positing device.
