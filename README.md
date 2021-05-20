Zespre's Blog
=============

[![Build Status](https://drone.internal.zespre.com/api/badges/starbops/blog/status.svg)](https://drone.internal.zespre.com/starbops/blog)

Build the Image
---------------

Choosing what environment to deploy to, "development" or "production".

```bash
$ cd blog/
$ docker build --build-arg JEKYLL_ENV=<ENVIRONMENT> -t zpcc-blog:<VERSION> .
```

Push the newly built image to a image registry.

```bash
$ docker tag zpcc-blog:<VERSION> registry.internal.zespre.com/zpcc-blog:<VERSION>
$ docker push registry.internal.zespre.com/zpcc-blog:<VERSION>
```

Run the Blog
------------

```bash
$ docker run -p 0.0.0.0:8080:80
$ docker run --rm -p 0.0.0.0:8080:80/tcp zpcc-blog:<VERSION>
```
