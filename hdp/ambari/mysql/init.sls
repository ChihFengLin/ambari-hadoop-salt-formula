{% from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}
{%- set deploy_env = ambari_props.deploy_env %}
{%- set ambari_server_hostname = ambari_props.host_group_mapping[deploy_env]['hdp_management'] | first %}

include:
{% if salt['grains.get']('ambari:agent:installed', False) and grains.fqdn == ambari_server_hostname %}
  - infoplatform.ambari_lab.mysql.install
  - infoplatform.ambari_lab.mysql.service
  - infoplatform.ambari_lab.mysql.database
  - infoplatform.ambari_lab.mysql.users
  - infoplatform.ambari_lab.mysql.grants
  - infoplatform.ambari_lab.mysql.add_database_flag
{% else %}
  - infoplatform.ambari_lab.skip
{% endif %}
