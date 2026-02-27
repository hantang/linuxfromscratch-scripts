#!/usr/bin/env python
# coding: utf-8

"""
Parse scripts in LFS html, output by chapters.
example:
    python html2scripts.py --version 12.0 --data lfs-doc --output lfs-out --all
"""

import argparse
import json
import logging
import re
from pathlib import Path
import shutil

from bs4 import BeautifulSoup

PARTS_COUNT = 5
TITLE_CLASS = "titlepage"


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
    # e.g.: python-3.11.4-docs-html.tar.bz2, ncurses-6.5-20250809.tgz
    pattern2 = r"(?P<name>\w[\w\-]*\w+)-(?P<version>(\d+\.)*\d+)-(?P<extra>[\w\-]+)\.(?P<suffix>((tar|tgz)(\.\w+)?)|(patch))"
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
        "sqlite": "sqlite-doc", # 13.0, sqlite-autoconf, sqlite-doc
    }
    package_rename = {k.lower(): v.lower() for k, v in package_rename.items()}
    return package_dict, package_rename


def _get_content_pairs(has_title, body, class_value, title_key):
    pairs = []
    contents = body.find_all("div", recursive=False, class_=class_value)
    if not has_title:
        titles = body.find_all("div", class_=title_key, recursive=False)
        assert len(titles) == len(contents)
        pairs = list(zip(titles, contents))
    else:
        pairs = [[ch.find("div", class_=title_key, recursive=False), ch] for ch in contents]
    return pairs


def _parse_page(pages, package_dict, package_rename):
    data_pages = []
    for page_title, page in pages:
        h2 = page_title.h2.text.strip()
        title = strip(h2)

        if page.find(class_="installation"):
            package = h2.split("\xa0", 1)[-1].split()[0]
            module = split_name2(package)
            package_info = package_dict[package_rename.get(module, module)]
        else:
            package = None
            package_info = None

        inputs = page.find_all("pre", class_="userinput")
        if not inputs:
            inputs = page.find_all("pre", class_="root")

        user_inputs = []
        for ipt in inputs:
            if "class" in ipt.parent.attrs:
                cmd_class = ipt.parent["class"]
            else:
                cmd_class = ipt.parent.parent["class"]
            cmd_class = " ".join(cmd_class)

            for kbd in ipt.find_all("kbd"):
                cmd = kbd.text.strip()
                cmd_params = {
                    "command": cmd,
                    "class": cmd_class,
                    "check": is_check(cmd),
                }
                user_inputs.append(cmd_params)
        tmp_page_data = {
            "title": title,
            "package": package,
            "info": package_info,
            "user_inputs": user_inputs,
        }
        data_pages.append(tmp_page_data)
    return data_pages


def parse_html(html_file, package_dict, package_rename, save_dir, save_all):
    chapter_classes = ["chapter", "preface", "appendix"]
    section_classes = ["sect1", "wrap"]
    part_classes = ["part", "preface", "index", "toc", TITLE_CLASS]

    logging.info(f"read {html_file}")
    with open(html_file, encoding="iso-8859-1") as f:
        text = f.read()

    soup = BeautifulSoup(text, "html.parser")
    body = soup.body
    book = body.find("div", class_="book")

    # toc = book.find(class_="toc")
    # preface = book.find(class_="preface")
    parts_titles = book.find_all("div", class_=TITLE_CLASS, recursive=False)
    parts_list = book.find_all("div", class_=part_classes, recursive=False)

    has_title = True  # title in chapter
    if len(parts_titles) > 1:  # tile in front of chapter
        has_title = False
        parts = []
        for i, part in enumerate(parts_list):
            if "part" in part["class"]:
                part_title = parts_list[i - 1]
                assert TITLE_CLASS in part_title["class"]
                parts.append([part_title, part])
    else:
        parts = [
            [part.find(class_=TITLE_CLASS), part]
            for part in parts_list
            if "part" in part["class"]
        ]

    assert len(parts) == PARTS_COUNT
    if not save_all:
        parts = parts[1:-1]  # Part II ~ Part IV

    script_data = []
    for part_title, part in parts:
        title_part = part_title.h1.text.strip()
        chapters_pairs = _get_content_pairs(has_title, part, chapter_classes, TITLE_CLASS)
        data_chap = []
        for chap_title, chap in chapters_pairs:
            title_chap = chap_title.h2.text.strip()
            sect_pairs = _get_content_pairs(
                has_title, chap, section_classes, TITLE_CLASS
            )
            data_pages = _parse_page(sect_pairs, package_dict, package_rename)
            tmp_chap_data = {
                "title_chapter": strip(title_chap),
                "page_count": len(sect_pairs),
                "pages": data_pages,
                "class": chap["class"],
            }
            data_chap.append(tmp_chap_data)

        tmp_part_data = {
            "title_part": strip(title_part),
            "chapter_count": len(chapters_pairs),
            "chapters": data_chap,
        }
        script_data.append(tmp_part_data)

    savefile = Path(save_dir, "scripts.json")
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


def output_scripts(script_data, save_dir, use_tar=False, line_len=72):
    line_part = "#" * line_len
    line_chap = "# " + "=" * (line_len - 2)
    line_page = "# " + "-" * (line_len - 2)
    input_class = ["sect1", "sect2", "sect3", "installation", "configuration"]
    cmt1 = "# " if use_tar else ""
    cmt2 = "" if use_tar else "# "

    logging.info("parse to scripts")
    last_check = 0
    chapter_index_last = None
    for part in script_data:
        prefix = re.sub(r"[\-\s]+", "-", part["title_part"].split(".")[0])
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

                    lines = [
                        f"{cmt1}begin_install {stem} {suffix}",
                        f"{cmt2}tar -xf {fullname} && cd {stem}",
                    ]
                    texts.extend(lines + [""])

                for ipt in page["user_inputs"]:
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
                    lines = ["", f"{cmt2}cd .. && rm -rf {stem}", f"{cmt1}end_install"]
                    texts.extend(lines)

            if "preface" in chap["class"]:
                save_name = "{}-ch{:02d}-pre.sh".format(prefix, chapter_index_last + 1)
            elif "appendix" in chap["class"]:
                name = chap["title_chapter"].split(".")[0].lower().strip()
                name = re.sub(r"[\-\s]+", "-")
                save_name = prefix + "-" + name + ".sh"
            else:
                chapter_index = int(chap["title_chapter"].split(".")[0].split(" ")[-1])
                chapter_index_last = chapter_index
                save_name = "{}-ch{:02d}.sh".format(prefix, chapter_index)

            savefile = Path(save_dir, save_name)
            logging.info(f"save to {savefile}")
            with open(savefile, "w") as fw:
                texts = strip2("\n".join(texts))
                fw.write(texts)


def process(lfs_version, doc_dir, out_dir, save_all):
    data_dir = Path(doc_dir, lfs_version)

    html_files = list(Path(data_dir).glob("LFS*-NOCHUNKS.html"))
    if not html_files:
        logging.warning(f"No html file in {data_dir}")
        return
    html_file = html_files[0]

    md5_file = Path(data_dir, "md5sums")
    logging.info(f"process lfs version = {lfs_version}")

    save_dir = Path(out_dir, lfs_version)
    if save_dir.exists():
        shutil.rmtree(save_dir)
    logging.info(f"make dir {save_dir}")
    save_dir.mkdir(parents=True)

    package_dict, package_rename = extract_packages(md5_file)
    script_data = parse_html(html_file, package_dict, package_rename, save_dir, save_all)
    output_scripts(script_data, save_dir, use_tar=False)


if __name__ == "__main__":
    """
    docs: https://www.linuxfromscratch.org/lfs/view/
    """
    fmt = "%(asctime)s [line:%(lineno)d] %(levelname)s %(message)s"
    logging.basicConfig(level=logging.INFO, format=fmt)

    parser = argparse.ArgumentParser()
    parser.add_argument("--version", type=str, required=True)
    parser.add_argument("--data", type=str, default="data")
    parser.add_argument("--output", type=str, default="output")
    parser.add_argument("--all", action="store_true")

    args = parser.parse_args()
    logging.info(f"args = {args}")
    process(args.version, args.data, args.output, args.all)
    logging.info("end")
