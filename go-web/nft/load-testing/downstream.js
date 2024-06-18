import { check } from 'k6';
import http from 'k6/http';
import {registerStubMapping} from "./wiremock.js";

export const options = {
    summaryTrendStats: ["avg", "min", "med", "max", "p(95)", "p(99)"],
    scenarios: {
        loadTest: {
            executor: 'constant-arrival-rate',
            rate: 1100, // add 10% buffer for dropped iterations
            timeUnit: '1s', // 1000 iterations per second, i.e. 1000 RPS
            duration: '3m',
            preAllocatedVUs: 200, // how large the initial pool of VUs would be
        },
    },
    thresholds: {
        checks: ['rate>0.99'],
        http_reqs: ['rate>999'],
        http_req_failed: ['rate<0.01'],
        http_req_duration: ['p(99)<500'],
    },
};

const SERVICE_ENDPOINT = __ENV.SERVICE_ENDPOINT || "http://reference-service";
const WIREMOCK_ENDPOINT = __ENV.WIREMOCK_ENDPOINT || "http://wiremock";

const testPath = "/api/test";
const testData = new Date().toString();

export function setup() {
    registerStubMapping(WIREMOCK_ENDPOINT, {
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