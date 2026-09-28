#!/bin/sh
set -eu

query_prometheus() {
	curl --fail --silent --show-error --get \
		--data-urlencode "query=$1" \
		"${PROMETHEUS_ENDPOINT%/}/api/v1/query" \
		| jq -e '.status == "success" and (.data.result | length == 0)' >/dev/null
}

query_prometheus \
	"avg(k6_http_req_duration{quantile=\"0.99\", namespace=\"${NAMESPACE}\", expected_response=\"true\"}) > 500" \
	|| (echo "Failed p(99) < 500ms" && false)

query_prometheus \
	"sum(rate(http_server_duration_milliseconds_count{namespace=\"${NAMESPACE}\"}[${DURATION}])) < ${REQ_PER_SECOND}*0.9" \
	|| (echo "Failed ${REQ_PER_SECOND} TPS" && false)

echo "Passed"
