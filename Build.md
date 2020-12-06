# Eressea Docker
To build the Docker Image call next command in the folder where `Dockerfile` is located:
```
docker build \
    -t jacsid/eressea \
    --build-arg eressea_branch=develop \
    --build-arg echeck_branch=develop \
    .
```
You can choose to build the image with [Eressea](https://github.com/eressea/server) **master** or **develop** branch.

`EChecker` is currently under development. In the [GitHub Repository](https://github.com/eressea/echeck) only the master branch is available. Because this is the one, which is in active development, the Docker image uses the branch name **develop**.
The older versions are available as Debian [package](https://packagecloud.io/enno/eressea). If you choose `echeck_branch=`**master** the image uses version 4.4.9 

***But note: This version does not run with Debian. It fails with segmentation fault.***

Hence you should bild the image with one of these options:
* --build-arg eressea_branch=develop --build-arg echeck_branch=develop
* --build-arg eressea_branch=master --build-arg echeck_branch=develop