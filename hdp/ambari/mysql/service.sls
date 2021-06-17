{% from "infoplatform/ambari_lab/map.jinja" import mysql with context %}
{% set root_password = salt['pillar.get']('mysql:root_password', mysql.root_password) %}

include:
  - infoplatform.ambari_lab.mysql.install

disable_selinux_for_mysql:
  selinux.mode:
    - name: disabled

mysql_config:
  file.managed:
    - name: {{ mysql.config }}
    - source: salt://infoplatform/ambari_lab/mysql/files/my.cnf.{{ grains.os_family }}
    - mode: 644
    - template: jinja
    - require:
      - pkg: mysql57_community_release

update_mysql_systemd_pid_path:
  file.replace:
    - name: /etc/systemd/system/multi-user.target.wants/mysqld.service
    - pattern: '^PIDFile=.*'
    - repl: 'PIDFile={{ mysql.pid_root_dir }}/mysqld.pid'
    - require:
      - pkg: mysql57_community_release

update_mysql_systemd_pid_startup_path:
  file.replace:
    - name: /etc/systemd/system/multi-user.target.wants/mysqld.service
    - pattern: '^ExecStart=/usr/sbin/mysqld --daemonize --pid-file=.*'
    - repl: 'ExecStart=/usr/sbin/mysqld --daemonize --pid-file={{ mysql.pid_root_dir }}/mysqld.pid $MYSQLD_OPTS'
    - require:
      - pkg: mysql57_community_release

mysql_service:
  service.running:
    - name: {{ mysql.service }}
    - enable: True
    - reload: True
    - require:
      - file: mysql_config
    - watch:
      - file: mysql_config
      - file: update_mysql_systemd_pid_path
      - file: update_mysql_systemd_pid_startup_path

{% if salt['grains.get']('mysql:database:first', True) %}
reset_root_password_using_mysql_secure:
  cmd.script:
    - source: salt://infoplatform/ambari_lab/mysql/files/mysql_secure.sh
    - user: root
    - group: root
    - shell: /bin/bash
    - args: "'{{ mysql.log_file_dir }}/mysql.log' '{{ root_password }}'"
    - require:
      - service: mysql_service

add_database_first_install_to_grain:
  grains.present:
    - name: mysql:database:first
    - value: False
    - require:
      - service: mysql_service
{% endif %}