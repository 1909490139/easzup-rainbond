FROM easzlab/kubeasz:2.1.0

COPY ./ansible-file/90.setup.yml /etc/ansible/90.setup.yml

COPY ./ansible-file/install-rainbond /etc/ansible/roles/install-rainbond

COPY ./easzup /etc/ansible/tools/easzup

