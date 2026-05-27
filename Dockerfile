# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2023.2@sha256:f2feae082b5e0f5114df2deb122df81b6f7893a0e41a6ff8f1aecb1963a5d4cd AS build
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
    https://github.com/storpool/storpool-openstack-integration/raw/master/drivers/os_brick/openstack/bobcat/storpool.py \
    /var/lib/openstack/lib/python3.10/site-packages/os_brick/initiator/connectors/storpool.py

FROM ghcr.io/vexxhost/python-base:2023.2@sha256:a536af52a25e5f5247b34f7c17cb35addfdb64bb1abcc6d83e0f62842315f26c
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
