FROM mambaorg/micromamba:0.17.0

# This dockerfile uses cached mounts, so to build use e.g.
# singlem-wdl-local/dockers/singlem$ DOCKER_BUILDKIT=1 docker build .

# Don't need all of the dependencies of singlem, because only pipe is going to be run.
RUN --mount=type=cache,target=/opt/conda/pkgs micromamba install -y -c conda-forge -c bioconda -c defaults -n base \
       python diamond=2.0.13 tempdir biopython hmmer orfm mfqe extern graftm krona pplacer time sra-tools google-cloud-sdk pigz sracat bird_tool_utils_python requests aria2 && \
    micromamba clean --all --yes

# RUN echo "source activate base" > ~/.bashrc
# ENV PATH ~/bin:$PATH

# Kingfisher
RUN --mount=type=cache,target=/opt/conda/pkgs micromamba install -y -c conda-forge -c bioconda -c defaults -n base git
RUN git clone https://github.com/wwood/kingfisher-download && cd kingfisher-download && git checkout 5988edd
RUN ln -s `pwd`/kingfisher-download/bin/kingfisher /opt/conda/bin/ -v
RUN bash -c 'source ~/.bashrc && kingfisher -h'

# NOTE: The following 2 hashes should be changed in sync.
RUN rm -rf singlem && git clone https://github.com/wwood/singlem && cd singlem && git checkout e97d171
RUN echo '__version__ = "0.13.2-dev31.e97d171"' >singlem/singlem/version.py

# Remove bundled singlem packages
RUN rm -rfv singlem/singlem/data singlem/.git singlem/test singlem/appraise_plot.png

# Removed the individual dmnd files from Rossen's chainsaw'd package, to save space.
ADD S3.metapackage_20211101.smpkg /mpkg

CMD /bin/bash
