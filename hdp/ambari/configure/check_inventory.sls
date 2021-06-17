{% from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}
{%- set deploy_env = ambari_props.deploy_env %}
{%- set ambari_server_hostname = ambari_props.host_group_mapping[deploy_env]['hdp_management'] | first %}
{%- set server_conf = ambari_props.ambari_server_conf %}
{%- set security = ambari_props.security %}
{%- set security_options = ambari_props.security_options %}
{%- set blueprint_dynamic = ambari_props.blueprint_dynamic %}
{%- set inventory = ambari_props.host_group_mapping[deploy_env] %}

{%- set host_groups = {} %}
{%- set group_number = 0 %}
{%- for group, hosts in inventory.iteritems() %}
  {% set group_number = group_number + 1 %}
  {% set group_name = group.encode('utf-8') %}
  {% set _dummy = host_groups.update({group_name:hosts}) %}
{% endfor %}

{% for item in blueprint_dynamic %}
  {% if item.host_group in host_groups %}
    {% set group_number = group_number - 1 %}
  {% else %}
inventory_and_blueprint_host_group_not_match:
  test.fail_without_changes:
    - name: "Inventory and blueprint's host_group odes not match"
    - failhard: True
  {% endif %}
{% endfor %}

{% if not group_number == 0 %}
inventory_and_blueprint_total_group_number_not_match:
  test.fail_without_changes:
    - name: "Inventory and blueprint's group number does not match"
    - failhard: True
{% endif %}