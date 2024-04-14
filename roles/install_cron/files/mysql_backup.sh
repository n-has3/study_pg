#!/bin/bash

source /etc/profile

# MySQLの接続情報
DB_USER="root"
DB_PASSWORD="$DB_PASSWORD"
# backup対象のDB名を入れる
DB_NAME="<対象のDB名>"

# バックアップディレクトリとファイル名
BACKUP_DIR="/tmp"
# 日付を取得
DATE=$(date +%F)
BACKUP_FILE="$BACKUP_DIR/backup_$DATE.sql"

# MySQLのバックアップを作成
mysqldump -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_FILE"

# 圧縮
gzip "$BACKUP_FILE"

# 5日前のバックアップを削除
find "$BACKUP_DIR" -type f -name "backup_*" -mtime +5 -exec rm {} \;