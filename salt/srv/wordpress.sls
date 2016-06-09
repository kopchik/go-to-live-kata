wp_user:
  user.present:
    - name: {{ grains['WP_USER'] }}
    - home: {{ grains['WP_USER_HOME'] }}
    - shell: /bin/bash
    - createhome: True
    - roomnumber: 666
  file.directory:
    - name: {{ grains['WP_USER_HOME'] }}
    - group: www-data


## Salt and/or python stuck here if we use pkg.installed for mariadb-server
## https://github.com/saltstack/salt/issues/9736
## Workaround: install manually in terminal.
mysql-server:
  cmd.run:
    - use_vt: True
    - name: |
        DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
    - unless: which mysqld
  pkg.installed:
    - pkgs:
      ## this one is for salt itself or mysql routines will not work with misleading errors
      - python-mysqldb


## weird, default mysql installation is not secure -- it leaves root without password
secure-mysql-server:
  cmd.run:
    - use_vt: True
    - name: mysql -e "update mysql.user set plugin='unix_socket' where Password=''; flush privileges;"
    - require:
      - id: mysql-server
      - id: unix_sock


# could be split in multiple rules, but, nah, fine like this :)
wp_db_stuff:
  mysql_database.present:
    - name: {{ grains['WP_DB'] }}
    - require:
      - id: mysql-server
      - id: unix_sock
      - id: wp_user
  mysql_user.present:
    - name: {{ grains['WP_USER'] }}
    - host: localhost
    - allow_passwordless: True
    - unix_socket: True
  mysql_grants.present:
    - grant: all privileges
    - database: {{ grains['WP_DB'] }}.*
    - user: {{ grains['WP_USER'] }}


nginx:
  pkg:
    - installed
  file.absent:
    - name: /etc/nginx/sites-enabled/default
  service.running:
    - enable: True
    - reload: True
    - watch:
      - pkg: nginx


secure-nginx:
    file.replace:
        - name: /etc/nginx/nginx.conf
        - pattern: '# server_tokens off;'
        - repl: "server_tokens off;"
        - require:
            - pkg: nginx
        - watch_in:
            - service: nginx


nginx-wp:
  file.managed:
    - name: /etc/nginx/sites-available/wordpress
    - source: salt://configs/nginx-wp.cfg
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - service: nginx
    - require:
      - pkg: nginx


nginx-wp-symlink:
  file.symlink:
    - name: /etc/nginx/sites-enabled/wordpress
    - target: /etc/nginx/sites-available/wordpress
    - require:
      - id: nginx-wp
    - watch_in:
      - service: nginx
    - require:
      - pkg: nginx


wp_repo:
  pkg.installed:
    - name: git
  git.latest:
    - name: https://github.com/WordPress/WordPress.git
    - target: {{ grains['WP_PATH'] }}
    - user:   {{ grains['WP_USER'] }}
    - rev:    {{ grains['WP_VERSION'] }}
    ## TODO achtung, it doesn't fetch tags with depth=1 :(
    # - depth: 1
    - unless: wp-cli --path={{ grains['WP_PATH'] }} core is-installed
    - require:
      - id: wp_user
      - id: git
      - id: wp-cli


php5-fpm:
  pkg.installed: []
  service.running:
    - enable: True


## run-time wordpress dependencies
wp_deps:
  pkg.installed:
    - pkgs:
      - php5-mysqlnd
    - require:
      - id: wp_repo
      - id: mysql-server
      - pkg: php5-fpm
    - watch_in:
      - service: php5-fpm


wp_php-fpm_config:
  file.managed:
    - source: salt://configs/php-fpm.cfg
    - name:   /etc/php5/fpm/pool.d/{{ grains['WP_USER'] }}.conf
    - template: jinja
    - watch_in:
      - service: php5-fpm


# remove default pool because it is useless and insecure
php5-fpm_default_pool:
  file.absent:
    - name: /etc/php5/fpm/pool.d/www.conf
    - require:
      - id: wp_php-fpm_config
    - watch_in:
      - service: php5-fpm
  # for some reason salt does not restart service, let's do it manually
  #cmd.run:
  #  - name: /etc/init.d/php5-fpm restart


# actually copies file only if it is missing
wp_fresh_config:
  file.copy:
    - name:   {{ grains['WP_PATH'] }}/wp-config.php
    - source: {{ grains['WP_PATH'] }}/wp-config-sample.php


# edit configuration file
{% for key, value in [('database_name_here', grains['WP_DB']), ('username_here', grains['WP_USER']), ('password_here', '')] %}
wp_config_{{ key }}:
  file.replace:
    - name: {{ grains['WP_PATH'] }}/wp-config.php
    - pattern: {{ key }}
    - repl: '{{ value }}'
    - require:
      - id: wp_fresh_config
{% endfor %}


# here we trust wp-cli not to do any harm
# (mirrored on my server just in case)
wp-cli:
  pkg.installed:
      - name: php5-cli
  file.managed:
    - name: /usr/local/bin/wp-cli
    - source: http://www.messir.net/static/tmp/wp-cli.phar
    - source_hash: md5=b4344acd05a2cc9ba9c6ef1188a8a82b
    - mode: 755


# For relative URLs: wp-cli plugin install relative-url --activate
install_wordpress:
 cmd.run:
  - runas: {{ grains['WP_USER'] }}
  - cwd: {{ grains['WP_PATH'] }}
  - name: |
      wp-cli core install \
          --url=http://localhost:8888/ \
          --title="Oh My Wordpress" \
          --admin_user=notadmin \
          --admin_password="{{ grains['WP_PASSWORD'] }}" \
          --admin_email='pietro.dibello@xpeppers.com'
  - unless: wp-cli --path={{ grains['WP_PATH'] }} core is-installed
  - require:
    - id: wp_php-fpm_config


## activate auth_socket
unix_sock:
  cmd.run:
    - name: |
          mysql -e "INSTALL PLUGIN unix_socket SONAME 'auth_socket'"
    - onlyif: exit `mysql -BNe "select count(*) from INFORMATION_SCHEMA.PLUGINS where PLUGIN_NAME='unix_socket'"`


## these packages can be useful, but not immediately needed
#fullstackpkgs:
#  pkg.installed:
#    - install_recommends: False
#    - pkgs:
#      - build-essential
#      - checkinstall
