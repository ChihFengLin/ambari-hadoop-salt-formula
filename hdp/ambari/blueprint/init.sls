{% from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}
{%- set deploy_env = ambari_props.deploy_env %}
{%- set ambari_server_hostname = ambari_props.host_group_mapping[deploy_env]['hdp_management'] | first %}
{%- set prerequsite_installed = (
  salt['grains.get']('mysql:installed', False) and 
  salt['grains.get']('ambari:agent:installed', False) and
  salt['grains.get']('ambari:server:installed', False) and
  salt['grains.get']('blueprint_%s:configure' % (ambari_props.cluster_name), False)
) %}

include:
{% if prerequsite_installed and grains.fqdn == ambari_server_hostname %}
  - infoplatform.ambari_lab.blueprint.populate_blueprint
  - infoplatform.ambari_lab.blueprint.service
{% else %}
  - infoplatform.ambari_lab.skip
{% endif %}
