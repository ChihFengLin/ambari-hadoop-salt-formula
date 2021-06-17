{% from "infoplatform/ambari_lab/map.jinja" import ambari_props with context -%}
{% from "infoplatform/ambari_lab/map.jinja" import java_configurations with context -%}
{% from "infoplatform/ambari_lab/map.jinja" import mysql with context %}
{% from "infoplatform/ambari_lab/map.jinja" import common_vars with context -%}

make_sure_ntp_service_is_started:
  service.running:
    - name: {{ ambari_props.ntp_service_name }}
    - enable: True

disableselinux:
  selinux.mode:
    - name: disabled

make_sure_/etc/security/limits.d_exists:
  file.directory:
    - name: /etc/security/limits.d
    - dir_mode: 755

update_kernel_parameters:
  file.managed:
    - name: /etc/security/limits.d/99-hadoop.conf
    - mode: 0644
    - create: True
    - contents:
      - "* soft nofile 100000"
      - "* hard nofile 65536"
      - "* soft nproc 32768"
      - "* hard nproc 32768"
      - "* soft core 0"
      - "* hard core unlimited"
      - "root       soft    nproc    unlimited"
      - "ams        -       nofile   64000"
      - "atlas      -       nofile   64000"
      - "druid      -       nofile   64000"
      - "hive       -       nofile   64000"
      - "infra-solr -       nofile   64000"
      - "kms        -       nofile   64000"
      - "knox       -       nofile   64000"
      - "logsearch  -       nofile   64000"
      - "ranger     -       nofile   64000"
      - "spark      -       nofile   64000"
      - "zeppelin   -       nofile   64000"
      - "zookeeper  -       nofile   64000"

disabled_ipv6:
  file.append:
    - name: /etc/sysctl.conf
    - text:
      - "net.ipv6.conf.all.disable_ipv6 = 1"
      - "net.ipv6.conf.default.disable_ipv6 = 1"
      - "net.ipv6.conf.lo.disable_ipv6 = 1"
      - "vm.swappiness=1"

disable_transparent_huge_pages_until_the_next_reboot:
  cmd.run:
    - name: >-
        echo never > /sys/kernel/mm/transparent_hugepage/enabled &&
        echo never > /sys/kernel/mm/transparent_hugepage/defrag
    - onlyif: 'test -e /sys/kernel/mm/transparent_hugepage/enabled'

update_grub_parameters:
  file.append:
    - name: /etc/default/grub
    - text:
      - "GRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE_LINUX transparent_hugepage=never\""

remove_stale_hadoop_env_file:
  file.absent:
    - name: /etc/profile.d/hadoopenv.sh

export_global_env_variables:
  file.managed:
    - name: /etc/profile.d/hadoop_profile.sh
    - source: salt://infoplatform/ambari_lab/hadoopbase/files/hadoop_profile.sh.jinja
    - template: jinja
    - mode: 0644
    - user: root
    - group: root
    - allow_empty: False
    - context:
        java_open_jdk_dir: {{ java_configurations.openjdk_path }}
        java_bin_dir: {{ common_vars.java_bin }}
        python_lib_dir: {{ common_vars.python3_lib }}
        python_bin_dir: {{ common_vars.python3_bin }}
        yarn_conf_dir: {{ common_vars.yarn_conf_dir }}
        spark_home: {{ common_vars.spark_home }}
        hadoop_home: {{ common_vars.hadoop_home }}
        hadoop_conf_dir: {{ common_vars.hadoop_conf_dir }}
        hadoop_common_home: {{ common_vars.hadoop_common_home }}
        hadoop_hdfs_home: {{ common_vars.hadoop_hdfs_home }}
        hadoop_yarn_home: {{ common_vars.hadoop_yarn_home }}
        hadoop_mapred_home: {{ common_vars.hadoop_mapred_home }}
        hbase_home: {{ common_vars.hbase_home }}
        hbase_conf_dir: {{ common_vars.hbase_conf_dir }}
        veritas_local_lib_dir: {{ common_vars.valrs_local_lib }}
        veritas_local_lib64_dir: {{ common_vars.valrs_local_lib64 }}
        veritas_local_bin: {{ common_vars.valrs_local_bin }}

add_dynamic_lib_path_into_system_cache:
  file.managed:
    - name: /etc/ld.so.conf.d/hadoop.conf
    - source: salt://infoplatform/ambari_lab/hadoopbase/files/hadoop.conf.jinja
    - template: jinja
    - mode: 0644
    - user: root
    - group: root
    - allow_empty: False
    - context:
        veritas_local_lib_dir: {{ common_vars.valrs_local_lib }}
        veritas_local_lib64_dir: {{ common_vars.valrs_local_lib64 }}

refresh_ldconfig_if_path_updated:
  cmd.run:
    - name: ldconfig
    - onchanges:
      - file: add_dynamic_lib_path_into_system_cache

'grub2-mkconfig -o /boot/grub2/grub.cfg':
  cmd.run

add_cluster_to_grain:
  grains.present:
    - name: clustername
    - value: {{ambari_props.cluster_name}}

ambari-agent-libdir:
  file.directory:
    - name: /{{ ambari_props.hadoop_log_root_dir }}/lib/ambari-agent
    - mode: 755
    - makedirs: true

/var/lib/ambari-agent:
  file.symlink:
    - target: /{{ ambari_props.hadoop_log_root_dir }}/lib/ambari-agent

ambari-agent-logdir:
  file.directory:
    - name: /{{ ambari_props.hadoop_log_root_dir }}/log/ambari-agent
    - mode: 755
    - makedirs: true

/var/log/ambari-agent:
  file.symlink:
    - target: /{{ ambari_props.hadoop_log_root_dir }}/log/ambari-agent


ambari-server-libdir:
  file.directory:
    - name: /{{ ambari_props.hadoop_log_root_dir }}/lib/ambari-server
    - mode: 755
    - makedirs: true

/var/lib/ambari-server:
  file.symlink:
    - target: /{{ ambari_props.hadoop_log_root_dir }}/lib/ambari-server


ambari-server-logdir:
  file.directory:
    - name: /{{ ambari_props.hadoop_log_root_dir }}/log/ambari-server
    - mode: 755
    - makedirs: true

/var/log/ambari-server:
  file.symlink:
    - target: /{{ ambari_props.hadoop_log_root_dir }}/log/ambari-server

ambari-hdp-dir:
  file.directory:
    - name: /{{ ambari_props.hadoop_log_root_dir }}/hdp
    - mode: 755
    - makedirs: true

/usr/hdp:
  file.symlink:
    - target: /{{ ambari_props.hadoop_log_root_dir }}/hdp

add_role_flag:
  grains.present:
    - name: role
    - value: True

add_dremio_user:
  cmd.run:
    - name: /usr/sbin/useradd -m -d /home/dremio dremio
    - unless: /usr/bin/id -u dremio

add_dremio_into_hadoop_group:
  group.present:
    - name: hadoop
    - addusers:
      - dremio

assign_dremio_user_to_home_directory:
  file.directory:
    - name: /home/dremio
    - user: dremio
    - group: hadoop
    - mode: 755
    - makedirs: True