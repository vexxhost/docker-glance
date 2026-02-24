# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2024.2@sha256:662f7d137684e54d21bd3f93f6eec3d50967dbf66f4a6ef623bbb31de4272904 AS build
RUN --mount=type=bind,from=glance,source=/,target=/src/glance,readwrite \
    --mount=type=bind,from=glance_store,source=/,target=/src/glance_store,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        /src/glance \
        /src/glance_store[cinder] \
        storpool \
        storpool.spopenstack
EOF
ADD --chmod=644 \
    https://github.com/storpool/storpool-openstack-integration/raw/master/drivers/os_brick/openstack/caracal/storpool.py \
    /var/lib/openstack/lib/python3.12/site-packages/os_brick/initiator/connectors/storpool.py

FROM ghcr.io/vexxhost/python-base:2024.2@sha256:77ef39992ef9cfa3983fe3bf801f6c4fda0bf5fa0a4d9a4990d529655f4807f0
RUN \
    groupadd -g 42424 glance && \
    useradd -u 42424 -g 42424 -M -d /var/lib/glance -s /usr/sbin/nologin -c "Glance User" glance && \
    mkdir -p /etc/glance /var/log/glance /var/lib/glance /var/cache/glance && \
    chown -Rv glance:glance /etc/glance /var/log/glance /var/lib/glance /var/cache/glance
RUN <<EOF bash -xe
apt-get update -qq
apt-get install -qq -y --no-install-recommends \
    ceph-common dmidecode lsscsi nvme-cli python3-rados python3-rbd qemu-block-extra qemu-utils sysfsutils udev util-linux
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
ADD --chmod=755 https://dl.k8s.io/release/v1.29.3/bin/linux/amd64/kubectl /usr/local/bin/kubectl
COPY --from=build --link /var/lib/openstack /var/lib/openstack
