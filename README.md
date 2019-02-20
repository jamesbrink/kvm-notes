# Linux KVM/Virsh Notes

This is just a dumping ground for some Linux KVM notes and scripts for later reference.  


## Creating guest instances

To create a Debian 9 instance. 

```shell
    virt-install \
    --name debian9 \
    --ram 1024 \
    --disk path=./debian8.qcow2,size=9 \
    --vcpus 1 \
    --os-type linux \
    --os-variant debian8 \
    --network bridge=virbr10 \
    --console pty,target_type=serial \
    --graphics vnc,listen=0.0.0.0 --noautoconsole \
    --location 'http://ftp.nl.debian.org/debian/dists/stretch/main/installer-amd64/' \
    --extra-args 'console=ttyS0,115200n8 serial' \
```

You can remove the `network` argument to use the default built in NAT.  

Be sure to get a terminal after install and run the following if you want to continue using tty console. *This does not cover grub support*

```shell
systemctl enable serial-getty@ttyS0.service
```

Adding vnc to an existing domain (guest)

```shell
virsh edit --domain debian9
```

```XML
<graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'/>
```

## References

* [libvirt networking handbook](https://jamielinux.com/docs/libvirt-networking-handbook/)
* [virt-install one liners](https://raymii.org/s/articles/virt-install_introduction_and_copy_paste_distro_install_commands.html)