# Robopenguins Project Archive

This is used to document the various projects that I've worked on.

It was imported from my previous Wordpress site.

Project images aren't checked into version control and are found at:
`https://www.robopenguins.com/assets/wp-content/uploads/`

First time
`bundle install`

Local Debug:
`bundle exec jekyll serve --host localhost`

NOTE to test with project image set you need to copy down the images from S3
`aws s3 sync s3://www.robopenguins.com/assets/wp-content/ assets/wp-content/`

Deployed with:
`JEKYLL_ENV=production jekyll build`
`aws s3 sync _site/ s3://www.robopenguins.com/ --delete --exclude="assets/wp-content/*"`
if images were added
`aws s3 sync _site/assets/wp-content/ s3://www.robopenguins.com/assets/wp-content/`


Template from:
https://github.com/wowthemesnet/mediumish-theme-jekyll