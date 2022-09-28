#python IOGen.py IOManager_PreGen.sv IOConfig.cfg
import glob, importlib, os, pathlib, sys

# Config Read - Called once per file
def cfg_gen():
    cfg_path = os.argv[3]
    with open(cfg_path, "r") as cfg:
        cfg_content = cfg.readlines()

# Template Grab - Called once per GEN/ENDGEN block

# Example Swap





#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# IOGen_TopPorts
def IOGen_TopPorts(cfg):
    local_config = cfg_gen()

# IOGen_Top
def IOGen_Top(cfg):
    pass

# IOGen_ManagerParameters
def IOGen_ManagerParameters(cfg):
    pass

# IOGen_Ports
def IOGen_Ports(cfg):
    pass

# IOGen_Controllers
def IOGen_Controllers(cfg):
    pass