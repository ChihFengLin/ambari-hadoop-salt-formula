{% from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}
{% from "infoplatform/ambari_lab/map.jinja" import rpm_pkg with context %}
{% set repos = ambari_props.repos %}
{% set hosts = ambari_props.hosts %}
{% set deploy_env = ambari_props.deploy_env %}

{% if salt['grains.get']('os_family') == 'RedHat' %}

{% set centos_v = 'centos7' if  salt['grains.get']('osmajorrelease') == 7 else 'centos6' %}

download_mysql_pubkey:
  file.managed:
    - name: /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
    - source: {{ salt['pillar.get']('mysql:pubkey', rpm_pkg.key) }}
    - skip_verify: True

add_mysql_repo:
  cmd.run:
    - name: sudo rpm -ivh {{ rpm_pkg.rpm }}
    - creates: /etc/yum.repos.d/mysql-community.repo

set_up_mysql_pubkey:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/mysql-community.repo
    - pattern: '^gpgkey=.*'
    - repl: 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql'

AMBARI-repo-{{ repos.ambari.version }}:
  pkgrepo.managed:
    - name: AMBARI-{{ repos.ambari.version }}
    - humanname: AMBARI-{{ repos.ambari.version }}
    - baseurl: http://{{ hosts.repo_server[deploy_env]['hostname'] }}/ambari/centos7/2.x/updates/{{ repos.ambari.version }}
    - gpgcheck: 0
    - enabled: 1
    - priority: 1

HDP-repo-{{ repos.hdp.version }}:
  pkgrepo.managed:
    - name: HDP-{{ repos.hdp.version }}
    - humanname: HDP-{{ repos.hdp.version }}
    - baseurl: http://{{ hosts.repo_server[deploy_env]['hostname'] }}/hdp/HDP/centos7/3.x/updates/{{ repos.hdp.version }}
    - gpgcheck: 0
    - enabled: 1
    - priority: 1

HDP-UTILS-repo-{{ repos.hdp_utils.version }}:
  pkgrepo.managed:
    - name: HDP-UTILS-{{ repos.hdp_utils.version }}
    - humanname: HDP-UTILS-{{ repos.hdp_utils.version }}
    - baseurl: http://{{ hosts.repo_server[deploy_env]['hostname'] }}/hdp/HDP-UTILS-{{ repos.hdp_utils.version }}/repos/centos7
    - gpgcheck: 0
    - enabled: 1
    - priority: 1

{% endif %}