{%- from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}
{%- set repos = ambari_props.repos %}
{%- set deploy_env = ambari_props.deploy_env %}
{%- set server_conf = ambari_props.ambari_server_conf %}
{%- set security = ambari_props.security %}
{%- set security_options = ambari_props.security_options %}
{%- set blueprint_dynamic = ambari_props.blueprint_dynamic %}

{% if not salt['grains.get']('blueprint_%s:uploaded' % (ambari_props.cluster_name), False) %}

##########################################################################
## Construct host groups from blueprint yaml file and store into grains ##
##########################################################################
{%- set host_groups = {} %}
{%- set inventory = ambari_props.host_group_mapping[deploy_env] %}
{%- for group, hosts in inventory.iteritems() %}
    {% set group_name = group.encode('utf-8') %}
    {% set _dummy = host_groups.update({group_name:hosts}) %}
{% endfor %}

add_host_groups_to_grain:
  grains.present:
    - name: blueprint_{{ ambari_props.cluster_name }}:host_groups
    - value: {{ host_groups }}
    - force: True

# Generate cluster template and blueprint json files
generate_cluster_template_file:
  file.managed:
    - name: /tmp/cluster_template.json
    - source: salt://infoplatform/ambari_lab/blueprint/files/{{ ambari_props.cluster_template_file }}
    - template: jinja
    - mode: 0640
    - user: root
    - group: root
    - allow_empty: False
    - context:
        host_groups: {{ host_groups | json }}
        security: {{ security }}
        security_options: {{ security_options | json }}
    - require:
        - grains: add_host_groups_to_grain

#############################################################################
## Construct service groups from blueprint yaml file and store into grains ##
#############################################################################
{%- set service_groups = {} %}

# Set initial list value for each service group
{%- set ambari_groups = [] %}
{%- set namenode_groups = [] %}
{%- set namenode_hosts = [] %}
{%- set zkfc_groups = [] %}
{%- set resourcemanager_groups = [] %}
{%- set journalnode_groups = [] %}
{%- set zookeeper_groups = [] %}
{%- set zookeeper_hosts = [] %}
{%- set hiveserver_hosts = [] %}
{%- set oozie_hosts = [] %}
{%- set atlas_hosts = [] %}
{%- set druid_hosts = [] %}
{%- set superset_hosts = [] %}
{%- set kafka_groups = [] %}
{%- set kafka_hosts = [] %}
{%- set rangeradmin_groups = [] %}
{%- set rangeradmin_hosts = [] %}
{%- set rangerkms_hosts = [] %}
{%- set streamline_hosts = [] %}
{%- set registry_hosts = [] %}
{%- set blueprint_all_services = [] %}
{%- set blueprint_all_clients = [] %}

# Update service groups based on blueprint yaml file
{% for item in blueprint_dynamic %}
  
  {% if 'AMBARI_SERVER' in item.services %}
    {%- set _dummy = ambari_groups.append(item.host_group.encode('utf-8')) %}
  {% endif %}

  {% if 'NAMENODE' in item.services %}
    {%- set _dummy = namenode_groups.append(item.host_group.encode('utf-8')) %}
    {%- set _dummy = namenode_hosts.extend(host_groups[item.host_group]) %}
  {% endif %}

  {% if 'ZKFC' in item.services %}
    {%- set _dummy = zkfc_groups.append(item.host_group.encode('utf-8')) %}
  {% endif %}

  {% if 'RESOURCEMANAGER' in item.services %}
    {%- set _dummy = resourcemanager_groups.append(item.host_group.encode('utf-8')) %}
  {% endif %}

  {% if 'JOURNALNODE' in item.services %}
    {%- set _dummy = journalnode_groups.append(item.host_group.encode('utf-8')) %}
  {% endif %}

  {% if 'ZOOKEEPER_SERVER' in item.services %}
    {%- set _dummy = zookeeper_groups.append(item.host_group.encode('utf-8')) %}
    {%- set _dummy = zookeeper_hosts.extend(host_groups[item.host_group]) %}
  {% endif %}

  {% if 'HIVE_SERVER' in item.services %}
    {%- set _dummy = hiveserver_hosts.extend(host_groups[item.host_group]) %}
  {% endif %}

  {% if 'OOZIE_SERVER' in item.services %}
    {%- set _dummy = oozie_hosts.extend(host_groups[item.host_group]) %}
  {% endif %}

  {% if 'ATLAS_SERVER' in item.services %}
    {%- set _dummy = atlas_hosts.extend(host_groups[item.host_group]) %}
  {% endif %}

  {%- if 'DRUID_BROKER' in item.services or 
         'DRUID_COORDINATOR' in item.services or 
         'DRUID_ROUTER' in item.services or 
         'DRUID_MIDDLEMANAGER' in item.services or 
         'DRUID_HISTORICAL' in item.services or 
         'DRUID_OVERLORD' in item.services %}
    {%- set _dummy = druid_hosts.extend(host_groups[item.host_group]) %}
  {% endif %}

  {% if 'KAFKA_BROKER' in item.services %}
    {%- set _dummy = kafka_groups.append(item.host_group.encode('utf-8')) %}
    {%- set _dummy = kafka_hosts.extend(host_groups[item.host_group]) %}
  {% endif %}
  
  {% if 'RANGER_ADMIN' in item.services or 'RANGER_USERSYNC' in item.services %}
    {%- set _dummy = rangeradmin_groups.append(item.host_group.encode('utf-8')) %}
    {%- set _dummy = rangeradmin_hosts.extend(host_groups[item.host_group]) %}
  {% endif %}

  {% if 'RANGER_KMS_SERVER' in item.services %}
    {%- set _dummy = rangerkms_hosts.extend(host_groups[item.host_group]) %}
  {% endif %}

  {% set _dummy = blueprint_all_services.extend(item.services) %}
  {% set _dummy = blueprint_all_clients.extend(item.clients) %}

{% endfor %}

{% set blueprint_all_services_encoded = [] %}
{% for item in blueprint_all_services %}
  {% set _dummy = blueprint_all_services_encoded.append(item.encode('utf-8')) %}
{% endfor %}

{% set blueprint_all_clients_encoded = [] %}
{% for item in blueprint_all_clients %}
  {% set _dummy = blueprint_all_clients_encoded.append(item.encode('utf-8')) %}
{% endfor %}

{%- set _dummy = service_groups.update(
  {
    "ambari_groups" : ambari_groups,
    "namenode_groups": namenode_groups,
    "namenode_hosts": namenode_hosts,
    "zkfc_groups": zkfc_groups,
    "resourcemanager_groups": resourcemanager_groups,
    "journalnode_groups": journalnode_groups,
    "zookeeper_groups": zookeeper_groups,
    "zookeeper_hosts": zookeeper_hosts,
    "hiveserver_hosts": hiveserver_hosts,
    "oozie_hosts": oozie_hosts,
    "atlas_hosts": atlas_hosts,
    "druid_hosts": druid_hosts,
    "superset_hosts": superset_hosts,
    "kafka_groups": kafka_groups,
    "kafka_hosts": kafka_hosts,
    "rangeradmin_groups": rangeradmin_groups,
    "rangeradmin_hosts": rangeradmin_hosts,
    "rangerkms_hosts": rangerkms_hosts,
    "streamline_hosts": streamline_hosts,
    "registry_hosts": registry_hosts,
    "blueprint_all_services": blueprint_all_services_encoded | unique,
    "blueprint_all_clients": blueprint_all_clients_encoded | unique
  }
) %}

add_service_groups_to_grain:
  grains.present:
    - name: blueprint_{{ ambari_props.cluster_name }}:service_groups
    - value: {{ service_groups }}
    - force: True

generate_blueprint_dynamic_file:
  file.managed:
    - name: /tmp/blueprint_dynamic.json
    - source: salt://infoplatform/ambari_lab/blueprint/files/{{ ambari_props.blueprint_file }}
    - template: jinja
    - mode: 0640
    - user: root
    - group: root
    - allow_empty: False
    - context:
        security: {{ security }}
        security_options: {{ security_options | json }}
        database_config: {{ ambari_props.database_configurations | json }}
        blueprint_dynamic: {{ blueprint_dynamic | json }}
        ambari_groups: {{ ambari_groups }}
        namenode_groups: {{ namenode_groups }}
        namenode_hosts: {{ namenode_hosts }}
        zkfc_groups: {{ zkfc_groups }}
        resourcemanager_groups: {{ resourcemanager_groups }}
        journalnode_groups: {{ journalnode_groups }}
        zookeeper_groups: {{ zookeeper_groups }}
        zookeeper_hosts: {{ zookeeper_hosts }}
        hiveserver_hosts: {{ hiveserver_hosts }}
        oozie_hosts: {{ oozie_hosts }}
        atlas_hosts: {{ atlas_hosts }}
        druid_hosts: {{ druid_hosts }}
        superset_hosts: {{ superset_hosts }}
        kafka_groups: {{ kafka_groups }}
        kafka_hosts: {{ kafka_hosts }}
        rangeradmin_groups: {{ rangeradmin_groups }}
        rangeradmin_hosts: {{ rangeradmin_hosts }}
        rangerkms_hosts: {{ rangerkms_hosts }}
        streamline_hosts: {{ streamline_hosts }}
        registry_hosts: {{ registry_hosts }}
        blueprint_all_services: {{ blueprint_all_services_encoded }}
        blueprint_all_clients: {{ blueprint_all_clients_encoded }}
    - require:
        - grains: add_service_groups_to_grain

{% endif %}
