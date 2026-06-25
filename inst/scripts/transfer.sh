## see /home/$USER/.config/rclone/rclone.conf
## entry example
## [cf_u24_rw]
## type = s3
## provider = Ceph
## access_key_id = **
## secret_access_key = **
## endpoint = https://nyu1.osn.mghpcc.org
## no_check_bucket = true

## count json.gz files in json folder
## rclone ls cf_u24_ro:waldronlab-image-features/hovernet/json

## copy folders to bucket
rclone copy /mnt/STORE1/imagetcga/hovernet/json  \
    cf_u24_rw:waldronlab-image-features/hovernet/json \
    --exclude "*.json" -vv --dry-run

## copy parquet to bucket
rclone copy /mnt/STORE1/imagetcga/hovernet/parquet \
    cf_u24_rw:waldronlab-image-features/hovernet/parquet \
    -vv --dry-run
