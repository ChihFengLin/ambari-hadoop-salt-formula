{%- from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}
{%- set hosts = ambari_props.hosts %}
{%- set repos = ambari_props.repos %}
{%- set server_conf = ambari_props.ambari_server_conf %}
{%- set blueprint_dynamic = ambari_props.blueprint_dynamic %}

{% if not salt['grains.get']('blueprint_%s:uploaded' % (ambari_props.cluster_name), False) %}
upload_the_blueprint_{{ ambari_props.blueprint_name }}_to_the_Ambari_server:
  cmd.run:
    - name: >-
        curl --user {{ server_conf.admin_user }}:{{ server_conf.admin_password }} -H 'X-Requested-By:ambari'
        -X POST http://{{ grains.fqdn }}:8080/api/v1/blueprints/{{ ambari_props.blueprint_name }}
        -d @/tmp/{{ ambari_props.blueprint_file | replace('jinja', 'json') }}

add_uploaded_blueprint_flag_to_grain:
  grains.present:
    - name: blueprint_{{ ambari_props.cluster_name }}:uploaded
    - value: True
    - force: True
{% endif %}

{% if not salt['grains.get']('blueprint_%s:cluster_%s:created' % (ambari_props.cluster_name, ambari_props.cluster_name), False) %}
launch_the_create_cluster_request:
  cmd.run:
    - name: >-
        curl --user {{ server_conf.admin_user }}:{{ server_conf.admin_password }} -H 'X-Requested-By:ambari'
        -X POST http://{{ grains.fqdn }}:8080/api/v1/clusters/{{ ambari_props.cluster_name }}
        -d @/tmp/{{ ambari_props.cluster_template_file | replace('jinja', 'json') }}
    - require:
      - cmd: upload_the_blueprint_{{ ambari_props.blueprint_name }}_to_the_Ambari_server

add_cluster_created_flag_to_grain:
  grains.present:
    - name: blueprint_{{ ambari_props.cluster_name }}:cluster_{{ ambari_props.cluster_name }}:created
    - value: True
    - force: True

{% endif %}