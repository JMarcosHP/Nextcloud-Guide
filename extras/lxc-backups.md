# How to make LXC Backups

For this guide is recommended 1 HDD/SSD apart from your main storage to save the backups or a Proxmox Backup Server to store the snapshots externally. Also, ZFS filesystem is recommended.

*NOTE: With this backup method, the bind-mounted directories will be excluded from the backup, only the LXC volume will be saved.*

**Table of Contents:**
 + [Guide](#guide)
	+ [STEP 1 (Optional)](#step-1-optional)
	+ [STEP 2](#step-2)
	+ [STEP 3](#step-3)
	+ [STEP 4 (Optional)](#step-4-optional)
+ [How to restore a container backup](#how-to-restore-a-container-backup)

## Guide

### STEP 1 (Optional):
If you already have a ZFS Pool for backups skip this step.

For this case I'll create a dataset in my dedicated disk for backups, since I backup another things apart. Inside the Proxmox shell execute:

    zfs create disk3/ct-backups

Then get the mountpoint for the created pool/dataset. (By default Proxmox mounts new ZFS Pools in `/poolname`)

    zfs get mountpoint disk3/ct-backups

### STEP 2:
Go to Datacenter > Storage in the Proxmox GUI, then select the storage type as Directory.

<img width="373" height="408" alt="image" src="https://github.com/user-attachments/assets/6a4d8a52-13dd-4fbe-a1e4-05d31195654f" />

<br/><br/><br/>

And add your ZFS pool/dataset as backup storage content, set the full mountpoint path, give it a name for ID and select your Proxmox node.

<img width="599" height="262" alt="image" src="https://github.com/user-attachments/assets/22b25f46-404e-483c-82a4-79a77ba7ff58" />

### STEP 3:
Create a Backup.
Select your Nextcloud container and go to the backup configuration.

<img width="542" height="240" alt="Captura desde 2025-08-06 15-26-17" src="https://github.com/user-attachments/assets/a46c63ec-4b98-4244-b2a3-482b8eb8f299" />

<br/><br/><br/>

Click in backup now. Then select your ZFS `ct-backups` storage, select Snapshot mode and ZSTD compression type.

<img width="600" height="306" alt="image" src="https://github.com/user-attachments/assets/c5572613-4a95-4092-9c8d-7bf2aeb2ca44" />

<br/><br/><br/>

Backup successfully created.

<img width="800" height="506" alt="Captura desde 2025-08-06 15-40-46" src="https://github.com/user-attachments/assets/56ed6e19-e2f6-4120-b7f9-8bdc3ed1277a" />

<br/><br/><br/>

### STEP 4 (Optional):
Setup a backup schedule job.

Go to Datacenter > Backup in the Proxmox GUI, and click the "Add" button.

Here, you can specify the Proxmox Node, and select your backup storage pool/dataset.

For the schedule, in this case I configured it to make backups everyday at 06:00 AM, you can check the Proxmox documentation about the [schedule format](https://pbs.proxmox.com/docs/calendarevents.html).

Make sure you selected your container ID to create a exclusive backup job schedule for it.

<img width="720" height="663" alt="image" src="https://github.com/user-attachments/assets/4c329c46-e688-47c0-a5aa-709b90a1c5d2" />

<br/><br/><br/>

## How to restore a container backup
To restore a container backup, simply select the desired backup file and click in the restore button. You can modify many options before restoring the backup if needed.

<img width="501" height="359" alt="image" src="https://github.com/user-attachments/assets/7ba0f6ba-3ee3-457c-a22f-5d3114b99c53" />



