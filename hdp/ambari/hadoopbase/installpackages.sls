{% from "infoplatform/ambari_lab/map.jinja" import common_vars with context -%}

pkg_req_pkgs:
  pkg.installed:
    - pkgs:
      - libtirpc-devel
      - curl
      - unzip
      - tar
      - wget
      - openssl
      - openssl-devel
      - openssh-clients
      - chrony
      - mysql-connector-java
      - java-1.8.0-openjdk
      - java-1.8.0-openjdk-devel
      - policycoreutils-python
      - selinux-policy-targeted
      - policycoreutils

{%- set pip_dependencies_str = ' '.join(common_vars.pip_dependencies) %}
install_hadoopbase_python_pkg:
  cmd.run:
    - name: >-
        su - {{ common_vars.user }} -c 
        "cd {{ common_vars.python3_home }} && 
        SLUGIFY_USES_TEXT_UNIDECODE=yes 
        ./bin/pip install --trusted-host files.pythonhosted.org
        {{ pip_dependencies_str }}"
