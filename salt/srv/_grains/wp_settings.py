#!/usr/bin/env python2
import json
import urllib2
import os
from string import letters, digits
from random import choice

JSON_URL = "https://api.wordpress.org/core/version-check/1.7/"
WP_PWDFILE = "/root/{prefix}_wp_admin_passwd"

def get_wp_defaults():
  grains = { 'WP_USER':      "mysite",
             'WP_USER_HOME': "/home/mysite",
             'WP_PATH':      "/home/mysite/wp",
             'WP_DB':        "mysite" }
  pwd_path = WP_PWDFILE.format(prefix=grains['WP_USER'])
  if os.path.exists(pwd_path):
    ## for security reasons we do not keep password loaded in salt
    #grains['WP_PASSWORD'] = '<INVALID_PW>' + ''.join(choice(letters+digits) for _ in range(16))
    grains['WP_PASSWORD'] = open(pwd_path, 'rt').read()
  else:
    password = ''.join(choice(letters+digits) for _ in range(16))
    # securely create password file
    with os.fdopen(os.open(pwd_path,
                   os.O_WRONLY | os.O_CREAT, 0600), 'w') as fd:
      fd.write(password)
    grains['WP_PASSWORD'] = password
  return grains


def get_wp_version():
  data = json.load(urllib2.urlopen(JSON_URL))
  grains = {}
  grains['WP_VERSION'] = data['offers'][0]['version']  # latest stable version
  return grains


## to check from command line
if __name__ == '__main__':
  print(get_wp_defaults())
