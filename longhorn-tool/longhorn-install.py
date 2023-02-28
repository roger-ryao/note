#!/usr/bin/env python3

import os
import sys
import subprocess
import time

if len(sys.argv) < 2:
    print("Please provide the version and kubeconfig path arguments.")
    print("Usage: python3 longhorn-install.py <version> [<kubeconfig path>]")
    print("Examples:")
    print("  python3 longhorn-install.py v1.4.0")
    print("  python3 longhorn-install.py v1.4.0 kubeconfig.yaml")
    sys.exit(1)

version = sys.argv[1]

home_dir = os.path.expanduser("~")
print(home_dir)

if len(sys.argv) == 2:
    kubeconfig = home_dir + "/.kube/config"
else:
    kubeconfig = sys.argv[2]

print(f"Using kubeconfig: {kubeconfig}")

# Taint control-plane nodes
get_nodes_cmd = f"kubectl --kubeconfig={kubeconfig} get node"
get_nodes_proc = subprocess.Popen(get_nodes_cmd.split(), stdout=subprocess.PIPE)
get_nodes_output, _ = get_nodes_proc.communicate()
control_nodes = [node.split()[0] for node in get_nodes_output.decode().split('\n') if "control-plane" in node.split()]

for node in control_nodes:
    taint_cmd = f"kubectl --kubeconfig={kubeconfig} taint node {node} node-role.kubernetes.io/master=true:NoExecute"
    subprocess.run(taint_cmd.split(), check=True)
    taint_cmd = f"kubectl --kubeconfig={kubeconfig} taint node {node} node-role.kubernetes.io/master=true:NoSchedule"
    subprocess.run(taint_cmd.split(), check=True)

print("Tainted control-plane nodes:")
get_nodes_cmd = f"kubectl --kubeconfig={kubeconfig} get node --show-labels"
get_nodes_proc = subprocess.Popen(get_nodes_cmd.split(), stdout=subprocess.PIPE)
get_nodes_output, _ = get_nodes_proc.communicate()
print([node for node in get_nodes_output.decode().split('\n') if "node-role.kubernetes.io/master=true" in node])

# Install Longhorn
nfs_install_cmd = f"kubectl --kubeconfig={kubeconfig} apply -f https://raw.githubusercontent.com/longhorn/longhorn/{version}/deploy/prerequisite/longhorn-nfs-installation.yaml"
subprocess.run(nfs_install_cmd.split(), check=True)

iscsi_install_cmd = f"kubectl --kubeconfig={kubeconfig} apply -f https://raw.githubusercontent.com/longhorn/longhorn/{version}/deploy/prerequisite/longhorn-iscsi-installation.yaml"
subprocess.run(iscsi_install_cmd.split(), check=True)

if version == "v1.3.x":
    longhorn_install_cmd = f"kubectl --kubeconfig={kubeconfig} apply -f longhorn-13x.yaml"
elif version == "v1.4.x":
    longhorn_install_cmd = f"kubectl --kubeconfig={kubeconfig} apply -f longhorn-14x.yaml"
else:
    longhorn_install_cmd = f"kubectl --kubeconfig={kubeconfig} apply -f https://raw.githubusercontent.com/longhorn/longhorn/{version}/deploy/longhorn.yaml"

subprocess.run(longhorn_install_cmd.split(), check=True)

# Wait for Longhorn components to be ready
time.sleep(30)
timeout = 180
print(f"Waiting for Longhorn components to be ready... (timeout: {timeout}s)")

wait_cmd = f"kubectl --kubeconfig={kubeconfig} wait --for=condition=ready pod --all -n longhorn-system --timeout={timeout}s"
try:
    output = subprocess.check_output(wait_cmd, shell=True, stderr=subprocess.STDOUT)
    print("All Longhorn components are ready.")
    print(output.decode())
except subprocess.CalledProcessError as e:
    print(f"Not all Longhorn components are ready after {timeout} seconds.")
    print(e.output.decode())
    exit(1)

#start_time = time.time()
#while True:
#    result = subprocess.run(wait_cmd.split(), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
#    if time.time() - start_time > timeout:
#        print("Timeout exceeded. Exiting...")
#        sys.exit(1)
#    if result != 0:
#        print("Longhorn is not ready yet. Retrying...")
#        print(result.stdout.decode())
#        time.sleep(10)
#    else:
#        print("Longhorn is ready.")
#        break

# Print Longhorn UI URL
longhorn_ui_url_cmd = "echo \"Longhorn UI: http://localhost:8000\""
subprocess.run(longhorn_ui_url_cmd, shell=True)

print("Installation completed successfully.")
