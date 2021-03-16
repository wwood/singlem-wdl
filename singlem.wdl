version 1.0

workflow SingleM_SRA {
  input {
    File SRA_accession_list
    String AWS_User_Key_Id
    String AWS_User_Key
  }
  call get_run_from_runlist { 
    input: 
      runlist = SRA_accession_list
    }
  scatter(SRA_accession_num in get_run_from_runlist.runarray) {
    call download_and_extract_ncbi {
      input:
        SRA_accession_num = SRA_accession_num,
	AWS_User_Key_Id = AWS_User_Key_Id,
	AWS_User_Key = AWS_User_Key
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

task download_and_extract_ncbi {
  input {
    String SRA_accession_num
    String dockerImage = "amazon/aws-cli:latest" 
    String AWS_User_Key_Id
    String AWS_User_Key
  }
  command <<<
    export AWS_ACCESS_KEY_ID=~{AWS_User_Key_Id}
    export AWS_SECRET_ACCESS_KEY=~{AWS_User_Key}  
    aws s3 ls > test.txt
  >>>
  runtime {
    docker: dockerImage
  }
  output {
    Array[File] extracted_reads = glob("*.fasta.gz")
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
