#!/usr/bin/env python3

import subprocess
import time
import sys
import os
import logging

# Check if version argument is provided
if len(sys.argv) < 2:
    print("Please provide a Longhorn version number as an argument.")
    print("Usage: python3 uninstall-longhorn.py <version> [<kubeconfig path>]")
    print("Examples:")
    print("  python3 uninstall-longhorn.py v1.4.0")
    print("  python3 uninstall-longhorn.py v1.4.0 kubeconfig.yaml")
    sys.exit(1)

version = sys.argv[1]

home_dir = os.path.expanduser("~")
print(home_dir)

if len(sys.argv) == 2:
    kubeconfig = home_dir + "/.kube/config"
else:
    kubeconfig = sys.argv[2]

print(f"Using kubeconfig: {kubeconfig}")

# Confirm that the user wants to proceed with the uninstall
confirmation = input(
    "Are you sure you want to uninstall Longhorn? This action cannot be undone. (y/n)")
if confirmation.lower() != "y":
    print("Uninstall aborted.")
    sys.exit(1)

# Allow for the uninstallation of Longhorn and modify deletion confirmation flag (only for v1.4+)
if version.startswith("v1.4") or version.startswith("v1.5") or version.startswith("v1.6"):
    retry_count = 0
    max_retries = 3
    expected_output = f"setting.longhorn.io/deleting-confirmation-flag patched"
    while True:
        cmd = f"kubectl --kubeconfig={kubeconfig} -n longhorn-system patch -p '{{\"value\": \"true\"}}' --type=merge setting.longhorn.io/deleting-confirmation-flag"
        command_output = subprocess.run(
            cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        if expected_output in command_output.stdout or expected_output in command_output.stderr:
            print(f"stdout: {command_output.stdout}")
            print(f"stderr: {command_output.stderr}")
            print("Successfully set deleting-confirmation-flag to true")
            break
        else:
            retry_count += 1
            if retry_count > max_retries:
                print(
                    f"Failed to set deleting-confirmation-flag after {retry_count} retries. Expected output: {expected_output}")
                sys.exit(1)
            else:
                print(
                    f"Failed to set deleting-confirmation-flag. Retrying in 30 seconds... (retry {retry_count}/{max_retries})")
                time.sleep(5)


# Uninstall Longhorn
subprocess.run(
    f"kubectl --kubeconfig={kubeconfig} create -f https://raw.githubusercontent.com/longhorn/longhorn/{version}/uninstall/uninstall.yaml", shell=True, check=True)

# Wait for the Longhorn uninstall job to complete (different namespaces for different versions)
if version.startswith("v1.4") or version.startswith("v1.5") or version.startswith("v1.6"):
    namespace = "longhorn-system"
else:
    namespace = "default"
subprocess.run(
    f"kubectl --kubeconfig={kubeconfig} wait --for=condition=complete job/longhorn-uninstall -n {namespace} --timeout=5m", shell=True, check=True)

# Remove remaining components
try:
    subprocess.run(
        f"kubectl --kubeconfig={kubeconfig} delete -f https://raw.githubusercontent.com/longhorn/longhorn/{version}/deploy/longhorn.yaml", shell=True, stderr=subprocess.DEVNULL)
except subprocess.CalledProcessError as e:
    print(f"Error deleting longhorn.yaml: {e.stderr}")

try:
    subprocess.run(f"kubectl --kubeconfig={kubeconfig} delete -f https://raw.githubusercontent.com/longhorn/longhorn/{version}/uninstall/uninstall.yaml",
                   shell=True, check=True, stderr=subprocess.DEVNULL)
except subprocess.CalledProcessError as e:
    error_msg = e.stderr.decode(
        'utf-8').strip() if e.stderr else "Unknown error"
    if error_msg:
        if error_msg != "Unknown error":
            print(f"Error deleting uninstall.yaml: {error_msg}")
        else:
            print("Longhorn uninstallation job deleted successfully")


# Continuously check if the longhorn-system namespace exists, if it does, continue waiting until timeout
# Set waiting time to 3 minutes
timeout = 180

# Set up logging
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s %(levelname)s: %(message)s')
logging.info("Waiting for longhorn-system namespace to be deleted...")

start_time = time.time()
deleted_successfully = False
while time.time() - start_time < timeout:
    cmd = f"kubectl --kubeconfig={kubeconfig} get ns longhorn-system"
    command_output = subprocess.run(
        cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    print(f"stdout: {command_output.stdout}")
    print(f"stderr: {command_output.stderr}")
    if "namespaces \"longhorn-system\" not found" in command_output.stderr:
        print("longhorn-system namespace has been deleted successfully.")
        logging.info("longhorn-system namespace has been deleted.")
        deleted_successfully = True
        break
    else:
        logging.info(
            f"longhorn-system namespace still exists. {timeout - int(time.time() - start_time)} seconds remaining until timeout.")
        time.sleep(10)

if not deleted_successfully:
    logging.warning("Timeout reached. longhorn-system namespace has not been deleted.")
    exit(1)
