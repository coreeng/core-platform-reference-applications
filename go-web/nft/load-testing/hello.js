import { check } from 'k6';
import http from 'k6/http';

export const options = {
    summaryTrendStats: ["avg", "min", "med", "max", "p(95)", "p(99)"],
    scenarios: {
        loadTest: {
            executor: 'constant-arrival-rate',
            rate: 1100, // add 10% buffer for dropped iterations
            timeUnit: '1s', // 1000 iterations per second, i.e. 1000 RPS
            duration: '30s',
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

const SERVICE_ENDPOINT = __ENV.SERVICE_ENDPOINT || "http://service:8080";

export default function () {
    const res = http.get(`${SERVICE_ENDPOINT}/hello`);
    check(res, {
        'status is 200': (r) => r.status === 200,
        'response body is correct': (r) => r.body.includes("Hello world"),
    });
}