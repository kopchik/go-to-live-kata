#!/usr/bin/env python2
import json
import urllib2

JSON_URL = "https://api.wordpress.org/core/version-check/1.7/"

def get_wp_defaults():
  grains = { 'WP_USER':      "mysite",
             'WP_USER_HOME': "/home/mysite",
             'WP_PATH':      "/home/mysite/wp",
             'WP_DB':        "mysite" }
  return grains


def get_wp_version():
  data = json.load(urllib2.urlopen(JSON_URL))
  grains = {}
  grains['WP_VERSION'] = data['offers'][0]['version']  # latest stable version
  return grains
