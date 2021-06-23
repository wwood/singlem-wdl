FROM continuumio/miniconda3

ENV USER=root
RUN apt update && \
      apt-get install -y curl unzip && \
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
      unzip awscliv2.zip && \
      ./aws/install

# Don't need all of the dependencies of singlem, because only pipe is going to be run.
RUN conda create -c conda-forge -c bioconda -c defaults -n env python diamond=2.0.9 tempdir biopython hmmer orfm mfqe extern graftm krona pplacer time sra-tools google-cloud-sdk pigz ncbi-vdb ncbi-ngs-sdk
RUN echo "source activate env" > ~/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH

# sracat
RUN git clone https://github.com/wwood/KWAGE && cd KWAGE && git checkout 80d163c1
RUN sed -i 's%^SRA_PATH.*%SRA_PATH = /opt/conda/envs/env%' KWAGE/sracat/Makefile
RUN apt install -y build-essential 
RUN apt install -y zlib1g-dev
RUN cd KWAGE/sracat && make
RUN cp KWAGE/sracat/sracat /usr/bin -v
RUN sracat -h

# Kingfisher
RUN git clone https://github.com/wwood/kingfisher-download && cd kingfisher-download && git checkout 87acece
RUN ln -s `pwd`/kingfisher-download/bin/kingfisher /usr/bin -v
RUN bash -c 'source activate env && pip install bird_tool_utils'
RUN bash -c 'source activate env && kingfisher -h'

# NOTE: The following 2 hashes should be changed in sync.
RUN git clone https://github.com/wwood/singlem && cd singlem && git checkout 4ba1c49
RUN echo '__version__ = "0.13.2-dev25.4ba1c49"' >singlem/singlem/version.py

# Remove bundled singlem packages
RUN rm -rfv singlem/singlem/data singlem/.git singlem/test singlem/appraise_plot.png

# Removed the individual dmnd files from Rossen's chainsaw'd package, to save space.
ADD 2.0-attempt4-chainsaw-keep-tree.trim5.chainsaw /pkgs
ADD 53_db2.0-attempt4.0.60.faa.dmnd /pkgs
ADD 53_db2.0-attempt4.0.60.faa.dmnd.seed_idx /pkgs

CMD /bin/bash
# /singlem/bin/singlem
