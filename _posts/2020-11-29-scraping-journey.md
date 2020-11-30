---
title: Scraping a web journal with Selenium
author: jon
layout: post
categories:
  - Software
image: 2020/se_logo.png
---

Last year I kept a daily journal using the Journey android app. After falling off the wagon, I wanted to export my entries to a more durable format, so I wrote a quick script to scrape them with Selenium.

Selenium is a browser automation tool. It lets you control any of the major browsers programmatically and collect data from the rendered pages. I ended up using Selenium over writing the HTTP requests directly since the site uses oauth and all the data is loaded dynamically with Javascript. It's been quite awhile since I'd touched selenium, but I was able to get up and running with it in Firefox with Python in a few minutes, and I really didn't hit any major roadblocks that didn't have answers in the [documentation](https://selenium-python.readthedocs.io/).

I did cheat a bit though. I found it faster to do a couple things manually then to script everything. So I just had the script pause for 20 seconds at the start while I manually logged in and cleared a dialogue.

Actually, the thing I learned the most about was probably XPath. XPath is an expression language for specifying elements in a XML document. I used it extensively here to specify the elements I wanted to interact with in Journey's web app.

Here's the commented code I ended up with.

```python
import time
import os
# location of geckodriver.exe
# I didn't want to add the location to my system path
app_path = 'E:\\Downloads\\'
os.environ["PATH"] += os.pathsep + app_path
from selenium.webdriver.common.by import By
from selenium import webdriver

# Journey doesn't have a "remember my login" option so needs to reautherize each time
url = "https://journey.cloud/auth/google_oauth2"
# use my actual profile to use the cached Google credentials
fp = webdriver.FirefoxProfile('C:\\Users\\A\\AppData\\Roaming\\Mozilla\\Firefox\\Profiles\\9xfddkez.default-1421542590410')

driver = webdriver.Firefox(fp)
driver.get(url)
# sleep while I complete the login, and press the load button once and clear the dialogue
time.sleep(20)

# The app is a single page
# The "Load More…" button just adds more entries at the bottom of the page
# While there are more entries press the "Load More…"
while True:
    try:
        btn_elem = driver.find_elements(By.XPATH, '//button[text()="Load More…"]')
        if len(btn_elem) == 0:
            break
        btn_elem[0].click()
        # Probably a better way to do this, could poll with timeout instead of fixed wait
        time.sleep(2)
    except:
        break

# index for tagging scraped entries
index = 0
# This is the class for the entries' containers
for elem in driver.find_elements(By.XPATH, "//div[contains(@class, 'timelinex-card') and contains(@class, 'entry')]"):
    # folder to save results in
    path = f'out/{index}_data'
    try: 
        os.mkdir(path) 
    except OSError: 
        pass
    # Text of the actual entry
    text_elem = elem.find_elements_by_xpath(".//div[contains(@class, 'cardText')]")
    if len(text_elem) > 0:
        with open(os.path.join(path,'text.txt'), 'w') as fd:
            fd.write(text_elem[0].text)
    # Image used with entry
    # Originally I hoped to access the image data directly, but taking a screenshot of the DOM
    # element seems like a lot less hassle and was fine for my use case.
    image_elem = elem.find_elements_by_xpath(".//div[contains(@class, 'zoomable')]")
    if len(image_elem) > 0:
        with open(os.path.join(path,'image.png'), 'wb') as fd:
            fd.write(image_elem[0].screenshot_as_png)
    # Date and metadata
    footer_elem = elem.find_elements_by_xpath(".//div[contains(@class, 'cardFooter')]")
    if len(footer_elem) > 0:
        with open(os.path.join(path,'footer.txt'), 'w') as fd:
            # This is to handle some non-ascii characters in some of the location names
            try:
                text = footer_elem[0].text.encode("ascii", "ignore")
                fd.write(text.decode())
            except:
                pass
    print(index)
    index += 1

driver.close()
```
