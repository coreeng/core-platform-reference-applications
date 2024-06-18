import { check } from 'k6';
import http from 'k6/http';

export function registerStubMapping(wiremockEndpoint, stubMappingDefinition) {
    const url = `${wiremockEndpoint}/__admin/mappings`;
    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
    };

    const res = http.post(url, JSON.stringify(stubMappingDefinition), params);
    check(res, {
        'stub mapping created': (r) => r.status === 201,
    });
}