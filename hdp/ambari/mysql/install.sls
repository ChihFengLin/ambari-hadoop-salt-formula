{% from "infoplatform/ambari_lab/map.jinja" import mysql with context %}
{% from "infoplatform/ambari_lab/map.jinja" import rpm_pkg with context %}

install_pubkey_mysql:
  file.managed:
    - name: /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
    - source: {{ salt['pillar.get']('mysql:pubkey', rpm_pkg.key) }}
    - skip_verify: True
        
add_rpm_into_repo:
  cmd.run:
    - name: sudo rpm -ivh {{ rpm_pkg.rpm }}
    - creates: /etc/yum.repos.d/mysql-community.repo

mysql57_community_release:
  pkg.installed:
    - pkgs: 
      - {{ mysql.server_pkg }}
      - {{ mysql.client_pkg }}
    - require:
      - file: install_pubkey_mysql

install_mysql_python_pkg:
  pkg.installed:
    - name: {{ mysql.python_pkg }}

set_pubkey_mysql:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/mysql-community.repo
    - pattern: '^gpgkey=.*'
    - repl: 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql'
    - require:
      - pkg: mysql57_community_release

set_gpg_mysql:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/mysql-community.repo
    - pattern: 'gpgcheck=.*'
    - repl: 'gpgcheck=1'
    - require:
      - pkg: mysql57_community_release

mysql_config_dir:
  file.directory:
    - name: /etc/mysql/conf.d
    - makedirs: true
    - mode: 755

change_pid_directory_permission:
  file.directory:
    - name: {{ mysql.pid_root_dir }}
    - user: mysql
    - group: mysql
    - dir_mode: 775
    - makedirs: True
    - force: True
    - recurse:
      - user
      - group
      - mode

change_mysql_data_directory_permission:
  file.directory:
    - name: {{ mysql.data_root_dir }}
    - user: mysql
    - group: mysql
    - dir_mode: 775
    - makedirs: True
    - force: True
    - recurse:
      - user
      - group
      - mode

change_mysql_log_directory_permission:
  file.directory:
    - name: {{ mysql.log_file_dir }}
    - user: mysql
    - group: mysql
    - dir_mode: 777
    - makedirs: True
    - force: True
    - recurse:
      - user
      - group
      - mode