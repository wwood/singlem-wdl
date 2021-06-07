version 1.0

workflow SingleM_SRA {
  input {
    String SRA_accession_num
    Int metagenome_size_in_gbp
    String Download_Method_Order
    File? GCloud_User_Key_File
    Boolean GCloud_Paid
    String? AWS_User_Key_Id
    String? AWS_User_Key
  }
  call singlem {
    input:
      SRA_accession_num = SRA_accession_num,
      metagenome_size_in_gbp = metagenome_size_in_gbp,
      GCloud_User_Key_File = GCloud_User_Key_File,
      GCloud_Paid = GCloud_Paid,
      AWS_User_Key_Id = AWS_User_Key_Id,
      AWS_User_Key = AWS_User_Key,
      Download_Method_Order = Download_Method_Order,

      # collections_of_sequences = download_and_extract_ncbi.extracted_reads,
      # srr_accession = SRA_accession_num,
      # metagenome_size_in_gbp = metagenome_size_in_gbp
  }
  output {
    File SingleM_tables = singlem.singlem_otu_table_gz
  }
}

task singlem {
  input { 
    #Array[File] collections_of_sequences
    # String srr_accession
    Int metagenome_size_in_gbp
    String dockerImage = "gcr.io/maximal-dynamo-308105/singlem:0.13.2-dev21.6634f90"

    String SRA_accession_num
    String Download_Method_Order
    File? GCloud_User_Key_File
    Boolean GCloud_Paid
    String? AWS_User_Key_Id
    String? AWS_User_Key                        
  }
  
  Int disk_size = metagenome_size_in_gbp * 3 + 10
  String disk_size_str = "local-disk "+ disk_size + " HDD"
  Int preemptible_tries = if (metagenome_size_in_gbp > 100) then 0 else 3
  Int ram = 3 + (metagenome_size_in_gbp / 50)
  String ram_str = ram + ".5 GiB"
  
  command {
    python /kingfisher-download/bin/kingfisher get \
      -r ~{SRA_accession_num} \
      ~{if (GCloud_Paid) then "--allow-paid-from-gcp" else ""} \
      --gcp-user-key-file ~{if defined(GCloud_User_Key_File) then (GCloud_User_Key_File) else "undefined"} \
      --output-format-possibilities sra \
      -m ~{Download_Method_Order} && \
    /opt/conda/envs/env/bin/time /singlem/bin/singlem pipe \
        --sra-files ~{SRA_accession_num}.sra \
        --archive_otu_table ~{SRA_accession_num}.singlem.json --threads 1 \
        --assignment-method diamond \
        --diamond-prefilter \
        --diamond-prefilter-performance-parameters '--block-size 0.5 --target-indexed -c1 --min-orf 24' \
        --diamond-prefilter-db /pkgs/53_db2.0-attempt4.0.60.faa.dmnd \
        --min_orf_length 72 \
        --singlem-packages `ls -d /pkgs/*spkg` \
        --diamond-package-assignment \
        --diamond-taxonomy-assignment-performance-parameters '--block-size 0.5 --target-indexed -c1' \
        --working-directory-tmpdir && gzip ~{SRA_accession_num}.singlem.json
  }
  runtime {
    docker: dockerImage
    memory: ram_str
    disks: disk_size_str
    cpu: 1
    preemptible: preemptible_tries
    noAddress: true
  }
  output {
    File singlem_otu_table_gz = "~{SRA_accession_num}.singlem.json.gz"
  }
}
