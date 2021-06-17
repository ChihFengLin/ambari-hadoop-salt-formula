{% from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}
{%- set ambari_agent_conf = ambari_props.ambari_agent_conf %}
{%- set ambari_version = ambari_props.repos.ambari %}

{% if not salt['grains.get']('ambari:agent:installed', False) %}

ambari_agent_{{ ambari_version.version }}_pkg:
  pkg.installed:
    - name: ambari-agent

ambari_agent_{{ ambari_version.version }}_config:
  file.managed:
    - name: /etc/ambari-agent/conf/ambari-agent.ini
    - source: salt://infoplatform/ambari_lab/agent/files/ambari-agent.ini
    - template: jinja
    - mode: 0640
    - user: root
    - group: root
    - makedirs: True
    - require_in:
      - pkg: ambari_agent_{{ ambari_version.version }}_pkg

ambari_agent_svc:
  service.running:
    - name: ambari-agent
    - enable: True
    - require:
      - pkg: ambari_agent_{{ ambari_version.version }}_pkg
    - watch:
      - file: ambari_agent_{{ ambari_version.version }}_config

add_ambari_agent_installed_flag_to_grain:
  grains.present:
    - name: ambari:agent:installed
    - value: True
    - force: True
    - require:
      - pkg: ambari_agent_{{ ambari_version.version }}_pkg
      - service: ambari_agent_svc

{% endif %}
