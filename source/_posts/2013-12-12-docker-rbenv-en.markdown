---
layout: post
title: 'Docker image with multiple versions of ruby'
date: 2013-12-12 21:40
comments: true
categories: docker
---

[docker-rbev](https://github.com/tcnksm/docker-rbenv)

This can generate 2 Docker images below;

- [tcnksm/rbenv](https://index.docker.io/u/tcnksm/rbenv/): Image which is installed multiple versions of ruby by rbenv
- [tcnksm/rbenv-rubygems](https://index.docker.io/u/tcnksm/rbenv-rubygems/): Image which is installed bundler and basic rubygems to each vesion on the above image

Both are uploaded to [index.docker.io](https://index.docker.io/), so you can use it just by `docker pull`. 

Belows are how to create these images in details.

First, [rbenv-image/Dockerfile](https://github.com/tcnksm/docker-rbenv/blob/master/rbenv-image/Dockerfile) execute just same as you do when you download ruby by rbenv. 

```
FROM base

MAINTAINER tcnksm, https://github.com/tcnksm

RUN apt-get update
RUN apt-get install -y --force-yes build-essential curl git
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get clean

RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
RUN ./root/.rbenv/plugins/ruby-build/install.sh

ADD ./rbenvrc /etc/profile.d/rbenvrc
ADD ./rubies.txt /root/rubies.txt

ENV PATH /root/.rbenv/bin:$PATH

# Install multiple versions of ruby
ENV CONFIGURE_OPTS --disable-install-doc
RUN xargs -L 1 rbenv install < /root/rubies.txt

```



1. To pull base image (`FROM base`)
1. To install packages which is needed for building ruby(`RUN apt-get ...`)
1. To clone [rbenv](https://github.com/tcnksm/docker-rbenv/tree/master)
1. To clone [ruby-build](https://github.com/sstephenson/ruby-build)
1. To add `rbenvrc` which is used for setting environmental variables rbenv into image(`ADD ./rbenvrc /etc/profile.d/rbenvrc`)
1. To add `rubies.txt` which is defined version what you want to install into image
1. Execute `rbenv install ...`

If you want to install other vesions of ruby, edit `rubies.txt`. To generate the image, execute below command, 

``` bash
docker build -t rbenv rbenv-image/
```

And if you want to upload it to index.docker.io, 

``` bash
docker login
docker push rbenv
```

Second, [rbenv-rubygems-image/Dockerfile](https://github.com/tcnksm/docker-rbenv/blob/master/rbenv-rubygems-image/Dockerfile) install bunlder and basic rubygems by Gemfile on rbenv-image generated above.


```
FROM tcnksm/rbenv
MAINTAINER tcnksm, https://github.com/tcnksm

ADD ./Gemfile /root/Gemfile

# Install bundler
RUN . /etc/profile.d/rbenvrc; for v in $(cat /root/rubies.txt); do rbenv global $v; gem install --no-rdoc --no-ri bundler; done

# Install basic rubygems by bundler
RUN . /etc/profile.d/rbenvrc; cd /root/; for v in $(cat rubies.txt); do rbenv global $v; bundle install; done
```

1. To pull rbenv-image (`FROM tcnksm/rbenv`)
1. To add Gemfile into image (`ADD ./Gemfile /root/Gemfile`)
1. To install budler
1. Execute `bundle install`

And,

``` bash
docker build -t rbenv-rubygems rbenv-rubygems-image
```

It's super easy. But I wrote very complicated shellscripts for handling multiple versions. I hope we could write more structual Dockerfile.

And I want to change it more easy to execute test code. 

Reference:

- [Docker for Rubyists](http://www.sitepoint.com/docker-for-rubyists/)
- [docker-plenv-vanilla](https://github.com/miyagawa/docker-plenv-vanilla)
- [Docker Cheat Sheet with examples](https://coderwall.com/p/2es5jw)



