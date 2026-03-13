process SINGLEM_PIPE {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/singlem:0.20.3--pyhdfd78af_2' :
        'quay.io/biocontainers/singlem:0.20.3--pyhdfd78af_2' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.profile.tsv"), emit: profile
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def read_list = (reads instanceof List) ? reads : [reads]

    if (meta.single_end && read_list.size() != 1) {
        error "SINGLEM_PIPE expected 1 input read for single-end sample '${meta.id}', got ${read_list.size()}"
    }
    if (!meta.single_end && read_list.size() != 2) {
        error "SINGLEM_PIPE expected 2 input reads for paired-end sample '${meta.id}', got ${read_list.size()}"
    }

    def input_args = meta.single_end
        ? "-1 ${read_list[0]}"
        : "-1 ${read_list[0]} -2 ${read_list[1]}"

    def metapackage_args = meta.db ? "--metapackage ${meta.db}" : ""

    println "DEBUG SINGLEM meta = ${meta}"
    println "DEBUG SINGLEM meta.db = ${meta.db}"
    println "DEBUG SINGLEM metapackage_args = ${metapackage_args}"

    """
    singlem pipe \
        $input_args \
        $metapackage_args \
        --threads $task.cpus \
        -p ${prefix}.profile.tsv \
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        singlem: \$(singlem --version 2>&1)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.profile.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        singlem: stub
    END_VERSIONS
    """
}