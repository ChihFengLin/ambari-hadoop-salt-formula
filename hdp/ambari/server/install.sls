{% from 'infoplatform/ambari_lab/map.jinja' import ambari_props with context %}
{%- set ambari_server_conf = ambari_props.ambari_server_conf %}
{%- set repos = ambari_props.repos %}
{%- set hosts = ambari_props.hosts %}
{%- set ambari_version = ambari_props.repos.ambari %}
{%- set db_conf = ambari_props.database_configurations %}
{%- set java_conf = ambari_props.java_configurations %}
{%- set deploy_env = ambari_props.deploy_env %}
{%- set hdp_baseurl = "http://%s/hdp/HDP/centos7/3.x/updates/%s" % (
  hosts.repo_server[deploy_env]['hostname'], repos.hdp.version
) %}
{%- set hdp_utils_base_url = "http://%s/hdp/HDP-UTILS-%s/repos/centos7" % (
  hosts.repo_server[deploy_env]['hostname'], repos.hdp_utils.version
) %}

{% if not salt['grains.get']('ambari:server:installed', False) %}

ambari_server_{{ ambari_version.version }}_pkg:
  pkg.installed:
    - name: ambari-server

ambari_server_properties:
  file.managed:
    - name: /etc/ambari-server/conf/ambari.properties
    - source: salt://infoplatform/ambari_lab/server/files/ambari.properties
    - template: jinja
    - user: root
    - group: root
    - permission: 0644
    - makedirs: True
    - require_in:
      - pkg: ambari_server_{{ ambari_version.version }}_pkg

ambari-server-log4j:
  file.managed:
    - name: /etc/ambari-server/conf/log4j.properties
    - source: salt://infoplatform/ambari_lab/server/files/log4j.properties
    - template: jinja
    - user: root
    - group: root
    - permission: 0644
    - makedirs: True
    - require_in:
      - pkg: ambari_server_{{ ambari_version.version }}_pkg

enable_user_home_directory_creation:
  file.append:
    - name: /etc/ambari-server/conf/ambari.properties
    - text:
      - ambari.post.user.creation.hook.enabled=true
      - ambari.post.user.creation.hook=/var/lib/ambari-server/resources/scripts/post-user-creation-hook.sh

{% if db_conf.database_type == 'mysql' %}
install_mysql_required_packages:
  pkg.installed:
    - pkgs:
      - MySQL-python
      - mysql-connector-java

load_ambari_server_schema_into_mysql:
  cmd.run:
    - name: >-
        mysql -uambari
        -p{{ db_conf.database_options.ambari.db_password }}
        {{ db_conf.database_options.ambari.db_name }}
        < /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql

configure_ambari_JDBC_driver_mysql:
  cmd.run:
    - name: >-
        /usr/sbin/ambari-server setup
        --jdbc-db=mysql
        --jdbc-driver={{ db_conf['mysql'].jdbc_location }}

ambari_server_setup_for_java_home_and_database:
  cmd.run:
    - name: >-
        /usr/sbin/ambari-server setup -s -j {{ java_conf.openjdk_path }}
        --database={{ db_conf.database_type }}
        --databasehost={{ grains.host }}
        --databaseport={{ hosts.database_server.port }}
        --databaseusername=ambari
        --databasename={{ db_conf.database_options.ambari.db_name }}
        --databasepassword={{ db_conf.database_options.ambari.db_password }}

{% endif %}

increase_agent_installation_timeout:
  file.replace:
    - name: /etc/ambari-server/conf/ambari.properties
    - pattern: ^agent.package.install.task.timeout.*
    - repl: agent.package.install.task.timeout=9600
    - append_if_not_found: True

increase_http_session_timeout:
  file.replace:
    - name: /etc/ambari-server/conf/ambari.properties
    - pattern: ^server.http.session.inactive_timeout.*
    - repl: server.http.session.inactive_timeout=9600
    - append_if_not_found: True

ambari_server_svc:
  service.running:
    - name: ambari-server
    - enable: True
    - require:
      - pkg: ambari_server_{{ambari_version.version}}_pkg
    - watch:
      - file: ambari_server_properties

add_ambari_server_installed_flag_to_grain:
  grains.present:
    - name: ambari:server:installed
    - value: True
    - force: True
    - require:
      - service: ambari_server_svc

{% endif %}