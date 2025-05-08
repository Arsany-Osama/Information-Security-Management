#!/bin/bash

# Check if log file is provided as an argument/parameter
if [ $# -ne 1 ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

LOG_FILE="$1"
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' not found."
    exit 1
fi

# Temporary directory for intermediate file
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Analyze total, GET, POST, and other request counts
analyze_request_counts() {
    TOTAL_REQUESTS=$(wc -l < "$LOG_FILE")
    GET_REQUESTS=$(grep '"GET' "$LOG_FILE" | wc -l)
    POST_REQUESTS=$(grep '"POST' "$LOG_FILE" | wc -l)
    OTHER_REQUESTS=$(grep -vE '"(GET|POST)' "$LOG_FILE" | grep -E '"[A-Z]+' | wc -l)

    echo "1. Request Counts"
    echo "----------------"
    echo "Total Requests: $TOTAL_REQUESTS"
    echo "GET Requests: $GET_REQUESTS"
    echo "POST Requests: $POST_REQUESTS"
    echo "Other Requests: $OTHER_REQUESTS"
    echo ""
}

# Analyzing unique IP addresses and their GET/POST counts
analyze_unique_ips() {
    awk '{print $1}' "$LOG_FILE" | sort | uniq > "$TEMP_DIR/unique_ips.txt"
    UNIQUE_IP_COUNT=$(wc -l < "$TEMP_DIR/unique_ips.txt")

    : > "$TEMP_DIR/ip_requests.txt"
    while read -r ip; do
        ip_get=$(grep "$ip.*\"GET" "$LOG_FILE" | wc -l)
        ip_post=$(grep "$ip.*\"POST" "$LOG_FILE" | wc -l)
        echo "$ip $ip_get $ip_post" >> "$TEMP_DIR/ip_requests.txt"
    done < "$TEMP_DIR/unique_ips.txt"

    echo "2. Unique IP Addresses"
    echo "---------------------"
    echo "Total Unique IPs: $UNIQUE_IP_COUNT"
    echo "GET and POST Requests per IP (non-zero counts):"
    while read -r ip get_count post_count; do
        if [ "$get_count" -gt 0 ] || [ "$post_count" -gt 0 ]; then
            echo "  IP $ip: $get_count GET, $post_count POST"
        fi
    done < "$TEMP_DIR/ip_requests.txt"
    echo ""
}

# Analyze failed requests (4xx/5xx) and their percentage
analyze_failure_requests() {
    FAIL_REQUESTS=$(awk '$9 ~ /^[45][0-9][0-9]$/ {count++} END {print count+0}' "$LOG_FILE")
    FAIL_PERCENT=$(echo "scale=2; ($FAIL_REQUESTS / $TOTAL_REQUESTS) * 100" | bc)

    echo "3. Failure Requests"
    echo "------------------"
    echo "Failed Requests (4xx/5xx): $FAIL_REQUESTS"
    echo "Percentage of Failed Requests: $FAIL_PERCENT%"
    echo ""
}

# To find the most active IP
analyze_top_user() {
    awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 | while read -r count ip; do
        echo "4. Top User"
        echo "----------"
        echo "Most Active IP: $ip with $count requests"
        echo ""
    done
}

# Calculating average requests per day
analyze_daily_request_averages() {
    awk -F'[' '{print $2}' "$LOG_FILE" | awk -F':' '{print $1}' | sort | uniq -c > "$TEMP_DIR/daily_counts.txt"
    DAY_COUNT=$(wc -l < "$TEMP_DIR/daily_counts.txt")
    AVERAGE_REQUESTS=$(echo "scale=2; $TOTAL_REQUESTS / $DAY_COUNT" | bc)

    echo "5. Daily Request Averages"
    echo "------------------------"
    echo "Number of Days: $DAY_COUNT"
    echo "Average Requests per Day: $AVERAGE_REQUESTS"
    echo ""
}

# To identify days with the highest failure requests
analyze_failure_analysis() {
    awk '$9 ~ /^[45][0-9][0-9]$/ {print $4}' "$LOG_FILE" | awk -F'[' '{print $2}' | awk -F':' '{print $1}' | sort | uniq -c | sort -nr | head -5 > "$TEMP_DIR/fail_days.txt"

    echo "6. Failure Analysis"
    echo "-------------------"
    if [ -s "$TEMP_DIR/fail_days.txt" ]; then
        echo "Days with most failures:"
        cat "$TEMP_DIR/fail_days.txt" | while read -r count date; do
            echo "  $date: $count failed requests"
        done
    else
        echo "No failed requests found."
    fi
    echo ""
}

# To calculate requests per hour (per day and across all days)
analyze_requests_by_hour() {
    # Per-day hourly counts
    awk -F'[' '{print $2}' "$LOG_FILE" | awk -F':' '{print $1 " " $2}' | sort | uniq -c > "$TEMP_DIR/daily_hourly_counts.txt"
    echo "7. Requests by Hour"
    echo "------------------"
    echo "Requests per hour for each day:"
    current_date=""
    while read -r count date hour; do
        if [ "$date" != "$current_date" ]; then
            if [ -n "$current_date" ]; then
                echo ""
            fi
            echo "  $date:"
            current_date="$date"
        fi
        echo "    Hour $hour: $count requests"
    done < "$TEMP_DIR/daily_hourly_counts.txt"
    echo ""

    # Across all days
    awk -F'[' '{print $2}' "$LOG_FILE" | awk -F':' '{print $2}' | sort | uniq -c > "$TEMP_DIR/hourly_counts.txt"
    echo "Requests per hour (across all days):"
    cat "$TEMP_DIR/hourly_counts.txt" | while read -r count hour; do
        echo "  Hour $hour: $count requests"
    done
    echo ""
}

# To identify request trends
analyze_request_trends() {
    echo "8. Request Trends"
    echo "-----------------"
    echo "Hourly Trends (across all days):"
    cat "$TEMP_DIR/hourly_counts.txt" | sort -k2n | while read -r count hour; do
        echo "  Hour $hour: $count requests"
    done
    echo "Daily Trends:"
    cat "$TEMP_DIR/daily_counts.txt" | sort -k2 | while read -r count date; do
        echo "  $date: $count requests"
    done
    echo "Observations:"
    PEAK_HOUR=$(cat "$TEMP_DIR/hourly_counts.txt" | sort -nr | head -1 | awk '{print $2}')
    PEAK_HOUR_COUNT=$(cat "$TEMP_DIR/hourly_counts.txt" | sort -nr | head -1 | awk '{print $1}')
    echo "  - Peak hour: Hour $PEAK_HOUR with $PEAK_HOUR_COUNT requests."
    PEAK_DAY=$(cat "$TEMP_DIR/daily_counts.txt" | sort -nr | head -1 | awk '{print $2}')
    PEAK_DAY_COUNT=$(cat "$TEMP_DIR/daily_counts.txt" | sort -nr | head -1 | awk '{print $1}')
    echo "  - Peak day: $PEAK_DAY with $PEAK_DAY_COUNT requests."
    if [ "$(wc -l < "$TEMP_DIR/daily_counts.txt")" -gt 1 ]; then
        FIRST_DAY_COUNT=$(head -1 "$TEMP_DIR/daily_counts.txt" | awk '{print $1}')
        LAST_DAY_COUNT=$(tail -1 "$TEMP_DIR/daily_counts.txt" | awk '{print $1}')
        if [ "$LAST_DAY_COUNT" -gt "$FIRST_DAY_COUNT" ]; then
            echo "  - Trend: Request volume appears to increase over time."
        elif [ "$LAST_DAY_COUNT" -lt "$FIRST_DAY_COUNT" ]; then
            echo "  - Trend: Request volume appears to decrease over time."
        else
            echo "  - Trend: No clear increase or decrease in request volume over time."
        fi
    else
        echo "  - Single day detected; no daily trend analysis possible."
    fi
    echo ""
}

# To provide status code breakdown
analyze_status_codes() {
    awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr > "$TEMP_DIR/status_codes.txt"

    echo "9. Status Codes Breakdown"
    echo "-----------------------"
    echo "Status Code Frequency:"
    cat "$TEMP_DIR/status_codes.txt" | while read -r count code; do
        echo "  $code: $count occurrences"
    done
    echo ""
}

# To identify most active IPs by GET and POST methods
analyze_most_active_by_method() {
    echo "10. Most Active User by Method"
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
}

# To identify patterns in failure requests (by hour and day)
analyze_failure_patterns() {
    # Failures by hour
    awk '$9 ~ /^[45][0-9][0-9]$/ {print $4}' "$LOG_FILE" | awk -F'[' '{print $2}' | awk -F':' '{print $2}' | sort | uniq -c > "$TEMP_DIR/fail_hours.txt"
    # Failures by day (all days, not just top 5)
    awk '$9 ~ /^[45][0-9][0-9]$/ {print $4}' "$LOG_FILE" | awk -F'[' '{print $2}' | awk -F':' '{print $1}' | sort | uniq -c > "$TEMP_DIR/all_fail_days.txt"

    echo "11. Patterns in Failure Requests"
    echo "-------------------------------"
    if [ -s "$TEMP_DIR/fail_hours.txt" ]; then
        echo "Failed requests by hour:"
        cat "$TEMP_DIR/fail_hours.txt" | while read -r count hour; do
            echo "  Hour $hour: $count failed requests"
        done
    else
        echo "No failed requests by hour found."
    fi
    echo ""
    if [ -s "$TEMP_DIR/all_fail_days.txt" ]; then
        echo "Failed requests by day:"
        cat "$TEMP_DIR/all_fail_days.txt" | while read -r count date; do
            echo "  $date: $count failed requests"
        done
    else
        echo "No failed requests by day found."
    fi
    echo ""
}

# Main report anaylsis generation
echo "Log File Analysis Report"
echo "======================="
echo "Log File: $LOG_FILE"
echo ""

# Execute analysis functions in requirement order
analyze_request_counts
analyze_unique_ips
analyze_failure_requests
analyze_top_user
analyze_daily_request_averages
analyze_failure_analysis
analyze_requests_by_hour
analyze_request_trends
analyze_status_codes
analyze_most_active_by_method
analyze_failure_patterns

echo "Analysis Complete."