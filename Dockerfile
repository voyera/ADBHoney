FROM alpine:3.8

ENV ALPINE_VERSION=3.8

# These are always installed. Notes:
#   * dumb-init: a proper init system for containers, to reap zombie children
#   * bash: For entrypoint, and debugging
#   * python: the binaries themselves
#   * py-setuptools: required only in major version 2, installs easy_install so we can install Pip.
ENV PACKAGES="\
  bash \
  python2 \
  py-setuptools \
"

RUN echo \
  # replacing default repositories with edge ones
  && echo "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/testing" > /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/community" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main" >> /etc/apk/repositories \
  # Add the packages, with a CDN-breakage fallback if needed
  && apk add --no-cache $PACKAGES || \
    (sed -i -e 's/dl-cdn/dl-4/g' /etc/apk/repositories && apk add --no-cache $PACKAGES) \
  # turn back the clock -- so hacky!
  && echo "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main/" > /etc/apk/repositories \
  # && echo "@community http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/community" >> /etc/apk/repositories \
  # && echo "@testing http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/testing" >> /etc/apk/repositories \
  # && echo "@edge-main http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
  # make some useful symlinks that are expected to exist
  && if [[ ! -e /usr/bin/python ]];        then ln -sf /usr/bin/python2.7 /usr/bin/python; fi \
  && if [[ ! -e /usr/bin/python-config ]]; then ln -sf /usr/bin/python2.7-config /usr/bin/python-config; fi \
  && if [[ ! -e /usr/bin/easy_install ]];  then ln -sf /usr/bin/easy_install-2.7 /usr/bin/easy_install; fi \
  # Install and upgrade Pip
  && easy_install pip \
  && pip install --upgrade pip \
  && if [[ ! -e /usr/bin/pip ]]; then ln -sf /usr/bin/pip2.7 /usr/bin/pip; fi \
  && echo

# Copy in the entrypoint script -- this installs prerequisites on container start.
RUN pip install hexdump
RUN mkdir -p /ADBHoney/data
COPY main.py /ADBHoney/main.py
COPY protocol.py /ADBHoney/protocol.py
EXPOSE 5555/tcp

# These packages are not installed immediately, but are added at runtime or ONBUILD to shrink the image as much as possible. Notes:
#   * build-base: used so we include the basic development packages (gcc)
#   * linux-headers: commonly needed, and an unusual package name from Alpine.
#   * lib6-compat: compatibility libraries for glibc
#   * python2-dev: are used for gevent e.g.
#   * git: to ease up clones of repos
ENV BUILD_PACKAGES="\
  build-base \
  linux-headers \
  libc6-compat \
  python2-dev \
  git \
"

# Entry points runs main.py indefinitly.
#ENTRYPOINT ["/usr/bin/dumb-init", "bash", "python /ADBHoney/main.py"]
ENTRYPOINT ["python", "/ADBHoney/main.py"]
