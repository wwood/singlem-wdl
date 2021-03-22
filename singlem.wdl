version 1.0

workflow SingleM_SRA {
  input {
    File SRA_accession_list
    Boolean Data_From_s3
    String AWS_User_Key_Id = ""
    String AWS_User_Key = ""
  }
  call get_run_from_runlist { 
    input: 
      runlist = SRA_accession_list
    }
  scatter(SRA_accession_num in get_run_from_runlist.runarray) {
    if(Data_From_s3) { 
      call download_and_extract_ncbi_s3 {
        input:
          SRA_accession_num = SRA_accession_num,
          AWS_User_Key_Id = AWS_User_Key_Id,
          AWS_User_Key = AWS_User_Key
      }
    }
    if(!Data_From_s3) {              
      call download_and_extract_ncbi {
        input: 
          SRA_accession_num = SRA_accession_num 
      }
    }
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

task download_and_extract_ncbi_s3 {
  input {
    String SRA_accession_num
    String dockerImage = "public.ecr.aws/m5a0r7u5/ubuntu-sra-tools:dev3"
    String AWS_User_Key_Id
    String AWS_User_Key
    Boolean run_local = false
  }
  command <<<
    export AWS_ACCESS_KEY_ID=~{AWS_User_Key_Id}
    export AWS_SECRET_ACCESS_KEY=~{AWS_User_Key}
    ~{if run_local then
    "python /ena-fast-download/ncbi-download.py --download-method prefetch ~{SRA_accession_num}"
    else
    "python /ena-fast-download/ncbi-download.py --download-method aws-cp --allow-paid ~{SRA_accession_num}"
    }
  >>>
  runtime {
    docker: dockerImage
  }
  output {
    Array[File] extracted_reads = glob("*.fastq")
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
    String dockerImage = "public.ecr.aws/m5a0r7u5/singlem-wdl:0.13.2-dev6.cfd1521a"
  }
  command {
    echo starting at `date` >&2 && \
    cat /proc/meminfo >&2 && \
    lscpu >&2 && \
    /opt/conda/envs/env/bin/time /singlem/bin/singlem pipe \
      --forward ~{collections_of_sequences[0]} \
      ~{if length(collections_of_sequences) > 1 then "--reverse ~{collections_of_sequences[1]}" else ""} \
      --archive_otu_table ~{srr_accession}.singlem.json --threads 2 --diamond-package-assignment --assignment-method diamond \
      --diamond-prefilter-performance-parameters '--block-size 0.45' \
      --min_orf_length 72 \
      --singlem-packages `ls -d /pkgs/*spkg` \
      --working-directory /tmp/working && gzip ~{srr_accession}.singlem.json
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
