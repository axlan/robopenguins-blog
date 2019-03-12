---
id: 257
title: Security Camera From a Webcam
date: 2012-11-18T23:54:32+00:00
author: jdiamond
layout: post
guid: http://robopenguins.com/wordpress/?p=257
permalink: /2012/11/18/security-camera-from-a-webcam/
categories:
  - Personal
  - Software
  - Uncategorized
---
Here&#8217;s a quick project that came together the evening before a long vacation. In order to get a little piece of mind I wanted to set up a simple security camera on a network accessible storage (NAS) server that I had recently set up. What I wanted was a program that could connect to a USB webcam and send me an email with a photo of any motion that occurred.

<!--more-->

The NAS server was a QNAP which has some security center software built in. It was mainly focused on connecting to networked security cameras, but it did support some basic functionality for webcams. Unfortunately, it did not support any of the motion detection features.

The NAS server let you SSH and install packages with ipkg. I found a package called motion, here&#8217;s a forum post that led me through the basic setup <http://forum.qnap.com/viewtopic.php?p=273345>

Here&#8217;s a copy of the post for posterity:

> &nbsp;
> 
> There&#8217;s an Optware package called &#8220;motion&#8221;, which can do motion detection.
> 
> I installed it a day ago and so far it works very well together with a Logitech USB camera. It can take interval snapshots, and record jpg and/or avi once motion is detected. With a frame rate of 5 and a 640&#215;480 resolution my TS-212 uses around 30% CPU. With a lower frame rate the CPU usage is accordingly lower. In contrary to that, QUSBCam with firmware 3.7.1 took 100% all the time even at one frame per second and quarter VGA resolution.
> 
> To get it working just
> 
>   * install the Optware QPKG
>   * install the motion IPKG
>   * install the nano IPKG (simple text editor for editing the config file)
>   * Activate SSH, if not already active
>   * Use ssh to log onto the NAS
>   * edit the config file /opt/etc/motion.conf by typing 
>     :   `nano /opt/etc/motion.conf`
>     
>     and change the output path to something reasonable, e.g.
>     
>     :   `target_dir /share/Recordings/MyUSBCam`
> 
>   * if you want videos, then you have to activate the switch in the config file, there are lots of comments in the file. Find the entry ffmpeg\_cap\_new and change it from off to on 
>     :   `ffmpeg_cap_new on`
> 
>   * Save the file (Ctrl-O) and exit (Ctrl-X)
>   * Run motion 
>     :   `/opt/etc/init.d/S99motion`
> 
> If you want to start motion at system startup you have to apply the optware startup patch, that you can find somewhere in this forum.

It took me a little bit of fiddling to get things working, but everything worked as advertised. Once a motion is detected for some configurable amount of time, it triggers an event. This event continues until no motion is detected for some amount of time and then the event ends. This would prevent my inbox from getting an inordinate amount of photos. There is a setting on\_event\_start that tells motion to run a command at the start of an event.

I wasted a decent amount of time trying to send an email with a bash command, but I wasn&#8217;t having any luck. I&#8217;m sure it easy if you know what you&#8217;re doing, but most of the packages seemed more geared toward running a mail server then a simple notifier. Eventually I went with a solution I had used in the past, Python.

I installed python and wrote up the following script:

<pre lang="PYTHON" line="1">import smtplib
import sys  

fromaddr = '' 
toaddrs = '' 
msg = 'There was a motion detected!'

# Credentials (if needed)
username = ''
password = ''

# The actual mail send
server = smtplib.SMTP('smtp.gmail.com:587') 
server.starttls()
server.login(username,password)

#get the file name from stdin
file='/share/Recordings/motion/'+sys.stdin.read().strip('n')

# Here are the email package modules we'll need
from email.mime.image import MIMEImage 
from email.mime.multipart import MIMEMultipart 
COMMASPACE = ', '
# Create the container (outer) email message.
msg = MIMEMultipart() 
msg['Subject'] = 'Detection'
msg['From'] = fromaddr
msg['To'] = toaddrs
msg.preamble = 'Detection'
# Assume we know that the image files are all in PNG format
# Open the files in binary mode.  Let the MIMEImage class automatically guess the specific image type.
fp = open(file, 'rb')
img = MIMEImage(fp.read())
fp.close()
msg.attach(img)
# Send the email via our own SMTP server.
server.sendmail(fromaddr, toaddrs, msg.as_string())
server.quit()</pre>

Of course you need to replace the from/to address ,the username, and  the password to the correct values. You would also need to set the file location to the same configuration you used in motion.conf

Then I edited on\_event\_start in motion.conf
:   `on_event_start ls /share/Recordings/motion/ -tr|tail -1|python /home/test/sendtest.py`

This took me a bit to write since I&#8217;m not a super wizard with bash scripting. What this setting does is run these commands when an event occurs. I configured motion to output the webcam images to the folder /share/Recordings/motion/, so this command lists all the files in this directory sorted by time and sends the name of the most recent image into the python script through stdin.

Once that was all done I had the solution that I wanted that worked like a charm while I was away. I would send a few false positives a day, which was actually kind of nice since it let me know things were still working.

All in all not the cleanest system in the world. Networked webcams aren&#8217;t that expensive and would have been much easier to deal with. The whole system isn&#8217;t that secure since of course the whole server could have been stolen and all I would end up with is a few pictures of the perp. Still for something that was thrown together after packing, it fulfilled it&#8217;s purpose.