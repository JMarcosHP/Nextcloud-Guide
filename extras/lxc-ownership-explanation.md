# LET'S CLARIFY THE LXC UNPRIVILEGED OWNESHIP

For this guide we will use an unprivileged LXC container. So for every local mountpoint on the Proxmox Host, you need to map the right uid and gid ownership.

For the Nextcloud data directory and other directories mounted as local external storage in the web interface that IDs translate from `33:33` (`www-data`) to `100033:100033`.

But if you already have a samba share configured with your own user and password, this will be no issue, because you can mount that share as external storage using your credentials and all your permissions/ownership will be inherited if you configured it correctly.

You can use Samba as an easy way to add external storage.

But if you feel brave, and choose the local external storage way, simply use a group with the same `uid:gid` in every LXC/VM.

For example, I have a ZFS dataset where I store all my personal data, that dataset called "home" is mounted locally in `/srv/nas/disk0/home` (The pool is named `disk0`) in the Proxmox node, I want to share it with samba to access it in my local network but at the same time I want to mount it as local external storage via the Nextcloud web interface to access it remotely in another network like google drive.

To make it working, first in the Proxmox host, change the ownership of all your shares: 

    chown -R 100033:100033 /srv/nas/disk0/home
    chmod -R 2775:2775 /srv/nas/disk0/home

(This is only for `www-data`, you can use another group like "`users`" `100100:100100`)

Then mount it in the Samba LXC (unprivileged).
Create a user (let's say files):

    useradd files -u 1000

And in the samba configuration use the following parameters for every folder share:

    force user = www-data
    force group = www-data

or:

    force group = users

If you want to mount the samba share directly in the web interface.

By using this, every file and folder you create will inherit that ownership and permissions using the `100033:100033` IDs assuming you always use unprivileged containers for data access, no matter what samba user you use it will be the same ownership for everyone and nextcloud will manage the content without issue.

Now if you need another unix user to access the data locally in another unprivileged LXC:

    useradd user -u 1000 -m -s /bin/bash 
    usermod -aG 33 user # 33 is the same as 100033 outside the container

Accessing from the Proxmox host:

    groupadd -g 100033 data # we can't use the same name as it's reserved for 33:33
    useradd user -u 101000 -g 100033 -m -s /bin/bash

This way, you can create a user with different name but maintaining the same uid.
You can read more about all of this [here](https://blog.kye.dev/proxmox-zfs-mounts).
Other guide about unix ownership [here](https://www.youtube.com/watch?v=CFhlg6qbi5M).

Explaining all of this, lets start.


