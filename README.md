Zespre's Blog
=============

Build the Image
---------------

Choosing what environment to deploy to, "development" or "production".

```bash
$ cd blog/
$ docker build --build-arg JEKYLL_ENV=<ENVIRONMENT> -t zpcc-blog:<VERSION> .
$ docker tag zpcc-blog:<VERSION> registry.internal.zespre.com/zpcc-blog:<VERSION>
$ docker push registry.internal.zespre.com/zpcc-blog:<VERSION>
```

Deploy the Blog
---------------

```bash
$ kubectl apply -f *.yaml
```
