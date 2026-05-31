adb shell su -c "cp /data/data/com.example.sdaa/databases/bloom_v3.db /sdcard/bloom_v3.db"
adb pull /sdcard/bloom_v3.db
python bloom_analytics.py