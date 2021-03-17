FROM continuumio/miniconda3
# Don't need all of the dependencies of singlem, because only pipe is going to be run.
RUN conda create -c conda-forge -c bioconda -c defaults -n env python diamond=2.0.8 tempdir biopython hmmer orfm mfqe extern graftm krona pplacer time
RUN echo "source activate env" > ~/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH

# NOTE: The following 2 hashes should be changed in sync.
RUN git clone https://github.com/wwood/singlem && cd singlem && git checkout 39b924d5
RUN echo '__version__ = "0.13.2-dev5.39b924d5"' >singlem/singlem/version.py

# Remove bundled singlem packages
RUN rm -rfv singlem/singlem/data singlem/.git singlem/test singlem/appraise_plot.png

# Removed the individual dmnd files from Rossen's chainsaw'd package, to save space.
ADD spkg_picked_chainsaw20210225.smaller /pkgs

CMD /bin/bash
# /singlem/bin/singlem
