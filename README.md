# Zoo Modeling

## Clone

1. Get access to [this GIN repo](https://gin.g-node.org/lnnrtwttkhn/zoo-modeling) ([ask Lennart](mailto:wittkuhn@mpib-berlin.mpg.de))
2. Set up [SSH on GIN](https://gin.g-node.org/user/settings/ssh) (recommended)
3. Install the DataLad dataset and retrieve the data (this takes about 1 min.):

```bash
datalad install --get-data --source git@gin.g-node.org:/lnnrtwttkhn/zoo-modeling.git
```

Done! 🎉

## Run

Inside the project directory (you might need to `cd zoo-modeling`), run `make all` to run `sr-modeling.R` which recreates [Figure 3d of the preprint](https://www.biorxiv.org/content/biorxiv/early/2022/02/02/2022.02.02.478787/F3.large.jpg?width=800&height=600&carousel=1).

## Requirements

All R requirements listed in [renv.lock](renv.lock).

## Dataset structure

- All inputs (i.e. building blocks from other sources) are located in
  `inputs/`.
- All custom code is located in `code/`.

## References

> Statistical learning of successor representations is related to on-task replay. Lennart Wittkuhn, Lena M. Krippner, Nicolas W. Schuck. *bioRxiv* 2022.02.02.478787; doi: https://doi.org/10.1101/2022.02.02.478787 
