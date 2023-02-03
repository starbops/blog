Zespre's Blog
=============

[![Build Status](https://drone.internal.zespre.com/api/badges/starbops/blog/status.svg)](https://drone.internal.zespre.com/starbops/blog)

Testing
-------

```bash
make test
```

Build the Image
---------------

Choosing what environment to deploy to, "development" or "production".

```bash
JEKYLL_ENV="development" VERSION="v0.1.0" make build
```

Run the Blog
------------

```bash
VERSION="v0.1.0" make run
```
