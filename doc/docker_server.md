# Docker Server

We provide dnd3 server Docker images using the GitHub container registry.

Images are built on each commit and available using the following tag scheme:

* `ghcr.io/dnd3-org/dnd3:master` (latest build)
* `ghcr.io/dnd3-org/dnd3:<tag>` (specific Git tag)
* `ghcr.io/dnd3-org/dnd3:latest` (latest Git tag, which is the stable release)

See [here](https://github.com/dnd3-org/dnd3/pkgs/container/dnd3) for all available tags.

Versions released before the project was renamed are available with the same tag scheme at `ghcr.io/dnd3/dnd3`.
See [here](https://github.com/orgs/dnd3/packages/container/package/dnd3) for all available tags.

For a quick test you can easily run:

```shell
docker run ghcr.io/dnd3-org/dnd3:master
```

To use it in a production environment, you should use volumes bound to the Docker host to persist data and modify the configuration:

```shell
docker create -v /home/dnd3/data/:/var/lib/dnd3/ -v /home/dnd3/conf/:/etc/dnd3/ ghcr.io/dnd3-org/dnd3:master
```

You may also want to use [Docker Compose](https://docs.docker.com/compose):

```yaml
---
version: "2"
services:
  minetest_server:
    image: ghcr.io/dnd3-org/dnd3:master
    restart: always
    networks:
      - default
    volumes:
      - /home/dnd3/data/:/var/lib/dnd3/
      - /home/dnd3/conf/:/etc/dnd3/
    ports:
      - "30000:30000/udp"
      - "127.0.0.1:30000:30000/tcp"
```

Data will be written to `/home/dnd3/data` on the host, and configuration will be read from `/home/dnd3/conf/dnd3.conf`.

**Note:** If you don't understand the previous commands please read the [official Docker documentation](https://docs.docker.com) before use.
