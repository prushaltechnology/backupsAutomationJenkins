#!/bin/bash
set -e

# Expects these env vars to be set by the calling Jenkinsfile:
# SERVER_HOST, SERVER_USER, DB_NAME, DB_USER, REMOTE_DIR, REMOTE_FILES,
# LOCAL_BACKUP_DIR, KEEP_LAST, INSTANCE_NAME, DB_PASS

STAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "${LOCAL_BACKUP_DIR}"

ssh -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_HOST}" "
    mkdir -p /tmp/backup_${STAMP} &&
    mysqldump -u ${DB_USER} -p'${DB_PASS}' ${DB_NAME} > /tmp/backup_${STAMP}/db.sql &&
    cp -r ${REMOTE_DIR} /tmp/backup_${STAMP}/folder &&
    cp ${REMOTE_FILES} /tmp/backup_${STAMP}/ &&
    tar -czf /tmp/backup_${STAMP}.tar.gz -C /tmp backup_${STAMP} &&
    rm -rf /tmp/backup_${STAMP}
"

rsync -avz -e "ssh -o StrictHostKeyChecking=no" \
    "${SERVER_USER}@${SERVER_HOST}:/tmp/backup_${STAMP}.tar.gz" \
    "${LOCAL_BACKUP_DIR}/${INSTANCE_NAME}_backup_${STAMP}.tar.gz"

ssh "${SERVER_USER}@${SERVER_HOST}" "rm -f /tmp/backup_${STAMP}.tar.gz"

cd "${LOCAL_BACKUP_DIR}"
ls -1t ${INSTANCE_NAME}_backup_*.tar.gz | tail -n +$((KEEP_LAST+1)) | xargs -r rm --