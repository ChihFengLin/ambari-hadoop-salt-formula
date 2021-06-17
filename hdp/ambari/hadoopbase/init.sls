{% from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}

include:
{% if not ambari_props.deploy_env == 'local' %}
  - base: jdk
{% endif %}
  - infoplatform.ambari_lab.hadoopbase.mineupdate
{% if salt['grains.get']('mine:updated', False) %}
  - infoplatform.ambari_lab.hadoopbase.repo
  - infoplatform.ambari_lab.hadoopbase.installpackages
  - infoplatform.ambari_lab.hadoopbase.osprerequisite
{% if salt['grains.get']('role', False) %}
  - infoplatform.ambari_lab.agent
{% endif %}
{% endif %}