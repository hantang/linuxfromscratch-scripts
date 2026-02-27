# linuxfromscratch-scripts

`Linux From Scratch` Scripts.

## Documents

- [Linux From Scratch, linuxfromscratch.org](https://www.linuxfromscratch.org/lfs/read.html)
- [Linux From Scratch 中文翻译, xry111.site](https://lfs.xry111.site/zh_CN/)
- Local guidance/note: [lfs/note.md](lfs/note.md)

## Versions

- Version 13 (2026-):
  - [ ] Version 13.0-rc1: February 14th, 2026
- Version 12 (2023-2025):
  - [ ] Version 12.4: September 1st, 2025
  - [ ] Version 12.3: March 5th, 2025
  - [ ] Version 12.2: September 1st, 2024
  - [ ] Version 12.1: March 1st, 2024
  - [x] Version 12.0: September 1st, 2023
- Version 11 (2021-2023):
  - [ ] Version 11.3: March 1st, 2023
  - [ ] Version 11.2: September 1st, 2022
  - [ ] Version 11.1: March 1st, 2022
  - [ ] Version 11.0: September 1st, 2021
- Version 10 (2020-2021):
  - [ ] Version GIT-20210406-g8186f16b0 (10.2-rc1): April 6th, 2021
  - [ ] Version 10.1: March 1st, 2021
  - [ ] Version 10.0: September 1st, 2020
- Version 9 (2019-2020):
  - [ ] Version 9.1: March 1st, 2020
  - [ ] Version 9.0: September 1st, 2019

## Steps

1. Create Scripts

> [!info]
> This step extract script from `LFS` document `<pre>` part.

```shell
# optional: download full directory, just need NOCHUNKS.html and md5sums file
bash download.sh lfs-doc 12.4
## sysvinit version
# wget -r -np -nH --cut-dirs=2 -R index.html -P demo https://www.linuxfromscratch.org/lfs/downloads/12.0/
## systemd version
# wget -r -np -nH --cut-dirs=2 -R index.html https://www.linuxfromscratch.org/lfs/downloads/12.0-systemd/

## stable version
# https://www.linuxfromscratch.org/lfs/downloads/stable/
# https://www.linuxfromscratch.org/lfs/downloads/stable-systemd/

# run scripts, use python 3.10+ with beautifulsoup4
# pip install -r requirements.txt
python html2scripts.py --version 12.4 --data lfs-doc --output lfs-out
```

2. Run LFS Scripts

> [!warning]
> Before run, read the LFS documents first and check autogen scripts.

Don't run immediately, read the LFS documents first,
then follow the `Step-by-Step` part in [lfs/note.md](lfs/note.md#step-by-step),
run the command in your terminal manually.
Some modifications are added from original extracted shell scripts by python.

## Related

- [luisgbm/lfs-scripts](https://github.com/luisgbm/lfs-scripts)
- [FreeFlyingSheep/lfs](https://github.com/FreeFlyingSheep/lfs)
- [qundao/mirror-lfs](https://github.com/qundao/mirror-lfs)
