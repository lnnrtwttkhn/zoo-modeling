FROM r-base:4.2.2

ENV RENV_CONFIG_AUTOLOADER_ENABLED FALSE
ENV RENV_AUTOLOAD_ENABLED FALSE

RUN apt-get update

RUN echo 'APT::Get::Install-Recommends "false";' >> /etc/apt/apt.conf
RUN echo 'options(Ncpus=4, repos=structure(c(CRAN="https://cloud.r-project.org")))' > ~/.Rprofile
RUN echo 'installOrQuit <- function(p) {tryCatch(install.packages(p), warning=function(e){q(status=1)})}' >> ~/.Rprofile

# external dependencies
RUN apt-get install -y pandoc && apt-get clean

# prefer binary R packages, if they are available
RUN apt-get update && apt-get install -y \
r-cran-data.table r-cran-nloptr r-cran-optparse \
r-cran-rmarkdown r-cran-car r-cran-ggplot2 \
r-cran-magrittr r-cran-gtools

# add missing source packages
RUN Rscript -e "installOrQuit(c('pacman', 'here', 'lme4', 'assertr', 'renv'))"