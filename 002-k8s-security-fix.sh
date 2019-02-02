#!/usr/bin/env bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

# security fixup for exposing via kubernetes, which impersonates local TCP connections
sed -i 's@host.*all.*all.*127.0.0.1/32.*@host\tall\t\tall\t\t127.0.0.1/32\t\tscram-sha-256@' /var/lib/postgresql/data/pg_hba.conf
sed -i 's@host.*all.*all.*::1/128.*@host\tall\t\tall\t\t::1/128\t\t\tscram-sha-256@' /var/lib/postgresql/data/pg_hba.conf
sed -i 's@host all all all trust@#host all all all scram-sha-256@' /var/lib/postgresql/data/pg_hba.conf
/usr/lib/postgresql/11/bin/pg_ctl -D /var/lib/postgresql/data reload -s
psql -c "SET password_encryption = 'scram-sha-256';alter user postgres with password 'kyrixftw'"
