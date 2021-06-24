version 1.0

workflow SingleM_SRA {
  input {
    String SRA_accession_num
    Int metagenome_size_in_GB
    Int metagenome_size_in_gbp
    String Download_Method_Order
    File? GCloud_User_Key_File
    Boolean GCloud_Paid
    String? AWS_User_Key_Id
    String? AWS_User_Key
    String singlem_docker = "gcr.io/maximal-dynamo-308105/singlem:0.13.2-dev26.4ba1c49"
  }
  call singlem_gather {
    input:
      dockerImage = singlem_docker,
      SRA_accession_num = SRA_accession_num,
      metagenome_size_in_GB = metagenome_size_in_GB,
      metagenome_size_in_gbp = metagenome_size_in_gbp,
      GCloud_User_Key_File = GCloud_User_Key_File,
      GCloud_Paid = GCloud_Paid,
      AWS_User_Key_Id = AWS_User_Key_Id,
      AWS_User_Key = AWS_User_Key,
      Download_Method_Order = Download_Method_Order,
  }
  call singlem_taxonomy {
    input:
      dockerImage = singlem_docker,
      SRA_accession_num = SRA_accession_num,
      metagenome_size_in_GB = metagenome_size_in_GB,
      metagenome_size_in_gbp = metagenome_size_in_gbp,
      unannotated_archive = singlem_gather.unannotated_archive
  }
  output {
    File SingleM_tables = singlem_taxonomy.singlem_otu_table_gz
  }
}

task singlem_gather {
  input {
    Int metagenome_size_in_GB
    Int metagenome_size_in_gbp
    String dockerImage
    Float singlem_gather_disk_multiplier = 1.1
    Float singlem_gather_disk_buffer = 10

    String SRA_accession_num
    String Download_Method_Order
    File? GCloud_User_Key_File
    Boolean GCloud_Paid
    String? AWS_User_Key_Id
    String? AWS_User_Key
  }

  Int disk_size = floor(metagenome_size_in_GB * singlem_gather_disk_multiplier + singlem_gather_disk_buffer)
  String disk_size_str = "local-disk "+ disk_size + " HDD"
  Int ram = 3 + 2*(metagenome_size_in_gbp / 100) # Runs like SRR7589585 (109Gbp) fail on 3.5GB
  String ram_str = ram + ".5 GiB"

  command {
    python /kingfisher-download/bin/kingfisher get \
        -r ~{SRA_accession_num} \
        ~{if (GCloud_Paid) then "--allow-paid-from-gcp" else ""} \
        --gcp-user-key-file ~{if defined(GCloud_User_Key_File) then (GCloud_User_Key_File) else "undefined"} \
        --output-format-possibilities sra \
        --guess-aws-location `# Guess location in case the NCBI goes down, as it has done previously.` \
        --hide-download-progress `# No sense logging this`\
        -m ~{Download_Method_Order} && \
      /opt/conda/envs/env/bin/time /singlem/bin/singlem pipe \
          --sra-files ~{SRA_accession_num}.sra \
          --archive_otu_table ~{SRA_accession_num}.unannotated.singlem.json \
          --threads 1 \
          --diamond-prefilter-performance-parameters '--block-size 0.5 --target-indexed -c1 --min-orf 24' \
          --diamond-prefilter-db /pkgs/53_db2.0-attempt4.0.60.faa.dmnd \
          --min_orf_length 72 \
          --singlem-packages `ls -d /pkgs/*spkg` \
          --diamond-package-assignment \
          --no-assign-taxonomy \
          --working-directory-tmpdir
  }
  runtime {
    docker: dockerImage
    memory: ram_str
    disks: disk_size_str
    cpu: 1
    preemptible: if (metagenome_size_in_gbp > 100) then 0 else 3
    noAddress: false
  }
  output {
    File unannotated_archive = "~{SRA_accession_num}.unannotated.singlem.json"
  }
}


task singlem_taxonomy {
  input {
    Int metagenome_size_in_GB
    Int metagenome_size_in_gbp
    String dockerImage
    String SRA_accession_num
    File unannotated_archive
    Float singlem_taxonomy_disk_multiplier = 0.1
    Float singlem_taxonomy_disk_buffer = 10
  }

  Int disk_size = floor(metagenome_size_in_GB * singlem_taxonomy_disk_multiplier + singlem_taxonomy_disk_buffer)
  String disk_size_str = "local-disk "+ disk_size + " HDD"

  command {
    /opt/conda/envs/env/bin/time /singlem/bin/singlem renew \
      --min_orf_length 72 \
      --input-archive-otu-table ~{unannotated_archive} \
      --singlem-packages `ls -d /pkgs/*spkg` \
      --archive-otu-table ~{SRA_accession_num}.singlem.json \
      --assignment-method diamond \
      --diamond-taxonomy-assignment-performance-parameters '--block-size 0.5 --target-indexed -c1' \
        && gzip ~{SRA_accession_num}.singlem.json
  }
  runtime {
    docker: dockerImage
    memory: "3.5 GiB"
    disks: disk_size_str
    cpu: 1
    preemptible: if (metagenome_size_in_gbp > 100) then 0 else 3
    noAddress: false
  }
  output {
    File singlem_otu_table_gz = "~{SRA_accession_num}.singlem.json.gz"
  }
}
