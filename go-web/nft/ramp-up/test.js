import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '20s', target: 200 },
        { duration: '20s', target: 100 },
        { duration: '2m', target: 50 },
    ],
    thresholds: {
        'http_req_duration{status:200}': ['max>=0'],
        'http_req_duration{status:403}': ['max>=0'],
        'http_req_duration{status:404}': ['max>=0'],
        'http_req_duration{status:503}': ['max>=0'],
    },
};

const SERVICE_ENDPOINT = __ENV.SERVICE_ENDPOINT || "http://service:8080";

export default function () {
    const res = http.get(`${SERVICE_ENDPOINT}/hello`);
    check(res, { 'status was 200': (r) => r.status == 200 });
    sleep(1);
}