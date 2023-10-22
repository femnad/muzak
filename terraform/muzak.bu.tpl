# vim: set filetype=yaml:
variant: fcos
version: 1.5.0
storage:
  directories:
    - path: ${music_mount_point}
      user:
        name: core
      group:
        name: core
    - path: ${navidrome_mount_point}
      user:
        name: core
      group:
        name: core
  files:
    - path: ${caddy_dir}/Caddyfile
      contents:
        inline: |
          {
              email ${email }
          }

          ${host} {
              reverse_proxy 127.0.0.1:4533
          }
  filesystems:
    - device: /dev/disk/by-id/google-navidrome
      format: ext4
      path: ${navidrome_mount_point}
systemd:
  units:
    - name: caddy.service
      enabled: true
      contents: |
        [Unit]
        Description=Fast and extensible multi-platform HTTP/1-2-3 web server with automatic HTTPS
        After=network-online.target
        Wants=network-online.target

        [Service]
        ExecStartPre=/usr/bin/chown -R core:core ${caddy_dir}
        ExecStart=/usr/bin/docker container run -p 443:443 --privileged --mount type=bind,source=${caddy_dir},target=/etc/caddy --rm --name caddy caddy:2.7.5-alpine

        [Install]
        WantedBy=multi-user.target
    - name: gcsfuse.service
      enabled: true
      contents: |
        [Unit]
        Description=A user-space file system for interacting with Google Cloud Storage
        After=network-online.target
        Wants=network-online.target

        [Service]
        ExecStart=/usr/bin/docker container run --device /dev/fuse --privileged --mount type=bind,source=${music_mount_point},target=${music_mount_point},bind-propagation=shared --rm --name gcsfuse ${gcsfuse_image} ${bucket} ${music_mount_point}

        [Install]
        WantedBy=multi-user.target
    - name: navidrome.service
      enabled: true
      contents: |
        [Unit]
        Description=Modern Music Server and Streamer compatible with Subsonic/Airsonic
        After=network-online.target
        Wants=network-online.target

        [Service]
        ExecStartPre=/usr/bin/chown -R core:core ${navidrome_mount_point}
        ExecStart=/usr/bin/docker container run --privileged --mount type=bind,source=${base_mount_point},target=${base_mount_point},bind-propagation=shared --rm --name navidrome ${navidrome_image} --datafolder ${navidrome_mount_point} --musicfolder ${music_mount_point}

        [Install]
        WantedBy=multi-user.target
