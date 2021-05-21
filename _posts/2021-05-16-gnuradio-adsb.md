---
title: Setting Up GNURadio and Tracking Planes
author: jon
layout: post
categories:
  - Software
  - Hardware
image: 2021/gnuradio/ads-b_thumb.webp
---

I bought a cheap [software defined radio (SDR)](https://en.wikipedia.org/wiki/Software-defined_radio), and tracked planes in realtime with ADS-B. This was a bit of a warmup for a bigger project I wanted to use the SDR for. I wanted to get an existing project up and running to make sure my hardware and software environment with in order.

# Setting up an SDR

I bought one of the cheaper SDRs off of Amazon, <https://www.nooelec.com/store/sdr/sdr-receivers/nesdr/nesdr-smart.html>

This selection was mostly to get a cheap SDR that seemed relatively well supported. I didn't do much research so there are likely better options, but I wanted to avoid being overwhelmed by choice. I can say it got the job done for everything I tried with it, but I wasn't doing anything that much have pushed it's capabilities either.

For my purpose I was using the SDR to capture a portion of the RF signals so they could be processed on a PC. There's a lot of nuance in what goes on with SDR before it digitizes the samples into something you can process, from the antenna, to amplifiers, filters, mixers, but at least for this project I got away without having to worry too much about the details of the analogue components.

To set up the SDR with an Ubuntu PC I followed the directions in <https://www.nooelec.com/store/downloads/dl/file/id/72/product/294/nesdr_installation_manual_for_ubuntu.pdf>. Unsurprisingly, things were a bit out of date. The gist of it is that you need to disable the default driver that gets used for the device (dvb_usb_rtl28xxu) and install the correct one:

```shell
sudo echo "blacklist dvb_usb_rtl28xxu" > /etc/modprobe.d/blacklist-dvb.conf 
sudo apt-get install rtl-sdr
restart
```

To do a basic test, I used `gqrx` (`sudo apt install gqrx-sdr`). This tool is a nice simple way to:
  * Configure the SDR
  * See plots of the received frequency spectrum
  * Listen to an audio representation of the data
  * Capture the raw data for processing in another application

Here's the configuration I used to listen to some staticy FM radio:

[<img class="center" src="{{ site.image_host }}/2021/gnuradio/gqrx.webp" alt="agent link">]({{ site.image_host }}/2021/2021/weather/gqrx.web)

The IO device is configured to use my USB SDR, and the frequency is tuned to an FM station that I found by looking for the signals in the spectrum analysis window.

A more in depth guide can be found at <https://payatu.com/blog/Nitesh-Malviya/getting-started-radio-hacking-part-2-listening-fm-using-rtl-sdr-gqrx>

# Testing Out GNURadio by Tracking Planes

Based on some previous projects, I decided to look into using [GNU Radio](https://www.gnuradio.org/) to simplify setting up processing for the SDR data. GNU Radio is one of those huge projects that develops a whole environment that you can slot your project into to take advantage of the tool chains. I think of it holding a similar place to [The Robot Operating System (ROS)](https://www.ros.org/), a machine learning framework like [TensorFlow](https://www.tensorflow.org/), or even some of the cloud frameworks like [Kubernetes](https://kubernetes.io/).

The high level concept is that you can create inter-connectable processing blocks and use the large library of existing blocks. You start with a source like the SDR, and pass it through filters and decoders until you get something that writes to a file or some other sink.

Initially, I was using the GNURadio package from the Ubuntu package manager. It was on an older distro, and while everything worked, I hit issues with it's use of python2. For this documentation effort I decided to retry everything, but use the GNURadio "package manager" PyBombs. 

## Installing GNU Radio with SDR Blocks

PyBomobs is a GNURadio tool for helping with installing blocks and managing the environment. The basic idea is it creates something like a container where you can install the binaries and python libraries you want to associate with an instance of GNURadio. The instructions for setting up a GNURadio instance is explained at <https://github.com/gnuradio/gnuradio#pybombs>

For me, the default recipe installed GNURadio 3.8 to the prefix `~/gnuradio`.

This did not include a block for my SDR, so I needed to install `gr-osmosdr`. However, since some of the dependencies had already switched to GNURadio 3.9, I needed to do the following to get the install to complete:

```shell
➜  pybombs install gr-osmosdr
# ... an error about gr-iqbal only supporting GNURadio 3.9
➜  cd /home/axlan/gnuradio/src/gr-iqbal/
➜  git checkout -t origin/gr3.8
➜  cd -
➜  pybombs install gr-osmosdr
# ... an error about gr-iqbal only supporting GNURadio 3.9
➜  cd /home/axlan/gnuradio/src/gr-osmosdr/
➜  git checkout -t origin/gr3.8
➜  cd -
➜  pybombs install gr-osmosdr
➜  sudo ldconfig
➜  volk_profile
```

With that done I was able to see the `RTL-SDR` block when I ran `pybombs run gnuradio-companion`. `gnuradio-companion` is a graphical tool that lets you place, configurate, and connect the processing blocks.

It's important to note that pybombs uses a mix of the system path and it's own prefix. I got burned quite a few times by not realizing where a certain binary or library were coming from. Throughout this project I needed to run `source ~/gnuradio/setup_env.sh` and always use the install prefix `~/gnuradio/` when possible.

## Plotting planes with gr-adsb

As a test I decided to try to run the project <https://github.com/mhostetter/gr-adsb>.

[ADS-B](https://en.wikipedia.org/wiki/Automatic_Dependent_Surveillance%E2%80%93Broadcast) is a broadcast that planes make to share there current location for tracking. It's un-encrypted and relatively simple. I found this article <https://www.mathworks.com/help/supportpkg/rtlsdrradio/ug/airplane-tracking-using-ads-b-signals.html> particularly useful even though the actual code is Matlab focussed.

The key parameters are:
  * Transmit Frequency: 1090 MHz
  * Modulation: Pulse Position Modulation
  * Data Rate: 1 Mbit/s

So to capture the signal you need to mix down the transmit frequency and use a sample rate of at least 2Msps.

There were a few incompatibilities with the example when I ran it, so I created a fork <https://github.com/axlan/gr-adsb> with the example updated for my SDR.

To get it to install to the pybomb target correctly I needed to build with:

```
cmake -DCMAKE_INSTALL_PREFIX=~/gnuradio ../
make install
```

and make sure I was using the `source ~/gnuradio/setup_env.sh` when running the web server.

Here's what it looked like up and running:

[<img class="center" src="{{ site.image_host }}/2021/gnuradio/ads-b_thumb.webp" alt="agent link">]({{ site.image_host }}/2021/2021/gnuradio/ads-b.png)

I also had to play around a bit with the gain and threshold to get it to reliably detect the transmission.

## Some Potential Improvements

The application is made to all run on a single machine, and would take a little tweaking to allow you to run the GNURadio, webserver, or web browser on different machines.

In addition, it seemed like there were improvements that could be made to the demodulation algorithm. It only works for sampling rates that are a multiple of 1Msps, and seemed like it wouldn't work great as the SNR decreased.

With this under my belt I was ready to move on to the real project [Adding Wifi to Home Weather Station]({% post_url 2021-05-17-weather-station %}) !
