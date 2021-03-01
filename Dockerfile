FROM continuumio/miniconda3
# Don't need all of the dependencies of singlem, because only pipe is going to be run.
RUN conda create -c conda-forge -c bioconda -c defaults -n env python=3.6 diamond=2.0.7 tempdir biopython dendropy pandas biom-format orator squarify matplotlib-base hmmer h5py orfm mfqe graftm extern
RUN echo "source activate env" > ~/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH

# NOTE: The following 2 hashes should be changed in sync.
RUN git clone --branch dev https://github.com/wwood/singlem && cd singlem && git checkout 6dbe5e70
RUN echo '__version__ = "0.13.2-dev1.6dbe5e70"' >singlem/singlem/version.py

# Remove bundled singlem packages
RUN rm -rfv singlem/singlem/data

CMD /bin/bash
# /singlem/bin/singlem