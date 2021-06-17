{%- from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}
{%- set hosts = ambari_props.hosts %}
{%- set repos = ambari_props.repos %}
{%- set deploy_env = ambari_props.deploy_env %}
{%- set server_conf = ambari_props.ambari_server_conf %}

{% if salt['grains.get']('os_family') == 'RedHat' %}

{%- set centos_v = 'centos7' 
  if salt['grains.get']('osmajorrelease') == 7 else 'centos6' 
%}

{%- set hdp_repo_url = 
  'http://%s/hdp/HDP/%s/3.x/updates/%s' % (
    hosts.repo_server[deploy_env].ipv4, centos_v, repos.hdp.version
) %}

{%- set hdp_utils_repo_url = 
  'http://%s/hdp/HDP-UTILS-%s/repos/%s' % (
    hosts.repo_server[deploy_env].ipv4, repos.hdp_utils.version, centos_v
) %}

{% endif %}

include:
  - infoplatform.ambari_lab.configure.check_inventory

{% if not salt['grains.get']('blueprint_%s:configure' % (ambari_props.cluster_name), False) %}

generate_cluster_vdf-HDP-{{ repos.hdp.version }}_xml_file:
  file.managed:
    - name: /tmp/cluster_vdf.xml
    - source: salt://infoplatform/ambari_lab/configure/files/vdf-HDP-{{ repos.hdp.version }}.xml
    - template: jinja
    - mode: 0640
    - user: root
    - group: root
    - allow_empty: False
    - context:
        repos: {{ repos | json }}
        hdp_repo_url: {{ hdp_repo_url }}
        hdp_utils_repo_url: {{ hdp_utils_repo_url }}

register_vdf_with_ambari:
  http.query:
    - name: http://{{ grains.host }}:8080/api/v1/version_definitions
    - header_list: ["X-Requested-By: ambari"]
    - username: {{ server_conf.admin_user }}
    - password: {{ server_conf.admin_password }}
    - method: POST
    - data: " {\"VersionDefinition\":{ \"version_url\":\"file:/tmp/cluster_vdf.xml\"}}"
    - verify_ssl: False
    - status: 201
    - require:
      - file: generate_cluster_vdf-HDP-{{ repos.hdp.version }}_xml_file

restart_ambari_server_svc_after_vdf_registration:
  service.running:
    - name: ambari-server
    - enable: True
    - watch:
      - http: register_vdf_with_ambari

{%- set require_list = [] %}
{%- set pending_added_host = [] %}
{%- set inventory = ambari_props.host_group_mapping[deploy_env] %}
{%- for group, hosts in inventory.iteritems() %}
    {% set _dummy = pending_added_host.extend(hosts) %}
{% endfor %}

{%- for server_name in pending_added_host %}

make_sure_Ambari_Agents_{{ server_name }}_has_registered:
  http.query:
    - name: http://{{ grains.host }}:8080/api/v1/hosts/{{ server_name }}
    - header_list: ["X-Requested-By: ambari"]
    - username: {{ server_conf.admin_user }}
    - password: {{ server_conf.admin_password }}
    - method: GET
    - verify_ssl: False
    - status: 200

{%- set _dummy = require_list.append({
  'http': ('make_sure_Ambari_Agents_%s_has_registered' % (server_name)).encode('utf8')
}) %}

{% endfor %}

add_configure_flag_to_grain:
  grains.present:
    - name: blueprint_{{ ambari_props.cluster_name }}:configure
    - value: True
    - force: True
    - require: {{ require_list }}

{% endif %}