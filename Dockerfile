FROM ruby:alpine3.18

RUN apk add build-base git

# Tested with 2.5.15
RUN gem install bundler
# Tested with 4.3.3
RUN gem install jekyll

COPY Gemfile* .

RUN bundle install
