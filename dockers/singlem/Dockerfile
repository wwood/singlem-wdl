FROM continuumio/miniconda3

ENV USER=root
RUN apt update && \
      apt-get install -y curl unzip && \
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
      unzip awscliv2.zip && \
      ./aws/install

# Don't need all of the dependencies of singlem, because only pipe is going to be run.
RUN conda create -c conda-forge -c bioconda -c defaults -n env python diamond=2.0.13 tempdir biopython hmmer orfm mfqe extern graftm krona pplacer time sra-tools google-cloud-sdk pigz sracat bird_tool_utils_python requests aria2
RUN echo "source activate env" > ~/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH

# Kingfisher
RUN git clone https://github.com/wwood/kingfisher-download && cd kingfisher-download && git checkout aa8cb8ae
RUN ln -s `pwd`/kingfisher-download/bin/kingfisher /usr/bin -v
RUN bash -c 'source activate env && kingfisher -h'

# NOTE: The following 2 hashes should be changed in sync.
RUN rm -rf singlem && git clone https://github.com/wwood/singlem && cd singlem && git checkout 64783d2
RUN echo '__version__ = "0.13.2-dev29.64783d2"' >singlem/singlem/version.py

# Remove bundled singlem packages
RUN rm -rfv singlem/singlem/data singlem/.git singlem/test singlem/appraise_plot.png

# Removed the individual dmnd files from Rossen's chainsaw'd package, to save space.
ADD S3.metapackage_20211101.smpkg /mpkg

CMD /bin/bash
