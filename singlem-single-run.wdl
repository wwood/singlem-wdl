version 1.0

workflow SingleM_SRA {
  input {
    String SRA_accession_num
    Int metagenome_size_in_bp
    String Download_Method_Order
    File? GCloud_User_Key_File
    Boolean GCloud_Paid
    String? AWS_User_Key_Id
    String? AWS_User_Key
  }
  call download_and_extract_ncbi {
    input:
      SRA_accession_num = SRA_accession_num,
      metagenome_size_in_bp = metagenome_size_in_bp,
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
    Int metagenome_size_in_bp
    String Download_Method_Order
    File? GCloud_User_Key_File
    Boolean GCloud_Paid
    String? AWS_User_Key_Id
    String? AWS_User_Key
    String dockerImage = "gcr.io/maximal-dynamo-308105/download_and_extract_ncbi:dev9.11e56131"
  }
  
  #Float disk_size_1 = metagenome_size_in_bp/1000000000*5
  #Int disk_size_2 = ceil(disk_size_1+10)
  #Float disk_size_3 = disk_size_2/10
  #Int disk_size_4 = ceil(disk_size_3*10)
  
  
  #String disk_size = ceil( (ceil(metagenome_size_in_bp/1000000000*5) + 10) / 10 ) *  10
  #String disk_str = "local-disk "+ disk_size_4 + " SSD"
  
  command {
    python /ena-fast-download/bin/kingfisher \
      -r ~{SRA_accession_num} \
      --gcp-user-key-file ~{if defined(GCloud_User_Key_File) then (GCloud_User_Key_File) else "undefined"} \
      ~{if (GCloud_Paid) then "--allow-paid-from-gcp" else ""} \
      --output-format-possibilities fastq \
      -m ~{Download_Method_Order}
  }
  runtime {
    docker: dockerImage
    disks: "local-disk 50 SSD"
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
    String dockerImage = "gcr.io/maximal-dynamo-308105/singlem:0.13.2-dev10.a6cc1b4"
  }
  command {
    export INPUT=`/singlem/extras/sra_input_generator.py --fastq-dump-outputs ~{sep=' ' collections_of_sequences} --min-orf-length 72`
    if [ ! -z "$INPUT" ]
      then
      /opt/conda/envs/env/bin/time /singlem/bin/singlem pipe \
        $INPUT \
        --archive_otu_table ~{srr_accession}.singlem.json --threads 2 \
        --assignment-method diamond \
        --diamond-prefilter \
        --diamond-prefilter-performance-parameters '--block-size 0.5 --target-indexed -c1' \
        --diamond-prefilter-db /pkgs/53_db2.0-attempt4.0.60.faa.dmnd \
        --min_orf_length 72 \
        --singlem-packages `ls -d /pkgs/*spkg` \
        --diamond-taxonomy-assignment-performance-parameters '--target-indexed -c1' \
        --working-directory-tmpdir && gzip ~{srr_accession}.singlem.json
    fi 
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
