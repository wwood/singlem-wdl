FROM mambaorg/micromamba:0.17.0

# This dockerfile uses cached mounts, so to build use e.g.
# singlem-wdl-local/dockers/singlem$ DOCKER_BUILDKIT=1 docker build .

# Don't need all of the dependencies of singlem, because only pipe is going to be run.
RUN --mount=type=cache,target=/opt/conda/pkgs micromamba install -y -c conda-forge -c bioconda -c defaults -n base \
       python diamond=2.0.13 tempdir biopython hmmer orfm mfqe extern graftm krona pplacer google-cloud-sdk pigz sracat bird_tool_utils_python requests aria2 \
       awscli \
       procps-ng sysstat htop && \
    micromamba clean --all --yes

# RUN echo "source activate base" > ~/.bashrc
# ENV PATH ~/bin:$PATH

# Kingfisher
RUN --mount=type=cache,target=/opt/conda/pkgs micromamba install -y -c conda-forge -c bioconda -c defaults -n base git
RUN git clone https://github.com/wwood/kingfisher-download && cd kingfisher-download && git checkout 88f6d2d
RUN ln -s `pwd`/kingfisher-download/bin/kingfisher /opt/conda/bin/ -v
RUN bash -c 'source ~/.bashrc && kingfisher -h'

# NOTE: The following 2 hashes should be changed in sync.
RUN rm -rf singlem && git clone https://github.com/wwood/singlem && cd singlem && git checkout e97d171
RUN echo '__version__ = "0.13.2-dev37.e97d171"' >singlem/singlem/version.py

# Remove bundled singlem packages
RUN rm -rfv singlem/singlem/data singlem/.git singlem/test singlem/appraise_plot.png

# Install sra-tools from source so it is more likely to work
RUN curl -o a.tar.gz https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/2.11.3/sratoolkit.2.11.3-centos_linux64.tar.gz
RUN tar xf a.tar.gz
RUN rm a.tar.gz
RUN ln -s `pwd`/sratoolkit.2.11.3-centos_linux64/bin/prefetch /opt/conda/bin/ -v
RUN mkdir /home/micromamba/.ncbi
ADD user-settings.mkfg /home/micromamba/.ncbi/

ADD S3.metapackage_20211101.smpkg /mpkg

CMD /bin/bash
