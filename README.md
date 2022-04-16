## docker-deepstack

[![docker hub](https://img.shields.io/badge/docker_hub-link-blue?style=for-the-badge&logo=docker)](https://hub.docker.com/r/vcxpz/deepstack) ![docker image size](https://img.shields.io/docker/image-size/vcxpz/deepstack?style=for-the-badge&logo=docker) [![auto build](https://img.shields.io/badge/docker_builds-automated-blue?style=for-the-badge&logo=docker?color=d1aa67)](https://github.com/hydazz/docker-deepstack/actions?query=workflow%3A"Auto+Builder+CI")

**This is an unofficial image that has been modified for my own needs. If my needs match your needs, feel free to use this image at your own risk.**

Fork of [johnolafenwa/DeepStack](https://github.com/johnolafenwa/DeepStack). (Equivalent to 2022.01.1)

[DeepStack](https://www.deepstack.cc/) is an AI server that empowers every developer in the world to easily build state-of-the-art AI systems both on-premise and in the cloud. The promises of Artificial Intelligence are huge but becoming a machine learning engineer is hard. Build and deploy AI-powered applications with in-built and custom AI APIs, all offline and self-hosted

## Usage

```bash
docker run -d \
  --name=deepstack \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Australia/Melbourne \
  -v <path to data>:/config \
  -p 5000:5000 \
  --restart unless-stopped \
  vcxpz/deepstack
```

[![template](https://img.shields.io/badge/unraid_template-ff8c2f?style=for-the-badge&logo=docker?color=d1aa67)](https://github.com/hydazz/docker-templates/blob/main/hydaz/deepstack.xml)

## Upgrading DeepStack

To upgrade, all you have to do is pull the latest Docker image. We automatically check for Deepstack updates daily. When a new version is released, we build and publish an image both as a version tag and on `:latest`.

## Fixing Appdata Permissions

If you ever accidentally screw up the permissions on the appdata folder, run `fix-perms` within the container. This will restore most of the files/folders with the correct permissions.
