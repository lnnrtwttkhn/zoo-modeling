# Zoo Modeling

## Clone

1. Get access to [this GIN repo](https://gin.g-node.org/lnnrtwttkhn/zoo-modeling) ([ask Lennart](mailto:wittkuhn@mpib-berlin.mpg.de))
2. Set up [SSH on GIN](https://gin.g-node.org/user/settings/ssh) (recommended)
3. Install the DataLad dataset and retrieve the data (this takes about 1 min.):

```bash
datalad install --get-data --source git@gin.g-node.org:/lnnrtwttkhn/zoo-modeling.git
```

Done! 🎉

## Add GIN remote

Following a `datalad clone` from GitLab, you need to configure the GIN remote:

```bash
datalad siblings add -s gin --url git@gin.g-node.org:/lnnrtwttkhn/zoo-modeling.git
```

```bash
datalad siblings configure -s origin --publish-depends gin
```

## Run

Inside the project directory (you might need to `cd zoo-modeling`), run `make all` to run `sr-modeling.R` which recreates [Figure 3d of the preprint](https://www.biorxiv.org/content/biorxiv/early/2022/02/02/2022.02.02.478787/F3.large.jpg?width=800&height=600&carousel=1).

## Requirements

All R requirements listed in [renv.lock](renv.lock).

## Docker

The following instructions are only needed for building the **Docker** container.

- The recipe for the Docker container is specified in [this Dockerfile](.docker/modeling/Dockerfile)
- To get the required R packages out of the `renv` environment, the following command is helpful:

```R
unique(renv::dependencies()$Package)
```

- The container can be build by running `make docker-build` (see [Makefile](Makefile))
- The container can be pushed to the [container registry](https://git.mpib-berlin.mpg.de/wittkuhn/zoo-modeling/container_registry) by running `make docker-push` (see [Makefile](Makefile))

## Tardis

On Tardis, we can't use docker, so we need to create an [Apptainer](https://apptainer.org/) (formely known as "Singularity").

- On Tardis, an apptainer (aka. singularity) container can be build from the Docker file by running `make apptainer-pull` (see [Makefile](Makefile)).
This will generate an apptainer called `modeling.sif` that is used on the cluster.
The command basically pulls the Docker container from the container registry and turns it into an Apptainer called `modeling.sif`.
- The command will ask you for login details for the container resgitry.
If you are a repository maintainer, your MPIB credentials should work!

## Dataset structure

- All inputs (i.e. building blocks from other sources) are located in
  `inputs/`.
- All custom code is located in `code/`.

## References

> Statistical learning of successor representations is related to on-task replay. Lennart Wittkuhn, Lena M. Krippner, Nicolas W. Schuck. *bioRxiv* 2022.02.02.478787; doi: https://doi.org/10.1101/2022.02.02.478787 
