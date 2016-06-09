## Setup

~~~
vagrant plugin install vagrant-salt
vagrant up
~~~
Then point your browser to http://localhost:8888/ and that's it :).

I used [4] and [5] to make the secured nginx configuration.

The deplyment is done via saltstack (like ansible but worse :)).
There are some nice dependencies so that, e.g., nginx will be restarted if its configuration is changed.

## Some Quirks

Could be done in a more concise way, but because of salt bugs I used more verbose syntax.
1. Container initialization is a bit long because we install salt from github and bootstrap scripts have numerous issues (they don't use --depth=1 for git clone, etc) and installs all the development dependencies.
The salt-minion shipped with ubuntu 14.04 is has numerous bugs ([1],[3]).
1. Yet bootstrap script does not install python-mysqldb which is required for mysql states.
I modified the bootstrap script because it needs to be present at the time salt is running.
1. I use mariadb because the ancent mysql shipped with ubuntu 14.04 does not support unix_socket. I decided not to go with backports or something.
1. Some parameters could be parametrized, but I think yaml+templates look just ugly.
1. We trust wp-cli provided by a third party is not malicious.


## What's left

1. Monitoring
1. Backups
1. User configs for homedir
1. Some basic firewall protection
1. Time sync. Is it needed inside


## References

[1] Crash with "KeyError: 'mysql_user.present'" message https://github.com/saltstack/salt/issues/27321
[2] Crash: "KeyError: 'mysql_user.present'" https://docs.saltstack.com/en/latest/topics/troubleshooting/yaml_idiosyncrasies.html
[3] Stuck on "[apt-get] <defunct>" https://github.com/saltstack/salt/issues/9736
[4] https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-nginx-on-ubuntu-14-04
[5] https://codex.wordpress.org/Nginx


Go to live! kata
==================================

Contained in this repo, there are some instructions for a new application that will go live in the next month!

You will need to:

1. Fork this repository.

2. Automate the creation of the infrastructure and the setup of the application.

   You have only these instructions:

   2.1 It works on Ubuntu Linux 14.04 x64

   2.2 It's based on the last version of WordPress (it will be more useful if we can parameterize the version)

   2.3 You can choose Apache, Nginx or whatever you want

   For any other issues or question you will have to ask to the developers. In this case please ask us without problems :)

3. Once deployed, the application should be secure, fast and stable. Assume that the machine is running on the public Internet and should be hardened and locked down.

4. Make any assumptions that you need to. This is an opportunity to showcase your skills, so if you want to, implement the deployment process with any additional features, tools or techniques you'd like to.

5. We are evaluating solutions based on the architecture and quality of the deployment. Show us just how beautiful, clean and pragmatic your code can be.

6. Once your solution is ready, please send us the link of your project.
