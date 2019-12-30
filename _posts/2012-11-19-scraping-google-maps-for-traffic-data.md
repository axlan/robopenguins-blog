---
title: Scraping Google Maps for Traffic Data
date: 2012-11-19T11:26:53+00:00
author: jon
layout: post
categories:
  - Software
---
I have a daily commute that I drive down the US 101 highway. The length of the drive can vary immensely with traffic, and I&#8217;ve always been curious what the optimal departure times are. I decided to gather data to solve this empirically, and went on an adventure in finding the right tool for the job.

I thought about timing my drive, but that would only gather data about my current commute times. I decided that the easiest way to get a rough sense of the best drive time, and how much it mattered would be to get the traffic estimates from a web service. Unfortunately, I was unable to find any site that offered traffic estimates for any time besides the present. If I wanted to gather information about how the estimates changed over time I would have to collect the data myself.

At first I thought that I could just write a simple HTTP client that would query a web service with my commute information, and then parse out the traffic information. I quickly learned that Google Maps tries to prevent this sort of behavior. I may have been able to get around this, but even the on sites that did allow me to download the html I couldn&#8217;t parse out the traffic data since it was populated with the pages javascript.

I figured this out by playing with the developers console in chrome. I could pull the information out from the page loaded in chrome by writing javascript. Unfortunately, executed my custom javascript on a page turned out to be a little tricky. I could do it through the developers console, or by writing bookmarklets, but I wanted a more automated system that could easily be scheduled and produce file output.

My first instinct was to try to write some sort of (cross site scripting) XSS hack. What this would do is load my page with my javascript along with the page containing the traffic info. My code would then access the traffic information and do something with it. I quickly realized that this was a bad idea for all sorts of reasons. This is exactly the sort of behavior that a virus would have, and all of these sorts of operations are made nigh impossible by browser security features and language limitations on javascript.

I then remembered that there were special scripting plugins for browsers that were made to run custom code on pages as they load. The most popular is for Firefox and is called Greasemonkey. Well I was able to use Greasemonkey to access the traffic information on Google Maps, but I wasn&#8217;t able to write it to a file. This is an intentional limitation of Greasemonkey and is there for security reasons. In any case doing the kind of repeated automatic data collect that I was hoping for, wouldn&#8217;t have been particularly natural in Greasemonkey anyway.

I finally found a solution that worked nearly perfectly in an unusual place. Apparently, it&#8217;s not uncommon to use tools originally designed for automated web site testing to do the sort of javascript scraping that I was trying to accomplish. I quickly settled on Selenium as my system. The key feature that Selenium offered was its Firefox plugin. This IDE let me perform the query and select the data I wanted in a very natural way by using the browser. Once I got the commands I needed I was able to export this to python code to wrap a loop around and perform the logging of the information. Here&#8217;s my modified version of the generated code:

<pre lang="PYTHON" line="1">from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
import unittest, time, re
import datetime

SLEEP_TIME=60*10
END_TIME=9

class MapTest(unittest.TestCase):
	def setUp(self):
		self.driver = webdriver.Firefox()
		self.driver.implicitly_wait(30)
		self.base_url = "http://maps.google.com/"
		self.verificationErrors = []
	
	def test_map(self):
		now=datetime.datetime.now()
		driver = self.driver
		with open(now.strftime("%m_%d_%Y_%H_%M_")+"trafficLog.txt", 'w') as f:
			while datetime.datetime.now().hour&lt;END_TIME:
				driver.get(self.base_url + "/")
				driver.find_element_by_id("d_launch").click()
				driver.find_element_by_id("d_d").clear()
				driver.find_element_by_id("d_d").send_keys("My Address, CA")
				driver.find_element_by_id("d_daddr").clear()
				driver.find_element_by_id("d_daddr").send_keys("Work Address, CA")
				driver.find_element_by_id("d_sub").click()
				driver.find_element_by_id("d_sub").click()
				for i in range(60):
					try:
						if driver.find_element_by_css_selector("div.altroute-rcol.altroute-aux > span").is_displayed(): break
					except: pass
					time.sleep(1)
				else: self.fail("time out")
				variable1 = driver.find_element_by_css_selector("div.altroute-rcol.altroute-aux > span").text
				f.write(datetime.datetime.now().strftime("%H:%M")+" - "+variable1+"n")
				f.flush()
				time.sleep(SLEEP_TIME)
	
	def is_element_present(self, how, what):
		try: self.driver.find_element(by=how, value=what)
		except NoSuchElementException, e: return False
		return True
	
	def tearDown(self):
		self.driver.quit()
		self.assertEqual([], self.verificationErrors)

if __name__ == "__main__":
	unittest.main()</pre>

I then scheduled this, and a slightly modified version of the script for my home commute, to run at the earliest I would consider starting my trips. The code runs until the hour specified by END_TIME, and makes a file with the start time in the name as an output. By collecting this and pulling out the specific traffic information I should have all the info I need.

This is still not a perfect solution. I in order to run this you at least need to have python and its Selenium client installed. Selenium must actually run the browser in order to do the data collection, so you can&#8217;t really have it run in the background. I decided to mitigate this issue by having it run on a virtual machine. All in all a much more complicated solution then I was expecting, but at least it was time better spent then sitting in traffic.