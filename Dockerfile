# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2025.1@sha256:93f80ea5e60b52f2da4f315b5e5040c03bbdc192ccf36ab4d38175b8afc6928a AS build
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

FROM ghcr.io/vexxhost/python-base:2025.1@sha256:80c672d6cbf2c7efbe34f0cdd4f08d5a0674f1c144f553f9fcad3630a824114a
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
ADD --chmod=755 https://dl.k8s.io/release/v1.34.1/bin/linux/amd64/kubectl /usr/local/bin/kubectl
COPY --from=build --link /var/lib/openstack /var/lib/openstack
