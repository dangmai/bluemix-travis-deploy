BlueMix Travis Deploy
=====================

My custom Bash script to deploy Docker container (built with [Rocker](https://github.com/grammarly/rocker)) to BlueMix from TravisCI.
This is mainly used by other projects and not on its own.
The workflow goes like this:

With `build.sh`:
- The script builds the project using Rocker, which specifies the tag at the end of the Rockerfile.

With `deploy.sh`:
- It then pushes the newly created image tag to Docker Hub.
- It downloads IBM Container Plugin for CloudFoundry,
then pushes the image to BlueMix private repository.
- The script then checks whether there's an existing container;
if yes, it will remove that container and takes away the public IP associated with it.
Then, it runs a new container from the new image,
and gives that container the newly unbounded public IP.

In order to use this, you need to have the following environment variables set:

- `REPO`: must be similar to the tag at the end of the `Rockerfile` in your repo.
- `CONTAINER_NAME`: the name of the container.
This is used in a regular expression, so no special character allowed.
- `DOCKERHUB_USERNAME`, `DOCKERHUB_PASSWORD`, `DOCKERHUB_EMAIL`:
Information about your DockerHub account.
- `BLUEMIX_USERNAME`, `BLUEMIX_PASSWORD`:
Information about your BlueMix account.
- `BLUEMIX_MEMORY`: How much memory to dedicate to this container,
more information at [this page](https://console.ng.bluemix.net/docs/containers/container_cli_reference_cfic.html#container_cli_reference_cfic__run)
- `PUBLIC_IP`: The IP used for the container of this image.

The script can also optionally pass a list of environment variables to `cf ic run`,
for example:

```
./deploy.sh -e HOST=example.com EMAIL=name@example.com
```
