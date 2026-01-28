#!/usr/bin/env bash
set -e

COMMAND=$1

# If image doesn't exist build.
if [[ "$(docker images -q jekyll 2> /dev/null)" == "" ]]; then
  docker build --tag 'jekyll' .
fi


if [[ "${COMMAND}" == "run" ]]; then
    # use --network=host since jekyll server limits connections to localhost.
    docker run -v .:/site -w /site --network=host -it --rm jekyll bundle exec jekyll serve --host 192.168.1.110 -p 4000:4000
elif [[ "${COMMAND}" == "upload" ]]; then
    docker run -v .:/site -w /site -it --rm -e JEKYLL_ENV=production jekyll bundle exec jekyll build
    aws s3 sync _site/ s3://www.robopenguins.com/ --delete --exclude="assets/wp-content/*" --exclude="fatal_core_dump/*"
fi
