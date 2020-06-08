FROM easzlab/kubeasz:2.1.0

RUN apk update && \
    apk add pwgen util-linux curl

COPY ./ansible-file/90.setup.yml /etc/ansible/90.setup.yml

COPY ./ansible-file/install-rainbond /etc/ansible/roles/install-rainbond

COPY ./easzup /etc/ansible/tools/easzup

COPY ./easzctl /usr/bin/easzctl
COPY ./easzctl /etc/ansible/tools/easzctl