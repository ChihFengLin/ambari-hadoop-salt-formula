{% from "infoplatform/ambari_lab/map.jinja" import mysql with context %}
{% from "infoplatform/ambari_lab/map.jinja" import ambari_props with context %}

include:
  - infoplatform.ambari_lab.mysql.database
  - infoplatform.ambari_lab.mysql.users

start_granting_user_database_access:
  cmd.run:
    - name: echo "start granting user database access"

{%- if ambari_props.database_configurations.database_options is defined %}
{% for user, userargs in ambari_props.database_configurations.database_options.iteritems() %}

{% if not salt['grains.get']('mysql:user:local:%s' % user, False) %}
grant_{{ user }}_user_with_localhost:
  mysql_query.run:
    - database: {{ userargs.db_name }}
    - query: "GRANT ALL PRIVILEGES ON *.* TO '{{ user }}'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    - connection_host: localhost
    - connection_user: {{ mysql.root_user }}
    - connection_pass: {{ mysql.root_password }}
    - connection_charset: utf8
    - require:
      - mysql_query: create_{{ user }}_database_user_with_localhost
{% endif %}

{% endfor %}
{% endif %}

{%- if ambari_props.database_configurations.database_options is defined %}
{% for user, userargs in ambari_props.database_configurations.database_options.iteritems() %}

{% if not salt['grains.get']('mysql:user:all:%s' % user, False) %}
grant_{{ user }}_user_with_all_hosts:
  mysql_query.run:
    - database: {{ userargs.db_name }}
    - query: "GRANT ALL PRIVILEGES ON *.* TO '{{ user }}'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    - connection_host: localhost
    - connection_user: {{ mysql.root_user }}
    - connection_pass: {{ mysql.root_password }}
    - connection_charset: utf8
    - require:
      - mysql_query: create_{{ user }}_database_user_with_all_hosts
{% endif %}

{% endfor %}
{% endif %}