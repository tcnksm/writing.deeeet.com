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

Both are uploaded to [index.docker.io](https://index.docker.io/), so you can use it just by `docker pull`. With these images, you can execute rspec tests for each vesions of ruby in **very clean environment** (it means no depnedency) like Travis CI at local.


``` bash
docker run tcnksm/rbenv-rubygems sh -ex sample.sh
```

``` bash
// sample.sh

. /etc/profile.d/rbenvrc

git clone https://github.com/tcnksm/sample-rb-project project
cd project

for v in 1.9.3-p392 2.0.0-p353
do
  rbenv global $v
  bundle
  rspec
done
            
```

Just it, very easy to execute rspec test. You can execute it repeatedly.

Belows are how to create these images in details.

First, [rbenv-image/Dockerfile](https://github.com/tcnksm/docker-rbenv/blob/master/rbenv-image/Dockerfile) execute just same as you do when you download ruby by rbenv. In other words,

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



