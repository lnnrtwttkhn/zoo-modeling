FROM r-base:4.2.2
WORKDIR /project

RUN apt-get update

RUN echo 'APT::Get::Install-Recommends "false";' >> /etc/apt/apt.conf

# external dependencies
RUN apt-get install -y pandoc && apt-get clean

# install renv
# details: https://rstudio.github.io/renv/articles/docker.html#creating-docker-images-with-renv
ENV RENV_VERSION 0.16.0
RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"

# copy renv.lock file
COPY renv.lock renv.lock

# specify library paths for package installation
RUN mkdir -p renv
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.dcf renv/settings.dcf

# restore packages specified in the lockfile:
RUN R -e "renv::restore()"