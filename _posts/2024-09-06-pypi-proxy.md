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

# Trying the Cache Mount Approach

This took a lot more trial and error then I was expecting. I guess this isn't a super common use case, but in each step I found I had to grope around blindly for a bit before I found what arguments or configs I needed to modify to overcome the next challenge. The end result at least isn't too complicated. However, once I knew about about the `sharing` setting on the Docker build cache, it seemed like aan all around better option. There's still places where the proxy would make more sense, but the simplicity of not needing to rely on another service wins out for my use case.

In actually testing it though I quickly hit a wall of problems. The biggest issue is that I was trying to run the container as a local user, and the build mounts have multiple problems that make this extremely difficult.

## Change in --no-cache
One of the top answers for how to do this on Stackoverflow is: <https://stackoverflow.com/questions/58018300/using-a-pip-cache-directory-in-docker-builds>

It uses `--no-cache` as part of the build command. At some point Docker changed the behavior of this flag to disable the cache mounts <https://github.com/moby/buildkit/issues/2447>.

## Problems Using Variables in Mount Arguments

There appear to be multiple issues using variables to set fields in configuring the mount. I wanted to set the target directory to a path in the user's home directory, and I wanted to set the user ID to a user specified as a command line argument:
`--mount=type=cache,target=${PIP_CACHE_DIR},uid=${USER_ID},sharing=locked`

Setting the target with a variable appears to work, but seems to silently just not actually cache <https://github.com/moby/buildkit/issues/1173#issuecomment-1635711278>.

Setting the uid with a variable causes the Dockerfile not to parse correctly.

## Bug in File Mode

To get around not being able to set the uid, I tried to set the permissions to allow all users to write to the mount:
`--mount=type=cache,target=/cache/pip,sharing=locked,mode=0777`
This runs, but the directory ends up with the permissions `755`.

This appears to be another bug <https://github.com/moby/moby/issues/47415>.

To work around these bugs I ended up needing to generate a dockerfile with the correct user id:

```bash
#!/usr/bin/env bash

USER_ID=$(id -u)

sed -e "s/__USER_ID__/1000/" Dockerfile_template > Dockerfile_out
docker buildx build --progress=plain --build-arg USER_NAME=$USER --build-arg USER_ID=$USER_ID --build-arg GROUP_ID=$(id -g) -f Dockerfile_out . 2>&1 | tee test.txt
```

Dockerfile_template:
```Dockerfile
FROM python:3.10

ARG PIP_CACHE_DIR=/cache/
RUN mkdir -p ${PIP_CACHE_DIR}

ARG USER_NAME=jdiamond
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g ${GROUP_ID} ${USER_NAME} && \
    useradd --create-home -l -u ${USER_ID} -g ${GROUP_ID} -G sudo,dialout ${USER_NAME} && \
    echo "${USER_NAME}:${USER_NAME}" | chpasswd
RUN chmod 777 /cache
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

RUN python -m venv venv
RUN --mount=type=cache,target=/cache/pip,uid=__USER_ID__,sharing=locked ~/venv/bin/pip --cache-dir=/cache/pip install numpy
```

It's a bit crazy that there are so many weird behaviors and flat out bugs in this portion of the buildkit functionality. The proxy ends up arguably being simpler after all...
