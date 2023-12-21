# linuxfromscratch-scripts

`Linux From Scratch` Scripts.

## Online Documents

- [Linux From Scratch ](https://www.linuxfromscratch.org/lfs/read.html)
- [Linux From Scratch 中文翻译](https://lfs.xry111.site/zh_CN/)

## Create Scripts

```shell
# optional: download full directory, just need NOCHUNKS.html and md5sums file
## sysvinit version
# wget -r -np -nH -R index.html https://www.linuxfromscratch.org/lfs/downloads/12.0/
## systemd version
# wget -r -np -nH -R index.html https://www.linuxfromscratch.org/lfs/downloads/12.0-systemd/

# python 3.10, needs beautifulsoup4
python html2scripts.py
```

## Run LFS Scripts

Don't run immediately, read the LFS documents first,
then follow the steps in [note](./lfs/note.md) in `lfs`.
Some modifications are added from original extracted scripts by python.

## Related

- [luisgbm/lfs-scripts](https://github.com/luisgbm/lfs-scripts)
- [FreeFlyingSheep/lfs](https://github.com/FreeFlyingSheep/lfs)
