#!/usr/bin/env bash
mkdir -p convert
grep -hioP 'src="{{ site.image_host }}/\K(.*?)\.(jpg|png)"' _posts/* | sed -e 's/"$//' > convert/images.txt
grep -hioP 'image: "?\K(20.+)\.(jpg|png)' _posts/* >> convert/images.txt

while read p; do
  withoutext=$(echo $p | sed -e 's/....$//')
  aws s3api head-object --bucket www.robopenguins.com --key "assets/wp-content/uploads/$withoutext.webp" --profile webdev || not_exist=true
  if [ $not_exist ]; then
    echo "$withoutext.webp does not exist"
    aws s3 cp "s3://www.robopenguins.com/assets/wp-content/uploads/$p" convert/image
    cwebp -q 50 convert/image -o convert/image.webp
    aws s3 cp convert/image.webp "s3://www.robopenguins.com/assets/wp-content/uploads/$withoutext.webp" --profile webdev
  else
    echo "$withoutext.webp exists"
  fi
done <convert/images.txt
