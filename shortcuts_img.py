#!/usr/bin/env python3
import os
import sys
import vdf
import shutil
import argparse


def __get_steam_user_dirs(steam_dir):
    base = os.path.join(steam_dir, "userdata")
    user_dirs = []
    if os.path.isdir(base):
        for d in os.listdir(base):
            if d not in ["anonymous", "ac", "0"]:
                user_dirs.append(os.path.join(base, d))
    return user_dirs


DATA_HOME = os.path.expanduser("~/.local/share")
STEAM_DIR = os.path.join(DATA_HOME, "Steam")
STEAM_USER_DIRS = __get_steam_user_dirs(STEAM_DIR)


def ensure_directory(directory):
    if not os.path.isdir(directory):
        os.makedirs(directory, mode=0o755, exist_ok=True)


def ensure_directory_for_file(file):
    d = os.path.dirname(file)
    ensure_directory(d)


def get_banner_id(compat_id):
    return str(compat_id)


def get_poster_id(compat_id):
    return str(compat_id) + "p"


def get_background_id(compat_id):
    return str(compat_id) + "_hero"


def get_logo_id(compat_id):
    return str(compat_id) + "_logo"


def get_icon_id(compat_id):
    return str(compat_id) + "_icon"


def get_image_id(type, compat_id):
    if type == "banner":
        return get_banner_id(compat_id)
    elif type == "poster":
        return get_poster_id(compat_id)
    elif type == "background":
        return get_background_id(compat_id)
    elif type == "logo":
        return get_logo_id(compat_id)
    elif type == "icon":
        return get_icon_id(compat_id)


class SteamShortcutsFile:
    """Class to manage Steam shortcuts files for users"""

    path: str
    tags: dict
    user_id: str
    current_data: dict

    def __init__(self, user_id: str, auto_load: bool = True):
        self.user_id = user_id
        self.path = os.path.join(STEAM_DIR, "userdata", user_id, "config/shortcuts.vdf")
        self.current_data = {}
        self.tags = {}
        if auto_load:
            self.load_data()

    def exists(self) -> bool:
        """Returns True if this file exists. False otherwise"""
        return os.path.exists(self.path)

    def get_user_dir(self) -> str:
        """Returns the user directory for this file"""
        return os.path.join(STEAM_DIR, "userdata", self.user_id)

    def get_current_data(self) -> dict:
        """Returns this file's shortcut data as a list of dictionaries"""
        return self.current_data

    def load_data(self) -> None:
        """Reads shortcut data from this file. It returns a dictionary
        with the data. If the file does not exists, it will load an empty
        dictionary.
        """
        if not self.exists():
            self.current_data = {}
            return

        with open(self.path, "rb") as vdf_file:
            data = vdf.binary_load(vdf_file)
            if "shortcuts" in data:
                self.current_data = data["shortcuts"]

    def save(self) -> None:
        """Save current file with current shortcuts data"""
        out = {}
        data = {}
        for index in self.current_data:
            data[str(index)] = self.current_data[index]
        out["shortcuts"] = data
        ensure_directory_for_file(self.path)
        with open(self.path, "wb") as ss_file:
            ss_file.write(vdf.binary_dumps(out))


def remove_all_images(dst, dstext):
    for ext in [dstext, ".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG"]:
        f = dst + ext
        if os.path.islink(f) or os.path.isfile(f):
            os.remove(f)


def create_image(
    img_path,
    compat_id,
    img_type_dst=None,
    steam_shortcuts_file: SteamShortcutsFile = None,
) -> None:
    if steam_shortcuts_file is not None:
        user_dir = steam_shortcuts_file.get_user_dir()
        create_image(img_path, compat_id, user_dir, img_type_dst)
    else:
        for user_dir in STEAM_USER_DIRS:
            create_image(img_path, compat_id, user_dir, img_type_dst)


def create_image(img_path, compat_id, user_dir, img_type_dst=None) -> str:
    _, ext = os.path.splitext(img_path)
    dst_dir = os.path.join(user_dir, "config", "grid")
    if not os.path.isdir(dst_dir):
        os.makedirs(dst_dir)
    img_id = get_image_id(img_type_dst, compat_id)
    dst = os.path.join(dst_dir, str(img_id))
    remove_all_images(dst, ext)
    dst = dst + ext

    home_dir = os.path.expanduser("~")
    if home_dir in img_path and img_path.index(home_dir) == 0:
        # image file is inside user's home directory, use symlinks for efficiency
        os.symlink(img_path, dst)
    else:
        # Steam does not load images outside the user's home directory, so copy the files instead
        shutil.copyfile(img_path, dst)
    return dst


def create_image_from_exe(exe, name, img_path, img_type_dst=None):
    for user_dir in STEAM_USER_DIRS:
        steam_shortcuts_file = SteamShortcutsFile(os.path.basename(user_dir))
        shortcuts_map = steam_shortcuts_file.get_current_data()
        for key in shortcuts_map:
            shortcut = shortcuts_map[key]
            if shortcut["exe"] == exe and shortcut["appname"] == name:
                app_id = shortcut["appid"]
                compat_id = app_id + 2**32
                dst = create_image(img_path, compat_id, user_dir, img_type_dst)
                print(f"Created image {dst} for {name}")
                if img_type_dst == "icon":
                    shortcut["icon"] = dst
        steam_shortcuts_file.save()


def main():
    parser = argparse.ArgumentParser(description="Steam shortcuts 图片管理")
    parser.add_argument(
        "-t", "--type", type=str, default="fromexe", help="操作类型, 默认为 fromexe"
    )
    parser.add_argument("-n", "--name", type=str, help="应用名称")
    parser.add_argument("-e", "--exe", type=str, help="执行文件路径")
    parser.add_argument("-i", "--icon", type=str, help="图标路径")
    parser.add_argument("-c", "--cover", type=str, help="封面路径")
    parser.add_argument("-cc", "--banner", type=str, help="封面横幅路径")
    parser.add_argument("-b", "--background", type=str, help="背景路径")
    parser.add_argument("-l", "--logo", type=str, help="Logo 路径")

    args = parser.parse_args()

    if args.type == "fromexe":
        if args.name is None or args.exe is None:
            print("错误: 当 --type 为 'fromexe' 时，--name 和 --exe 是必需的")
            sys.exit(1)
        name = args.name
        exe = args.exe
        if args.icon is not None:
            create_image_from_exe(exe, name, args.icon, "icon")
        if args.cover is not None:
            create_image_from_exe(exe, name, args.cover, "poster")
        if args.banner is not None:
            create_image_from_exe(exe, name, args.banner, "banner")
        if args.background is not None:
            create_image_from_exe(exe, name, args.background, "background")
        if args.logo is not None:
            create_image_from_exe(exe, name, args.logo, "logo")


if __name__ == "__main__":
    main()
