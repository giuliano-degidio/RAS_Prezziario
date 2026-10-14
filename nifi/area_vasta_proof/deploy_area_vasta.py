#!/usr/bin/env python3
"""Deploy a NiFi proof flow for frontiera_anag_area_vasta via NiFi REST API.

Environment variables required:
  NIFI_BASE_URL      e.g. https://192.168.248.135:8443/nifi
  NIFI_USERNAME      NiFi username
  NIFI_PASSWORD      NiFi password
  RASOP_JDBC_URL     e.g. jdbc:postgresql://192.168.248.135:5432/RAS_Operazionales
  RASOP_DB_USER      e.g. postgres
  RASOP_DB_PASSWORD  source DB password
  HCBI_JDBC_URL      e.g. jdbc:postgresql://192.168.248.135:5432/hcbi
  HCBI_DB_USER       e.g. hcbi
  HCBI_DB_PASSWORD   target DB password
Optional:
  POSTGRES_JDBC_JAR  path to postgres JDBC jar if not already installed in NiFi lib
  NIFI_VERIFY_SSL    0 to skip SSL verification (default: 0)
"""

import json
import os
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

SPEC_PATH = Path(__file__).with_name('flow_spec.json')
SPEC = json.loads(SPEC_PATH.read_text(encoding='utf-8'))

NIFI_BASE_URL = os.environ.get('NIFI_BASE_URL', '').rstrip('/')
NIFI_USERNAME = os.environ.get('NIFI_USERNAME', '')
NIFI_PASSWORD = os.environ.get('NIFI_PASSWORD', '')
VERIFY_SSL = os.environ.get('NIFI_VERIFY_SSL', '0') not in ('0', 'false', 'False', '')

RASOP_JDBC_URL = os.environ.get('RASOP_JDBC_URL', '')
RASOP_DB_USER = os.environ.get('RASOP_DB_USER', '')
RASOP_DB_PASSWORD = os.environ.get('RASOP_DB_PASSWORD', '')
HCBI_JDBC_URL = os.environ.get('HCBI_JDBC_URL', '')
HCBI_DB_USER = os.environ.get('HCBI_DB_USER', '')
HCBI_DB_PASSWORD = os.environ.get('HCBI_DB_PASSWORD', '')
POSTGRES_JDBC_JAR = os.environ.get('POSTGRES_JDBC_JAR', '')

REQUIRED = {
    'NIFI_BASE_URL': NIFI_BASE_URL,
    'NIFI_USERNAME': NIFI_USERNAME,
    'NIFI_PASSWORD': NIFI_PASSWORD,
    'RASOP_JDBC_URL': RASOP_JDBC_URL,
    'RASOP_DB_USER': RASOP_DB_USER,
    'RASOP_DB_PASSWORD': RASOP_DB_PASSWORD,
    'HCBI_JDBC_URL': HCBI_JDBC_URL,
    'HCBI_DB_USER': HCBI_DB_USER,
    'HCBI_DB_PASSWORD': HCBI_DB_PASSWORD,
}

missing = [k for k, v in REQUIRED.items() if not v]
if missing:
    print('Missing environment variables: ' + ', '.join(missing), file=sys.stderr)
    sys.exit(2)

if not POSTGRES_JDBC_JAR:
    print('Missing environment variable: POSTGRES_JDBC_JAR (path to the PostgreSQL JDBC driver jar)', file=sys.stderr)
    sys.exit(2)

jar_path = Path(POSTGRES_JDBC_JAR)
if not jar_path.is_file():
    print('POSTGRES_JDBC_JAR does not point to an existing file: {0}'.format(POSTGRES_JDBC_JAR), file=sys.stderr)
    sys.exit(2)

API_BASE = NIFI_BASE_URL.replace('/nifi', '/nifi-api') if NIFI_BASE_URL.endswith('/nifi') else NIFI_BASE_URL.rstrip('/') + '/nifi-api'
CLIENT_ID = str(uuid.uuid4())

ctx = ssl.create_default_context()
if not VERIFY_SSL:
    ctx = ssl._create_unverified_context()


def http_request(path, method='GET', data=None, headers=None, form=None, content_type=None):
    url = API_BASE + path
    req_headers = headers.copy() if headers else {}
    if content_type:
        req_headers['Content-Type'] = content_type
    req = urllib.request.Request(url, method=method, headers=req_headers)
    if form is not None:
        data = urllib.parse.urlencode(form).encode('utf-8')
        req.add_header('Content-Type', 'application/x-www-form-urlencoded')
    if data is not None:
        req.data = data
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=60) as resp:
            return resp.status, dict(resp.headers.items()), resp.read()
    except urllib.error.HTTPError as e:
        return e.code, dict(e.headers.items()), e.read()


def login():
    status, _, body = http_request('/access/token', method='POST', form={'username': NIFI_USERNAME, 'password': NIFI_PASSWORD})
    if status not in (200, 201):
        raise SystemExit('NiFi login failed ({0}): {1}'.format(status, body.decode('utf-8', errors='replace')))
    return body.decode('utf-8').strip()


def api(path, method='GET', token=None, payload=None):
    headers = {}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    data = None
    if payload is not None:
        data = json.dumps(payload).encode('utf-8')
        headers['Content-Type'] = 'application/json'
    status, _, body = http_request(path, method=method, data=data, headers=headers)
    if status >= 400:
        raise SystemExit('{0} {1} failed ({2}): {3}'.format(method, path, status, body.decode('utf-8', errors='replace')))
    return json.loads(body.decode('utf-8')) if body else {}


def get_root_group_id(token):
    # In NiFi the root group id is exposed as "root" in the REST path.
    api('/flow/process-groups/root', token=token)
    return 'root'


def create_process_group(token, parent_id, name, x, y):
    body = {
        'revision': {'clientId': CLIENT_ID, 'version': 0},
        'component': {'name': name, 'position': {'x': x, 'y': y}}
    }
    resp = api('/process-groups/{0}/process-groups'.format(parent_id), method='POST', token=token, payload=body)
    return resp['component']['id']


def create_controller_service(token, pg_id, name, typ, properties):
    body = {
        'revision': {'clientId': CLIENT_ID, 'version': 0},
        'component': {
            'name': name,
            'type': typ,
            'properties': properties,
            'comments': SPEC['description'],
        }
    }
    resp = api('/process-groups/{0}/controller-services'.format(pg_id), method='POST', token=token, payload=body)
    return resp['component']['id']


def create_processor(token, pg_id, name, typ, x, y, properties, auto_terms, scheduling_period='0 sec'):
    body = {
        'revision': {'clientId': CLIENT_ID, 'version': 0},
        'component': {
            'name': name,
            'type': typ,
            'position': {'x': x, 'y': y},
            'config': {'schedulingStrategy': 'TIMER_DRIVEN', 'schedulingPeriod': scheduling_period},
            'properties': properties,
            'autoTerminatedRelationships': auto_terms,
        }
    }
    resp = api('/process-groups/{0}/processors'.format(pg_id), method='POST', token=token, payload=body)
    return resp['component']['id']


def connect(token, pg_id, source_id, dest_id, rels):
    body = {
        'revision': {'clientId': CLIENT_ID, 'version': 0},
        'component': {
            'source': {'id': source_id, 'type': 'PROCESSOR', 'groupId': pg_id},
            'destination': {'id': dest_id, 'type': 'PROCESSOR', 'groupId': pg_id},
            'selectedRelationships': rels,
            'labelIndex': 1,
            'bends': []
        }
    }
    api('/process-groups/{0}/connections'.format(pg_id), method='POST', token=token, payload=body)


def enable_service(token, service_id):
    body = {'revision': {'clientId': CLIENT_ID, 'version': 0}, 'state': 'ENABLED'}
    api('/controller-services/{0}/run-status'.format(service_id), method='PUT', token=token, payload=body)


def main():
    token = login()
    root_id = get_root_group_id(token)

    pg_id = create_process_group(token, root_id, SPEC['name'], 0.0, 0.0)

    jar = POSTGRES_JDBC_JAR
    rasop_service = create_controller_service(
        token, pg_id, 'rasop-dbcp', 'org.apache.nifi.dbcp.DBCPConnectionPool',
        {
            'Database Connection URL': RASOP_JDBC_URL,
            'Database Driver Class Name': 'org.postgresql.Driver',
            'Database Driver Location(s)': jar,
            'Database User': RASOP_DB_USER,
            'Password': RASOP_DB_PASSWORD,
        }
    )
    hcbi_service = create_controller_service(
        token, pg_id, 'hcbi-dbcp', 'org.apache.nifi.dbcp.DBCPConnectionPool',
        {
            'Database Connection URL': HCBI_JDBC_URL,
            'Database Driver Class Name': 'org.postgresql.Driver',
            'Database Driver Location(s)': jar,
            'Database User': HCBI_DB_USER,
            'Password': HCBI_DB_PASSWORD,
        }
    )
    avro_reader = create_controller_service(
        token, pg_id, 'avro-reader', 'org.apache.nifi.avro.AvroReader',
        {}
    )

    enable_service(token, rasop_service)
    enable_service(token, hcbi_service)
    enable_service(token, avro_reader)

    p1 = create_processor(
        token, pg_id, 'Generate trigger', 'org.apache.nifi.processors.standard.GenerateFlowFile', 0.0, 0.0,
        {'Batch Size': '1', 'Custom Text': 'trigger', 'Data Format': 'Text'}, [], '5 min'
    )
    p2 = create_processor(
        token, pg_id, 'Prepare truncate SQL', 'org.apache.nifi.processors.standard.ReplaceText', 300.0, 0.0,
        {'Evaluation Mode': 'Entire text', 'Replacement Strategy': 'Always Replace', 'Replacement Value': SPEC['truncateSql']},
        []
    )
    p3 = create_processor(
        token, pg_id, 'Truncate target', 'org.apache.nifi.processors.standard.PutSQL', 600.0, 0.0,
        {'JDBC Connection Pooling Service': 'hcbi-dbcp'},
        []
    )
    p4 = create_processor(
        token, pg_id, 'Query rasop', 'org.apache.nifi.processors.standard.ExecuteSQL', 900.0, 0.0,
        {'JDBC Connection Pool': 'rasop-dbcp', 'SQL select query': SPEC['sourceQuery']},
        []
    )
    p5 = create_processor(
        token, pg_id, 'Insert into hcbi', 'org.apache.nifi.processors.standard.PutDatabaseRecord', 1200.0, 0.0,
        {
            'Database Connection Pooling Service': 'hcbi-dbcp',
            'Record Reader': 'avro-reader',
            'Schema Name': 'hcbi_ras',
            'Table Name': 'frontiera_anag_area_vasta',
            'Statement Type': 'INSERT',
        },
        ['success']
    )
    p6 = create_processor(
        token, pg_id, 'Log failure and stop', 'org.apache.nifi.processors.standard.LogMessage', 1500.0, 0.0,
        {
            'Log Level': 'warn',
            'Log Message': 'POC_FRONTIERA_ANAG_AREA_VASTA failed; see bulletins and processor logs.'
        },
        ['success']
    )

    connect(token, pg_id, p1, p2, ['success'])
    connect(token, pg_id, p2, p3, ['success'])
    connect(token, pg_id, p3, p4, ['success'])
    connect(token, pg_id, p4, p5, ['success'])
    connect(token, pg_id, p2, p6, ['failure'])
    connect(token, pg_id, p3, p6, ['failure', 'retry'])
    connect(token, pg_id, p4, p6, ['failure'])
    connect(token, pg_id, p5, p6, ['failure'])

    print('Created process group: {0}'.format(pg_id))
    print('Controller services enabled: {0}, {1}, {2}'.format(rasop_service, hcbi_service, avro_reader))
    print('Processors: {0}, {1}, {2}, {3}, {4}, {5}'.format(p1, p2, p3, p4, p5, p6))
    print('Next: open NiFi UI, enter the group, and start the processors in order.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
