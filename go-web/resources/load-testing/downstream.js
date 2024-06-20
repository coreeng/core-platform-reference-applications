import { check } from 'k6';
import http from 'k6/http';
import {registerStubMapping} from "./wiremock.js";

const SERVICE_ENDPOINT = __ENV.SERVICE_ENDPOINT || "http://reference-service";
const REQ_PER_SECOND = __ENV.REQ_PER_SECOND || 1000
const DURATION = __ENV.DURATION || "1m"
const VUS = __ENV.VUS || 200

const wiremockConfig = {
    port: __ENV.WIREMOCK_PORT || "8080",
    replicas: __ENV.WIREMOCK_REPLICAS || 1,
}

const testPath = "/api/test";
const testData = "Wed Mar 13 2024 08:48:49 GMT+0000 (UTC)";

export const options = {
    summaryTrendStats: ["avg", "min", "med", "max", "p(95)", "p(99)"],
    scenarios: {
        loadTest: {
            executor: 'constant-arrival-rate',
            rate: REQ_PER_SECOND,
            timeUnit: '1s', // iterations per second
            duration: DURATION,
            preAllocatedVUs: VUS, // how large the initial pool of VUs would be
        },
    },
    thresholds: {
        checks: ['rate>0.99'],
        http_reqs: ['rate>' + REQ_PER_SECOND * 0.9],
        http_req_failed: ['rate<0.01'],
        http_req_duration: ['p(99)<500'],
    },
    tags: {
        test_name: 'downstream',
    },
};

export function setup() {
    registerStubMapping(wiremockConfig, {
        request: {
            method: 'GET',
            url: testPath
        },
        response: {
            status: 200,
            jsonBody: {
                data: testData
            },
            headers: {
                'Content-Type': 'application/json'
            }
        }
    });
}

export default function () {
    const res = http.get(`${SERVICE_ENDPOINT}/downstream${testPath}`);
    check(res, {
        'status is 200': (r) => r.status === 200,
        'response body contains stubbed data': (r) => r.body.includes(testData),
    });
}