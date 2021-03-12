version 1.0

workflow SingleM_SRA {
  input {
    File SRA_accession_list
  }
  call get_run_from_runlist { 
    input: 
      runlist = SRA_accession_list
    }
  scatter(SRA_accession_num in get_run_from_runlist.runarray) {
    call download_and_extract_ncbi {
      input:
        SRA_accession_num = SRA_accession_num
    }
    # call get_reads_from_run { 
    #   input: 
    #     SRA_accession_num = SRA_accession_num
    # }
    # scatter(download_path_suffix in get_reads_from_run.download_path_suffixes) {
    #   call download_ascp { 
    #     input: 
    #       download_path_suffix = download_path_suffix
    #   }
    # }
    call singlem {
      input:
        collections_of_sequences = download_and_extract_ncbi.extracted_reads,
        srr_accession = SRA_accession_num
    }
  }
  output {
    Array[File] SingleM_tables = select_all(singlem.singlem_otu_table_gz)
  }
}

task get_run_from_runlist {
  input { 
    File runlist
    String dockerImage = "ubuntu"
  }
  command <<<
  echo 'hello'
  >>>
  output {
    Array[String] runarray = read_lines(runlist)
  }
  runtime {
    docker: dockerImage
  }
}

task get_reads_from_run {
  input { 
    String SRA_accession_num
    String dockerImage = "tutum/curl"
  }
  command <<<
    curl -k 'https://www.ebi.ac.uk/ena/portal/api/filereport?accession=~{SRA_accession_num}&result=read_run&fields=fastq_ftp' \
    --silent --show-error \
    | grep -Po 'vol.*?fastq.gz' \
    > ftp.txt
  >>>
  output {
    Array[String] download_path_suffixes = read_lines("ftp.txt")
  }
  runtime {
    docker: dockerImage
  }
}

task download_curl {
  input { 
    String download_path_suffix
    String filename = basename(download_path_suffix)
    String dockerImage = "tutum/curl"
  }
  command <<<
    curl \
    --silent --show-error \
    -L \
    ftp://ftp.sra.ebi.ac.uk/~{download_path_suffix} -o ~{filename}
    gunzip -f ~{filename}
    >>>
  runtime {
    docker: dockerImage
  }
  output {
    File extracted_read = basename(filename, ".gz")
  }
}

task download_ascp {
  input { 
    String download_path_suffix
    String filename = basename(download_path_suffix)
    String dockerImage = "mitchac/asperacli"
  }
  command <<<
    ascp -QT -l 300m -P33001 -i /root/.aspera/cli/etc/asperaweb_id_dsa.openssh era-fasp@fasp.sra.ebi.ac.uk:~{download_path_suffix} ~{filename}
    >>>
  runtime {
    docker: dockerImage
  }
  output {
    File collection_of_sequences = basename(filename)
  }
}

task download_and_extract_ncbi {
  input {
    String SRA_accession_num
    String dockerImage = "public.ecr.aws/m5a0r7u5/ubuntu-sra-tools:dev1"
  }
  # TODO: Switch to fasterq-dump, because it's faster? However, cannot directly output FASTA so need to convert
  # fasterq-dump -e 2 -m 1800MB ~{SRA_accession_num}
  # TODO: Switch to using ascp rather than http by changing the docker image. Not sure how that changes what happens in the cloud.
  command <<<
    prefetch ~{SRA_accession_num} && \
    fastq-dump --fasta default ~{SRA_accession_num} 
  >>>
  runtime {
    docker: dockerImage
  }
  output {
    Array[File] extracted_reads = glob("*.fasta")
  }
}

task singlem {
  input { 
    Array[File] collections_of_sequences
    String srr_accession
    String dockerImage = "public.ecr.aws/m5a0r7u5/singlem-wdl:0.13.2-dev5.39b924d5"
  }
  command {
    echo starting at `date` >&2 && \
    /opt/conda/envs/env/bin/time /singlem/bin/singlem pipe \
      --forward ~{collections_of_sequences[0]} \
      ~{if length(collections_of_sequences) > 1 then "--reverse ~{collections_of_sequences[1]}" else ""} \
      --archive_otu_table ~{srr_accession}.singlem.json --threads 2 --diamond-package-assignment --assignment-method diamond \
      --min_orf_length 72 \
      --singlem-packages `ls -d /pkgs/*spkg` \
      --working-directory-tmpdir && gzip ~{srr_accession}.singlem.json
  }
  runtime {
    docker: dockerImage
    # When using 3.7 GiB or more, jobs stay in runnable on AWS batch when c5.large is the only available instance.
    memory: "3.5 GiB"
    cpu: 2
  }
  output {
    File singlem_otu_table_gz = "~{srr_accession}.singlem.json.gz"
  }
}
