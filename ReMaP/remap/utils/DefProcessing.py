# Not used for now

import os
import regex as re

class Trigger:
    def __init__(self, pattern, callback=None, **key2group_map):
        self.rule = re.compile(pattern)
        self.callback = callback
        self.key2group_map = key2group_map

    def match2kwdict(self, match):
        return {key: match.group(group) for key, group in self.key2group_map.items()}

    def __call__(self, s: str, **kwargs) -> bool:
        match = self.rule.search(s)
        if match is None:
            return False
        if self.callback is not None:
            kwargs.update(self.match2kwdict(match))
            self.callback(**kwargs)

        return True


class DefFile:

    def __init__(self, file_name):
        assert os.path.exists()
        self.file_name = file_name
        self.lines = []
        self.s_idx_comp_end = None

    def parsing(self):
        with open(self.file_name, "r") as f:
            raw_lines = f.readlines()

        sentences = []
        buffer = []
        tg_end_part  = Trigger(r"END\s+[a-zA-Z0-9]+\s*$")
        tg_semicolon = Trigger(r".*;\s*$")
        for line in raw_lines:
            buffer.append(line)
            if tg_end_part(line) or tg_semicolon(line):
                sentences.append("\n".join(buffer))
                buffer.clear()

        if len(buffer) > 0:
            sentences.append("\n".join(buffer))

        component_flag = False

        tg_comp_begin = Trigger(r"COMPONENTS (\d+)\s*;")
        tg_comp_end   = Trigger(r"END\s+COMPONENTS")
        for index, s in enumerate(sentences):
            if tg_comp_begin(s):
                component_flag = True
                continue

            if tg_comp_end(s):
                component_flag = False
                self.s_idx_comp_end = index
                continue

            if component_flag:
                pass
            

    def setComponents(self, componentName=None, status="PLACED"):
        pass