# What should installed on every host (either physical or real or docker, whatever).
# Most of these tools are rarely needed, but for many reasons (e.g., network problems)
# it is handy have them preinstalled.

#update_salt:
#  pkgrepo.managed:
#    - name: deb https://repo.saltstack.com/apt/ubuntu/14.04/amd64/2016.3/ trusty main
#    - gpgkey: https://repo.saltstack.com/apt/ubuntu/14.04/amd64/2016.3/SALTSTACK-GPG-KEY.pub
#  pkg.latest:
#    #- refresh: True
#    #- skip_suggestions: True
#    #- allow_updates: True
#    - skip_verify: True  # I'm too lazy to mess up with keys
#    #- only_upgrade: True
#    #- version: 'latest'
#    - pkgs:
#      - salt-minion

basepkgs:
  pkg.installed:
    # just in case, id:apt-no-recommends will do the job anyway
    - install_recommends: False
    - pkgs:
      - git
      - tar
      - wget
      - lsof
      - less
      - pwgen
      - zip
      - strace
      - tmux
      - mc
      - iptables
      - ebtables
      - bridge-utils
      - tcpdump
      - openssh-server
      - debsums
      # for salt's better grains match
      - virt-what
      - telnet
      - psmisc
      #- openntpd
      - mdadm
      #- lvm2
      - whois
      - apcalc
      - links
      #- build-essential
      #- checkinstall
      # for salt to work with mysqll
      #- python-mysqldb


  require:
      - id: apt-no-recommends


# Optional packages are mostly garbage blowing up the VM.
# Let's explicitly disable them.
apt-no-recommends:
  file.managed:
    - name: "/etc/apt/apt.conf.d/11-apt-no-recommends"
    - source: salt://configs/11-apt-no-recommends
    - user: root
    - group: root
    - mode: '0644'
    - follow_symlinks: False



## taken from https://github.com/phistrom/ubuntu_workstation_salt
ssh_server_usedns_no:
    file.replace:
        - name: /etc/ssh/sshd_config
        - pattern: 'UseDNS.+'
        - repl: "UseDNS no"
        - flags:
            - 'IGNORECASE'
        - append_if_not_found: True
        - require:
            - pkg: openssh-server
        - watch_in:
            - service: openssh-server


openssh-server:
    pkg.installed: []
    service.running:
        - name: ssh


rpcbind:
  pkg.purged: []


## root comes with unknown hash
root:
  user.present:
    - password: '*'


## I don't know what is this user for and I don't like it
ubuntu:
  user.absent:
    - purge: True
    - force: True
