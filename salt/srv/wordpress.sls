## these packages can be useful, but not immediately needed
#fullstackpkgs:
#  pkg.installed:
#    - install_recommends: False
#    - pkgs:
#      - build-essential
#      - checkinstall


wp_user:
  user.present:
    - name: wp
    - shell: /bin/bash
    - createhome: True


mysql-server:
  cmd.run:
    ## Salt and/or python stuck here if we use pkg.installed for mariadb-server
    ## https://github.com/saltstack/salt/issues/9736
    ## Workaround: run in terminal and restart mariadb.
    - use_vt: True
    - name: |
        DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
  pkg.installed:
    - pkgs:
      ## this one is for salt itself or mysql routines will not work with misleading errors
      - python-mysqldb


wp_db_stuff:
  mysql_database.present:
    - name: wp
    - require:
      - id: mysql-server
  mysql_user.present:
    - name: wp
    - host: localhost
    - allow_passwordless: True
    - unix_socket: True
    - require:
      - id: unix_sock
      - id: wp_user
  mysql_grants.present:
    - grant: all privileges
    - database: wp.*
    - user: wp


## activate auth_socket
unix_sock:
  cmd.run:
    - name: |
          mysql -e "INSTALL PLUGIN unix_socket SONAME 'auth_socket'"
    - onlyif: exit `mysql -BNe "select count(*) from INFORMATION_SCHEMA.PLUGINS where PLUGIN_NAME='unix_socket'"`

