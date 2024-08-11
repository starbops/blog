Zespre's Blog
=============

[![build and publish workflow](https://github.com/starbops/blog/actions/workflows/push.yml/badge.svg)](https://github.com/starbops/blog/actions/workflows/push.yml)
[![release](https://img.shields.io/github/v/release/starbops/blog)](https://github.com/starbops/blog/releases)

The source of https://blog.zespre.com/.

## Development

If you would like to build the source or spin up a Hugo server, please make sure to init and update the theme submodule first:

```shell
git submodule update --init --recursive
```

After the changes have been made, run the following command to build a container image and push to the remote:

```shell
# Please make sure you have already logged in to the remote registry
make docker-buildx IMG=<REPO>/blog:<TAG>
```

## Deployment

Each new commit pushed to the `main` or `release` branch will trigger the auto-build and deploy pipeline with Cloudflare Pages.

- Staging: `main` branch
- Production: `release` branch

## How to Contribute

1. Clone the repository
2. Checkout a new branch from the `main` branch for the new post PR
3. Put your new post under `content/posts/` with its own directory
4. Ensure there's no syntax or stylish erorrs by running `make lint`
5. (Optional) Spin up a local server to see the rendered output using a browser by running `make run`
6. Commit the changes and push to the remote
7. Create a new PR targeted the `main` branch

## Rollout to Production

1. Clone the repository
2. Checkout to the `release` branch (to ensure the branch is up-to-date please run `git pull --rebase`)
3. Checkout  a new branch for the release PR
4. Cherry-pick the commits on the `main` branch
5. Bump the `.params.version` field in `config/_default/hugo.yaml` with a new version
6. Commit the changes and push to the remote
7. Create a new PR targeted the `release` branch

Note: we only tag versions on the `release` branch.
