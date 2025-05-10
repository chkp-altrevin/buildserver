comm -23 <(apt-mark showmanual | sort) <(grep " install " /var/log/dpkg.log | cut -d " " -sf4 | grep -o "^[^:]*" | sort) > initial-sbom
