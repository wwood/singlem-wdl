version 1.0

workflow SingleM_SRA {
  input {
    String SRA_accession_num
    String Download_Method_Order
    File? GCloud_User_Key_File
    Boolean? GCloud_Paid
    String? AWS_User_Key_Id
    String? AWS_User_Key
  }
  call download_and_extract_ncbi {
    input:
      SRA_accession_num = SRA_accession_num,
      GCloud_User_Key_File = GCloud_User_Key_File,
      GCloud_Paid = GCloud_Paid,
      AWS_User_Key_Id = AWS_User_Key_Id,
      AWS_User_Key = AWS_User_Key,
      Download_Method_Order = Download_Method_Order
  }
  call singlem {
    input:
      collections_of_sequences = download_and_extract_ncbi.extracted_reads,
      srr_accession = SRA_accession_num
  }
  output {
    File SingleM_tables = singlem.singlem_otu_table_gz
  }
}

task download_and_extract_ncbi {
  input {
    String SRA_accession_num
    String Download_Method_Order
    File? GCloud_User_Key_File
    Boolean? GCloud_Paid
    String? AWS_User_Key_Id
    String? AWS_User_Key
    String dockerImage = "public.ecr.aws/m5a0r7u5/ubuntu-sra-tools:dev7"
  }
  command {
    python /ena-fast-download/bin/kingfisher \
      -r ~{SRA_accession_num} \
      --gcp-user-key-file ~{if defined(GCloud_User_Key_File) then (GCloud_User_Key_File) else "undefined"} \
      ~{if (GCloud_Paid) then ("--allow-paid-from-gcp") else ""} \
      --output-format-possibilities fastq \
      -m ~{Download_Method_Order}
  }
  runtime {
    docker: dockerImage
  }
  output {
    Array[File] extracted_reads = glob("*.fastq")
  }
}

task singlem {
  input { 
    Array[File] collections_of_sequences
    String srr_accession
    String memory = "3.5 GiB"
    String disks = "local-disk 50 SSD"
    String dockerImage = "public.ecr.aws/m5a0r7u5/singlem-wdl:0.13.2-dev7.2c824562"
  }
  command {
    echo starting at `date` >&2 && \
    cat /proc/meminfo >&2 && \
    lscpu >&2 && \
    /opt/conda/envs/env/bin/time /singlem/bin/singlem pipe \
      --forward ~{collections_of_sequences[0]} \
      ~{if length(collections_of_sequences) > 1 then "--reverse ~{collections_of_sequences[1]}" else ""} \
      --archive_otu_table ~{srr_accession}.singlem.json --threads 2 \
      --assignment-method diamond \
      --diamond-prefilter \
      --diamond-prefilter-performance-parameters '--block-size 0.5 --target-indexed -c1' \
      --diamond-prefilter-db /pkgs/53_db2.0-attempt4.0.60.faa.dmnd \
      --min_orf_length 72 \
      --singlem-packages `ls -d /pkgs/*spkg` \
      --working-directory-tmpdir && gzip ~{srr_accession}.singlem.json
  }
  runtime {
    docker: dockerImage
    memory: memory
    disks: disks
    cpu: 2
  }
  output {
    File singlem_otu_table_gz = "~{srr_accession}.singlem.json.gz"
  }
}
