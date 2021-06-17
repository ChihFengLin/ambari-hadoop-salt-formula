{% from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}
{% set repos = ambari_props.repos %}
{% set hosts = ambari_props.hosts %}

{% if salt['grains.get']('os_family') == 'RedHat' %}

{% set centos_v = 'centos7' if  salt['grains.get']('osmajorrelease') == 7 else 'centos6' %}

AMBARI-repo-{{ repos.ambari.version }}:
  pkgrepo.managed:
    - name: AMBARI-{{ repos.ambari.version }}
    - humanname: AMBARI-{{ repos.ambari.version }}
    - baseurl: http://{{ hosts.repo_server.hostname }}/ambari/centos7/2.x/updates/{{ repos.ambari.version }}
    - gpgcheck: 0
    - enabled: 0
    - priority: 1

HDP-repo-{{ repos.hdp.version }}:
  pkgrepo.managed:
    - name: HDP-{{ repos.hdp.version }}
    - humanname: HDP-{{ repos.hdp.version }}
    - baseurl: http://{{ hosts.repo_server.hostname }}/HDP/centos7/3.x/updates/{{ repos.hdp.version }}
    - gpgcheck: 0
    - enabled: 0
    - priority: 1

HDP-UTILS-repo-{{ repos.hdp_utils.version }}:
  pkgrepo.managed:
    - name: HDP-UTILS-{{ repos.hdp_utils.version }}
    - humanname: HDP-UTILS-{{ repos.hdp_utils.version }}
    - baseurl: http://{{ hosts.repo_server.hostname }}/HDP-UTILS-{{ repos.hdp_utils.version }}/repos/centos7
    - gpgcheck: 0
    - enabled: 0
    - priority: 1

clean_legacy_repo_configuration:
  cmd.run:
    - name: rm -rf /etc/yum.repos.d/ambari-hdp-*

clean_previous_verison_HDP_repo:
  cmd.run:
    - name: rm -rf /etc/yum.repos.d/HDP-3.1.0.0*

clean_previous_version_AMBARI_repo:
  cmd.run:
    - name: rm -rf /etc/yum.repos.d/AMBARI-2.7.3.0*