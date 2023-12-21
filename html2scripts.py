#!/usr/bin/env python
# coding: utf-8

"""
Parse scripts in LFS html, output by chapters.
"""

import json
import logging
import re
from pathlib import Path

from bs4 import BeautifulSoup


def strip(text):
    return re.sub(r"\s+", " ", text).strip()


def strip2(text, last=True):
    text = text.strip()
    text = re.sub(r"\s+$", "", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text + "\n" if last else text


def is_check(text):
    # mark make test or make test
    if (
            re.findall(r"make .*(check|test)", text)
            or re.findall(r"(chown|su) .*tester", text)
            or "grub-mkrescue" in text
            or "test_summary" in text
            or "ulimit -s" in text
            or "libfoo" in text
            or ("dummy" in text and ("groupadd" in text or "groupdel" in text))
            or text.startswith("wget ")
    ):
        return True
    else:
        return False


def split_name(package):
    # package naming: name-version-extra.suffix
    # e.g.: acl-2.3.1.tar.xz
    pattern1 = r"(?P<name>\w[\w\-]*\w+)-(?P<version>(\d+\.)*\d+)(?P<extra>)\.(?P<suffix>(tar(\.\w+)?)|(patch))"
    # e.g.: python-3.11.4-docs-html.tar.bz2
    pattern2 = r"(?P<name>\w[\w\-]*\w+)-(?P<version>(\d+\.)*\d+)-(?P<extra>[\w\-]+)\.(?P<suffix>(tar(\.\w+)?)|(patch))"
    # e.g.: tcl8.6.13-src.tar.gz
    pattern3 = r"(?P<name>[a-zA-Z]+)(?P<version>(\d+\.)*\d+[a-z]?)-?(?P<extra>[\w\-]*)\.(?P<suffix>(tar(\.\w+)?)|(patch))"
    m = None
    for pat in [pattern1, pattern2, pattern3]:
        m = re.match(pat, package)
        if m:
            break
    return m


def split_name2(package):
    pack = package.lower().split()[0]
    m = re.match(r"(?P<name>\w[\w\-:]*\w+)-(?P<version>(\d+\.)*\d+)", pack)
    if m:
        return m.group("name")
    logging.warning(f"not found pack = {package}, {pack}")
    return pack


def extract_packages(md5_file):
    # extract package info from md5 file
    logging.info(f"read md5 file: {md5_file}")
    with open(md5_file) as f:
        md5list = f.readlines()

    logging.info("process packages")
    package_dict = {}
    for line in md5list:
        line = line.strip()
        if line == "":
            continue
        md5, pack = line.split()
        m = split_name(pack)
        if not m:
            logging.warning(f"Error split name of {pack}")
            continue
        name, version, extra, suffix = (
            m.group("name"),
            m.group("version"),
            m.group("extra"),
            m.group("suffix"),
        )
        if suffix == "patch":
            logging.info(f"ignore patch file: {pack}")
            continue
        if "html" in extra or "doc" in extra:
            logging.info(f"ignore doc file: {pack}")
            continue

        stem = pack.split(suffix)[0].rstrip(".")
        key = name.lower()
        assert key != ""
        assert key not in package_dict, (key, pack, package_dict[key])
        package_dict[key] = {
            "full": pack,
            "md5": md5,
            "stem": stem,
            "suffix": suffix,
            "name": name,
            "version": version,
            "extra": extra,
        }

    logging.info(f"Total packages = {len(package_dict)}")

    # special packages: part in tar or renamed
    package_rename = {
        "Libstdc++": "gcc",
        "Libelf": "elfutils",
        "Udev": "systemd",
        "Flit-Core": "flit_core",
        "XML::Parser": "XML-Parser",
        "D-Bus": "dbus",
    }
    package_rename = {k.lower(): v.lower() for k, v in package_rename.items()}
    return package_dict, package_rename


def parse_html(html_file, package_dict, package_rename, savedir):
    logging.info(f"read {html_file}")
    with open(html_file, encoding="iso-8859-1") as f:
        text = f.read()

    soup = BeautifulSoup(text, "html.parser")
    body = soup.body
    book = body.find("div", class_="book")
    # toc = book.find(class_="toc")
    # preface = book.find(class_="preface")

    parts_all = book.find_all("div", class_="part", recursive=False)
    parts = parts_all[1:-1]  # part2 ~ part4 (chapter 2~11)
    script_data = []
    for part in parts:
        title_part = part.find(class_="titlepage").h1.text.strip()
        chapters = part.find_all("div", class_="chapter")

        data_chap = []
        for chap in chapters:
            title_chap = chap.h2.text.strip()
            pages = chap.find_all("div", lang="en", recursive=False)
            data_pages = []
            for page in pages:
                h2 = page.h2.text.strip()
                title = strip(h2)

                if page.find(class_="installation"):
                    package = h2.split("\xa0")[1].split()[0]
                    module = split_name2(package)
                    package_info = package_dict[package_rename.get(module, module)]
                else:
                    package = None
                    package_info = None

                inputs = page.find_all("pre", class_="userinput")
                if not inputs:
                    inputs = page.find_all("pre", class_="root")

                if inputs:
                    userinputs = []
                    for ipt in inputs:
                        if "class" in ipt.parent.attrs:
                            cmd_class = ipt.parent["class"]
                        else:
                            cmd_class = ipt.parent.parent["class"]
                        cmd_class = " ".join(cmd_class)

                        for kbd in ipt.find_all("kbd"):
                            cmd = kbd.text.strip()
                            userinputs.append(
                                {
                                    "command": cmd,
                                    "class": cmd_class,
                                    "check": is_check(cmd),
                                }
                            )
                    tmp_page_data = {
                        "title": title,
                        "package": package,
                        "info": package_info,
                        "userinputs": userinputs,
                    }
                    data_pages.append(tmp_page_data)
            tmp_chap_data = {
                "title_chapter": strip(title_chap),
                "page_count": len(pages),
                "pages": data_pages,
            }
            data_chap.append(tmp_chap_data)
        tmp_part_data = {
            "title_part": strip(title_part),
            "chapter_count": len(chapters),
            "chapters": data_chap,
        }
        script_data.append(tmp_part_data)

    savefile = Path(savedir, "scripts.json")
    logging.info(f"save to json: {savefile}")
    with open(savefile, "w") as fw:
        json.dump(script_data, fw, indent=2, ensure_ascii=False)
    return script_data


def copy_tcl(pack_info):
    # rename: tclX.X.XX-src.tar.gz -> tclX.X.XX.tar.gz
    fullname = pack_info["full"]
    fullname2 = fullname.replace("-src", "")
    cmd = f"cp {fullname} {fullname2}"
    stem2 = pack_info["stem"].replace("-src", "")
    return [fullname2, stem2, cmd]


def output_scripts(script_data, savedir, use_tar=False, line_len=72):
    line_part = "#" * line_len
    line_chap = "# " + "=" * (line_len - 2)
    line_page = "# " + "-" * (line_len - 2)
    input_class = ["sect1", "sect2", "sect3", "installation", "configuration"]
    cmt1 = "# " if use_tar else ""
    cmt2 = "" if use_tar else "# "

    logging.info("parse to scripts")
    last_check = 0
    for part in script_data:
        for chap in part["chapters"]:
            texts = [
                line_part,
                f"### {part['title_part']}",
                line_part + "\n",
                line_chap,
                f"## {chap['title_chapter']}",
                line_chap + "\n",
            ]
            for page in chap["pages"]:
                texts.extend(["\n" + line_page, f"# {page['title']}"])
                if page["package"]:
                    texts.append(f"# {page['package']} ({page['info']['full']})")
                texts.append(line_page + "\n")

                if page["package"]:
                    stem = page["info"]["stem"]
                    suffix = page["info"]["suffix"]
                    fullname = page["info"]["full"]
                    if page["info"]["name"] == "tcl":
                        fullname, stem, cmd = copy_tcl(page["info"])
                        texts.append(cmd)
                    texts.extend([
                        f"{cmt1}begin_install {stem} {suffix}", f"{cmt2}tar -xf {fullname} && cd {stem}", ""
                    ])

                for ipt in page["userinputs"]:
                    cmd = ipt["command"]
                    last_check = ((last_check % 2) * 2) + int(ipt["check"])
                    if ipt["check"] or (ipt["class"] not in input_class):
                        if last_check == 0b1:
                            texts.append("")
                        if ipt["class"] not in input_class[:4]:
                            texts.append(f"\n## {ipt['class']}")
                        # convert to comment
                        new_cmd = "\n".join([f"# {line}" for line in cmd.split("\n")])
                        texts.extend([new_cmd])
                    else:
                        is_cat = cmd.strip().startswith("cat >") and cmd.strip().endswith("EOF")
                        if is_cat or last_check == 0b10:
                            texts.append("")
                        texts.append(cmd)
                        if is_cat:
                            texts.append("")

                if page["package"]:
                    texts.extend([
                        "", f"{cmt2}cd .. && rm -rf {stem}", f"{cmt1}end_install"
                    ])

            chapter_index = int(chap["title_chapter"].split(".")[0].split(" ")[-1])
            savefile = Path(savedir, "ch{:02d}.sh".format(chapter_index))
            logging.info(f"save to {savefile}")
            with open(savefile, "w") as fw:
                texts = strip2("\n".join(texts))
                fw.write(texts)


def process(lfs_version, doc_dir, save_dir):
    version_short = lfs_version.split("-")[0]
    prefix = lfs_version
    savedir = f"{save_dir}/{prefix}"
    doc_version = lfs_version
    html_file = f"{doc_dir}/{doc_version}/LFS-BOOK-{version_short}-NOCHUNKS.html"
    md5_file = f"{doc_dir}/{doc_version}/md5sums"

    logging.info(f"process lfs version = {lfs_version}")
    savedir = Path(savedir)
    if not savedir.exists():
        logging.info(f"make dir ${savedir}")
        savedir.mkdir(parents=True)

    package_dict, package_rename = extract_packages(md5_file)
    script_data = parse_html(html_file, package_dict, package_rename, savedir)
    output_scripts(script_data, savedir, use_tar=False)


if __name__ == "__main__":
    """
    docs: https://www.linuxfromscratch.org/lfs/view/
    """
    fmt = "%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s"
    logging.basicConfig(level=logging.INFO, format=fmt)

    doc_dir = "docs"
    save_dir = "scripts"
    for lfs_version in ["12.0", "12.0-systemd"]:
        process(lfs_version, doc_dir, save_dir)
    logging.info("end")
