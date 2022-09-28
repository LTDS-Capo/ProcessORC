import dataclasses
from typing import List

rtl_folder = "rtl"

import glob, importlib, os, pathlib, sys

# load templates
t = pathlib.Path("templates.py").stem
templates = importlib.import_module(t)


@dataclasses.dataclass
class Marker:
    start: int
    end: int
    eval: str


def template_file(file_content, markers: List[Marker]):
    lines = file_content.splitlines()
    for marker in reversed(markers):
        e = "templates." + marker.eval.lstrip().rstrip()
        res = eval(e)
        lines.insert(marker.start + 1, res)
    re = '\n'.join(lines)

    return re


def strip_file(file_content, markers: List[Marker]):
    lines = file_content.splitlines()

    for marker in reversed(markers):
        for i in range(0, marker.end - marker.start - 1):
            del lines[marker.start + 1]

    re = '\n'.join(lines)

    return re


def parse_file(file_content: str) -> List[Marker]:
    re: List[Marker] = []
    lines = file_content.splitlines()

    flag = False
    cur = Marker(0, 0, "")

    for line in range(0, len(lines)):
        if flag:
            if "$$ENDGEN$$" in lines[line]:
                cur.end = line
                flag = False
                cur.eval = lines[cur.start].split("$$GEN$$")[-1]
                re.append(cur)
                cur = Marker(0, 0, "")
        else:
            if "$$GEN$$" in lines[line]:
                cur.start = line
                flag = True

    return re


def gen_in_place():
    files = glob.glob(rtl_folder + '/**/*.sv', recursive=True)
    for f in files:
        templates.reset_parameter()
        print(f"Processing file {f}")
        final_content = ""
        with open(f, "r") as fl:
            content = fl.read()
            markers = parse_file(content)
            striped_content = strip_file(content, markers)
            markers = parse_file(striped_content)
            final_content = template_file(striped_content, markers)

        with open(f, "w") as fl:
            fl.write(final_content)
        print()


if __name__ == "__main__":
    gen_in_place()
