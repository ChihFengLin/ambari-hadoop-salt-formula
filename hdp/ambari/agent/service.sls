{% from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}

restart_ambari_agent_svc:
  cmd.run:
    - name: /usr/sbin/ambari-agent restart
    - onlyif: /usr/sbin/ambari-agent status | grep -i 'not running'
