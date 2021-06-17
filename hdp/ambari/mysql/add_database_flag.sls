include:
  - infoplatform.ambari_lab.mysql.install
  - infoplatform.ambari_lab.mysql.service
  - infoplatform.ambari_lab.mysql.database
  - infoplatform.ambari_lab.mysql.users
  - infoplatform.ambari_lab.mysql.grants

add_database_installation_flag:
  grains.present:
    - name: mysql:installed
    - value: True
    - require:
      - sls: infoplatform.ambari_lab.mysql.install
      - sls: infoplatform.ambari_lab.mysql.service
      - sls: infoplatform.ambari_lab.mysql.database
      - sls: infoplatform.ambari_lab.mysql.users
      - sls: infoplatform.ambari_lab.mysql.grants
