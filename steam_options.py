#!/usr/bin/env python3
from abc import ABC, abstractmethod
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


class SteamConfigFile(ABC):
    """Class to represent a Steam configuration file"""

    path: str
    config_data: vdf.VDFDict

    def __init__(self, path: str, auto_load=False):
        self.path = path
        self.config_data = None
        if auto_load:
            self.load_data()

    def exists(self) -> bool:
        """Returns True if the file exists, False otherwise"""
        return os.path.exists(self.path)

    @abstractmethod
    def apply_tweaks(self, tweak_data: dict, priority: int) -> None:
        """Apply tweaks data to this configuration file"""

    @abstractmethod
    def load_data(self) -> None:
        """Load data contained in this file and return a dictionary"""

    def save(self) -> None:
        """Save the file"""
        conf = vdf.dumps(self.config_data, pretty=True)
        ensure_directory_for_file(self.path)
        with open(self.path, "w") as file:
            file.write(conf)


class LocalSteamConfig(SteamConfigFile):
    """Handle local user Steam config file"""

    user_id: str

    def __init__(self, user_id: str, auto_load=False):
        self.user_id = user_id
        path_to_file = os.path.join(
            STEAM_DIR, "userdata", user_id, "config/localconfig.vdf"
        )
        super().__init__(path_to_file, auto_load)

    def load_data(self) -> None:
        if self.exists():
            data = vdf.load(open(self.path))
        else:
            data = vdf.VDFDict()
            data["UserLocalConfigStore"] = {"Software": {"Valve": {"Steam": {}}}}

        steam_input = data["UserLocalConfigStore"]
        if "apps" not in steam_input:
            steam_input["apps"] = {}

        launch_options = data["UserLocalConfigStore"]["Software"]["Valve"]["Steam"]
        if "apps" not in launch_options:
            launch_options["apps"] = {}

        self.config_data = data

    def get_launch_options(self, app_id: int) -> str:
        if not self.config_data:
            self.load_data()
        try:
            return self.config_data["UserLocalConfigStore"]["Software"]["Valve"]["Steam"][
                "apps"
            ][str(app_id)]["LaunchOptions"]
        except KeyError:
            return ""
        
    def set_launch_options(self, app_id: int, options: str) -> None:
        if not self.config_data:
            self.load_data()
        self.config_data["UserLocalConfigStore"]["Software"]["Valve"]["Steam"]["apps"][
            str(app_id)
        ]["LaunchOptions"] = options


def get_launch_options(app_id: int) -> str:
    for user_dir in STEAM_USER_DIRS:
        steam_config = LocalSteamConfig(os.path.basename(user_dir))
        options = steam_config.get_launch_options(app_id)
        if options:
            return options
    return ""

def set_launch_options(app_id: int, options: str) -> None:
    for user_dir in STEAM_USER_DIRS:
        steam_config = LocalSteamConfig(os.path.basename(user_dir))
        steam_config.set_launch_options(app_id, options)
        steam_config.save()

def main():
    parser = argparse.ArgumentParser(description="Steam app Launch Options 管理")
    parser.add_argument("opt", choices=["get", "set", "add"], help="操作类型")
    parser.add_argument("app_id", type=int, help="App ID")
    parser.add_argument("options", nargs="*", help="Launch Options")

    parser.add_argument('-v', '--version', action='version', version='%(prog)s 1.0')
    
    args = parser.parse_args()
    if args.opt == "get":
        print(get_launch_options(args.app_id))
    elif args.opt == "set":
        print(f"Set launch options for app {args.app_id} to [{''.join(args.options)}]")
        set_launch_options(args.app_id, "".join(args.options))
    # elif args.opt == "add":
    #     options = get_launch_options(args.app_id)
    #     options += " " + " ".join(args.options)
    #     set_launch_options(args.app_id, options)
    else:
        print("Invalid operation")
        sys.exit(1)



if __name__ == "__main__":
    main()
