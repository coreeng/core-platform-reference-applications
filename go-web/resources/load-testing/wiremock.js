import { check } from 'k6';
import http from 'k6/http';

export function registerStubMapping(config, stubMappingDefinition) {
    for (let i = 0; i < config.replicas; i++) {
        const replicaEndpoint = `http://wiremock-${i}.wiremocks:${config.port}`;
        callWiremock(replicaEndpoint, stubMappingDefinition);
    }
}

function callWiremock(endpoint, stubMappingDefinition) {
    const url = `${endpoint}/__admin/mappings`;
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