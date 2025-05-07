#!/bin/bash

# Check if log file is as an argument/parameter
if [ $# -ne 1 ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

LOG_FILE="$1"
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' not found."
    exit 1
fi

# Temporary directory for intermediate files
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Log File Analysis Report"
echo "======================="
echo "Log File: $LOG_FILE"
echo ""

# 1. Request Counts
TOTAL_REQUESTS=$(wc -l < "$LOG_FILE")
GET_REQUESTS=$(grep '"GET' "$LOG_FILE" | wc -l)
POST_REQUESTS=$(grep '"POST' "$LOG_FILE" | wc -l)

echo "1. Request Counts"
echo "----------------"
echo "Total Requests: $TOTAL_REQUESTS"
echo "GET Requests: $GET_REQUESTS"
echo "POST Requests: $POST_REQUESTS"
echo ""

# 2. Unique IP Addresses
awk '{print $1}' "$LOG_FILE" | sort | uniq > "$TEMP_DIR/unique_ips.txt"
UNIQUE_IP_COUNT=$(wc -l < "$TEMP_DIR/unique_ips.txt")

# Store IP request counts for later use
: > "$TEMP_DIR/ip_requests.txt"
while read -r ip; do
    ip_get=$(grep "$ip.*\"GET" "$LOG_FILE" | wc -l)
    ip_post=$(grep "$ip.*\"POST" "$LOG_FILE" | wc -l)
    echo "$ip $ip_get $ip_post" >> "$TEMP_DIR/ip_requests.txt"
done < "$TEMP_DIR/unique_ips.txt"

echo "2. Unique IP Addresses"
echo "---------------------"
echo "Total Unique IPs: $UNIQUE_IP_COUNT"
echo ""

# 3. Failure Requests
FAIL_REQUESTS=$(awk '$9 ~ /^[45][0-9][0-9]$/ {count++} END {print count+0}' "$LOG_FILE")
FAIL_PERCENT=$(echo "scale=2; ($FAIL_REQUESTS / $TOTAL_REQUESTS) * 100" | bc)

echo "3. Failure Requests"
echo "------------------"
echo "Failed Requests (4xx/5xx): $FAIL_REQUESTS"
echo "Percentage of Failed Requests: $FAIL_PERCENT%"
echo ""

# 4. Top User
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 | while read -r count ip; do
    echo "4. Top User"
    echo "----------"
    echo "Most Active IP: $ip with $count requests"
    echo ""
done

# 5. Daily Request Averages
awk -F'[' '{print $2}' "$LOG_FILE" | awk -F'/' '{print $1"/"$2"/"$3}' | sort | uniq -c > "$TEMP_DIR/daily_counts.txt"
DAY_COUNT=$(wc -l < "$TEMP_DIR/daily_counts.txt")
AVERAGE_REQUESTS=$(echo "scale=2; $TOTAL_REQUESTS / $DAY_COUNT" | bc)

echo "5. Daily Request Averages"
echo "------------------------"
echo "Number of Days: $DAY_COUNT"
echo "Average Requests per Day: $AVERAGE_REQUESTS"
echo "Requests per Day:"
cat "$TEMP_DIR/daily_counts.txt" | while read -r count date; do
    echo "  $date: $count requests"
done
echo ""

# 6. Days with Highest Failure Requests
awk '$9 ~ /^[45][0-9][0-9]$/ {print $4}' "$LOG_FILE" | awk -F'[' '{print $2}' | awk -F'/' '{print $1"/"$2"/"$3}' | sort | uniq -c | sort -nr > "$TEMP_DIR/fail_days.txt"

echo "6. Days with Highest Failure Requests"
echo "-----------------------------------"
if [ -s "$TEMP_DIR/fail_days.txt" ]; then
    echo "Days with most failures:"
    cat "$TEMP_DIR/fail_days.txt" | while read -r count date; do
        echo "  $date: $count failed requests"
    done
else
    echo "No failed requests found."
fi
echo ""

# 7. Requests by Hour
awk -F'[' '{print $2}' "$LOG_FILE" | awk -F':' '{print $2}' | sort | uniq -c > "$TEMP_DIR/hourly_counts.txt"

echo "7. Requests by Hour"
echo "------------------"
echo "Requests per hour (across all days):"
cat "$TEMP_DIR/hourly_counts.txt" | while read -r count hour; do
    echo "  Hour $hour: $count requests"
done
echo ""

# 8. Status Codes Breakdown
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr > "$TEMP_DIR/status_codes.txt"

echo "8. Status Codes Breakdown"
echo "-----------------------"
echo "Status Code Frequency:"
cat "$TEMP_DIR/status_codes.txt" | while read -r count code; do
    echo "  $code: $count occurrences"
done
echo ""

# 9. Most Active User by Method
echo "9. Most Active User by Method"
echo "----------------------------"
GET_TOP_IP=$(awk '{print $2 " " $1}' "$TEMP_DIR/ip_requests.txt" | sort -nr | head -1)
POST_TOP_IP=$(awk '{print $3 " " $1}' "$TEMP_DIR/ip_requests.txt" | sort -nr | head -1)
if [ -n "$GET_TOP_IP" ]; then
    read -r count ip <<< "$GET_TOP_IP"
    [ "$count" -gt 0 ] && echo "IP with most GET requests: $ip ($count GET requests)" || echo "No GET requests found."
else
    echo "No GET requests found."
fi
if [ -n "$POST_TOP_IP" ]; then
    read -r count ip <<< "$POST_TOP_IP"
    [ "$count" -gt 0 ] && echo "IP with most POST requests: $ip ($count POST requests)" || echo "No POST requests found."
else
    echo "No POST requests found."
fi
echo ""

# 10. Patterns in Failure Requests
awk '$9 ~ /^[45][0-9][0-9]$/ {print $4}' "$LOG_FILE" | awk -F'[' '{print $2}' | awk -F':' '{print $2}' | sort | uniq -c > "$TEMP_DIR/fail_hours.txt"

echo "10. Patterns in Failure Requests"
echo "-------------------------------"
if [ -s "$TEMP_DIR/fail_hours.txt" ]; then
    echo "Failed requests by hour:"
    cat "$TEMP_DIR/fail_hours.txt" | while read -r count hour; do
        echo "  Hour $hour: $count failed requests"
    done
else
    echo "No failed requests found."
fi
echo ""

# 11. Request Trends
echo "11. Request Trends"
echo "-----------------"
echo "Hourly Trends:"
cat "$TEMP_DIR/hourly_counts.txt" | sort -k2n | while read -r count hour; do
    echo "  Hour $hour: $count requests"
done
echo "Observations:"
# Check for peak hours
PEAK_HOUR=$(cat "$TEMP_DIR/hourly_counts.txt" | sort -nr | head -1 | awk '{print $2}')
PEAK_COUNT=$(cat "$TEMP_DIR/hourly_counts.txt" | sort -nr | head -1 | awk '{print $1}')
echo "  - Peak activity at hour $PEAK_HOUR with $PEAK_COUNT requests."
# Check for daily trends
if [ "$(wc -l < "$TEMP_DIR/daily_counts.txt")" -gt 1 ]; then
    echo "  - Multiple days detected; check daily counts for increasing/decreasing patterns."
else
    echo "  - Single day detected; no daily trend analysis possible."
fi
echo ""

echo "Analysis Complete."
