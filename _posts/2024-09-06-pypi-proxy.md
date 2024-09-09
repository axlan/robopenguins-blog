---
title: PyPI Proxying for Docker Builds
author: jon
layout: post
categories:
  - Software
  - Work
image: 2024/pypi.webp
---

I wanted to improve our CI system by caching PyPI data locally. I saw that there's a project to do this, but I didn't see any good examples actually using it.

Normally, when using pip to install Python packages, pip caches the downloaded files automatically. However, our Dockerized CI use case made this difficult to take advantage of.

There are two ways to do this:

1. Mount a cache during the build: <https://stackoverflow.com/questions/58018300/using-a-pip-cache-directory-in-docker-builds>
2. Use a proxy server that create a local cache: <https://github.com/EpicWink/proxpi>

The main advantage of `1.` is that it's a bit simpler. My main concern with it is that multiple builds could occur in parallel that might cause issues. We had seen instance when running multiple instances of pip simultaneously caused the cache to become corrupted. This may have been fixed in more recent pip releases <https://github.com/pypa/pip/issues/12361>.
#### UPDATE
After posting this article, a [Hacker News commenter](https://news.ycombinator.com/item?id=41476425) mentioned that there are ways to control concurrent access to the cache mount <https://docs.docker.com/reference/dockerfile/#run---mounttypecache>. This should address the corruption issue for Docker builds. The remaining issue would be reusing the cache for Docker runs as well, if needed. Theoretically, that could be managed with some sort of lock file.


The main advantage of `2.` is that a single server could be used by multiple machines. Since I didn't know what this would actually entail, I gave it a shot.

# Running Proxpi

Running proxpi is fairly straightforward. <https://github.com/EpicWink/proxpi> give instructions for running in a Docker container, or directly in Python. Since I didn't want to rely on the host Python, I used the docker container, and used a docker compose file:

```yaml
services:
    proxpi:
        container_name: proxpi
        restart: always
        image: 'epicwink/proxpi:latest'
        ports:
          - '5000:5000'

networks:
  default:
    name: jenkins_ci_shared
```

What this does in addition to just running the application in Docker, is to set it up as a service that will start on boot, and for it to join a network named `jenkins_ci_shared`. Other containers in the network can connect to it using the docker DNS at `proxpi:5000`. This service can then be started with `docker compose -f proxpi_compose.yaml up -d`. This docker compose file is the equivalent to `docker network create jenkins_ci_shared && docker run -d --restart=always --net=jenkins_ci_shared -p 5000:5000 --name=proxpi epicwink/proxpi`.

# Using proxpi

To use it, you need to configure pip to use this index, and to trust it. Here's an example running in a fresh container:
```bash
docker run -it --net=jenkins_ci_shared python:3.12 bash

# Go through proxy for initial download. The `--no-cache --force-reinstall` ensure that it tries to redownload.
pip install -v --no-cache --force-reinstall --index-url=http://proxpi:5000/index/ --trusted-host=proxpi numpy
# Get cached download from proxy.
pip install -v --no-cache --force-reinstall --index-url=http://proxpi:5000/index/ --trusted-host=proxpi numpy

# Try again without proxy.
pip install -v --no-cache --force-reinstall numpy

```

I used the tool `bmon` to monitor the network usage to prove to myself it was actually working.

[<img class="center" src="{{ site.image_host }}/2024/cache_picture.png" width="100%">]({{ site.image_host }}/2024/dice-box/jewel_box.jpg)

Here you can see the two spikes corresponding to the initial download, then when I reinstalled without the cache.


As an alternative to specifying --index-url and --trusted-host in the command line each time, you can add them to a `pip.conf` file:

```conf
[global]
index-url=http://proxpi:5000/index/
[install]
trusted-host=proxpi
```

Initially, I tried to also leave `extra-index-url=http://pypi.python.org/pypi` as a fallback, but it turns out that there's no way to ensure that it doesn't get used instead of the proxy (<https://stackoverflow.com/questions/67253141/python-pip-priority-order-with-index-url-and-extra-index-url>) causing the image to be downloaded over WAN instead of the cache.

# Using proxpi in a Docker Build

It took a few tries before I managed to use proxpi in a Docker build. The challenge was that I was using `docker buildx` for including secrets in the build. That makes it difficult to make sure the build had access to the Docker `jenkins_ci_shared` network <https://github.com/moby/buildkit/issues/978>. It appears to be possible through a multi-step process <https://superuser.com/questions/1709975/docker-build-use-a-containers-network>, but in the end I used:

```bash
# Load the SSH keys into the docker container to access the private repos.
# Use the host user to avoid permisions issues when accessing other secrets.
eval $(ssh-agent)
ssh-add
docker buildx build \
  --build-arg USER_NAME=$USER \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g) \
  --network=host \
  --ssh default=$SSH_AUTH_SOCK \
  -f "$SCRIPT_DIR/Dockerfile" \
  -t $IMAGE_NAME "$REPO_ROOT"
```
The `--network=host` line let's the builder access the host network and connect to the proxpi as `localhost:5000`

# Conclusion

This took a lot more trial and error then I was expecting. I guess this isn't a super common use case, but in each step I found I had to grope around blindly for a bit before I found what arguments or configs I needed to modify to overcome the next challenge. The end result at least isn't too complicated.

Now I'm just left with my original question of proxpi versus mounting a cache volume. Unfortunately, I don't have a a great idea of how robust these solutions will be when they're being used in parallel, possibly by different versions of Python and pip. Since we've had issues with the shared file approach, I think I'm going to use the proxy for production (and not just due to sunk cost).

#### UPDATE
Knowing about the `sharing` setting on the Docker build cache, has pushed me back to using this approach instead. There's still places where the proxy would make more sense, but the simplicity of not needing to rely on another service wins out for my use case.
