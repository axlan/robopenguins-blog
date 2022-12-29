---
title: Server Side Site Analytics
author: jon
layout: post
categories:
  - Software
  - Blogging
image: 2022/analytics/last_year_google_thumb.webp
---

I'm removing Google Analytics from my blog, but still get the view counts. To do this I'm running my own analysis of the HTTP request logs provided by AWS CloudFront.

With Google requiring a migration for their analytics service, I decided now was a good time to bite the bullet and get rid of it. The only problem is that I get a lot of satisfaction to see that at least a few people are looking at this blog, so I wanted a way to get similar data without needing to run client side code.

As I mentioned way back in [Added SSL to Blog]({% post_url 2020-01-25-add-ssl-to-blog %}), this site is currently hosted from an AWS S3 bucket behind a CloudFront CDN. CloudFront has a feature where it will log all the requests to an S3 bucket <https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html>.

This logs are written as a new compressed CSV files every 5 minutes or so in the "Extended Log File Format" standard. Hypothetically, this means the analysis I'm doing here is generic to any web server that logs requests in this format.

# What I Want to Reproduce from Google Analytics  

Since I don't run adds or do anything commercial with this site, I'm just trying to see:

1. How much traffic my site gets.
2. Which pages are the most popular.

To save them for posterity here are the logs since I set up my current blog hosting on AWS.

[<img class="center" src="{{ site.image_host }}/2022/analytics/last_year_google_thumb.webp">]({{ site.image_host }}/2022/analytics/last_year_google.jpg)

[<img class="center" src="{{ site.image_host }}/2022/analytics/all_monthly_traffic_thumb.webp">]({{ site.image_host }}/2022/analytics/all_monthly_traffic.jpg)

[<img class="center" src="{{ site.image_host }}/2022/analytics/all_page_views_thumb.webp">]({{ site.image_host }}/2022/analytics/all_page_views.jpg)

Here's the "life time" views for the top 25 pages on my site.

| Page                                                       | Pageviews | Unique Pageviews | Avg. Time on Page |
|------------------------------------------------------------|-----------|------------------|-------------------|
| [printing-mtg-cards](/printing-mtg-cards/)                 |    30,275 |           25,803 |           0:04:14 |
| [root page](/)                                             |     2,696 |            2,361 |           0:01:31 |
| [toy-avr-os](/toy-avr-os/)                                 |     2,262 |            1,919 |           0:05:15 |
| [opencv-camera-effects](/opencv-camera-effects/)           |     2,062 |            1,709 |           0:04:01 |
| [weather-station](/weather-station/)                       |     1,596 |            1,289 |           0:04:04 |
| [even-more-custom-mtg-cards](/even-more-custom-mtg-cards/) |     1,331 |            1,147 |           0:02:58 |
| [chip-whisperer](/chip-whisperer/)                         |       898 |              772 |           0:05:37 |
| [cross-compiling](/cross-compiling/)                       |       898 |              847 |           0:06:14 |
| [gnuradio-adsb](/gnuradio-adsb/)                           |       809 |              719 |           0:05:15 |
| [nest](/nest/)                                             |       683 |              576 |           0:06:08 |
| [sql-murder-mystery](/sql-murder-mystery/)                 |       665 |              572 |           0:07:54 |
| [tis100-on-fpga](/tis100-on-fpga/)                         |       616 |              548 |           0:02:45 |
| [cat-trolly](/cat-trolly/)                                 |       611 |              541 |           0:03:22 |
| [jindosh-riddle](/jindosh-riddle/)                         |       532 |              479 |           0:03:57 |
| [categories page](/categories.html)                        |       423 |              351 |           0:01:25 |
| [icosahedron-travel-globe](/icosahedron-travel-globe/)     |       409 |              373 |           0:02:52 |
| [cpp-data-memory](/cpp-data-memory/)                       |       367 |              316 |           0:08:57 |
| [portfolio page](/portfolio.html)                          |       362 |              344 |           0:01:36 |
| [roll20-stats](/roll20-stats/)                             |       333 |              291 |           0:06:47 |
| [haunted-doll](/haunted-doll/)                             |       305 |              259 |           0:04:22 |
| [about page](/about.html)                                  |       293 |              275 |           0:01:39 |
| [hacking-ctfs](/hacking-ctfs/)                             |       285 |              266 |           0:06:46 |
| [yo](/yo/)                                                 |       260 |              216 |           0:05:53 |
| [exapunks-optimization](/exapunks-optimization/)           |       235 |              215 |           0:04:13 |
| [x86-boot-loading](/x86-boot-loading/)                     |       232 |              204 |           0:03:30 |
| ...                                                        |       ... |              ... |           ....... |
| Total                                                      |    55,183 |           47,480 |           0:03:40 |
{:.mbtablestyle}

Which is about 140 days of page view time.

# AWS CloudFront Analytics

So it turns out CloudFront has built in analytics. These are accessible from the AWS web console.

[<img class="center" src="{{ site.image_host }}/2022/analytics/cloudfront_viewers_thumb.webp">]({{ site.image_host }}/2022/analytics/cloudfront_viewers.png)

There are a couple of problems though:

 * They can go back a max of 60 days.
 * They only track raw requests and not "unique visitors".
 * There's no API for downloading the data periodically to archive it.

These aren't huge problems, and would pretty much get me what I wanted. However, I found that turning on logging gives me enough data to roughly replicate most of the additional Google Analytics features.

# Limitations and Challenges in Rolling my Own Server Side Analytics

Unfortunately, without any client side code, I'll have a few challenges reproducing some of the site metrics.

1. Unique visitors - While I could try to do something more complicated, I plan on using the IP as a unique identifier for each visitor. While this has some limitations, as long as there isn't some sort of load balancer or proxy being reported instead of the actual requester, this should be good enough to distinguish unique visitors.
2. Bot or not - It would be good to have some sense of how much of my traffic is bot generated. Google Analytics appears to just filter out bot traffic. I have no definitive way to detect bots. However, if a bot isn't trying to hide itself, the user agent string should identify it. This is a bit of a messy solution though since user agent string can be anything.
3. Additional user data - Stuff like the device type, or geographic location. I don't really care that much, and I can get a decent idea of location from IP address and device type from user agent.

On the other hand, in some ways I might get data I was missing with Google Analytics. Since users with adblock and bots probably don't run the analytics script I they are probably not accounted for in the Google Analytics results. Since analytics is mostly concerned with serving ads, this isn't a problem. Here though I can get some rough information that includes these "viewers".

# Enabling and Downloading Logs

I followed the guide in <https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html> to write the logs to an S3 bucket. One gotcha is that the bucket needs "ACLs enabled" to allow the CloudFront service to create files.

I then created a new Policy, Group, and User so I could generate a read only token to access these logs. For reference I used the following policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3-object-lambda:Get*",
                "s3-object-lambda:List*"
            ],
            "Resource": [
                "arn:aws:s3:::MY_BUCKET_NAME",
                "arn:aws:s3:::MY_BUCKET_NAME/*"
            ]
        }
    ]
}
```

With the AWS CLI using the newly generated credentials I could then download the logs with:
`aws s3 sync s3://MY_BUCKET_NAME/ out/`

# Creating a Custom Analytics Dashboard

The code I'll be discussing can be accessed at: <https://github.com/axlan/http_server_log_analytics>

To actually few the logs I wanted to write a simple dashboard. The hardest decision was how I wanted to capture the data. If I wanted this to scale, using AWS lambda to push the logs into a DB as they were generated would probably make the most sense. I wanted some simpler, so I wrote a script that would generate an intermediate CSV of the combined logs which would be loaded into the dashboard app.

The script is <https://github.com/axlan/http_server_log_analytics/blob/main/update_combined_logs.py>. The only attempt at some efficiency is that it tries to detect if there was a previous run, and append to it instead of reprocessing all the logs.

The intermediate CSV has the:
 * Client IP address
 * Reverer URL
 * Requested URL
 * HTTP Status
 * Datetime of request
 * The device/OS/agent derived from the user agent string

These last values from the user agent string are parsed from <https://github.com/ua-parser> which is a project that maintains a regex for getting these values for most use cases from a massive regex. It's the weakest link of my analysis, but seems to do a reasonable job.

This CSV is then loaded into my dashboard code <https://github.com/axlan/http_server_log_analytics/blob/main/run_dashboard.py>. Here's an example:

[<img class="center" src="{{ site.image_host }}/2022/analytics/my_dash_thumb.webp">]({{ site.image_host }}/2022/analytics/my_dash.png)

It is also fairly quick and dirty. There's a lot of additional features and displays I could add. I also load the whole set of requests into memory where I could probably do a lot iteratively if I wanted to.

# Attempted Hacking

One interesting thing I noticed was that some of the bots or bots pretending to be real users would attempt to scan the site for Wordpress vulnerabilities. Most would look for `/wp-login.php`, but some tried as many as 55 different pages.

Fortunately, since my site is just an S3 bucket, I'm not too concerned.
