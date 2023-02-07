---
title: Running Syncthing on ancient QNAP NAS
author: jon
layout: post
categories:
  - Software
image: 2023/qnap_sync_logo_thumb.webp
---

[Syncthing](https://syncthing.net/) is a Dropbox alternative that I've wanted to try out. I decided to set it up to run on my decade old QNAP NAS.

# What I Wanted to Do

After once again running low on Google Drive space, I wanted to explore alternatives for syncing file between my devices. [Syncthing](https://syncthing.net/) is a mature well supported open source project that seemed like it would fit the bill. I haven't dug too deep, but it seems like the main complaints are that it's too complicated for some users.

It works best when syncing between PCs. There's convenient GUI interfaces, and it pretty much just works without having to read the documentation. However, it's a point-to-point syncing service, so you need to have the devices active at the same time for the syncing to occur. I figured set it up on my NAS (network accessible storage) would be a good quick project to provide an always on node for syncing.

# What's a NAS?

Having a NAS used to be a more valuable proposition Before "The Cloud" became the go to for backups and media. The idea is to have a computer connected to some large drives that you could use to self host things like streaming, backup, and file sharing. Usually, they were mainly for LAN usage, but often offered somewhat sketchy ways to access the files over the internet as well. While you could set up a NAS using any old PC, some companies would make dedicated NAS hardware and software to streamline the process.

Back when I was in the market for one 10 years ago, I decided on the [QNAP TS-212](https://www.qnap.com/en-us/product/ts-212). It's continued to receive updates and chug along admirably. It doesn't get too much use these days since everything is streamed, but it can be nice to have for local backups or just storing some large files running a [RAID 1](https://en.wikipedia.org/wiki/Standard_RAID_levels#RAID_1) configuration.

I actually used this NAS for a project ages ago in [Security Camera from a Webcam]({% post_url 2012-11-18-security-camera-from-a-webcam %}).

# Running Syncthing on the QNAP

At the end of the day though, they're still just Linux computers. QNAP has an app store of sorts with built in apps, and people have made third party sites for sharing apps the side-load. I did find someone who packaged Syncthing as a QNAP package <https://qnapclub.eu/en/qpkg/692>, but my device seemed too old to get a binary for.

Instead of trying to get a random package to work, or figure out the packaging myself, I decided I would see if I could just run Syncthing on the QNAP directly.

Looking at <https://syncthing.net/downloads/> the project publishes binaries for a variety of platforms. I looked up the processor in the TS-212 which is a Marvell 6281 1.2GHz. Some further googling revealed it's "fully ARMv5TE-compliant", so I knew that the ARM binary would be the one to try.

Getting SSH access onto the device is super easy <https://www.qnap.com/en/how-to/faq/article/how-do-i-access-my-qnap-nas-using-ssh>. While there is some storage for the NAS itself, it tends to be very small and mostly meant to be read only, so I decided to download the binary to a directory in the RAID. Using `df` I saw that this is mounted to `/share/MD0_DATA/`. All I had to do to run it was extract the binary and make it executable with `chmod`.

This was actually pretty surprising. I've written in the past about [Cross Compiling]({% post_url 2021-04-30-cross-compiling %}), and while I wasn't too surprised that the ARM executable would have the right instruction set, I was fairly surprised that the ABI and GLibc libraries were compatible. I guess either the Syncthing is compiled in a way that provides great backwards compatibility, or the QNAP updates have been keeping the core libraries up to date. The kernel itself is 3.4.6 which was released in 2012 so who knows.

# Setting Up Syncthing for Actual Use

While the application would run, I still had some work to do to actually set it up. As I don't have much experience with Syncthing it took a little trial and error to figure things out from the command line.

The first issue is that I needed to add my NAS as a device on my other devices. While I later found out that the web GUI and Windows desktop app will actually list other nearby devices, I initially tried to add it to my phone. The devices identify themselves with a long ID string and the QNAP would print this to the command line when the process starts up. Rather then type it out I used a QR code generator to make a code to scan with my phone.

The next issue is that I needed to access the web GUI for the application running on the NAS. This is required since I needed to accept the requests to add the NAS from my other devices. By default it is only accessible on the machine it's running on. Initially, I tried to use SSH tunnelling, to access the page, but after having some issues, I realized I could just run `./syncthing --gui-address $MY_LAN_ADDRESS:8384` to make the GUI accessible on the LAN. From there I could go to http://$MY_LAN_ADDRESS:8384 from my PC to control the Syncthing running on the NAS.

Since I wanted Syncthing to run on startup I looked at <https://wiki.qnap.com/wiki/Running_Your_Own_Application_at_Startup>. The challenge here is that normally you can't update the configuration file that runs at startup, so you need to first mount it's location. The easiest way was using:

```bash
/etc/init.d/init_disk.sh mount_flash_config
# Edit the file.
/etc/init.d/init_disk.sh umount_flash_config
```

After testing this, I realized the process wasn't saving the configuration and was generating a new ID. It turns out that it writes to the home directory by default (`/root` in this case). On the QNAP this gets cleared on reboot. This was easy enough to avoid with another CLI flag `./syncthing --home $DIRECTORY_TO_STORE_STATE_TO`

So after mounting the flash config, I used the following command to modify the `autorun.sh`.

```bash
echo "/share/MD0_DATA/Public/Transfer/syncthing-linux-arm-v1.23.0/syncthing --home /share/MD0_DATA/Public/Transfer/syncthing-linux-arm-v1.23.0 --gui-address $MY_LAN_ADDRESS:8384" >> /tmp/nasconfig_tmp/autorun.sh
```

From there things have been working smoothly. Honestly, a bit surprised it was that easy. I can understand why Syncthing can be considered too complex. It has a lot more setup then just using Dropbox, but it's been great for my weird use case.
