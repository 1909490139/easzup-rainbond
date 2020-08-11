FROM easzlab/kubeasz:2.1.0

COPY ./ansible-file/ /etc/ansible/

COPY ./easzup /etc/ansible/tools/easzup

COPY ./easzctl /usr/bin/easzctl
COPY ./easzctl /etc/ansible/tools/easzctl