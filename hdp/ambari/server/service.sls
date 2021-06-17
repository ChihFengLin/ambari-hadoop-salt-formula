{% from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}

restart_ambari_server_svc:
  cmd.run:
    - name: /usr/sbin/ambari-server restart
    - onlyif: /usr/sbin/ambari-server status | grep -i 'not running'
